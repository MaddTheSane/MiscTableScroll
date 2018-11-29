#ifndef __MiscTableUtil_h
#define __MiscTableUtil_h
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
// MiscTableUtil.h
//
//	Common inline functions used by the MiscTableScroll object.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableUtil.h,v 1.4 98/03/29 23:57:54 sunshine Exp $
// $Log:	MiscTableUtil.h,v $
// Revision 1.4  98/03/29  23:57:54  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// 
//  Revision 1.3  98/03/22  13:13:55  sunshine
//  v133.1: Eliminated data-sizing.
//  
//  Revision 1.2  97/11/23  07:39:45  sunshine
//  v130.1: Added MISC_ENUM_CHECK.
//-----------------------------------------------------------------------------
#include <MiscTableScroll/MiscTableTypes.h>
#include "bool.h"
extern "C" {
#import <Foundation/NSException.h>
}

inline MiscBorderType otherBorder( MiscBorderType t )
    { return (t == MISC_COL_BORDER) ? MISC_ROW_BORDER : MISC_COL_BORDER; }

inline bool isFixed( MiscTableSizing x )
	{ return x == MISC_NUSER_NSPRINGY_SIZING; }

inline bool isSpringy( MiscTableSizing x )
	{ return (((int)x) & MISC_SIZING_SPRINGY_BIT) != 0; }

inline bool isSizeable( MiscTableSizing x )
	{ return (((int)x) & MISC_SIZING_USER_BIT) != 0; }

inline MiscTableSizing setAttribute( MiscTableSizing x, int bit, bool b )
	{ return (MiscTableSizing) (b ? ((int)x | bit) : ((int)x & ~bit)); }

inline MiscTableSizing setSpringy( MiscTableSizing x, bool b )
	{ return setAttribute( x, MISC_SIZING_SPRINGY_BIT, b ); }

inline MiscTableSizing setSizeable( MiscTableSizing x, bool b )
	{ return setAttribute( x, MISC_SIZING_USER_BIT, b ); }

#define	MISC_ENUM_CHECK(E,N)\
	NSCParameterAssert((unsigned int)(E) <= (unsigned int)(N))

#endif	// __MiscTableUtil_h
