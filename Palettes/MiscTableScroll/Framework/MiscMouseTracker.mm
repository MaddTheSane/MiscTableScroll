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
// MiscMouseTracker.M
//
//	Abstract class defining selection behavior based upon mouse tracking.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscMouseTracker.M,v 1.4 96/12/30 09:12:52 sunshine Exp $
// $Log:	MiscMouseTracker.M,v $
// Revision 1.4  96/12/30  09:12:52  sunshine
// v107.1: All access to the selection now goes through MiscTableBorder.
// 
//  Revision 1.3  96/05/07  02:12:42  sunshine
//  For OpenStep conformance, keyboard events are now treated the same as
//  mouse events (i.e. one must use the same modifiers with keyboard events
//  as one does with mouse events rather than the behavior being different
//  for keyboard events).  Ditched -keyDown:atPos: method.
//  
//  Revision 1.2  96/04/30  05:38:33  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#import "MiscMouseTracker.h"
#import "MiscSparseSet.h"
#import "MiscTableBorder.h"


@implementation MiscMouseTracker

//-----------------------------------------------------------------------------
// initBorder:
//-----------------------------------------------------------------------------
- (id) initBorder:(MiscTableBorder*)b
    {
    [super init];
    border = b;
    border->selectNone();
    return self;
    }


//-----------------------------------------------------------------------------
// subclassResponsibility:
//-----------------------------------------------------------------------------
- (void) subclassResponsibility:(SEL)s
    {
    [NSException raise:NSInvalidArgumentException
		format:@"*** Subclass responsibility: %s", sel_getName(s)];
    }


//-----------------------------------------------------------------------------
// mouseDown:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDown:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    [self subclassResponsibility:_cmd];
    }


//-----------------------------------------------------------------------------
// mouseDragged:atPos:
//-----------------------------------------------------------------------------
- (void) mouseDragged:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    [self subclassResponsibility:_cmd];
    }


//-----------------------------------------------------------------------------
// mouseUp:atPos:
//-----------------------------------------------------------------------------
- (void) mouseUp:(NSEvent*) event atPos:(MiscCoord_V)pos
    {
    [self subclassResponsibility:_cmd];
    }

@end
