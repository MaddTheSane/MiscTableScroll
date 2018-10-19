#ifndef __MiscTableViewPrivate_h
#define __MiscTableViewPrivate_h
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
// MiscTableViewPrivate.h
//
//	Private methods for MiscTableView.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableViewPrivate.h,v 1.1 97/11/23 07:42:07 sunshine Exp $
// $Log:	MiscTableViewPrivate.h,v $
// Revision 1.1  97/11/23  07:42:07  sunshine
// v130.1: Private table view methods.
// 
//-----------------------------------------------------------------------------
#import "MiscTableView.h"

@interface MiscTableView(Private)
- (MiscTableBorder*)borderFor:(MiscBorderType)b;
- (NSRect)getSlotInsideAt:(MiscCoord_P)slot from:(MiscBorderType)bdr;
- (void)border:(MiscBorderType)bdr scrollToVisible:(MiscCoord_P)pslot;


// CURSOR ---------------------------------------------------------------------
- (void)drawCursorClipTo:(NSRect)clip;


// DRAGGING -------------------------------------------------------------------
- (BOOL)canPerformDragAtRow:(MiscCoord_P)r column:(MiscCoord_P)c
    withEvent:(NSEvent*)p;
- (BOOL)awaitDragEvent:(NSEvent*)mouseDown
    atRow:(MiscCoord_P)row column:(MiscCoord_P)col inRect:(NSRect)rect;
@end

#endif // __MiscTableViewPrivate_h
