#ifndef __MiscTableScroll_new_h
#define __MiscTableScroll_new_h
//=============================================================================
//
//	Copyright (C) 1997 by Paul S. McCarthy and Eric Sunshine.
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
// new.h
//
//	A local version of <new.h> which defines a default "placement new"
//	operator.  This file is required since <new.h> is entirely missing
//	in OPENSTEP 4.2 for Mach, and the one redistributed from Microsoft
//	in OPENSTEP 4.2 for NT is buggy (and crashes the compilation).
//
//	This file is compatible with OPENSTEP 4.1, and therefore does not
//	compromise its continued support.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: new.h,v 1.1 97/06/18 09:54:27 sunshine Exp $
// $Log:	new.h,v $
// Revision 1.1  97/06/18  09:54:27  sunshine
// v125.9: Patch for broken <new.h> in OPENSTEP 4.2 for Mach and NT.
// 
//-----------------------------------------------------------------------------

inline void* operator new( size_t, void* ptr ) { return ptr; }

#endif // __MiscTableScroll_new_h
