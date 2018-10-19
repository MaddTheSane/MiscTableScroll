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
// MiscRadioTracker.M
//
//	Radio-mode selection tracking.
//
//	NOTE *1*
//		We emulate Matrix behavior here.  In radio mode if the mouse 
//		goes up and the shift-key is held down then the cell is 
//		deselected.  Since keyboard events are treated like mouse 
//		events we do the same for keyUp events -- however since we 
//		don't actually receive keyUp events, we also perform special 
//		checking for the shift-key modifier in -mouseDown: when the 
//		event is a keyboard event.  
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRadioTracker.M,v 1.5 96/12/30 09:13:09 sunshine Exp $
// $Log:	MiscRadioTracker.M,v $
// Revision 1.5  96/12/30  09:13:09  sunshine
// v107.1: All access to the selection now goes through MiscTableBorder.
// 
//  Revision 1.4  96/12/30  03:12:01  sunshine
//  v104.1: Selected-slot was removed from SparseSet and promoted to
//  TableBorder.
//  
//  Revision 1.3  96/05/07  02:12:34  sunshine
//  For OpenStep conformance, keyboard events are now treated the same as
//  mouse events (i.e. one must use the same modifiers with keyboard events
//  as one does with mouse events rather than the behavior being different
//  for keyboard events).  Ditched -keyDown:atPos: method.
//-----------------------------------------------------------------------------
#import "MiscRadioTracker.h"
#import "MiscSparseSet.h"
#import "MiscTableBorder.h"


@implementation MiscRadioTracker

//-----------------------------------------------------------------------------
// mouseDown:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDown:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    if ([event type] == NSKeyDown &&				// NOTE *1*
		([event modifierFlags] & NSShiftKeyMask) != 0 &&
		border->hasSelection() && pos == border->selectedSlot())
	border->selectNone();
    else
	border->selectOne( pos );
    }


//-----------------------------------------------------------------------------
// mouseDragged:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDragged:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    if (border->goodPos(pos))
	border->selectOne( pos );
    else
	border->selectNone();
    }


//-----------------------------------------------------------------------------
// mouseUp:atPos:
//-----------------------------------------------------------------------------
- (void) mouseUp:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    if (([event modifierFlags] & NSShiftKeyMask) != 0 &&	// NOTE *1*
	border->goodPos(pos) && border->isSelected(pos))
	border->selectNone();
    }

@end
