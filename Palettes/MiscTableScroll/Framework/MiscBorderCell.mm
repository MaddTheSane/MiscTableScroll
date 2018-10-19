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
// MiscBorderCell.M
//
//	Cell class used by MiscBorderView to manage column headings and row 
//	labels for MiscTableScroll.  
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscBorderCell.M,v 1.7 98/03/29 23:38:17 sunshine Exp $
// $Log:	MiscBorderCell.M,v $
// Revision 1.7  98/03/29  23:38:17  sunshine
// v138.1: Now derived from NSTableHeaderCell rather than NSTextFieldCell
// so that it knows how to correctly draw and color itself on all platforms
// rather than only being able to draw itself in a NextStep-like fashion.
// 
//  Revision 1.6  97/03/23  05:45:38  sunshine
//  v125.4: Worked around OPENSTEP 4.1 bug where -setupFieldEditorAttributes:
//  never gets called, so text was not drawing white.  Worked around problem by
//  subclassing from NSTextFieldCell rather than NSCell.  This way color can
//  be set with -setTextColor:.
//-----------------------------------------------------------------------------
#import "MiscBorderCell.h"
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>

int const RESIZE_WIDTH = 4; // Resize zone to right of "toggle" image.

@implementation MiscBorderCell

//-----------------------------------------------------------------------------
// -setToggleImage:
//-----------------------------------------------------------------------------
- (void)setToggleImage:(NSImage*)p
{
    if (p != toggleImage)
    {
        [toggleImage release];
        toggleImage = [p retain];
    }
}


//-----------------------------------------------------------------------------
// -initBorderCell
//-----------------------------------------------------------------------------
- (void)initBorderCell
{
    toggleImage = 0;
    [self setBordered:YES];
    [self setWraps:NO];
    [self setAlignment:NSTextAlignmentCenter];
}


//-----------------------------------------------------------------------------
// -initTextCell:
//-----------------------------------------------------------------------------
- (id)initTextCell:(NSString*)s
{
    [super initTextCell:s];
    [self initBorderCell];
    return self;
}


//-----------------------------------------------------------------------------
// -initImageCell:
//-----------------------------------------------------------------------------
- (id)initImageCell:(NSImage*)p
{
    [super initImageCell:p];
    [self initBorderCell];
    return self;
}


//-----------------------------------------------------------------------------
// -cellSizeForBounds:
//-----------------------------------------------------------------------------
- (NSSize)cellSizeForBounds:(NSRect)aRect
{
    NSSize s = [super cellSizeForBounds:aRect];
    if (toggleImage != 0)
        s.width += [toggleImage size].width;
    return s;
}


//-----------------------------------------------------------------------------
// -drawInteriorWithFrame:inView: -- Assumes the view is flipped.
//-----------------------------------------------------------------------------
- (void)drawInteriorWithFrame:(NSRect)r inView:(NSView*)v
{
    if (toggleImage != 0)
    {
        NSSize sz = [toggleImage size];
        NSPoint pt = { NSMaxX(r) - RESIZE_WIDTH, NSMaxY(r) };

        float const max_height = floor( NSHeight(r) );
        float const max_width = floor( NSWidth(r) - RESIZE_WIDTH );

        BOOL const too_high = sz.height > max_height;
        BOOL const too_wide = sz.width > max_width;
        if (too_high || too_wide)
        {
            NSRect q = { {0,0}, {sz.width, sz.height} };
            if (too_high)
            {
                q.size.height = max_height;
                q.origin.y = floor( (sz.height - max_height) / 2 );
            }
            else
            {
                // Center image vertically.
                pt.y = floor( pt.y - ((max_height - sz.height) / 2) );
            }
            if (too_wide)
            {
                q.size.width = max_width;
                q.origin.x = floor( (sz.width - max_width) / 2 );
            }
            sz = q.size;
            pt.x -= sz.width;
            [toggleImage drawAtPoint:pt fromRect:q
                           operation:NSCompositingOperationSourceOver fraction:1];
        }
        else
        {
            // Center image vertically.
            pt.y = floor( pt.y - ((max_height - sz.height) / 2) );
            pt.x -= sz.width;
            [toggleImage drawAtPoint:pt fromRect:NSZeroRect operation:NSCompositingOperationSourceOver fraction:1];
        }

        r.size.width -= (sz.width + RESIZE_WIDTH);
    }

    [super drawInteriorWithFrame:r inView:v];
}

@end
