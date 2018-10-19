//=============================================================================
//
//	Copyright (C) 1995, 1996 by Paul S. McCarthy and Eric Sunshine.
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
// MiscColView.M
//
//	View class for the column headings on an MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscColView.M,v 1.2 96/04/30 05:38:21 sunshine Exp $
// $Log:	MiscColView.M,v $
// Revision 1.2  96/04/30  05:38:21  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
// 
//-----------------------------------------------------------------------------
#import "MiscColView.h"

@implementation MiscColView

//-----------------------------------------------------------------------------
// - initWithFrame:scroll:info:
//-----------------------------------------------------------------------------
- initWithFrame: (NSRect) frameRect
     scroll: (MiscTableScroll*) i_scroll
       info: (MiscTableBorder*) i_info
{
    [super initWithFrame:frameRect scroll:i_scroll info:i_info
                    type:MISC_COL_BORDER_VIEW];
    return self;
}

@end
