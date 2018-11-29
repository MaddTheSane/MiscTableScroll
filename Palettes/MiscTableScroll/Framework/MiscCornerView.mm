//=============================================================================
//
//	Copyright (C) 1995-1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscCornerView.M
//
//	View class that covers the gap in the upper left corner when a 
//	MiscTableScroll has both row and column titles turned on.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscCornerView.M,v 1.4 98/03/22 13:30:10 sunshine Exp $
// $Log:	MiscCornerView.M,v $
// Revision 1.4  98/03/22  13:30:10  sunshine
// v133.1: MiscNullView --> MiscCornerView.  Added -title, -setTitle:.
// 
//  Revision 1.3  96/04/30  05:38:37  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#import "MiscCornerView.h"
#import "MiscBorderCell.h"

extern "C" {
#import <AppKit/NSGraphics.h>
}

@implementation MiscCornerView

- (BOOL)isFlipped { return YES; }
- (BOOL)isOpaque { return YES; }
- (NSString*)title { return [theCell stringValue]; }
- (void)setTitle:(NSString*)s { [theCell setStringValue:s]; }

//-----------------------------------------------------------------------------
// - initWithFrame:
//-----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frameRect
    {
    [super initWithFrame:frameRect];
    theCell = [[MiscBorderCell allocWithZone:[self zone]] initTextCell:@""];
    return self;
    }


//-----------------------------------------------------------------------------
// - dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    [theCell release];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// - drawRect:
//-----------------------------------------------------------------------------
- (void)drawRect:(NSRect)rect
    {
    [theCell drawWithFrame:[self bounds] inView:self];
    }

@end
