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
// $Id: DirWindow.h,v 1.3 97/11/22 23:33:31 sunshine Exp $
// $Log:	DirWindow.h,v $
// Revision 1.3  97/11/22  23:33:31  sunshine
// v32.1: Added row-numbers switch.
// 
// Revision 1.2  97/03/22  22:47:32  sunshine
// v29.1: Added 'writable' flag to prevent cmd-r from working in read-only
// directories.
// 
// Revision 1.1  97/03/21  18:30:59  sunshine
// v28: Directory window.
//-----------------------------------------------------------------------------
#import <Foundation/NSObject.h>
@class MiscTableScroll, NSButton, NSTextField, NSWindow;

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
    BOOL		writable;
    BOOL		autoSort;
    BOOL		dragUnscaled;
    BOOL		highlightDirs;
    BOOL		showHidden;
    }

+ (void)launchDir:(NSString*)dirname;

@end

#endif // __DirWindow_h
