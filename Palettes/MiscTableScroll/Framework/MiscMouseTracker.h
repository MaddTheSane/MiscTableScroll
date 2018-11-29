#ifndef __MiscMouseTracker_h
#define __MiscMouseTracker_h
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
// MiscMouseTracker.h
//
//	Abstract class defining selection behavior based upon mouse tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscMouseTracker.h,v 1.5 97/04/15 09:01:46 sunshine Exp $
// $Log:	MiscMouseTracker.h,v $
// Revision 1.5  97/04/15  09:01:46  sunshine
// v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
// framework organization.  Added implicit (id) type.
// 
//  Revision 1.4  96/12/30  09:12:50  sunshine
//  v107.1: All access to the selection now goes through MiscTableBorder.
//  
//  Revision 1.3  96/05/07  02:12:37  sunshine
//  For OpenStep conformance, keyboard events are now treated the same as
//  mouse events (i.e. one must use the same modifiers with keyboard events
//  as one does with mouse events rather than the behavior being different
//  for keyboard events).  Ditched -keyDown:atPos: method.
//-----------------------------------------------------------------------------
extern "C" {
#import <Foundation/NSObject.h>
}
#import <MiscTableScroll/MiscTableTypes.h>

class MiscTableBorder;
@class NSEvent;

@interface MiscMouseTracker : NSObject
    {
    MiscTableBorder* border;
    }

- (id)initBorder:(MiscTableBorder*)border;
- (void)mouseDown:(NSEvent*)event atPos:(MiscCoord_V)pos;
- (void)mouseDragged:(NSEvent*)event atPos:(MiscCoord_V)pos;
- (void)mouseUp:(NSEvent*)event atPos:(MiscCoord_V)pos;

@end

#endif // __MiscMouseTracker_h
