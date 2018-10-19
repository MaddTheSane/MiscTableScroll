#ifndef __MiscColView_h
#define __MiscColView_h
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
// MiscColView.h
//
//	View class for the column headings on an MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscColView.h,v 1.2 96/04/30 05:38:22 sunshine Exp $
// $Log:	MiscColView.h,v $
// Revision 1.2  96/04/30  05:38:22  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
// 
//-----------------------------------------------------------------------------
#import "MiscBorderView.h"

@interface MiscColView : MiscBorderView

- initWithFrame: (NSRect) frameRect
     scroll: (MiscTableScroll*) scroll
       info: (MiscTableBorder*) info;

@end

#endif // __MiscColView_h
