#ifndef __MiscTableConnector_h
#define __MiscTableConnector_h
//=============================================================================
//
//	Copyright (C) 1996-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableConnector.h
//
//	A custom sublcass of the Interface Builder NSNibControlConnector
//	that works for doubleTarget & doubleAction.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableConnector.h,v 1.5 99/06/15 02:45:59 sunshine Exp $
// $Log:	MiscTableConnector.h,v $
// Revision 1.5  99/06/15  02:45:59  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Imported header name changed: NSIBConnector.h --> NSNibConnector.h.
// Parent class name changed: NSIBControlConnector --> NSNibControlConnector.
// 
// Revision 1.4  1997/06/18 10:21:46  sunshine
// v125.9: Worked around Objective-C++ compiler crash in OPENSTEP 4.2 for NT
// when sending message to 'super' from within a category in a permanent
// fashion.
//-----------------------------------------------------------------------------
#import	"NSNibConnector.h"

@interface MiscTableConnector : NSNibControlConnector
    {
    NSString* outletName;	// Name of the "target" outlet.
    NSString* actionName;	// Name of the "action" variable.
    }

- (id)initWithCoder:(NSCoder*)coder;
- (void)dealloc;
- (void)establishConnection;

// See implementation for explanation of the following methods.
- (id)superInitSource:(id)src destination:(id)dest label:(NSString*)label;
- (void)superEncodeWithCoder:(NSCoder*)coder;

@end

#endif // __MiscTableConnector_h
