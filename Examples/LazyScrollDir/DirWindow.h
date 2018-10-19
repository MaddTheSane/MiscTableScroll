#ifndef __DirWindow_h
#define __DirWindow_h
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
// DirWindow.h
//
//	Manages window which displays directory listing.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirWindow.h,v 1.3 97/11/24 19:50:45 sunshine Exp $
// $Log:	DirWindow.h,v $
// Revision 1.3  97/11/24  19:50:45  sunshine
// v17.1: Fixed bug: Menu was sending -print: to first-responder even though
// any control can be first-responder, rather than just MiscTableScroll.
// Added row-numbers switch.  Adjusted initial cascade position for NT.
// 
// Revision 1.2  97/04/25  20:02:50  sunshine
// v14.2: Now uses NSArray for lazyRow.
// 
// Revision 1.1  97/03/23  01:59:18  sunshine
// v13.1: Browser window.
//-----------------------------------------------------------------------------
#import <Foundation/NSObject.h>
@class DirArray, MiscTableScroll, NSArray, NSButton, NSTextField, NSWindow;

@interface DirWindow : NSObject
    {
    MiscTableScroll*	scroll;
    NSWindow*		window;
    NSButton*		autoSortSwitch;
    NSButton*		cdButton;
    NSButton*		dragUnscaledSwitch;
    NSButton*		hiddenFilesSwitch;
    NSButton*		highlightSwitch;
    NSButton*		refreshButton;
    NSButton*		rowNumbersSwitch;
    NSTextField*	countField;
    NSString*		path;
    BOOL		autoSort;
    BOOL		dragUnscaled;
    BOOL		highlightDirs;
    BOOL		showHidden;
    DirArray*		dirArray;
    NSArray*		lazyRow;
    }

+ (void)launchDir:(NSString*)dirname;

@end

#endif // __DirWindow_h
