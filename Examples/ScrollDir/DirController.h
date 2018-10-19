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
// $Id: DirController.h,v 1.2 99/06/14 16:06:56 sunshine Exp $
// $Log:	DirController.h,v $
// Revision 1.2  99/06/14  16:06:56  sunshine
// v35.1: For clarity renamed -new: to -openDirectory:.
// 
// Revision 1.1  1997/03/21 18:30:43  sunshine
// v28: Directory controller.
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
