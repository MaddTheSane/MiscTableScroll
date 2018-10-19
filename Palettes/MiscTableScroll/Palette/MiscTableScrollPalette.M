//=============================================================================
//
//	Copyright (C) 1996,1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollPalette.M
//
//	Subclass of IBPalette for the MiscTableScroll palette.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollPalette.M,v 1.6 98/03/30 00:03:24 sunshine Exp $
// $Log:	MiscTableScrollPalette.M,v $
// Revision 1.6  98/03/30  00:03:24  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// 
// Revision 1.5  98/03/22  13:07:23  sunshine
// v133.1: Turns on auto-sort for rows.
// 
// Revision 1.4  97/03/10  10:41:54  sunshine
// v113.1: For OpenStep conformance, -setCol:... renamed to -setColumn:...
//-----------------------------------------------------------------------------
#import "MiscTableScrollPalette.h"
#import	<MiscTableScroll/MiscTableScroll.h>

@implementation MiscTableScrollPalette

//-----------------------------------------------------------------------------
// - finishInstantiate
//-----------------------------------------------------------------------------
- (void)finishInstantiate 
    {
    [tableScroll addColumn];
    [tableScroll addColumn];
    [tableScroll setColumn:1 autosize:YES];
    [tableScroll setAutoSortRows:YES];
    [tableScroll tile]; 
    }

@end
