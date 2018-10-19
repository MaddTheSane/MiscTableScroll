#ifndef __MiscRowView_h
#define __MiscRowView_h
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
// MiscRowView.h
//
//	View class for the row labels on an MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRowView.h,v 1.2 96/04/30 05:38:42 sunshine Exp $
// $Log:	MiscRowView.h,v $
// Revision 1.2  96/04/30  05:38:42  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
// 
//-----------------------------------------------------------------------------
#import "MiscBorderView.h"

@interface MiscRowView : MiscBorderView

- initWithFrame: (NSRect) frameRect
     scroll: (MiscTableScroll*) scroll
       info: (MiscTableBorder*) info;

@end

#endif // __MiscRowView_h
