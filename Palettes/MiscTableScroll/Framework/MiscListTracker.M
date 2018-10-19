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
// MiscListTracker.M
//
//	List-mode selection tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscListTracker.M,v 1.5 96/12/30 09:12:37 sunshine Exp $
// $Log:	MiscListTracker.M,v $
// Revision 1.5  96/12/30  09:12:37  sunshine
// v107.1: All access to the selection now goes through MiscTableBorder.
// 
//  Revision 1.4  96/12/30  03:11:54  sunshine
//  v104.1: Selected-slot was removed from SparseSet and promoted to
//  TableBorder.
//  
//  Revision 1.3  96/05/07  02:13:05  sunshine
//  Fixed bug: Was unable to shift-drag to deselect range of slots.
//  For OpenStep conformance, keyboard events are now treated the same as
//  mouse events (i.e. one must use the same modifiers with keyboard events
//  as one does with mouse events rather than the behavior being different
//  for keyboard events).  Ditched -keyDown:atPos: method.
//-----------------------------------------------------------------------------
#import "MiscListTracker.h"
#import "MiscSparseSet.h"
#import "MiscTableBorder.h"


@implementation MiscListTracker

//-----------------------------------------------------------------------------
// mouseDown:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDown:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    deselecting = NO;
    if ([event modifierFlags] & NSShiftKeyMask)
	{
	deselecting = border->isSelected( pos );
	border->toggle( pos );
	anchor = pos;
	}
    else if ([event modifierFlags] & NSAlternateKeyMask)
	{
	int selected_slot = border->selectedSlot();
	if (!border->goodPos( selected_slot ))
	    selected_slot = pos;
	border->select( selected_slot, pos );
	anchor = selected_slot;
	border->setSelectedSlot( pos );
	}
    else
	{
	border->selectOne( pos );
	anchor = pos;
	}
    }


//-----------------------------------------------------------------------------
// mouseDragged:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDragged:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    if (pos < 0) pos = 0;
    if (pos >= border->count()) pos = border->count() - 1;

    if (deselecting)
	border->unselect( anchor, pos );
    else
	{
	int selected_slot = border->selectedSlot();
	if (pos != selected_slot)
	    {
	    border->unselect( anchor, selected_slot );
	    border->select( anchor, pos );
	    }
	}
    border->setSelectedSlot( pos );
    }


//-----------------------------------------------------------------------------
// mouseUp:atPos:
//-----------------------------------------------------------------------------
- (void) mouseUp:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    }

@end
