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
// MiscTableView.M
//
//	General-purpose 2-D display object that works with the
//	MiscTableScroll to provide row/column sizing and dragging.
//
//	This object is responsible for drawing, mouse and keyboard
//	events in the content portion of the display.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableView.M,v 1.40 99/06/15 04:01:11 sunshine Exp $
// $Log:	MiscTableView.M,v $
// Revision 1.40  99/06/15  04:01:11  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// For clarity these methods were renamed:
// drawClippedText --> drawsClippedText
// trackBy: --> setSelectsByRows:
// trackingBy --> selectsByRows
// setTracking: --> setIsTrackingMouse:
// 
// Revision 1.39  1998/05/13 14:50:13  sunshine
// v139.1: Worked around AppKit problem where it sends -mouseDown: events to
// this view even though they are out of bounds.
//
//  Revision 1.38  98/03/29  23:58:32  sunshine
//  v138.1: Now uses NSColor's "system" color for grid rather than "gray".
//-----------------------------------------------------------------------------
#import "MiscTableViewPrivate.h"
#import	"MiscColorList.h"
#import	"MiscDrawList.h"
#import "MiscGeometry.h"
#import "MiscHighlightTracker.h"
#import "MiscListTracker.h"
#import "MiscRadioTracker.h"
#import	"MiscRectColorList.h"
#import	"MiscRectList.h"
#import "MiscSparseSet.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import <MiscTableScroll/MiscTableCell.h>
#import <MiscTableScroll/MiscTableScroll.h>
#import	<new>
#import <AppKit/NSApplication.h>
#import <AppKit/NSControl.h>	// Control-text notifications
#import <AppKit/NSText.h>
#import <AppKit/NSGraphicsContext.h>
#import <AppKit/NSWindow.h>
//#import <AppKit/psops.h>
#include <cmath>	// floor()

//-----------------------------------------------------------------------------
// dump_map
//-----------------------------------------------------------------------------
// static void dump_map( NSString* label, int const* map, int nc, int nr )
//     {
//     fprintf( stderr, "%s nc=%d, nr=%d\n", [label lossyCString], nc, nr );
//     int const* p = map;
//     for (int r = 0; r < nr; r++)
//         {
//         for (int c = 0; c < nc; c++, p++)
//             fprintf( stderr, " %d", *p );
//         fprintf( stderr, "\n" );
//         }
//     }


//-----------------------------------------------------------------------------
// extract_rect
//	Extract a contiguous rectangular group of cells to be drawn from
//	this boolean map of cells that need drawing.
//
//	1) Find the first cell that needs to be drawn (c0,r0).
//	2) Include all contiguous following cells on the same row
//		that also need to be drawn (cN,r0).
//	3) Include all contiguous following rows in which (c0..cN)
//		all need to be drawn.
//	4) Clear the flags from the map to indicate that these cells
//		do not need to be drawn again.
//-----------------------------------------------------------------------------
static int extract_rect( int* map, int nc, int nr,
                        MiscCoord_V& c0, MiscCoord_V& r0,
                        MiscCoord_V& cN, MiscCoord_V& rN )
{
    int* p = map;
    int* plim = p + (nc * nr);

    while (p < plim && *p == 0)
        p++;

    if (p >= plim)
        return 0;			// *** RETURN ***

    int rc = *p;

    int r, c;

    NSInteger const n = p - map;
    r0 = n / nc;
    c0 = n % nc;

    c = c0;
    while (c < nc && *p == rc)
    {
        c++;
        p++;
    }
    cN = c - 1;

    int const num_cols = (c - c0);

    r = r0;
    do  {
        p -= num_cols;
        memset( p, 0, num_cols * sizeof(*p) );
        if (++r >= nr)
            break;
        p += nc;
        plim = p + num_cols;
        while (p < plim && *p == rc)
            p++;
    }
    while (p >= plim);

    rN = r - 1;

    return rc;
}


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableView

//-----------------------------------------------------------------------------
// scroll
//-----------------------------------------------------------------------------
- (id)scroll
{
    return [self enclosingScrollView];
}


//-----------------------------------------------------------------------------
// - initWithFrame:scroll:colInfo:rowInfo:
//
//	NOTE *1*: Default behavior is to take keyboard-cursor information from
//		the row-border.
//-----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)rect
             scroll:(MiscTableScroll*)scroll
            colInfo:(MiscTableBorder*)i_col_border
            rowInfo:(MiscTableBorder*)i_row_border
{
    NSZone* const z = [self zone];
    
    rect.size.width = i_col_border->totalSize();
    rect.size.height = i_row_border->totalSize();
    
    [super initWithFrame:rect];
    
    colBorder = i_col_border;
    rowBorder = i_row_border;
    trackerBorder = MISC_ROW_BORDER;			// NOTE *1*
    
    oldColSel = new( NSZoneMalloc(z,sizeof(*oldColSel)) ) MiscSparseSet;
    oldRowSel = new( NSZoneMalloc(z,sizeof(*oldRowSel)) ) MiscSparseSet;
    [self setSelectionMode:[scroll selectionMode]];
    
    inhibitCursor = 0;
    cursorSlot = -1;
    return self;
}


//-----------------------------------------------------------------------------
// - dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
{
    [[self scroll] abortEditing];
    [tracker release];
    NSZone* const z = [self zone];
    if (oldColSel != 0)
    {
        oldColSel->MiscSparseSet::~MiscSparseSet();
        NSZoneFree( z, oldColSel );
    }
    if (oldRowSel != 0)
    {
        oldRowSel->MiscSparseSet::~MiscSparseSet();
        NSZoneFree( z, oldRowSel );
    }
    [super dealloc];
}


//-----------------------------------------------------------------------------
// - isFlipped
//-----------------------------------------------------------------------------
- (BOOL)isFlipped
{
    return YES;
}


//-----------------------------------------------------------------------------
// - isOpaque
//-----------------------------------------------------------------------------
- (BOOL)isOpaque
{
    return YES;
}


//-----------------------------------------------------------------------------
// - acceptsFirstMouse:
//-----------------------------------------------------------------------------
- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES;
}


//-----------------------------------------------------------------------------
// - acceptsFirstResponder
//-----------------------------------------------------------------------------
- (BOOL)acceptsFirstResponder
{
    return YES;
}


//-----------------------------------------------------------------------------
// - adjustSize
//-----------------------------------------------------------------------------
- (void)adjustSize
{
    [self setFrameSize:
     NSMakeSize( colBorder->totalSize(), rowBorder->totalSize() )];
}


//=============================================================================
// TYPE VARIATIONS
//=============================================================================

- (MiscTableBorder*)borderFor:(MiscBorderType)b
{ return (b == MISC_ROW_BORDER ? rowBorder : colBorder); }
- (MiscTableBorder*)otherBorder:(MiscBorderType)b
{ return [self borderFor:MISC_OTHER_BORDER(b)]; }


//=============================================================================
// FRAMES
//=============================================================================
//-----------------------------------------------------------------------------
// - cellFrameAtRow:column: -- Physical coords
//-----------------------------------------------------------------------------
- (NSRect)cellFrameAtRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    if (row < 0 || row >= rowBorder->count() ||
        col < 0 || col >= colBorder->count())
        return NSMakeRect( 0, 0, 0, 0 );
    else
    {
        MiscCoord_V v_row = rowBorder->physicalToVisual( row );
        MiscCoord_V v_col = colBorder->physicalToVisual( col );
        return NSMakeRect(  colBorder->getOffset(v_col),
                          rowBorder->getOffset(v_row),
                          colBorder->effectiveSize(v_col),
                          rowBorder->effectiveSize(v_row) );
    }
}


//-----------------------------------------------------------------------------
// - cellInsideAtRow:column: -- Actual cell frame inside border lines
//-----------------------------------------------------------------------------
- (NSRect)cellInsideAtRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    NSRect r = [self cellFrameAtRow:row column:col];
    if (!NSIsEmptyRect(r))
    {
        r.size.width--;
        r.size.height--;
    }
    return r;
}


//-----------------------------------------------------------------------------
// - getSlotFrameAt:from: -- Physical coords
//-----------------------------------------------------------------------------
- (NSRect)getSlotFrameAt:(MiscCoord_P)pslot from:(MiscBorderType)bdr
{
    MiscTableBorder* const b = [self borderFor:bdr];
    if (pslot < 0 || pslot >= b->count())
        return NSZeroRect;
    else
    {
        MiscCoord_V vslot = b->physicalToVisual( pslot );
        MiscRect_O ro( bdr, [self bounds] );
        ro.setX_O( b->getOffset(vslot) );
        ro.setWidth_O( b->effectiveSize(vslot) );
        return (NSRect)ro;
    }
}


//-----------------------------------------------------------------------------
// - getSlotInsideAt:from: -- Physical coords
//-----------------------------------------------------------------------------
- (NSRect)getSlotInsideAt:(MiscCoord_P)slot from:(MiscBorderType)bdr
{
    NSRect r = [self getSlotFrameAt:slot from:bdr];
    if (!NSIsEmptyRect(r))
    {
        r.size.width--;
        r.size.height--;
    }
    return r;
}


//-----------------------------------------------------------------------------
// - getRow:column:forPoint:
//-----------------------------------------------------------------------------
- (BOOL)getRow:(int*)row column:(int*)col forPoint:(NSPoint)pt
{
    if (NSPointInRect( pt, [self bounds] ))
    {
        MiscCoord_V const vr = rowBorder->visualForOffset( (MiscPixels)pt.y );
        MiscCoord_V const vc = colBorder->visualForOffset( (MiscPixels)pt.x );
        *row = rowBorder->visualToPhysical( vr );
        *col = colBorder->visualToPhysical( vc );
        return YES;
    }
    return NO;
}


//=============================================================================
// VISIBLE / SCROLLING STUFF
//=============================================================================
//-----------------------------------------------------------------------------
// - firstVisibleSlot: -- Physical coord
//-----------------------------------------------------------------------------
- (int)firstVisibleSlot:(MiscBorderType)bdr
{
    MiscCoord_P ret = -1;
    MiscTableBorder* const b = [self borderFor:bdr];
    int const lim = b->count();
    if (lim > 0)
    {
        MiscRect_O r( bdr, [self visibleRect] );
        MiscPixels const vorg = r.getX_O();
        MiscPixels const vlim = r.getMaxX_O();
        MiscCoord_V v = b->visualForOffset( vorg );
        if (v < lim - 1 && b->getOffset(v) < vorg && b->getOffset(v+1) < vlim)
            v++;		// First slot whose leading edge is visible
        ret = b->visualToPhysical( v );
    }
    return ret;
}


//-----------------------------------------------------------------------------
// - lastVisibleSlot: -- Physical coord
//-----------------------------------------------------------------------------
- (int)lastVisibleSlot:(MiscBorderType)bdr
{
    MiscCoord_P ret = -1;
    MiscTableBorder* const b = [self borderFor:bdr];
    if (b->count() > 0)
    {
        MiscRect_O r( bdr, [self visibleRect] );
        MiscPixels const vorg = r.getX_O();
        MiscPixels const vlim = r.getMaxX_O();
        MiscCoord_V v = b->visualForOffset( vlim );
        if (v > 0 && b->getOffset(v) + b->effectiveSize(v) > vlim &&
            b->getOffset(v-1) + b->effectiveSize(v-1) > vorg)
            v--;		// Last slot whose trailing edge is visible
        ret = b->visualToPhysical( v );
    }
    return ret;
}


//-----------------------------------------------------------------------------
// - numberOfVisibleSlots:
//-----------------------------------------------------------------------------
- (int)numberOfVisibleSlots:(MiscBorderType)bdr
{
    MiscTableBorder* const b = [self borderFor:bdr];
    if (b->count() > 0)
    {
        MiscRect_O r( bdr, [self visibleRect] );
        MiscPixels const vorg = r.getX_O();
        MiscPixels const vlim = r.getMaxX_O();
        MiscCoord_V const first = b->visualForOffset( vorg );
        MiscCoord_V const last  = b->visualForOffset( vlim );
        return last - first + 1;
    }
    return 0;
}


//-----------------------------------------------------------------------------
// - border:slotIsVisible: -- Physical coord
//-----------------------------------------------------------------------------
- (BOOL)border:(MiscBorderType)bdr slotIsVisible:(NSInteger)n
{
    MiscTableBorder* const b = [self borderFor:bdr];
    if (b->count() > 0)
    {
        MiscCoord_V const x = b->physicalToVisual(n);
        MiscPixels const xorg = b->getOffset(x);
        MiscPixels const xlim = xorg + b->effectiveSize(x);
        MiscRect_O r( bdr, [self visibleRect] );
        MiscPixels const vorg = r.getX_O();
        MiscPixels const vlim = r.getMaxX_O();
        return xorg <= vlim && xlim >= vorg;
    }
    return NO;
}


//-----------------------------------------------------------------------------
// - border:setFirstVisibleSlot: -- Physical coord
//-----------------------------------------------------------------------------
- (void)border:(MiscBorderType)bdr setFirstVisibleSlot:(NSInteger)n
{
    MiscTableBorder* const b = [self borderFor:bdr];
    int const num_slots = b->count();
    if (0 <= n && n < num_slots)
    {
        MiscCoord_V const x = b->physicalToVisual(n);
        MiscPixels const xorg = b->getOffset(x);
        MiscRect_O r( bdr, [[self superview] bounds] );
        r.setX_O( xorg );
        [self scrollPoint:r];
    }
}


//-----------------------------------------------------------------------------
// - border:setLastVisibleSlot: -- Physical coord
//-----------------------------------------------------------------------------
- (void)border:(MiscBorderType)bdr setLastVisibleSlot:(NSInteger)n
{
    MiscTableBorder* const b = [self borderFor:bdr];
    int const num_slots = b->count();
    if (0 <= n && n < num_slots)
    {
        MiscPixels const vwidth =
        MiscRect_O( bdr, [self visibleRect] ).getWidth_O();
        MiscCoord_V const x = b->physicalToVisual(n);
        MiscPixels const vorg = b->getOffset(x) + b->effectiveSize(x) - vwidth;
        MiscRect_O r( bdr, [[self superview] bounds] );
        r.setX_O( vorg );
        [self scrollPoint:r];
    }
}


//=============================================================================
// SCROLLING
//=============================================================================
//-----------------------------------------------------------------------------
// - scrollCellToVisibleAtRow:column: -- Physical coords
//-----------------------------------------------------------------------------
- (void)scrollCellToVisibleAtRow:(int)row column:(int)col
{
    [self scrollRectToVisible:[self cellFrameAtRow:row column:col]];
}


//-----------------------------------------------------------------------------
// - border:scrollToVisible: -- Physical coord
//-----------------------------------------------------------------------------
- (void)border:(MiscBorderType)bdr scrollToVisible:(MiscCoord_P)pslot
{
    MiscTableBorder* const b = [self borderFor:bdr];
    MiscCoord_V const vslot = b->physicalToVisual( pslot );
    NSRect v = [self visibleRect];
    MiscRect_O r( bdr, v );
    r.setX_O( b->getOffset(vslot) );
    r.setWidth_O( b->effectiveSize(vslot) );
    [self scrollRectToVisible:r];
}


//-----------------------------------------------------------------------------
// - scrollRowToVisible: -- Physical coord
//-----------------------------------------------------------------------------
- (void)scrollRowToVisible:(int)row
{
    [self border:MISC_ROW_BORDER scrollToVisible:row];
}


//-----------------------------------------------------------------------------
// - scrollColToVisible: -- Physical coord
//-----------------------------------------------------------------------------
- (void)scrollColumnToVisible:(int)col
{
    [self border:MISC_COL_BORDER scrollToVisible:col];
}


//=============================================================================
// DRAWING
//=============================================================================
//-----------------------------------------------------------------------------
// - cMin:cMax:rMin:rMax:forRect:
//-----------------------------------------------------------------------------
- (void)cMin:(MiscCoord_V*)cmin cMax:(MiscCoord_V*)cmax
        rMin:(MiscCoord_V*)rmin rMax:(MiscCoord_V*)rmax
     forRect:(NSRect)nsrect
{
    *cmin = colBorder->visualForOffset( (MiscPixels) nsrect.origin.x );
    *cmax = colBorder->visualForOffset(
                                       (MiscPixels) (nsrect.origin.x + nsrect.size.width) - 1 );
    *rmin = rowBorder->visualForOffset( (MiscPixels) nsrect.origin.y );
    *rmax = rowBorder->visualForOffset(
                                       (MiscPixels) (nsrect.origin.y + nsrect.size.height) - 1 );
}


//-----------------------------------------------------------------------------
// - drawRect:
//-----------------------------------------------------------------------------
- (void)drawRect:(NSRect)nsrect
{
    BOOL const need_clip = ([[self subviews] count] != 0);
    if (need_clip)
    {
        [NSGraphicsContext saveGraphicsState];
        NSRectClip( nsrect );
    }

    MiscCoord_V c, cmin, cmax, c0, cN;
    MiscCoord_V r, rmin, rmax, r0, rN;
    [self cMin:&cmin cMax:&cmax rMin:&rmin rMax:&rmax forRect:nsrect];

    if (cmin >= 0 && cmax >= 0 && rmin >= 0 && rmax >= 0)
    {
        MiscColorList cl;
        id const scroll = [self scroll];

        int const NORM_COLOR = cl.store([scroll backgroundColor]) + 1;
        int const HIGH_COLOR = cl.store([scroll selectedBackgroundColor]) + 1;

        int const nc = (cmax - cmin) + 1;
        int const nr = (rmax - rmin) + 1;
        int* map = (int*) calloc( nc * nr, sizeof(*map) );
        int* p = map;

        for (r = rmin; r <= rmax; r++)	// Transparent and ownerDraw
        {				// cell backgrounds.
            MiscCoord_P const pr = rowBorder->visualToPhysical(r);
            BOOL const row_lit = rowBorder->isSelected(r);
            for (c = cmin; c <= cmax; c++,p++)
            {
                MiscCoord_P const pc = colBorder->visualToPhysical(c);
                BOOL const lit = row_lit || colBorder->isSelected(c);
                id cell = [scroll cellAtRow:pr column:pc];
                if (cell == 0 || ![cell isOpaque])
                    *p = lit ? HIGH_COLOR : NORM_COLOR;
                else if ([cell respondsToSelector:@selector(ownerDraw)] &&
                         [cell ownerDraw])
                {
                    if (lit && [cell respondsToSelector:
                                @selector(selectedBackgroundColor)])
                        *p = cl.store( [cell selectedBackgroundColor] ) + 1;
                    else if ([cell respondsToSelector:
                              @selector(backgroundColor)])
                        *p = cl.store( [cell backgroundColor] ) + 1;
                    else
                        *p = lit ? HIGH_COLOR : NORM_COLOR;
                }
            }
        }

        MiscRectColorList rcl;
        NSRect rect;
        int color;
        while ((color = extract_rect( map, nc, nr, c0, r0, cN, rN )) != 0)
        {
            c0 += cmin; cN += cmin;
            r0 += rmin; rN += rmin;
            MiscPixels const x0 = colBorder->getOffset( c0 );
            MiscPixels const y0 = rowBorder->getOffset( r0 );
            MiscPixels const xN = colBorder->getOffset( cN ) +
            colBorder->effectiveSize( cN );
            MiscPixels const yN = rowBorder->getOffset( rN ) +
            rowBorder->effectiveSize( rN );
            rect.origin.x = x0;
            rect.origin.y = y0;
            rect.size.width = (xN - x0);
            rect.size.height = (yN - y0);
            
            rcl.append( rect, cl[ color - 1 ] );
        }

        free( map );

        MiscPixels x,y;
        MiscPixels const ix0 = colBorder->getOffset( cmin );
        MiscPixels const iy0 = rowBorder->getOffset( rmin );
        MiscPixels const ixN = colBorder->getOffset( cmax ) +
        colBorder->effectiveSize( cmax );
        MiscPixels const iyN = rowBorder->getOffset( rmax ) +
        rowBorder->effectiveSize( rmax );

        MiscRectList grid_rl;		// Grid drawing list.
        y = iy0;			// Horizontal grid lines.
        rect.origin.x    = floor( (float) ix0 );
        rect.size.width  = floor( (float) (ixN - ix0) );
        rect.size.height = 1;
        for (r = rmin; r <= rmax; r++)
        {
            MiscPixels const h = rowBorder->effectiveSize(r);
            y += h - 1;
            rect.origin.y = floor( (float) y );
            grid_rl.append( rect );
            y++;
        }

        x = ix0;			// Vertical grid lines.
        rect.origin.y    = floor( (float) iy0 );
        rect.size.width  = 1;
        rect.size.height = floor( (float) (iyN - iy0) );
        for (c = cmin; c <= cmax; c++)
        {
            MiscPixels const w = colBorder->effectiveSize(c);
            x += w - 1;
            rect.origin.x = floor( (float) x );
            grid_rl.append( rect );
            x++;
        }

        rcl.draw();
        grid_rl.draw( [NSColor gridColor] );

        NSColor* const fgColor = [scroll textColor];
        NSColor* const hfgColor = [scroll selectedTextColor];
        NSFont* const fnt = [scroll font];
        MiscDrawList dl( [scroll drawsClippedText] );

        y = iy0;			// Cell contents.
        for (r = rmin; r <= rmax; r++)
        {
            MiscCoord_P const pr = rowBorder->visualToPhysical(r);
            BOOL const row_lit = rowBorder->isSelected(r);
            MiscPixels const h = rowBorder->effectiveSize(r);
            rect.origin.y    = floor( (float) y );
            rect.size.height = floor( (float) (h - 1) );
            x = ix0;
            for (c = cmin; c <= cmax; c++)
            {
                MiscCoord_P const pc = colBorder->visualToPhysical(c);
                BOOL const lit = row_lit || colBorder->isSelected(c);
                MiscPixels const w = colBorder->effectiveSize(c);
                rect.origin.x   = x;
                rect.size.width = (w - 1);
                id cell = [scroll cellAtRow:pr column:pc];
                if (cell == 0 ||
                    [cell respondsToSelector:@selector(ownerDraw)] &&
                    [cell ownerDraw])
                {
                    dl.append( rect, cell, lit,
                              (lit ? hfgColor : fgColor), fnt );
                }
                else
                    [cell drawWithFrame:rect inView:self];
                x += w;
            }
            y += h;
        }

        dl.draw();
        if ([self shouldDrawCursor])
            [self drawCursorClipTo:NSMakeRect(ix0, iy0, ixN - ix0, iyN - iy0)];
    }

    if (need_clip)
        [NSGraphicsContext restoreGraphicsState];
}


//-----------------------------------------------------------------------------
// - drawCellAtRow:column: -- Physical coords
//-----------------------------------------------------------------------------
- (void)drawCellAtRow:(int)row column:(int)col
{
    [self drawRect:[self cellFrameAtRow:row column:col]];
}


//-----------------------------------------------------------------------------
// - drawRow: -- Physical coord
//-----------------------------------------------------------------------------
- (void)drawRow:(int)row
{
    if ([self canDraw] && row >= 0 && row < rowBorder->count())
    {
        MiscCoord_V const vRow   = rowBorder->physicalToVisual(row);
        MiscPixels  const offset = rowBorder->getOffset(vRow);
        MiscPixels  const size   = rowBorder->effectiveSize(vRow);

        NSRect r = [self visibleRect];
        if (offset + size >= NSMinY(r) && offset < NSMaxY(r))
        {
            r.origin.y = rowBorder->getOffset(vRow);
            r.size.height = rowBorder->effectiveSize(vRow);
            [self setNeedsDisplayInRect:r];
        }
    }
}


//-----------------------------------------------------------------------------
// - drawColumn: -- Physical coord
//-----------------------------------------------------------------------------
- (void)drawColumn:(int)col
{
    if ([self canDraw] && col >= 0 && col < colBorder->count())
    {
        MiscCoord_V const vCol   = colBorder->physicalToVisual(col);
        MiscPixels  const offset = colBorder->getOffset(vCol);
        MiscPixels  const size   = colBorder->effectiveSize(vCol);
        
        NSRect r = [self visibleRect];
        if (offset + size >= NSMinX(r) && offset < NSMaxX(r))
        {
            r.origin.x = colBorder->getOffset(vCol);
            r.size.width = colBorder->effectiveSize(vCol);
            [self setNeedsDisplayInRect:r];
        }
    }
}


//=============================================================================
// SELECTION
//=============================================================================
//-----------------------------------------------------------------------------
// - setSelectionMode:
//-----------------------------------------------------------------------------
- (void)setSelectionMode:(MiscSelectionMode)mode
{
    NSZone* const z = [self zone];
    if (tracker != 0)
        [tracker release];
    switch (mode)
    {
        case MISC_LIST_MODE:
            tracker = [MiscListTracker allocWithZone:z];
            break;
        case MISC_RADIO_MODE:
            tracker = [MiscRadioTracker allocWithZone:z];
            break;
        case MISC_HIGHLIGHT_MODE:
            tracker = [MiscHighlightTracker allocWithZone:z];
            break;
    }
    [tracker initBorder:[self borderFor:trackerBorder]];
}


//-----------------------------------------------------------------------------
// - selectionChanged
//-----------------------------------------------------------------------------
- (void)selectionChanged
{
    MiscSparseSet const& newColSel = colBorder->selectionSet();
    MiscSparseSet const& newRowSel = rowBorder->selectionSet();

    MiscCoord_V cmin, cmax;
    MiscCoord_V rmin, rmax;
    NSRect vis = [self visibleRect];
    [self cMin:&cmin cMax:&cmax rMin:&rmin rMax:&rmax forRect:vis];

    for (MiscCoord_V r = rmin; r <= rmax; r++)
    {
        BOOL rowWasOn = oldRowSel->contains(r);
        BOOL rowIsOn = newRowSel.contains(r);
        for (MiscCoord_V c = cmin; c <= cmax; c++)
        {
            BOOL wasOn = rowWasOn || oldColSel->contains(c);
            BOOL isOn = rowIsOn || newColSel.contains(c);
            if (isOn != wasOn)
            {
                [self setNeedsDisplayInRect:
                 NSMakeRect(	colBorder->getOffset(c),
                            rowBorder->getOffset(r),
                            colBorder->effectiveSize(c),
                            rowBorder->effectiveSize(r) )];
            }
        }
    }
    *oldColSel = newColSel;
    *oldRowSel = newRowSel;
}


//-----------------------------------------------------------------------------
// - resetSelection
//-----------------------------------------------------------------------------
- (void)resetSelection
{
    *oldColSel = colBorder->selectionSet();
    *oldRowSel = rowBorder->selectionSet();
}


//-----------------------------------------------------------------------------
// - setSelectsByRows:
//-----------------------------------------------------------------------------
- (void)setSelectsByRows:(BOOL)flag
{
    trackerBorder = (flag ? MISC_ROW_BORDER : MISC_COL_BORDER);
}


//-----------------------------------------------------------------------------
// - selectsByRows
//-----------------------------------------------------------------------------
- (BOOL)selectsByRows
{
    return (trackerBorder == MISC_ROW_BORDER);
}


//=============================================================================
// MOUSE TRACKING
//=============================================================================
//-----------------------------------------------------------------------------
// - constrainSlot:inBorder:
//-----------------------------------------------------------------------------
- (MiscCoord_V)constrainSlot:(MiscCoord_V)s inBorder:(MiscTableBorder*)b
{
    if (s < 0)
        s = 0;
    else if (s >= b->count())
        s = b->count() - 1;
    return s;
}


//-----------------------------------------------------------------------------
// - displayNewSelection
//-----------------------------------------------------------------------------
- (void)displayNewSelection
{
    id const scroll = [self scroll];
    [scroll selectionChanged];
    [scroll displayIfNeeded];
}


//-----------------------------------------------------------------------------
// - sendAction:to:
//
//	NOTE *1*: Conforms to Control's -sendAction:to: which does *not* send
//		any message if the "action" is null.
//-----------------------------------------------------------------------------
- (BOOL)sendAction:(SEL)cmd to:(id)obj
{
    if (cmd != 0)		// NOTE *1*
        return [NSApp sendAction:cmd to:obj from:[self scroll]];
    return NO;
}


//-----------------------------------------------------------------------------
// - setClickedCellFromEvent:
//-----------------------------------------------------------------------------
- (void)setClickedCellFromEvent:(NSEvent*)e
{
    NSPoint const p = [self convertPoint:[e locationInWindow] fromView:0];
    NSRect b = [self bounds];
    MiscCoord_V const v_row = (p.y < NSMaxY(b) ?
                               rowBorder->visualForOffset( (MiscPixels)p.y ) : -1);
    MiscCoord_V const v_col = (p.x < NSMaxX(b) ?
                               colBorder->visualForOffset( (MiscPixels)p.x ) : -1);
    MiscCoord_P const p_row = rowBorder->visualToPhysical( v_row );
    MiscCoord_P const p_col = colBorder->visualToPhysical( v_col );
    [[self scroll] setClickedRow:p_row column:p_col];
}


//-----------------------------------------------------------------------------
// - cellTrackMouse:atRow:column:
//-----------------------------------------------------------------------------
- (BOOL)cellTrackMouse:(NSEvent*)p
                 atRow:(MiscCoord_V)v_row column:(MiscCoord_V)v_col
{
    BOOL upInCell = NO;

    MiscCoord_P const p_col = colBorder->visualToPhysical( v_col );
    MiscCoord_P const p_row = rowBorder->visualToPhysical( v_row );

    NSRect r = [self cellInsideAtRow:p_row column:p_col];
    id const scroll = [self scroll];

    id cell = [scroll cellAtRow:p_row column:p_col];
    [scroll setClickedRow:p_row column:p_col];

    if ([scroll editIfAble:p atRow:p_row column:p_col])
        upInCell = YES;
    else if ([self canPerformDragAtRow:p_row column:p_col withEvent:p])
        upInCell = [self awaitDragEvent:p atRow:p_row column:p_col inRect:r];
    else if ([cell isEnabled])
    {
        NSWindow* win = [self window];
        [self lockFocus];
        [scroll setIsTrackingMouse:YES];
        [cell setCellAttribute:NSCellHighlighted to:1];
        [scroll drawCellAtRow:p_row column:p_col];
        [win flushWindow];
        upInCell = [cell trackMouse:p inRect:r ofView:self
                       untilMouseUp:[[cell class] prefersTrackingUntilMouseUp]];
        [scroll setIsTrackingMouse:NO];
        [cell setCellAttribute:NSCellHighlighted to:0];
        [scroll drawCellAtRow:p_row column:p_col];
        [self unlockFocus];
        [win flushWindow];
    }

    return upInCell;
}


//-----------------------------------------------------------------------------
// - mouseDown:
//
// NOTE: *OUT-OF-BOUNDS*
//	The AppKit allows up to 3 pixels of slop on double-clicks even when
//	the new location is outside the bounds of the view receiving the
//	original click.  They send the second event to the original view, but
//	they do not coerce the location to the same location as the original
//	event.  Our code assumes all mouseDown: events are located within
//	the bounds of our view, so reject all events outside our bounds.
//-----------------------------------------------------------------------------
- (void)mouseDown:(NSEvent*)p
{
    NSEventMask const WANTED =
    (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskPeriodic);

    id const scroll = [self scroll];
    BOOL const doubleClicked = ([p clickCount] > 1);
    NSPoint evpt = [self convertPoint:[p locationInWindow] fromView:0];
    float const x = evpt.x;			// NOTE *OUT-OF-BOUNDS*
    float const y = evpt.y;
    NSRect const r = [self bounds];

    if (x >= 0 && x < r.size.width && y >= 0 && y < r.size.height)
    {
        MiscCoord_V const v_col = colBorder->visualForOffset((MiscPixels)x);
        MiscCoord_V const v_row = rowBorder->visualForOffset((MiscPixels)y);
        NSParameterAssert( v_col >= 0 );
        NSParameterAssert( v_row >= 0 );
        NSParameterAssert( v_col < colBorder->count() );
        NSParameterAssert( v_row < rowBorder->count() );

        MiscCoord_V slot = (trackerBorder == MISC_COL_BORDER ? v_col : v_row);
        MiscTableBorder* const b = [self borderFor:trackerBorder];

        [self eraseCursor];
        [self disableCursor];

        [tracker mouseDown:p atPos:slot];
        [self otherBorder:trackerBorder]->selectNone();
        [self displayNewSelection];

        BOOL mouseUpInCell = NO;
        if ([scroll isEnabled])
            mouseUpInCell = [self cellTrackMouse:p atRow:v_row column:v_col];

        if (!mouseUpInCell)
        {
            [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
            NSEvent* lastEvent = [p copy];

            for (;;)
            {
                p = [[self window] nextEventMatchingMask:WANTED];
                if (p == 0 || [p type] == NSEventTypeLeftMouseUp)
                    break;
                else if ([p type] == NSEventTypePeriodic)
                    [self autoscroll:lastEvent];
                else
                {
                    [lastEvent release];
                    lastEvent = [p copy];
                }

                NSPoint const new_loc =
                [self convertPoint:[lastEvent locationInWindow] fromView:0];
                MiscPixels const offset =
                MiscPoint_O( trackerBorder, new_loc ).getX_O();
                MiscCoord_V const new_slot = offset <
                MiscRect_O(trackerBorder,[self bounds]).getMaxX_O() ?
                b->visualForOffset(offset) : b->count();
                if (new_slot != slot)
                {
                    slot = new_slot;
                    [tracker mouseDragged:p atPos:slot];
                    [self displayNewSelection];
                }
            }

            [lastEvent release];
            [NSEvent stopPeriodicEvents];
            [self setClickedCellFromEvent:p];
        }

        [tracker mouseUp:p atPos:slot];
        [self displayNewSelection];
        [scroll border:trackerBorder setCursorSlot:
         b->visualToPhysical([self constrainSlot:slot inBorder:b])];

        [self enableCursor];
        if ([self shouldDrawCursor])
            [self drawCursor];
        [[self window] flushWindow];

        if ([scroll isEnabled])
        {
            [scroll sendAction];
            if (doubleClicked && ![scroll isEditing])	// FIXME: not right
                [scroll sendDoubleAction];
        }
    }
}


//-----------------------------------------------------------------------------
// *FIXME*
//	OPENSTEP 4.2 Objective-C++ compiler for NT (final release) crashes
//	whenever a message is sent to 'super' from within a category.  This
//	bug also afflicts the 4.2 (prerelease) compiler for Mach and NT.
//	Work around it by providing stub methods in the main (non-category)
//	implementation which merely forward the appropriate message to 'super'
//	on behalf of the categories.  Though ugly, it works, is very
//	localized, and simple to remove when the bug is finally fixed.
//-----------------------------------------------------------------------------
- (void)superPrint:(id)sender { [super print:sender]; }

@end
