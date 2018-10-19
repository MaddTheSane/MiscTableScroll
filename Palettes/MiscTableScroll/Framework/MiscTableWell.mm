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
// MiscTableWell.M
//
//	View class that draws a well where a column/row laid before dragging
//	was started.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableWell.M,v 1.3 98/03/30 00:02:00 sunshine Exp $
// $Log:	MiscTableWell.M,v $
// Revision 1.3  98/03/30  00:02:00  sunshine
// v138.1: Now uses NSColor's "system" color for well rather than "gray".
// 
//  Revision 1.2  96/04/30  05:40:08  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#import "MiscTableWell.h"

@implementation MiscTableWell

- (BOOL)isOpaque { return YES; }

//-----------------------------------------------------------------------------
// - initWithFrame:
//-----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)r
{
    [super initWithFrame:r];
    return self;
}


//-----------------------------------------------------------------------------
// - drawRect:
//-----------------------------------------------------------------------------
- (void)drawRect:(NSRect)r
{
    [[NSColor scrollBarColor] set];
    NSRectFill(r);
}

@end
