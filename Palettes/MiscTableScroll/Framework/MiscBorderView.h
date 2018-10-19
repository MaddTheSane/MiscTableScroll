#ifndef __MiscBorderView_h
#define __MiscBorderView_h
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
// MiscBorderView.h
//
//	View class for the row/column borders on a MiscTableView.
//	Supports resizing, dragging.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscBorderView.h,v 1.10 97/04/15 08:53:49 sunshine Exp $
// $Log:	MiscBorderView.h,v $
// Revision 1.10  97/04/15  08:53:49  sunshine
// v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
// framework organization.  Consequently, removed the -inlineImageNamed: hack.
// 
//  Revision 1.9  97/03/20  19:12:32  sunshine
//  v123.1: Changed order of methods for NEXTSTEP 3.3 TableScroll consistency.
//  
//  Revision 1.8  97/03/10  10:11:39  sunshine
//  v113.1: Added -setFrameHeight:.  Added missing (id) to -initWithFrame:.
//-----------------------------------------------------------------------------
extern "Objective-C" {
#import <AppKit/NSView.h>
}
#import <MiscTableScroll/MiscTableTypes.h>
class MiscSparseSet;
class MiscTableBorder;
@class MiscBorderCell, MiscMouseTracker, MiscTableScroll, MiscTableView;

enum MiscBorderViewType { MISC_COL_BORDER_VIEW, MISC_ROW_BORDER_VIEW };

@interface MiscBorderView : NSView
    {
    MiscTableScroll*	scroll;
    MiscTableBorder*	info;
    MiscBorderCell*	theCell;
    MiscMouseTracker*	tracker;
    MiscSparseSet*	oldSel;
    MiscCoord_V		togglePos;
    BOOL		isHorz;
    }

- (id)initWithFrame:(NSRect)frameRect
     scroll:(MiscTableScroll*)scroll
       info:(MiscTableBorder*)info
       type:(MiscBorderViewType)type;
- (void)dealloc;

- (MiscPixels)frameHeight;
- (void)setFrameHeight:(MiscPixels)x;
- (void)adjustSize;
- (void)setSelectionMode:(MiscSelectionMode)mode;
- (void)selectionChanged;
- (void)resetSelection;
- (void)drawSlot:(MiscCoord_V)x;

@end

#endif // __MiscBorderView_h
