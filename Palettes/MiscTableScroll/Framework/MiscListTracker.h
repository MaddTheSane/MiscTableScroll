#ifndef __MiscListTracker_h
#define __MiscListTracker_h
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
// MiscListTracker.h
//
//	List-mode selection tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscListTracker.h,v 1.3 96/05/07 02:13:09 sunshine Exp $
// $Log:	MiscListTracker.h,v $
// Revision 1.3  96/05/07  02:13:09  sunshine
// Fixed bug: Was unable to shift-drag to deselect range of slots.
// For OpenStep conformance, keyboard events are now treated the same as
// mouse events (i.e. one must use the same modifiers with keyboard events
// as one does with mouse events rather than the behavior being different
// for keyboard events).  Ditched -keyDown:atPos: method.
// 
//  Revision 1.2  96/04/30  05:38:31  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#import "MiscMouseTracker.h"

@interface MiscListTracker : MiscMouseTracker
{
    MiscCoord_V anchor;
    BOOL deselecting;
}

- (void) mouseDown:(NSEvent*) event atPos: (MiscCoord_V) pos;
- (void) mouseDragged:(NSEvent*) event atPos: (MiscCoord_V) pos;
- (void) mouseUp:(NSEvent*) event atPos: (MiscCoord_V) pos;

@end

#endif // __MiscListTracker_h
