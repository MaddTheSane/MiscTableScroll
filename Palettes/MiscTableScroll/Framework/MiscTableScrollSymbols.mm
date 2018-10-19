//=============================================================================
//
//	Copyright (C) 1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollSymbols.M
//
//	A work around for a bug in the Objective-C++ compiler for YellowBox
//	and OpenStep for Windows.  By defining MISC_TABLE_SCROLL_EXPORTING,
//	this file tells Windows which variables to export from the DLL by
//	applying the __declspec(dllexport) directive to all symbols declared
//	with MISC_TABLE_SCROLL_EXTERN in the imported header files.  Actual
//	definition of the exported variables is performed elsewhere as
//	appropriate for each symbol.  This file merely provides the Microsoft
//	linker with the names of the symbols to export from the DLL.  See
//	MiscTableTypes.h and Notes/DLL-EXPORT.txt for a full discussion.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollSymbols.M,v 1.1 99/06/15 03:47:06 sunshine Exp $
// $Log:	MiscTableScrollSymbols.M,v $
// Revision 1.1  99/06/15  03:47:06  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// A work-around for an Objective-C++ compiler bug on Windows.  Tells the
// linker which variables should be exported from the framework's DLL.
// 
//-----------------------------------------------------------------------------
#define MISC_TABLE_SCROLL_EXPORTING
#import <MiscTableScroll/MiscTableScroll.h>
