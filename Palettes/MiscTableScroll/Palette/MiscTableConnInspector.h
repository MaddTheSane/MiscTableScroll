#ifndef __MiscTableConnInspector_h
#define __MiscTableConnInspector_h
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
// MiscTableConnInspector.h
//
//	A custom Interface Builder connection inspector so that the
//	doubleTarget and doubleAction can be set.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableConnInspector.h,v 1.3 99/06/14 19:25:13 sunshine Exp $
// $Log:	MiscTableConnInspector.h,v $
// Revision 1.3  99/06/14  19:25:13  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Nib connector classes changed name in MacOS/X Server from NSIBConnector,
// to NSIBOutletConnector, and NSIBControlConnector to NSNibConnector,
// NSNibOutletConnector, and NSNibControlConnector, respectively.
// The "Name" column on the outlet and action MiscTableScrolls now autosizes
// since the old hardcoded size is inappropriate for MacOS/X Server DR.
// Worked around problem introduced in MacOS/X Server and YellowBox DR2.
// Symptom was that method in action list for action and doubleAction was
// not being selected when inspected for nibs which had been loaded from a
// file.  Problem was that -[IBClassData actionsOfClass:] no longer appends
// a colon ":" to returned action names, as it did previously.  We were doing
// a simple string comparison to locate the name in the action list which
// consequently failed.  Now canonicalizes names before comparison.
// Now uses NSStringFromClass() in place of +[NSObject description].
// Added extra explanatory comments.
// 
// Revision 1.2  1996/04/30 05:38:51  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
extern "Objective-C" {
#import <InterfaceBuilder/InterfaceBuilder.h>
}

@class MiscTableScroll, NSArray, NSCharacterSet;

@interface MiscTableConnInspector:IBInspector
    {
    MiscTableScroll*	outletScroll;
    MiscTableScroll*	actionScroll;
    NSArray*		connList;
    id			cursrc;
    id			curdst;
    id			curout;
    NSCharacterSet*	punctuation;
    }

@end

#endif // __MiscTableConnInspector_h
