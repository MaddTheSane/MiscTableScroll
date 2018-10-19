#ifndef __SD_PageLayout_h
#define __SD_PageLayout_h
//=============================================================================
//
//	Copyright (C) 1996,1997,1999 by Paul S. McCarthy and Eric Sunshine.
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
// SD_PageLayout.h
//
//	Custom subclass of AppKit's NSPageLayout panel that adds user controls
//	for margins, pagination, & centering.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: SD_PageLayout.h,v 1.2 99/06/14 17:20:04 sunshine Exp $
// $Log:	SD_PageLayout.h,v $
// Revision 1.2  99/06/14  17:20:04  sunshine
// v19.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Removed unused +launch:.  Fixed up comments.  No longer makes an
// effort to supply missing NSPageLayout methods on Windows.  Now the entire
// implementation of the class is conditionally compiled as appropriate,
// instead of piecemeal.
// 
//-----------------------------------------------------------------------------
#import	<AppKit/NSPageLayout.h>
@class NSMatrix, NSTextField;

#if defined(WIN32)
#undef  SD_USE_PAGE_LAYOUT
#else
#define SD_USE_PAGE_LAYOUT
#endif

@interface SD_PageLayout : NSPageLayout
    {
#if defined(SD_USE_PAGE_LAYOUT)
    NSWindow*		accessoryWindow;
    NSTextField*	leftMarginField;
    NSTextField*	topMarginField;
    NSTextField*	rightMarginField;
    NSTextField*	bottomMarginField;
    NSMatrix*		centerMatrix;
    NSMatrix*		paginationMatrix;
#endif
    }
@end

#endif // __SD_PageLayout_h
