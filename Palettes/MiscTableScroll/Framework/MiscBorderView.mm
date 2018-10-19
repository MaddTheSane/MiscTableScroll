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
// MiscBorderView.M
//
//	View class for the row/column borders on a MiscTableView.
//	Supports resizing, dragging.
//
// NOTE: *COORDS*
//	COORDINATE SYSTEM RULES:
//
//	1) The BorderView and the TableView must *NOT* be scaled or rotated.
//		There is no reason to do so, and supporting this unnecessary
//		capability is complicated and slow.  The entire TableScroll
//		can be scaled and/or rotated, but the BorderView and
//		TableView subviews should not be scaled and/or rotated
//		relative to the TableScroll.
//
//	2) This means that the only coordinate transformations that are
//		necessary when converting coordinates between the BorderView,
//		TableView and/or TableScroll are simple translations.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscBorderView.M,v 1.30 99/06/14 23:11:13 sunshine Exp $
// $Log:	MiscBorderView.M,v $
// Revision 1.30  99/06/14  23:11:13  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Method renamed: -moveSlotFrom:to: --> -moveSlot:toSlot:
// Method renamed: -slotDraggedFrom:to: --> -slotDragged:toSlot:
// No longer uses PostScript "instance drawing" during slot resizing.  Now
// uses NSWindow's new -cacheImageInRect: & -restoreCachedImage: instead.
// Handling of cursor rectangles changed in MacOS/X Server DR2.  They fixed a
// problem where small, adjacent, non-overlapping rectangles were not handled
// properly in earlier versions of the AppKit.  Unfortunately their fix broke
// the our work-around for earlier versions.  Now our fix is conditionally
// compiled in on platforms which require it.
// 
// Revision 1.29  1998/05/13 14:50:17  sunshine
// v139.1: Worked around AppKit problem where it sends -mouseDown: events to
// this view even though they are out of bounds.
//
//  Revision 1.28  98/03/29  23:41:40  sunshine
//  v138.1: Fixed v134.1 bug: No longer suspends/resumes editing when border
//  view is used to change slot selection.  This broke relationship where one
//  and only selected slot was the one containing the edit session.
//  Fixed to account for new MiscBorderCell implementation which requires that
//  cell's highlight flag change rather than state in order to show selection.
//  Moved MISC_FRAME_HEIGHT & MISC_FRAME_WIDTH into MiscTableScrollPrivate.h
//  since MiscTableBorder.cc also needs access to those values.
//-----------------------------------------------------------------------------
#import "MiscBorderView.h"
#import "MiscBorderCell.h"
#import "MiscGeometry.h"
#import "MiscHighlightTracker.h"
#import "MiscListTracker.h"
#import "MiscRadioTracker.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import "MiscTableView.h"
#import "MiscTableWell.h"
#import <MiscTableScroll/MiscTableScroll.h>
#import <MiscTableScroll/MiscTableTypes.h>

#import	<new>

#import <Cocoa/Cocoa.h>

extern "C" {
#import <float.h>
#import <limits.h>
}
#include <cmath>
#include <cstring>
#include <cstdio>

static CGFloat MIN_TOGGLE_WIDTH	= 5;
static CGFloat TOGGLE_WIDTH	= 5;

int const MISC_RESIZE_EPSILON	= 4;

static NSCursor* horzCursor	= 0;
static NSCursor* vertCursor	= 0;
static NSCursor* dragCursor	= 0;
static NSCursor* reverseCursor	= 0;

static NSImage* sortAscendImage	  = 0;
static NSImage* sortAscendHImage  = 0;
static NSImage* sortDescendImage  = 0;
static NSImage* sortDescendHImage = 0;

static BOOL sendingPeriodicEvents = NO;

static inline MiscPixels dmin( MiscPixels a, MiscPixels b )
					{ return (a < b ? a : b); }
static inline MiscPixels dmax( MiscPixels a, MiscPixels b )
					{ return (a > b ? a : b); }

//-----------------------------------------------------------------------------
// Prior to MacOS/X Server DR2, the AppKit did not handle small, adjacent
// cursor rectangles properly.  In some cases, depending upon the movement
// direction of the mouse, such a cursor rectangle was frequently ignored.  To
// work around the problem, the rectangles were overlapped.  As of DR2,
// overlapping rectangles are improperly handled and often ignored depending
// upon the direction of mouse movement.  The following patch uses overlapping
// rectangles prior to DR2, and non-overlapping rectangles for DR2 and later.
//
// *FIXME* The current patch only fixes cursor rectangles for horizontal mouse
// movement on DR2.  Specifically, the current patch only keeps the toggle and
// resize rectangles from overlapping.  However, both rectangles still overlap
// the drag rectangle.  Consequently the resulting cursor rectangles do not
// work with vertical mouse movement.
//-----------------------------------------------------------------------------
#if defined(NS_TARGET_MAJOR) && (NS_TARGET_MAJOR < 5)
#define MISC_BROKEN_CURSOR_RECTS MISC_RESIZE_EPSILON
#else
#define MISC_BROKEN_CURSOR_RECTS 0
#endif


//----------------------------------------------------------------------------
// stopTimer
//----------------------------------------------------------------------------
static inline void stopTimer()
{
    if (sendingPeriodicEvents)
    {
        [NSEvent stopPeriodicEvents];
        sendingPeriodicEvents = NO;
    }
}


//----------------------------------------------------------------------------
// startTimer
//----------------------------------------------------------------------------
static inline void startTimer()
{
    if (!sendingPeriodicEvents)
    {
        sendingPeriodicEvents = YES;
        [NSEvent startPeriodicEventsAfterDelay:0.1 withPeriod:0.1];
    }
}


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscBorderView

//-----------------------------------------------------------------------------
// + imageNamed:
//-----------------------------------------------------------------------------
+ (id)imageNamed:(NSString*)name
{
    NSImage* image = [NSImage imageNamed:name];
    if (image == 0)
    {
        NSString* path = [[NSBundle bundleForClass:self]
                          pathForImageResource:name];
        if (path != 0)
        {
            image = [[[NSImage alloc] initByReferencingFile:path] autorelease];
            [image setName:name];
        }
    }
    return image;
}


//-----------------------------------------------------------------------------
// + cursorWithImage:hot:
//-----------------------------------------------------------------------------
+ (NSCursor*)cursorWithImage:(NSString*)name hot:(NSPoint)pt
{
    NSImage* image = [self imageNamed:name];
    return [[[NSCursor alloc] initWithImage:image hotSpot:pt] autorelease];
}


//-----------------------------------------------------------------------------
// + cursorWithImage:
//-----------------------------------------------------------------------------
+ (NSCursor*)cursorWithImage:(NSString*)name
{
    return [self cursorWithImage:name hot:NSMakePoint( 8, 8 )];
}


//-----------------------------------------------------------------------------
// + initialize
//-----------------------------------------------------------------------------
+ (void)initialize
{
    if (horzCursor == 0)
    {
        horzCursor = [[self cursorWithImage:@"MiscHorzResizeCursor"] retain];
        vertCursor = [[self cursorWithImage:@"MiscVertResizeCursor"] retain];
        dragCursor = [[self cursorWithImage:@"MiscSlotDragCursor"] retain];
        reverseCursor = [[self cursorWithImage:@"MiscReverseCursor"
                                           hot:NSMakePoint( 4, 0 )] retain];
        
        sortAscendImage   = [[self imageNamed:@"MiscSortAscend"] retain];
        sortAscendHImage  = [[self imageNamed:@"MiscSortAscendH"] retain];
        sortDescendImage  = [[self imageNamed:@"MiscSortDescend"] retain];
        sortDescendHImage = [[self imageNamed:@"MiscSortDescendH"] retain];
        
        TOGGLE_WIDTH = [sortAscendImage size].width;
        if (TOGGLE_WIDTH < MIN_TOGGLE_WIDTH)
            TOGGLE_WIDTH = MIN_TOGGLE_WIDTH;
    }
}


//-----------------------------------------------------------------------------
// TYPE VARIATIONS
//-----------------------------------------------------------------------------

- (MiscPixels)frameHeight
{
    NSRect rect = [self frame];
    return (MiscPixels) (isHorz ? rect.size.height : rect.size.width);
}

- (void)setFrameHeight:(MiscPixels)x
{
    NSRect rect = [self frame];
    if (isHorz)
        rect.size.height = x;
    else
        rect.size.width = x;
    [self setFrame:rect];
}

- (NSCursor*)cursor
{ return isHorz ? horzCursor : vertCursor; }
- (MiscBorderType)borderType
{ return isHorz ? MISC_COL_BORDER : MISC_ROW_BORDER; }
- (MiscTableBorder*)otherBorder
{ return [scroll border:MISC_OTHER_BORDER([self borderType])]; }
- (void)clearOtherBorder { [self otherBorder]->selectNone(); }
- (id)cellAtRow:(MiscCoord_P)row column:(MiscCoord_P)col
{ return isHorz ?   [scroll cellAtRow:row column:col] :
    [scroll cellAtRow:col column:row]; }


//-----------------------------------------------------------------------------
// - changeFrameIfNeeded
//	FIXME: The frame updates need to be untangled.  All requests should
//	go through the table-scroll object.  Implementations should only
//	update themselves, not other objects.
//-----------------------------------------------------------------------------
- (void)changeFrameIfNeeded
{
    MiscRect_O r( isHorz, [self frame] );
    MiscPixels const my_width = r.getWidth_O();
    MiscPixels const i_width = info->totalSize();
    if (my_width != i_width)
    {
        [[self window] invalidateCursorRectsForView:self];
        r.setWidth_O( i_width );
        [self setFrameSize:r];
        [[scroll documentView] adjustSize];
    }
}


//-----------------------------------------------------------------------------
// - setPos:width:
//-----------------------------------------------------------------------------
- (void)setPos:(MiscCoord_V)pos width:(MiscPixels)size
{
    MiscCoord_P pPos = info->visualToPhysical(pos);
    [scroll border:[self borderType] setSlot:pPos size:(float)size];
    [[self window] invalidateCursorRectsForView:self];
    [scroll setNeedsDisplay:YES];
}


//-----------------------------------------------------------------------------
// - initWithFrame:scroll:info:type:
//-----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frameRect
     scroll:(MiscTableScroll*)i_scroll
       info:(MiscTableBorder*)i_info
       type:(MiscBorderViewType)type
{
    NSZone* const z = [self zone];

    [super initWithFrame:NSZeroRect];

    togglePos = -1;
    isHorz = (type == MISC_COL_BORDER_VIEW);
    scroll = i_scroll;
    info = i_info;
    theCell = [[MiscBorderCell allocWithZone:z] initTextCell:@"Kilroy"];

    oldSel = new( NSZoneMalloc(z,sizeof(*oldSel)) ) MiscSparseSet;
    [self setSelectionMode:[scroll selectionMode]];

    MiscRect_O myFrame( isHorz, frameRect );
    myFrame.setWidth_O( i_info->totalSize() );
    myFrame.setHeight_O( (isHorz ? MISC_FRAME_HEIGHT : MISC_FRAME_WIDTH) );
    [self setFrame:myFrame];
    return self;
}


//-----------------------------------------------------------------------------
// - dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
{
    [theCell release];
    [tracker release];
    if (oldSel != 0)
    {
        oldSel->MiscSparseSet::~MiscSparseSet();
        NSZoneFree( [self zone], oldSel );
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



//=============================================================================
// CONVERSIONS
//=============================================================================
//-----------------------------------------------------------------------------
// - range::fromRect:
//	Returns by reference the range of visual slots contained in rect.
//	rMin is inclusive, rMax is exclusive.
//-----------------------------------------------------------------------------
- (void)range:(MiscCoord_V*)rMin :(MiscCoord_V*)rMax fromRect:(NSRect)rect
{
    MiscRect_O r( isHorz, rect );
    *rMin = info->visualForOffset( r.getX_O() );
    *rMax = info->visualForOffset( r.getMaxX_O() - 1 ) + 1;
}


//-----------------------------------------------------------------------------
// - rectForPos:
//-----------------------------------------------------------------------------
- (NSRect)rectForPos:(MiscCoord_V)pos
{
    MiscRect_O r( isHorz, [self bounds] );
    r.setX_O( info->getOffset(pos) );
    r.setWidth_O( info->effectiveSize(pos) );
    return r;
}



//=============================================================================
// DRAWING
//=============================================================================
//-----------------------------------------------------------------------------
// - getVisibleRange::
//
//	Returns by reference the range of visual slots contained in the visible
//	rectangle.  rMin is inclusive, rMax is exclusive.
//-----------------------------------------------------------------------------
- (void)getVisibleRange:(MiscCoord_V*)rMin :(MiscCoord_V*)rMax
{
    id v = [self superview];
    NSRect visRect = [v documentVisibleRect];
    [self range:rMin:rMax fromRect:visRect];
}


//-----------------------------------------------------------------------------
// drewPos:
//
//	Keeps the old selection sets up to date whenever we draw a cell.  This
//	way -selectionChanged has valid data to work from.
//-----------------------------------------------------------------------------
- (void)drewPos:(MiscCoord_V)slot
{
    BOOL isSelected = info->isSelected( slot );
    if (isSelected != oldSel->contains(slot))
    {
        if (isSelected)
            oldSel->add( slot );
        else
            oldSel->remove( slot );
    }
}


//-----------------------------------------------------------------------------
// - drawPos:inRect:controlView:
//-----------------------------------------------------------------------------
- (void)drawPos:(MiscCoord_V)pos inRect:(NSRect)r controlView:(NSView*)v
{
    NSImage* img = 0;
    if ([scroll autoSortSlots:MISC_OTHER_BORDER([self borderType])]) {
        if (info->isSortable(pos)) {
            if (info->getSortDirection(pos) == MISC_SORT_DESCENDING) {
                img = togglePos == pos ? sortDescendHImage : sortDescendImage;
            } else {
                img = togglePos == pos ? sortAscendHImage : sortAscendImage;
            }
        }
    }
    
    [theCell setToggleImage:img];
    [theCell setStringValue:info->getTitle(pos)];

    BOOL const need_off = !info->isSelected(pos); // Forces "real" boolean
    BOOL const is_off = ![theCell isHighlighted]; // in order to compare them.
    if (need_off != is_off)
        [theCell highlight:!need_off withFrame:r inView:v];
    else
        [theCell drawWithFrame:r inView:v];
}


//-----------------------------------------------------------------------------
// - drawPos:updateSel:
//-----------------------------------------------------------------------------
- (void)drawPos:(MiscCoord_V)pos updateSel:(BOOL)updateSel
{
    if (0 <= pos && pos < info->count())
    {
        NSRect rect = [self rectForPos:pos];
        [self drawPos:pos inRect:rect controlView:self];
        if (updateSel)
            [self drewPos:pos];
    }
}


//-----------------------------------------------------------------------------
// - drawPos:
//-----------------------------------------------------------------------------
- (void)drawPos:(MiscCoord_V)pos
{
    [self drawPos:pos updateSel:YES];
}


//-----------------------------------------------------------------------------
// - drawRect:
//-----------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
{
    MiscCoord_V pos_min;
    MiscCoord_V pos_max;
    [self range:&pos_min:&pos_max fromRect:rect];
    for (MiscCoord_V pos = pos_min;  pos < pos_max;  pos++)
        [self drawPos:pos];
}


//-----------------------------------------------------------------------------
// - drawSlot:	[public]
//-----------------------------------------------------------------------------
- (void)drawSlot:(MiscCoord_V)n
{
    MiscCoord_V rMin, rMax;
    [self getVisibleRange:&rMin:&rMax];
    if (rMin <= n && n < rMax)
        [self setNeedsDisplayInRect:[self rectForPos:n]];
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
    if (tracker)
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
    [tracker initBorder:info];
}


//-----------------------------------------------------------------------------
// - selectionChanged
//-----------------------------------------------------------------------------
- (void)selectionChanged
{
    MiscSparseSet const& newSel = info->selectionSet();
    
    MiscCoord_V rMin, rMax;
    [self getVisibleRange:&rMin:&rMax];
    
    for (MiscCoord_V i = rMin;  i < rMax;  i++)
        if (oldSel->contains(i) != newSel.contains(i))
            [self setNeedsDisplayInRect:[self rectForPos:i]];
    
    *oldSel = newSel;
}


//-----------------------------------------------------------------------------
// - resetSelection
//-----------------------------------------------------------------------------
- (void)resetSelection
{
    *oldSel = info->selectionSet();
}


//-----------------------------------------------------------------------------
// - selectPos:
//-----------------------------------------------------------------------------
- (void)selectPos:(MiscCoord_V)pos
{
    info->selectOne( pos );
    [scroll selectionChanged];
}



//=============================================================================
// CURSOR MANAGEMENT
//=============================================================================
//-----------------------------------------------------------------------------
// - toggleRect:forPos:visible:
//-----------------------------------------------------------------------------
- (BOOL)toggleRect:(NSRect*)nsrect forPos:(MiscCoord_V)pos visible:(NSRect)vis
{
    MiscPixels const pos_width = info->effectiveSize(pos);
    if (pos_width > 0)
    {
        *nsrect = [self rectForPos:pos];
        nsrect->origin.x += nsrect->size.width -
        (TOGGLE_WIDTH + MISC_RESIZE_EPSILON);
        nsrect->size.width = TOGGLE_WIDTH + MISC_BROKEN_CURSOR_RECTS;
        *nsrect = NSIntersectionRect( vis, *nsrect );
        return !NSIsEmptyRect( *nsrect );
    }
    return NO;
}


//-----------------------------------------------------------------------------
// - resizeRect:forPos:visible:
//-----------------------------------------------------------------------------
- (BOOL)resizeRect:(NSRect*)nsrect forPos:(MiscCoord_V)pos visible:(NSRect)vis
{
    MiscPixels const pos_width = info->effectiveSize(pos);
    if (pos_width > 0)
    {
        MiscPixels const pos_offset = info->getOffset(pos);
        MiscPixels const min_x = pos_offset + pos_width - MISC_RESIZE_EPSILON;
        MiscRect_O r( isHorz, [self bounds] );
        r.setX_O( min_x );
        r.setWidth_O( MISC_RESIZE_EPSILON );
        *nsrect = NSIntersectionRect( vis, r );
        return !NSIsEmptyRect( *nsrect );
    }
    return NO;
}


//-----------------------------------------------------------------------------
// - resetCursorRects
//-----------------------------------------------------------------------------
- (void)resetCursorRects
{
    BOOL const draggable = info->isDraggable();
    BOOL const sizeable = info->isSizeable();
    NSRect vis = [self visibleRect];

    if (draggable && !info->isModifierDrag())
        [self addCursorRect:vis cursor:dragCursor];

    if ([scroll autoSortSlots:MISC_OTHER_BORDER([self borderType])])
    {
        MiscCoord_V min_pos, max_pos;
        [self getVisibleRange:&min_pos:&max_pos];
        int const count = info->count();
        if (0 <= min_pos && min_pos < count)
        {
            NSRect rect;
            int const lim = (max_pos <= count) ? max_pos : count;
            for (MiscCoord_V pos = min_pos; pos < lim; pos++)
                if (info->isSortable(pos) &&
                    [self toggleRect:&rect forPos:pos visible:vis])
                    [self addCursorRect:rect cursor:reverseCursor];
        }
    }

    if (sizeable)
    {
        BOOL const uniform = info->isUniformSize();
        NSCursor* const resizeCursor = [self cursor];
        MiscCoord_V min_pos, max_pos;
        [self getVisibleRange:&min_pos:&max_pos];
        int const count = info->count();
        if (0 <= min_pos && min_pos < count)
        {
            NSRect rect;
            int const lim = (max_pos <= count) ? max_pos : count;
            for (MiscCoord_V pos = min_pos; pos < lim; pos++)
                if ((uniform || info->isSizeable(pos)) &&
                    [self resizeRect:&rect forPos:pos visible:vis])
                    [self addCursorRect:rect cursor:resizeCursor];
        }
    }
}



//=============================================================================
// MOUSE-TRACKING
//=============================================================================
//-----------------------------------------------------------------------------
// - posForMousePt:
//-----------------------------------------------------------------------------
- (MiscCoord_V)posForMousePt:(NSPoint)p
{
    MiscPixels pix = MiscPoint_O( isHorz, p ).getX_O();
    MiscRect_O r( isHorz, [self bounds] );
    return (pix < r.getMaxX_O() ? info->visualForOffset(pix) : info->count());
}



//=============================================================================
// RESIZING
//=============================================================================
//-----------------------------------------------------------------------------
// drawTransitoryRect:inView:
//-----------------------------------------------------------------------------
- (void)drawTransitoryRect:(NSRect)r inView:(NSView*)v
{
    NSWindow* const w = [self window];
    [w cacheImageInRect:[v convertRect:r toView:0]];
    NSRectFill(r);
    [w flushWindow];
}


//-----------------------------------------------------------------------------
// eraseTransitoryRect
//-----------------------------------------------------------------------------
- (void)eraseTransitoryRect
{
    NSWindow* const w = [self window];
    [w restoreCachedImage];
    [w discardCachedImage];
    [w flushWindow];
}


//-----------------------------------------------------------------------------
// - resizeEvent:x:deltaX:minX:maxX:
//-----------------------------------------------------------------------------
- (int)resizeEvent:(NSEvent*)p
                 x:(MiscPixels)x
            deltaX:(MiscPixels)deltaX
              minX:(MiscPixels)minX
              maxX:(MiscPixels)maxX
{
    NSRect nsDocFrame = [scroll documentClipRect];
    NSRect nsClipFrame = [[self superview] frame];
    MiscRect_O docFrame( isHorz, nsDocFrame );
    MiscRect_O clipFrame( isHorz, nsClipFrame );
    MiscPixels const minDrawX = clipFrame.getX_O();	// Scroll coords.
    MiscPixels const maxDrawX = clipFrame.getMaxX_O();	// Scroll coords.
    NSEventMask const WANTED =
    (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskPeriodic);

    x += deltaX;

    MiscPixels draw_x;					// Scroll coords.
    MiscRect_O line( isHorz );
    line.setX_O( x - 1 );
    line.setY_O( 0 );
    line.setWidth_O( 2 );
    line.setHeight_O( clipFrame.getHeight_O() + docFrame.getHeight_O() - 1 );
    line = [scroll convertPoint:line fromView:self];
    draw_x = line.getX_O();

    BOOL did_scroll = NO;
    BOOL in_bounds = (minDrawX <= draw_x && draw_x <= maxDrawX);

    [scroll lockFocus];
    [[NSColor blackColor] set];

    if (in_bounds)
        [self drawTransitoryRect:line inView:scroll];

    startTimer();
    NSEvent* lastEvent = [p copy];

    for (;;)
    {
        p = [[self window] nextEventMatchingMask:WANTED];

        if (p == 0 || [p type] == NSEventTypeLeftMouseUp)
            break;
        else if ([p type] == NSEventTypePeriodic)
        {
            NSPoint mousePt =
            [scroll convertPoint:[lastEvent locationInWindow] fromView:0];
            MiscPixels const mousePtX = MiscPoint_O( isHorz,mousePt ).getX_O();
            if (mousePtX < minDrawX || maxDrawX < mousePtX)
            {
                [self eraseTransitoryRect];
                [self autoscroll:lastEvent];
                did_scroll = YES;
            }
        }
        else
        {
            [lastEvent release];
            lastEvent = [p copy];
        }

        NSPoint new_loc =
        [self convertPoint:[lastEvent locationInWindow] fromView:0];
        MiscPixels mouseX = MiscPoint_O( isHorz, new_loc ).getX_O();
        MiscPixels new_x = (mouseX + deltaX);
        if (new_x < minX)
            new_x = minX;
        else if (new_x >= maxX)
            new_x = maxX - 1;

        BOOL const did_move = (new_x != x);
        if (did_move || did_scroll)
        {
            if (in_bounds && !did_scroll)
                [self eraseTransitoryRect];
            
            if (did_move)
            {
                x = new_x;
                line.setX_O( x - 1 );
                line.setY_O( 0 );
                line = [scroll convertPoint:line fromView:self];
                draw_x = line.getX_O();
                in_bounds = (minDrawX <= draw_x && draw_x <= maxDrawX);
            }

            if (in_bounds)
                [self drawTransitoryRect:line inView:scroll];
            
            did_scroll = NO;
        }
    }
    
    [lastEvent release];
    stopTimer();

    if (in_bounds)
        [self eraseTransitoryRect];

    [scroll unlockFocus];

    x -= deltaX;
    return x;
}


//-----------------------------------------------------------------------------
// - resizeEvent:inPos:atX:deltaX:finalWidth:
//-----------------------------------------------------------------------------
- (BOOL)resizeEvent:(NSEvent*)p
              inPos:(MiscCoord_V)pos
                atX:(MiscPixels)x_origin
             deltaX:(MiscPixels)delta_x
         finalWidth:(MiscPixels*)finalWidth
{
    MiscPixels const org_x = info->getOffset(pos);
    MiscPixels const min_x = org_x + info->effectiveMinSize(pos);
    MiscPixels const max_x = org_x + info->getMaxSize(pos) + 1;
    MiscPixels const curr_x =
    [self resizeEvent:p x:x_origin deltaX:delta_x minX:min_x maxX:max_x];
    MiscPixels final_delta = curr_x - x_origin;
    if (final_delta != 0)
    {
        *finalWidth = info->effectiveSize(pos) + final_delta;
        return YES;
    }
    
    return NO;
}


//-----------------------------------------------------------------------------
// - inResizeZone:forPos:atX:deltaX:
//-----------------------------------------------------------------------------
- (BOOL)inResizeZone:(NSPoint)pt
              forPos:(MiscCoord_V*)pos
                 atX:(MiscPixels*)pos_x
              deltaX:(MiscPixels*)delta_x
{
    if (info->isSizeable())
    {
        MiscCoord_V const plim = info->count();
        MiscPixels x = MiscPoint_O( isHorz, pt ).getX_O();
        MiscCoord_V p = info->visualForOffset(x);
        if (0 <= p && p < plim)
        {
            BOOL const uniform = info->isUniformSize();
            MiscPixels max_x = info->getOffset(p) + info->effectiveSize(p);
            MiscPixels delta = max_x - x;
            if (0 <= delta && delta <= MISC_RESIZE_EPSILON)
            {
                do { p++; } while (p < plim && info->effectiveSize(p) <= 0);
                p--;
                if (0 <= p && p < plim && (uniform || info->isSizeable(p)))
                {
                    *pos = p;
                    *pos_x = x;
                    *delta_x = delta;
                    return YES;
                }
            }
        }
    }
    return NO;
}


//-----------------------------------------------------------------------------
// - adjustSize
//-----------------------------------------------------------------------------
- (void)adjustSize
{
    [self changeFrameIfNeeded];
}



//=============================================================================
// DRAGGING
//=============================================================================
//-----------------------------------------------------------------------------
// draw_view
//	Draw a view hierarchy without calling lockFocus so that it can be
//	drawn onto a different window.  Used for drawing the drag cache
//	window.
//-----------------------------------------------------------------------------
static void draw_view( NSView* v, NSRect r )
{
    // FIXME: maybe clip, maybe manually transform graphics state coord matrix.
    [v drawRect:r];
    NSArray* subs = [v subviews];
    NSInteger lim = (subs ? [subs count] : 0);
    for (NSInteger i = 0; i < lim; i++)
    {
        NSView* sub = (NSView*)[subs objectAtIndex:i];
        NSRect subFrame = NSIntersectionRect( r, [sub frame] );
        if (!NSIsEmptyRect( subFrame ))
        {
            subFrame = [sub convertRect:subFrame fromView:v];
            draw_view( sub, subFrame );
        }
    }
}


//-----------------------------------------------------------------------------
// - dragCacheForPos:
//
// NOTE *COORDS*
//	The TableScroll, BorderView, and TableView all share the the same
//	scaling and rotation.  Also, the coordinate system of the TableView
//	is always anchored at the same "X" offset as the BorderView, so that
//	(orientation corrected) "X" coordinates and widths can be exchanged
//	between the two views without further adjustments.
//-----------------------------------------------------------------------------
- (NSImage*)dragCacheForPos:(MiscCoord_V)pos
{
    NSImage* cache = [[NSImage allocWithZone:[self zone]] init];
    MiscTableView* tableView = (MiscTableView*) [scroll documentView];

    NSRect nsBorder = [self rectForPos:pos];
    NSRect nsTable = [tableView visibleRect];

    MiscRect_O oBorder( isHorz, nsBorder );
    MiscRect_O oTable( isHorz, nsTable );

    MiscSize_O oCache( isHorz );
    oCache.setWidth_O( oBorder.getWidth_O() );
    oCache.setHeight_O( oBorder.getHeight_O() + oTable.getHeight_O() );
    NSSize nsCache = oCache;
    [cache setSize:nsCache];

    if (oTable.getX_O() <= oBorder.getX_O() &&		// Is entire slot
        oBorder.getMaxX_O() <= oTable.getMaxX_O())	// visible?
    {
        MiscRect_O oScroll( isHorz );
        oScroll.setX_O( oBorder.getX_O() );
        oScroll.setY_O( oBorder.getY_O() );
        oScroll.setWidth_O( oBorder.getWidth_O() );
        oScroll.setHeight_O( oCache.getHeight_O() );
        NSRect nsScroll = [scroll convertRect:oScroll fromView:self];

        NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
                                 initWithBitmapDataPlanes:NULL pixelsWide:ceil(nsScroll.size.width) pixelsHigh:ceil(nsScroll.size.height) bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:ceil(nsScroll.size.width)*4 bitsPerPixel:32];
        [scroll cacheDisplayInRect:nsScroll toBitmapImageRep:rep];

        [cache addRepresentation:rep];
        [rep release];
    }
    else
    {
        [cache lockFocusFlipped:YES];

        oTable.setX_O( oBorder.getX_O() );		// NOTE *COORDS*
        oTable.setWidth_O( oBorder.getWidth_O() );
        nsTable = oTable;

        MiscPoint_O oDelta( isHorz, nsTable.origin );
        oDelta.setY_O( oDelta.getY_O() - oBorder.getHeight_O() );
        NSPoint delta = oDelta;

        NSView* focusView = [NSView focusView];

        [focusView translateOriginToPoint:NSMakePoint( -delta.x, -delta.y )];
        draw_view( tableView, nsTable );
        [focusView translateOriginToPoint:NSMakePoint( delta.x, delta.y )];

        [focusView translateOriginToPoint:
         NSMakePoint( -nsBorder.origin.x, -nsBorder.origin.y )];
        draw_view( self, nsBorder );
        [focusView translateOriginToPoint:
         NSMakePoint( nsBorder.origin.x, nsBorder.origin.y )];
        
        [cache unlockFocus];
    }

    return [cache autorelease];
}


//-----------------------------------------------------------------------------
// - getVisibleCacheMin:max:
//-----------------------------------------------------------------------------
- (NSImage*)getVisibleCacheMin:(MiscPixels*)pMin max:(MiscPixels*)pMax
{
    MiscRect_O rDoc( isHorz, [[scroll documentView] visibleRect] );
    MiscRect_O rVis( isHorz, [self visibleRect] );
    *pMin = rVis.getX_O();
    *pMax = rVis.getMaxX_O();
    rDoc = [scroll convertRect:rDoc fromView:[scroll documentView]];
    rVis = [scroll convertRect:rVis fromView:self];

    MiscRect_O r( isHorz );
    r.setX_O( rVis.getX_O() );
    r.setY_O( rVis.getY_O() );
    r.setWidth_O( rVis.getWidth_O() );
    r.setHeight_O( rVis.getHeight_O() + rDoc.getHeight_O() );

    
    NSBitmapImageRep* rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes:NULL pixelsWide:r.getWidth() pixelsHigh:r.getHeight() bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bytesPerRow:r.getWidth()*4 bitsPerPixel:32];
    [scroll cacheDisplayInRect:r toBitmapImageRep:rep];

    NSImage* cache = [[NSImage alloc] initWithSize:r];
    [cache addRepresentation:rep];
    [rep release];
    return [cache autorelease];
}


//-----------------------------------------------------------------------------
// - setWells::forPos:
//-----------------------------------------------------------------------------
- (void)setWells:(MiscTableWell**)w1 :(MiscTableWell**)w2
    forPos:(MiscCoord_V)pos
{
    MiscTableView* doc = [scroll documentView];
    MiscRect_O rDoc( isHorz, [doc visibleRect] );
    MiscRect_O rClip( isHorz, [[self superview] frame] );

    MiscRect_O r( isHorz );
    r.setX_O( info->getOffset(pos) );
    r.setWidth_O( info->effectiveSize(pos) );
    r.setHeight_O( rClip.getHeight_O() );

    *w1 = [[MiscTableWell alloc] initWithFrame:r];
    [self addSubview:*w1];

    r.setY_O( rDoc.getY_O() );
    r.setHeight_O( rDoc.getHeight_O() );
    *w2 = [[MiscTableWell alloc] initWithFrame:r];
    [doc addSubview:*w2];

    [*w1 display];
    [*w2 display];
}


//-----------------------------------------------------------------------------
// - clearWells::
//-----------------------------------------------------------------------------
- (void)clearWells:(MiscTableWell**)w1 :(MiscTableWell**)w2
{
    [*w1 removeFromSuperview];
    [*w2 removeFromSuperview];
    [*w1 release];
    [*w2 release];
    *w1 = 0;
    *w2 = 0;
    // NOTE: Does not need display here.  Everything will get displayed later.
}


//-----------------------------------------------------------------------------
// - offsetFromEvent:
//-----------------------------------------------------------------------------
- (float)offsetFromEvent:(NSEvent*)ev
{
    NSPoint mLoc = [self convertPoint:[ev locationInWindow] fromView:0];
    return MiscPoint_O( isHorz, mLoc ).getX_O();
}


//-----------------------------------------------------------------------------
// - calcDrop:::
//-----------------------------------------------------------------------------
- (MiscCoord_V)calcDrop:(MiscCoord_V)fromPos
			:(NSPoint)mouseDownPt
			:(NSPoint)mouseUpPt
{
    MiscCoord_V toPos = fromPos;
    MiscPixels const start_pos = MiscPoint_O( isHorz, mouseDownPt ).getX_O();
    MiscPixels const end_pos   = MiscPoint_O( isHorz, mouseUpPt   ).getX_O();
    MiscPixels const delta_pos = (end_pos - start_pos);

    MiscPixels const SLOP = 4;
    if (delta_pos < -SLOP || SLOP < delta_pos)
    {
        MiscPixels const start_ofs = info->getOffset( fromPos );
        MiscPixels drop_pos = start_ofs + delta_pos;
        if (delta_pos < 0)
            drop_pos += SLOP;
        else
            drop_pos += info->effectiveSize(fromPos) - SLOP;
        toPos = info->visualForOffset( drop_pos );
        if (toPos < 0)
            toPos = 0;
    }

    return toPos;
}


//-----------------------------------------------------------------------------
// - dragEvent:inPos:
//-----------------------------------------------------------------------------
- (MiscCoord_V)dragEvent:(NSEvent*)event inPos:(MiscCoord_V)pos
{
    NSEventMask const WANTED =
    (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskPeriodic);

    NSPoint mouseDownPt =
    [self convertPoint:[event locationInWindow] fromView:nil];
    NSPoint mouseUpPt = mouseDownPt;
    NSWindow* win = [self window];

    [scroll disableCursor];
    [win flushWindow];
    [win disableFlushWindow];

    NSImage* dragCache = [[self dragCacheForPos:pos] retain];

    MiscTableWell *w1, *w2;
    [self setWells:&w1 :&w2 forPos:pos];

    MiscPixels pMin,pMax;
    NSImage* visCache = [[self getVisibleCacheMin:&pMin max:&pMax] retain];

    MiscSize_O size( isHorz, [dragCache size] );
    MiscPixels pLoc = info->getOffset( pos );
    MiscPixels delta = MiscPixels( [self offsetFromEvent:event] - pLoc );

    NSEvent* lastEvent = [event copy];
    [scroll lockFocus];
    for (;;)
    {
        MiscPoint_O pt( isHorz );
        MiscRect_O rDrag( isHorz );
        MiscPixels const w = size.getWidth_O();
        MiscPixels const dw =
        dmin( dmin( dmin(w, pMax - pMin), pMax - pLoc), pLoc + w - pMin );
        BOOL const shouldDraw = (dw > 0);
        if (shouldDraw)
        {
            if (isHorz)
            {
                pt.setX( dmax( pLoc, pMin ) );
                pt.setY( size.getHeight_O() );
                if (pLoc < pMin)
                    rDrag.setX( pMin - pLoc );
            }
            else
            {
                pt.setX( 0 );
                pt.setY( dmax( pLoc, pMin ) + dw );
                if (pLoc + w >= pMax)
                    rDrag.setY( pLoc + w - pMax );
            }
            pt = [scroll convertPoint:pt fromView:self];
            rDrag.setWidth_O( dw );
            rDrag.setHeight_O( size.getHeight_O() );
            [dragCache drawAtPoint:pt fromRect:rDrag
                         operation:NSCompositingOperationCopy fraction:1];
        }
        [win enableFlushWindow];
        [win flushWindow];

        event = [[self window] nextEventMatchingMask:WANTED];

        [win disableFlushWindow];
        if (shouldDraw)
        {
            NSSize s = [visCache size];
            MiscPixels xTarg;
            if (isHorz)
            {
                xTarg = (pLoc < pMin ? 0 : pLoc - pMin);
            }
            else
            {
                if (pLoc < pMin)
                    xTarg = MiscPixels(s.height) - dw;
                else if (pLoc < pMax)
                    xTarg = pMax - pLoc - dw;
                else
                    xTarg = 0;
            }
            MiscRect_O rVis( isHorz );
            rVis.setX_O( xTarg );
            rVis.setWidth_O( rDrag.getWidth_O() );
            rVis.setHeight_O( rDrag.getHeight_O() );
            [visCache drawAtPoint:pt fromRect:rVis
                        operation:NSCompositingOperationCopy fraction:1];
        }

        if (event == 0)
            break;
        else if ([event type] == NSEventTypeLeftMouseUp)
        {
            mouseUpPt = [self convertPoint:[event locationInWindow] fromView:0];
            break;
        }
        else if ([event type] != NSEventTypePeriodic)
        {
            [lastEvent release];
            lastEvent = [event copy];
        }

        MiscPixels mLoc = MiscPixels( [self offsetFromEvent:lastEvent] );
        if ((mLoc < pMin && pMin > 0.0) || (mLoc > pMax &&
                                            pMax < MiscRect_O( isHorz, [self bounds] ).getMaxX_O()))
        {
            [self autoscroll:lastEvent];
            [visCache release];
            visCache = [[self getVisibleCacheMin:&pMin max:&pMax] retain];
            mLoc = MiscPixels( [self offsetFromEvent:lastEvent] );
            startTimer();
        }
        else
        {
            stopTimer();
        }

        pLoc = mLoc - delta;
        if (pLoc < pMin - size.getWidth_O())
            pLoc = pMin - size.getWidth_O();
        else if (pLoc > pMax)
            pLoc = pMax;
    }

    [lastEvent release];
    stopTimer();
    [scroll unlockFocus];
    [self clearWells:&w1 :&w2];
    [visCache release];
    [dragCache release];

    MiscCoord_V const toPos = [self calcDrop:pos :mouseDownPt :mouseUpPt];

    if (toPos != pos)
    {
        [scroll border:[self borderType] moveSlot:pos toSlot:toPos];
        [win invalidateCursorRectsForView:self];
        [scroll border:[self borderType] slotDragged:pos toSlot:toPos];
        [self setNeedsDisplay:YES];
        [[scroll documentView] setNeedsDisplay:YES];
    }
    else
    {
        // Need to redisplay the slot that the wells were covering.
        MiscBorderType const b = [self borderType];
        int const phys_pos = [scroll border:b slotAtPosition:toPos];
        [scroll border:b drawSlotTitle:phys_pos];
        [scroll border:b drawSlot:phys_pos];
    }

    [scroll enableCursor];
    [scroll displayIfNeeded];
    [win enableFlushWindow];
    [win flushWindow];
    return toPos;
}


//-----------------------------------------------------------------------------
// - awaitDragEvent:inPos:
//-----------------------------------------------------------------------------
- (MiscCoord_V)awaitDragEvent:(NSEvent*)event inPos:(MiscCoord_V)pos
{
    MiscCoord_V toPos = pos;
    NSEventMask const WANTED = (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged);
    float const SLOP = 2.0;
    NSWindow* win = [self window];
    NSEvent* mouseDown = [event copy];
    NSPoint origLoc = [mouseDown locationInWindow];
    for (;;)
    {
        NSEvent* p = [win nextEventMatchingMask:WANTED
                                      untilDate:[NSDate distantFuture]
                                         inMode:NSEventTrackingRunLoopMode
                                        dequeue:NO];
        if (p == 0)
            break;
        else if ([p type] == NSEventTypeLeftMouseUp)
        {
            [win nextEventMatchingMask:NSEventMaskLeftMouseUp];
            break;
        }
        else // ([p type] == NSLeftMouseDragged)
        {
            NSPoint newLoc = [p locationInWindow];
            if (newLoc.x > origLoc.x + SLOP || newLoc.y > origLoc.y + SLOP ||
                newLoc.x < origLoc.x - SLOP || newLoc.y < origLoc.y - SLOP)
            {
                [scroll suspendEditing];
                toPos = [self dragEvent:mouseDown inPos:pos];
                [scroll resumeEditing];
                break;
            }
            else
                [win nextEventMatchingMask:NSEventMaskLeftMouseDragged];
        }
    }
    [mouseDown release];
    return toPos;
}



//=============================================================================
// TOGGLE SORT DIRECTION
//=============================================================================
//-----------------------------------------------------------------------------
// - toggleRectForPos:
//-----------------------------------------------------------------------------
- (NSRect)toggleRectForPos:(MiscCoord_V)pos
{
    NSRect r = [self rectForPos:pos];
    CGFloat const w = TOGGLE_WIDTH + MISC_RESIZE_EPSILON;
    r.origin.x = floor( r.origin.x + r.size.width - w );
    r.size.width = w;
    return r;
}


//-----------------------------------------------------------------------------
// - inToggleZone:forPos:
//-----------------------------------------------------------------------------
- (BOOL)inToggleZone:(NSPoint)pt forPos:(MiscCoord_V)pos
{
    if ([scroll autoSortSlots:MISC_OTHER_BORDER([self borderType])] &&
        info->isSortable(pos))
    {
        NSRect r = [self toggleRectForPos:pos];
        return r.origin.x <= pt.x && pt.x <= (r.origin.x + r.size.width);
    }
    return NO;
}


//-----------------------------------------------------------------------------
// - toggleEvent:forPos:
//-----------------------------------------------------------------------------
- (void)toggleEvent:(NSEvent*)p forPos:(MiscCoord_V)pos
{
    BOOL was_in_zone = YES;
    BOOL is_in_zone = YES;
    
    NSRect toggleZone = [self toggleRectForPos:pos];
    NSWindow* win = [self window];

    togglePos = pos;
    [self lockFocus];
    [self drawPos:pos];
    [win flushWindow];

    for (;;)
    {
        p = [win nextEventMatchingMask:
             (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged)];

        NSPoint new_loc = [p locationInWindow];
        new_loc = [self convertPoint:new_loc fromView:0];
        is_in_zone = NSPointInRect( new_loc, toggleZone );
        if (was_in_zone != is_in_zone)
        {
            was_in_zone = is_in_zone;
            togglePos = (is_in_zone ? pos : -1);
            [self drawPos:pos];
            [win flushWindow];
        }
        
        if ([p type] == NSEventTypeLeftMouseUp)
            break;
    }

    togglePos = -1;
    [self unlockFocus];

    if (is_in_zone)
    {
        MiscBorderType const bt = [self borderType];
        MiscSortDirection dir = info->getSortDirection( pos );
        dir = MISC_OTHER_DIRECTION( dir );
        MiscCoord_P p_pos = info->visualToPhysical( pos );
        [scroll border:bt setSlot:p_pos sortDirection:dir];
        [scroll border:bt slotSortReversed:p_pos];
        [self setNeedsDisplayInRect:[self rectForPos:pos]];
        [scroll displayIfNeeded];
    }
}



//=============================================================================
// SELECTION
//=============================================================================
//-----------------------------------------------------------------------------
// - adjustCursor:
//-----------------------------------------------------------------------------
- (void)adjustCursor:(MiscCoord_V)p
{
    if (p < 0)
        p = 0;
    else if (p >= info->count())
        p = info->count() - 1;
    [scroll border:[self borderType] setCursorSlot:info->visualToPhysical(p)];
}


//-----------------------------------------------------------------------------
// - selectionEvent:fromPos:
//-----------------------------------------------------------------------------
- (void)selectionEvent:(NSEvent*)p fromPos:(MiscCoord_V)pos
{
    NSEventMask const WANTED =
    (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged | NSEventMaskPeriodic);
    BOOL doubleClicked = ([p clickCount] > 1);

    [scroll disableCursor];
    [self clearOtherBorder];
    [tracker mouseDown:p atPos:pos];
    [scroll selectionChanged];
    [scroll displayIfNeeded];

    startTimer();
    NSEvent* lastEvent = [p copy];

    for(;;)
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
        
        NSPoint new_loc = [lastEvent locationInWindow];
        new_loc = [self convertPoint:new_loc fromView:0];
        MiscCoord_V new_pos = [self posForMousePt:new_loc];
        if (new_pos != pos)
        {
            pos = new_pos;
            [tracker mouseDragged:p atPos:pos];
            [scroll selectionChanged];
            [scroll displayIfNeeded];
        }
    }

    [lastEvent release];
    stopTimer();

    [tracker mouseUp:p atPos:pos];
    [scroll selectionChanged];
    [self adjustCursor:pos];
    [scroll enableCursor];
    [[self window] flushWindow];

    [scroll displayIfNeeded];
    if ([scroll isEnabled])
    {
        [scroll sendAction];
        if (doubleClicked)
            [scroll sendDoubleAction];
    }
}



//=============================================================================
// MOUSE-EVENTS
//=============================================================================
//-----------------------------------------------------------------------------
// - acceptsFirstMouse:
//-----------------------------------------------------------------------------
- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
    return YES;
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
    NSRect const r = [self bounds];
    NSPoint const evpt = [self convertPoint:[p locationInWindow] fromView:0];
    if (evpt.x >= 0 && evpt.x < r.size.width &&		// NOTE *OUT-OF-BOUNDS*
        evpt.y >= 0 && evpt.y <= r.size.height)
    {
        MiscCoord_V pos = [self posForMousePt:evpt];
        MiscPixels x, delta_x;

        if ([self inResizeZone:evpt forPos:&pos atX:&x deltaX:&delta_x])
        {
            [scroll suspendEditing];
            MiscPixels finalWidth;
            BOOL doit;
            doit = [self resizeEvent:p inPos:pos atX:x deltaX:delta_x
                          finalWidth:&finalWidth];
            if (doit)
            {
                if (info->isUniformSize())
                {
                    [scroll border:[self borderType]
               setUniformSizeSlots:finalWidth];
                    [[self window] invalidateCursorRectsForView:self];
                    [scroll setNeedsDisplay:YES];
                }
                else
                    [self setPos:pos width:finalWidth];
                [scroll border:[self borderType] slotResized:pos];
            }
            [scroll resumeEditing];
        }
        else if ([self inToggleZone:evpt forPos:pos])
        {
            [scroll suspendEditing];
            [self toggleEvent:p forPos:pos];
            [scroll resumeEditing];
        }
        else if (info->isDraggable() && (info->isModifierDrag() ==
                                         (([p modifierFlags] & NSEventModifierFlagCommand) != 0)))
        {
            [self awaitDragEvent:p inPos:pos];
        }
        else
        {
            NSParameterAssert( tracker != 0 );	// End cell editing.
            [[self window] makeFirstResponder:[scroll documentView]];
            [self selectionEvent:p fromPos:pos];
        }
    }
}

@end
