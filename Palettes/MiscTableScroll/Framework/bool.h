#ifndef __bool_h
#define __bool_h
//=============================================================================
//
//	Copyright (C) 1995-1997 by Paul S. McCarthy and Eric Sunshine.
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
// bool.h
//
//	A header to supplement NeXT's lack of bool type in their C++ compiler.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: bool.h,v 1.2 97/04/01 08:07:37 sunshine Exp $
// $Log:	bool.h,v $
// Revision 1.2  97/04/01  08:07:37  sunshine
// v0.125.5: Ported to OPENSTEP 4.2 prerelease for NT.
// 'bool' is now a built-in type.
// 
//  Revision 1.1  95/09/27  12:21:21  zarnuk
//  Initial revision
//-----------------------------------------------------------------------------

#if defined(__NeXT__) && (__GNUC__ < 2 || __GNUC_MINOR__ < 7)

typedef char bool;
#define false	((bool)0)
#define true	((bool)1)

#endif

#endif	// __bool_h
