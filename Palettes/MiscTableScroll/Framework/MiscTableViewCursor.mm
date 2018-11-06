//=============================================================================
//
//	Copyright (C) 1995-1999 by Paul S. McCarthy and Eric Sunshine.
//		Written by Paul S. McCarthy and Eric Sunshine.
//			    All Rights Reserved.
//
//	This notice may not be removed from this source code.
//
//	This object is included in the MiscKit by permission from the authors
//	and its use is governed by the MiscKit license, found in the file
//	"License.rtf" in the MiscKit distribution.  Please refer to that file
//	for a list of all applicable permissions and restrictions.
//
//=============================================================================
//-----------------------------------------------------------------------------
// MiscTableViewCursor.M
//
//	Keyboard cursor methods for MiscTableView.
//
// FIXME: The PostScript pattern used to draw the dotted "keyboard focus" 
//	rectangle gets "out-of-phase" as this view scrolls.  Consequently it 
//	does not tile correctly.  The Adobe Purple Book section 10.4.4 implies 
//	that the pattern has to be recreated each time the view changes.  (I 
//	forsee using -initGState for this.) As an alternative, consider using 
//	NSDottedFrameRect() which is available under OPENSTEP 4.2, but not 4.1.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableViewCursor.M,v 1.3 99/06/15 04:03:27 sunshine Exp $
// $Log:	MiscTableViewCursor.M,v $
// Revision 1.3  99/06/15  04:03:27  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Sends new -didBecomeFirstResponder & -didResignFirstResponder messages to
// owning MiscTableScroll.  No longer notifies NSFontManager when becoming
// first responder.  MiscTableScroll is now responsible for that. 
// 
// Revision 1.2  98/03/29  23:59:05  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscTableViewPrivate.h"
#import "MiscTableBorder.h"
#import "MiscMouseTracker.h"
#import <AppKit/NSFontManager.h>
#import <AppKit/NSWindow.h>

extern "C" {
//#import "MiscTableViewPS.h"
	extern void MISC_TV_initps(void);
	extern void MISC_TV_dashedrects(float const*, int);
}
#include <cmath>

int const NUM_EDGES = 4;	// 4 edges to draw per focus rectangle
int const NUM_COORDS = 4;	// 4 coords per rectangle (x,y,w,h)
int const MAX_COORDS = NUM_EDGES * NUM_COORDS;	// 16 coords per 4 rects

//-----------------------------------------------------------------------------
// init_pswrap
//-----------------------------------------------------------------------------
static inline void init_pswrap()
{
    static BOOL initialized = NO;
    if (!initialized)
    {
        initialized = YES;
        MISC_TV_initps();
    }
}


@implementation MiscTableView(Cursor)
//=============================================================================
// CURSOR DRAWING
//=============================================================================
- (BOOL)isCursorEnabled	{ return (inhibitCursor == 0); }
- (void)disableCursor	{ inhibitCursor++; }
- (void)enableCursor	{ inhibitCursor--; }


//-----------------------------------------------------------------------------
// - shouldDrawCursor
//-----------------------------------------------------------------------------
- (BOOL)shouldDrawCursor
{
    NSWindow* w = [self window];
    return ([self isCursorEnabled] && [self canDraw] && [w isKeyWindow] &&
            [w firstResponder] == self);
}


//-----------------------------------------------------------------------------
// - getCursorSlot
//-----------------------------------------------------------------------------
- (MiscCoord_V)getCursorSlot
{
    MiscTableBorder* const b = [self borderFor:trackerBorder];
    MiscCoord_V vslot = b->getCursor();
    int const lim = b->count();
    if (lim > 0 && (vslot < 0 || vslot >= lim))
    {
        vslot = b->selectedSlot();
        if (vslot < 0)
            vslot = b->physicalToVisual([self firstVisibleSlot:trackerBorder]);
        NSParameterAssert( 0 <= vslot );
        NSParameterAssert( vslot < lim );
        b->setCursor( vslot );
    }
    return vslot;
}


//-----------------------------------------------------------------------------
// - getCursorFrame:
//-----------------------------------------------------------------------------
- (NSRect)getCursorFrame:(NSRect)clip
{
    NSRect ret = NSZeroRect;
    if (rowBorder->count() > 0 && colBorder->count() > 0)
    {
        MiscTableBorder* const b = [self borderFor:trackerBorder];
        MiscCoord_P const pslot = b->visualToPhysical( [self getCursorSlot] );
        if (pslot >= 0)
        {
            NSRect r = [self getSlotInsideAt:pslot from:trackerBorder];
            if (NSIntersectsRect( r, clip ))
                ret = r;
        }
    }
    return ret;
}


//-----------------------------------------------------------------------------
// - getCursorEdges:clipTo:
//
//	Compute rectangles for drawing which make up the edges of the "focus
//	frame".  Each edge is composed of values from the focus frame,
//	possibly including its: X, Y, MAXX, MAXY.
//-----------------------------------------------------------------------------
- (int)getCursorEdges:(NSRect*)edges clipTo:(NSRect)clip
{
    struct TV_Lines { char xs, maxxs, xc, ys, maxys, yc, ws, wc, hs, hc; };
    static TV_Lines const LINES[ NUM_EDGES ] =
    {
        { 1, 0,  0, 1, 0,  0, 1,  0, 0,  1 }, // top
        { 1, 0,  0, 0, 1, -1, 1,  0, 0,  1 }, // bottom
        { 1, 0,  0, 1, 0,  1, 0,  1, 1, -2 }, // left
        { 0, 1, -1, 1, 0,  1, 0,  1, 1, -2 }, // right
    };

    NSRect* edge = edges;
    NSRect rCursor = [self getCursorFrame:clip];
    if (!NSIsEmptyRect( rCursor ))
    {
        for (int i = 0; i < NUM_EDGES; i++)
        {
            TV_Lines const& l = LINES[i];
            NSRect r = NSMakeRect(
                                  l.xs * NSMinX(rCursor) + l.maxxs * NSMaxX(rCursor) + l.xc,
                                  l.ys * NSMinY(rCursor) + l.maxys * NSMaxY(rCursor) + l.yc,
                                  l.ws * NSWidth(rCursor) + l.wc,
                                  l.hs * NSHeight(rCursor) + l.hc );
            r = NSIntersectionRect( clip, r );
            if (!NSIsEmptyRect(r))
                *edge++ = r;
        }
    }
    return (edge - edges);
}


//-----------------------------------------------------------------------------
// - getCursorCoords:clipTo:
//-----------------------------------------------------------------------------
- (int)getCursorCoords:(float*)coords clipTo:(NSRect)in_clip
{
    int num_coords = 0;

    NSRect clip;
    if (NSIsEmptyRect( in_clip ))
        clip = [self visibleRect];
    else
        clip = in_clip;

    NSRect edges[ NUM_EDGES ];
    int const num_edges = [self getCursorEdges:edges clipTo:clip];
    if (num_edges > 0)
    {
        float* p = coords;
        for (int i = 0; i < num_edges; i++)
        {
            NSRect const& edge = edges[i];
            *p++ = NSMinX( edge );
            *p++ = NSMinY( edge );
            *p++ = NSWidth( edge );
            *p++ = NSHeight( edge );
        }
        num_coords = num_edges * NUM_COORDS;
    }
    return num_coords;
}


//-----------------------------------------------------------------------------
// - drawCursorCoords:count:
//-----------------------------------------------------------------------------
- (void)drawCursorCoords:(float const*)coords count:(int)n
{
    init_pswrap();
    BOOL needsFocus = ([NSView focusView] != self);
    if (needsFocus) [self lockFocus];
    MISC_TV_dashedrects( coords, n );
    if (needsFocus) [self unlockFocus];
}


//-----------------------------------------------------------------------------
// - drawCursorClipTo:
//-----------------------------------------------------------------------------
- (void)drawCursorClipTo:(NSRect)clip
{
    if ([self isCursorEnabled])
    {
        float coords[ MAX_COORDS ];
        int const num_coords = [self getCursorCoords:coords clipTo:clip];
        if (num_coords > 0)
        {
            [self drawCursorCoords:coords count:num_coords];
            cursorSlot = [self borderFor:trackerBorder]->getCursor();
        }
    }
}


//-----------------------------------------------------------------------------
// - drawCursor
//-----------------------------------------------------------------------------
- (void)drawCursor
{
    [self drawCursorClipTo:NSZeroRect];
}


//-----------------------------------------------------------------------------
// - eraseCursor
//-----------------------------------------------------------------------------
- (void)eraseCursor
{
    if ([self isCursorEnabled])
    {
        MiscTableBorder* const b = [self borderFor:trackerBorder];
        if (cursorSlot >= 0 && cursorSlot < b->count())
        {
            [self disableCursor];

            MiscCoord_P s = b->visualToPhysical( cursorSlot );
            if (trackerBorder == MISC_COL_BORDER)
                [self drawColumn:s];
            else
                [self drawRow:s];

            [self enableCursor];
            cursorSlot = -1;
        }
    }
}


//-----------------------------------------------------------------------------
// - becomeFirstResponder
//-----------------------------------------------------------------------------
- (BOOL)becomeFirstResponder
{
    NSWindow* win = [self window];
    if (win && [win isKeyWindow])
    {
        if ([self shouldDrawCursor])
        {
            [self drawCursor];
            [win flushWindow];
        }
        [[self scroll] didBecomeFirstResponder];
    }
    return YES;
}


//-----------------------------------------------------------------------------
// - resignFirstResponder
//-----------------------------------------------------------------------------
- (BOOL)resignFirstResponder
{
    [self eraseCursor];
    [[self window] flushWindow];
    [[self scroll] didResignFirstResponder];
    return YES;
}


//-----------------------------------------------------------------------------
// - becomeKeyWindow
//-----------------------------------------------------------------------------
- (void)becomeKeyWindow
{
    if ([self shouldDrawCursor])
    {
        [self drawCursor];
        [[self window] flushWindow];
    }
    [[NSFontManager sharedFontManager]
     setSelectedFont:[[self scroll] font] isMultiple:NO];
}


//-----------------------------------------------------------------------------
// - resignKeyWindow
//-----------------------------------------------------------------------------
- (void)resignKeyWindow
{
    [self eraseCursor];
    [[self window] flushWindow];
}


//-----------------------------------------------------------------------------
// - reflectCursor
//-----------------------------------------------------------------------------
- (void)reflectCursor
{
    if ([self shouldDrawCursor])
    {
        NSWindow* w = [self window];
        [w disableFlushWindow];
        [self eraseCursor];
        [self drawCursor];
        [w enableFlushWindow];
        [w flushWindow];
    }
}


//-----------------------------------------------------------------------------
// - moveCursorBy:
//-----------------------------------------------------------------------------
- (void)moveCursorBy:(int)delta
{
    MiscTableBorder* const b = [self borderFor:trackerBorder];
    int const lim = b->count();
    if (lim > 0)
    {
        MiscCoord_V slot = b->getCursor() + delta;
        if (slot < 0)
            slot = lim - 1;
        else if (slot >= lim)
            slot = 0;
        b->setCursor( slot );

        NSWindow* const w = [self window];
        [w disableFlushWindow];
        [self reflectCursor];
        [self border:trackerBorder scrollToVisible:b->visualToPhysical(slot)];
        [w enableFlushWindow];
        [w flushWindow];
    }
}


//-----------------------------------------------------------------------------
// - keyboardSelect:
//-----------------------------------------------------------------------------
- (void)keyboardSelect:(NSEvent*)p 
{
    [tracker mouseDown:p atPos:[self borderFor:trackerBorder]->getCursor()];
}

@end
