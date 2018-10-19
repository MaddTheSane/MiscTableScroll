#ifndef __DirController_h
#define __DirController_h
//=============================================================================
//
//	Copyright (C) 1995-1999 by Paul S. McCarthy and Eric Sunshine.
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
// DirController.h
//
//	Manages application which demonstrates use of TableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirController.h,v 1.2 99/06/14 17:35:40 sunshine Exp $
// $Log:	DirController.h,v $
// Revision 1.2  99/06/14  17:35:40  sunshine
// v19.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// For clarity renamed -new: to -openDirectory:.
// 
// Revision 1.1  1997/03/23 01:59:08  sunshine
// v13.1: Application controller.
//-----------------------------------------------------------------------------
#import <Foundation/NSObject.h>
@class NSNotification, NSPanel, NSText;

@interface DirController : NSObject
    {
    NSPanel* infoPanel;
    NSText*  infoText;
    }

- (id)init;
- (void)dealloc;
- (void)applicationDidFinishLaunching:(NSNotification*)n;
- (void)applicationWillTerminate:(NSNotification*)n;
- (void)openDirectory:(id)sender;
- (void)info:(id)sender;

@end

#endif // __DirController_h
