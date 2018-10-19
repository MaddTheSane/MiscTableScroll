//=============================================================================
//
//  Copyright (C) 1995,1996,1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableViewDrag.M
//
//	Image dragging methods for MiscTableView.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableViewDrag.M,v 1.2 98/03/29 23:59:48 sunshine Exp $
// $Log:	MiscTableViewDrag.M,v $
// Revision 1.2  98/03/29  23:59:48  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// Implemented -shouldDelayWindowOrderingForEvent:
// 
// Revision 1.1  97/11/23  07:41:42  sunshine
// v130.1: Image dragging methods.
//-----------------------------------------------------------------------------
#import "MiscTableViewPrivate.h"
#import "MiscTableScrollPrivate.h"
#import <MiscTableScroll/MiscTableCell.h>
#import <AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSWindow.h>
#include <cmath>	// floor()

typedef MiscDelegateFlags DF;

@implementation MiscTableView(Drag)

//=============================================================================
// IMAGE DRAGGING
//=============================================================================
static inline float absval( float x ) { return (x < 0 ? -x : x ); }
static inline BOOL isSlop( NSEvent* e1, NSEvent* e2, float const slop )
{
    NSPoint const p1 = [e1 locationInWindow];
    NSPoint const p2 = [e2 locationInWindow];
    return (absval(p1.x - p2.x) <= slop && absval(p1.y - p2.y) <= slop);
}


//-----------------------------------------------------------------------------
// draggingSourceOperationMaskForLocal:
//-----------------------------------------------------------------------------
- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)flag
{
    id const scroll = [self scroll];
    id const d = [scroll responsibleDelegate:DF::DEL_DRAG_OP_MASK];
    if (d != 0)
        return [d tableScroll:scroll draggingSourceOperationMaskForLocal:flag];
    return NSDragOperationGeneric;
}


//-----------------------------------------------------------------------------
// ignoreModifierKeysWhileDragging
//-----------------------------------------------------------------------------
- (BOOL)ignoreModifierKeysWhileDragging
{
    id const scroll = [self scroll];
    id const d = [scroll responsibleDelegate:DF::DEL_DRAG_IGNORE_MODIFIERS];
    if (d != 0)
        return [d tableScrollIgnoreModifierKeysWhileDragging:scroll];
    return YES;
}


//-----------------------------------------------------------------------------
// shouldDelayWindowOrderingForEvent:
//-----------------------------------------------------------------------------
- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent*)e
{
    BOOL delay = NO;
    NSPoint const p = [self convertPoint:[e locationInWindow] fromView:0];
    MiscCoord_P r,c;
    if ([self getRow:&r column:&c forPoint:p] &&
        [self canPerformDragAtRow:r column:c withEvent:e])
    {
        id const scroll = [self scroll];
        id d = [scroll responsibleDelegate:DF::DEL_DRAG_DELAY_WIN_ORDERING];
        if (d != 0)
            delay = [d tableScroll:scroll shouldDelayWindowOrderingForEvent:e];
        else
            delay = YES;
    }
    return delay;
}


//-----------------------------------------------------------------------------
// getDragImageAtRow:column:
//-----------------------------------------------------------------------------
- (NSImage*)getDragImageAtRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    NSImage* i = 0;
    id const scroll = [self scroll];
    id const d = [scroll responsibleDelegate:DF::DEL_IMAGE_FOR_DRAG];
    if (d != 0)
        i = [d tableScroll:scroll imageForDragOperationAtRow:row column:col];
    if (i == 0)
    {
        NSCell* cell = (NSCell*)[scroll cellAtRow:row column:col];
        if ([cell type] == NSImageCellType)
            i = [cell image];
    }
    return i;
}


//-----------------------------------------------------------------------------
// calcOrigin:andOffset:forImage:inRect:atRow:column:downEvent:dragEvent:
//
// Compute the origin of the image and the offset of the mouse for dragging 
// via NSView's -dragImage:at:offset:... method.  There are two cases: 
//
// CASE *1*: The image being dragged fits exactly in the cell's image area.  
//    In this case drag from the point where the mouse went down inside the 
//    image's boundry.  This give the visual impression of lifting the image 
//    exactly from where it is sitting; without it jumping to some other 
//    location.  
// CASE *2*: The image is a different size than the cell's image area.  In 
//    this case just center the image under the mouse.  
//-----------------------------------------------------------------------------
- (void)calcOrigin:(NSPoint*)origin
    andOffset:(NSSize*)offset
    forImage:(NSImage*)image
    inRect:(NSRect)rect
    atRow:(MiscCoord_P)row
    column:(MiscCoord_P)col
    downEvent:(NSEvent*)downEvent
    dragEvent:(NSEvent*)dragEvent
{
    offset->width = 0;
    offset->height = 0;

    NSSize image_s = [image size];

    id cell = [[self scroll] cellAtRow:row column:col];
    NSRect image_r = [cell imageRectForBounds:rect];

    if (image_s.width  == image_r.size.width &&			// CASE *1*
        image_s.height == image_r.size.height)
    {
        *origin = image_r.origin;
        if ([self isFlipped])
            origin->y += image_r.size.height;

        if (dragEvent != 0 && [dragEvent type] == NSEventTypeLeftMouseDragged)
        {
            NSPoint ptDrag = [dragEvent locationInWindow];
            NSPoint ptDown = [downEvent locationInWindow];
            offset->width = ptDrag.x - ptDown.x;
            offset->height = ptDrag.y - ptDown.y;
        }
    }
    else							// CASE *2*
    {
        *origin = [self convertPoint:[downEvent locationInWindow] fromView:0];
        origin->x -= floor( image_s.width / 2 );
        origin->y -= floor( image_s.height / 2 ) * ([self isFlipped] ? -1 : 1);
    }
}


//-----------------------------------------------------------------------------
// prepareDragPasteboard:atRow:column:
//-----------------------------------------------------------------------------
- (void)prepareDragPasteboard:(NSPasteboard*)pb
    atRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    id const scroll = [self scroll];
    id const d = [scroll responsibleDelegate:DF::DEL_PREPARE_PB_FOR_DRAG];
    if (d != 0)
        [d tableScroll:scroll preparePasteboard:pb
 forDragOperationAtRow:row column:col];
}


//-----------------------------------------------------------------------------
// performDrag:atRow:column:inRect:dragEvent:
//-----------------------------------------------------------------------------
- (BOOL)performDrag:(NSEvent*)mouseDown
    atRow:(MiscCoord_P)row
    column:(MiscCoord_P)col
    inRect:(NSRect)r
    dragEvent:(NSEvent*)dragEvent
{
    BOOL ret = NO;

    NSImage* i = [self getDragImageAtRow:row column:col];
    if (i != 0)
    {
        NSPoint origin;
        NSSize offset;
        [self calcOrigin:&origin andOffset:&offset forImage:i inRect:r
                   atRow:row column:col downEvent:mouseDown dragEvent:dragEvent];

        NSPasteboard* pb = [NSPasteboard pasteboardWithName:NSPasteboardNameDrag];
        [self prepareDragPasteboard:pb atRow:row column:col];

        [self dragImage:i at:origin offset:offset
                  event:mouseDown pasteboard:pb source:self slideBack:YES];
        ret = YES;
    }
    return ret;
}


//-----------------------------------------------------------------------------
// awaitDragEvent:atRow:column:
//-----------------------------------------------------------------------------
- (BOOL)awaitDragEvent:(NSEvent*)mouseDown
    atRow:(MiscCoord_P)row column:(MiscCoord_P)col inRect:(NSRect)rect
{
    CGFloat const DELAY = 0.25;
    CGFloat const SLOP = 4.0;
    NSEventMask const WANTED = (NSEventMaskLeftMouseUp | NSEventMaskLeftMouseDragged);

    BOOL ret = NO;
    NSEvent* event;
    NSWindow* win = [self window];

    do	{
        event = [win nextEventMatchingMask:WANTED
                                 untilDate:[NSDate dateWithTimeIntervalSinceNow:DELAY]
                                    inMode:NSEventTrackingRunLoopMode dequeue:NO];
        if (event != 0 && [event type] == NSEventTypeLeftMouseDragged)
            event = [win nextEventMatchingMask:NSEventMaskLeftMouseDragged];
    } while (event != 0 && [event type] == NSEventTypeLeftMouseDragged &&
             isSlop( event, mouseDown, SLOP ));

    if (event == 0 || [event type] == NSEventTypeLeftMouseDragged)
        ret = [self performDrag:mouseDown atRow:row column:col inRect:rect
                      dragEvent:event];
    return ret;
}


//-----------------------------------------------------------------------------
// canPerformDragAtRow:column:withEvent:
//-----------------------------------------------------------------------------
- (BOOL)canPerformDragAtRow:(MiscCoord_P)r column:(MiscCoord_P)c
    withEvent:(NSEvent*)p
{
    id const scroll = [self scroll];
    id const d = [scroll responsibleDelegate:DF::DEL_ALLOW_DRAG];
    return (d != 0 && 
            [d tableScroll:scroll allowDragOperationAtRow:r column:c] &&
            [scroll responsibleDelegate:DF::DEL_PREPARE_PB_FOR_DRAG] != 0 &&
            ([(NSCell*)[scroll cellAtRow:r column:c] type] == NSImageCellType ||
             [scroll responsibleDelegate:DF::DEL_IMAGE_FOR_DRAG] != 0));
}

@end
