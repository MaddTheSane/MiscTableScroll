#ifndef __MiscRadioTracker_h
#define __MiscRadioTracker_h
//=============================================================================
//
//	Copyright (C) 1995, 1996 by Paul S. McCarthy and Eric Sunshine.
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
// MiscRadioTracker.h
//
//	Radio-mode selection tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRadioTracker.h,v 1.3 96/05/07 02:12:26 sunshine Exp $
// $Log:	MiscRadioTracker.h,v $
// Revision 1.3  96/05/07  02:12:26  sunshine
// For OpenStep conformance, keyboard events are now treated the same as
// mouse events (i.e. one must use the same modifiers with keyboard events
// as one does with mouse events rather than the behavior being different
// for keyboard events).  Ditched -keyDown:atPos: method.
// 
//  Revision 1.2  96/04/30  05:38:40  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#import "MiscMouseTracker.h"

@interface MiscRadioTracker : MiscMouseTracker
    {
    }

- (void) mouseDown:(NSEvent*) event atPos: (MiscCoord_V) pos;
- (void) mouseDragged:(NSEvent*) event atPos: (MiscCoord_V) pos;
- (void) mouseUp:(NSEvent*) event atPos: (MiscCoord_V) pos;

@end

#endif // __MiscRadioTracker_h
