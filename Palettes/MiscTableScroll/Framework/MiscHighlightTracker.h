#ifndef __MiscHighlightTracker_h
#define __MiscHighlightTracker_h
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
// MiscHighlightTracker.h
//
//	Highlight-mode selection tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscHighlightTracker.h,v 1.3 96/05/07 02:12:47 sunshine Exp $
// $Log:	MiscHighlightTracker.h,v $
// Revision 1.3  96/05/07  02:12:47  sunshine
// For OpenStep conformance, keyboard events are now treated the same as
// mouse events (i.e. one must use the same modifiers with keyboard events
// as one does with mouse events rather than the behavior being different
// for keyboard events).  Ditched -keyDown:atPos: method.
// 
//  Revision 1.2  96/04/30  05:38:27  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#import "MiscListTracker.h"

@interface MiscHighlightTracker : MiscListTracker
{
    BOOL extending;
    MiscCoord_V lastPos;
}

- (void) mouseDown:(NSEvent*) event atPos: (MiscCoord_V) pos;
- (void) mouseDragged:(NSEvent*) event atPos: (MiscCoord_V) pos;
- (void) mouseUp:(NSEvent*) event atPos: (MiscCoord_V) pos;

@end

#endif // __MiscHighlightTracker_h
