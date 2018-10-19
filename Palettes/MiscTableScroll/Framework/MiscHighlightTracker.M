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
// MiscHighlightTracker.M
//
//	Highlight-mode selection tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscHighlightTracker.M,v 1.5 96/12/30 09:12:19 sunshine Exp $
// $Log:	MiscHighlightTracker.M,v $
// Revision 1.5  96/12/30  09:12:19  sunshine
// v107.1: All access to the selection now goes through MiscTableBorder.
// 
//  Revision 1.4  96/12/30  03:11:11  sunshine
//  v104.1: Selected-slot was removed from SparseSet and promoted to
//  TableBorder.
//  
//  Revision 1.3  96/05/07  02:12:49  sunshine
//  For OpenStep conformance, keyboard events are now treated the same as
//  mouse events (i.e. one must use the same modifiers with keyboard events
//  as one does with mouse events rather than the behavior being different
//  for keyboard events).  Ditched -keyDown:atPos: method.
//-----------------------------------------------------------------------------
#import "MiscHighlightTracker.h"
#import "MiscSparseSet.h"
#import "MiscTableBorder.h"


@implementation MiscHighlightTracker

//-----------------------------------------------------------------------------
// mouseDown:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDown:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    extending = (([event modifierFlags] & NSAlternateKeyMask) != 0);
    if (extending)
	{
	[super mouseDown: event atPos: pos];
	}
    else
	{
	border->toggle( pos );
	lastPos = pos;
	}
    }


//-----------------------------------------------------------------------------
// mouseDragged:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDragged:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    if (extending)
	{
	[super mouseDragged: event atPos: pos];
	}
    else
	{
	if (border->goodPos( lastPos ))
	    border->toggle( lastPos );
	if (border->goodPos( pos ))
	    border->toggle( pos );
	lastPos = pos;
	}
    }


//-----------------------------------------------------------------------------
// mouseUp:atPos:
//-----------------------------------------------------------------------------
- (void) mouseUp:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    if (extending)
	[super mouseUp: event atPos: pos];
    }

@end
