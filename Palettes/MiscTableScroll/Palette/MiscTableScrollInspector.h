#ifndef __MiscTableScrollInspector_h
#define __MiscTableScrollInspector_h
//=============================================================================
//
//  Copyright (C) 1995-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollInspector.h
//
//	Interface Builder inspector for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollInspector.h,v 1.9 99/06/14 19:15:31 sunshine Exp $
// $Log:	MiscTableScrollInspector.h,v $
// Revision 1.9  99/06/14  19:15:31  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Converted slot list from a matrix of buttons to MiscTableScroll.
// Reworked color controls so that user can preview color combinations.  This
// is accomplished by the addition of two text fields.  One displays the
// foreground and background color for unselected slots; the other selected
// slots.  This configuration makes better use of screen real estate.
// 
// Revision 1.8  1998/03/30 00:06:13  sunshine
// v138.1: Ditched unnecessary "align title" text field since under OPENSTEP,
// buttons are correctly dimmed when disabled.  Consequently I don't have to
// worry about figuring out correct enabled/disabled colors for the field.
//
//  Revision 1.7  98/03/22  13:07:57  sunshine
//  v133.1: Eliminated constrain-max, constrain-min is now implicit based on
//  presence/absence of auto-size slots.  Eliminated data-sizing.
//  Added alignment control.
//-----------------------------------------------------------------------------
extern "C" {
#import <InterfaceBuilder/InterfaceBuilder.h>
}
#import <MiscTableScroll/MiscTableTypes.h>

@class NSButton, NSColorWell, NSMatrix, NSScrollView, NSTextField;
@class MiscTableScroll;
class MiscTableBorder;

@interface MiscTableScrollInspector : IBInspector
    {
    NSButton*		autosizeSwitch;
    NSButton*		autoSortSwitch;
    NSPopUpButton*	borderPopUp;
    NSPopUpButton*	cellClassPopUp;
    NSButton*		deleteButton;
    NSButton*		downButton;
    NSButton*		draggableSwitch;
    NSButton*		enabledSwitch;
    NSButton*		lazySwitch;
    NSPopUpButton*	modePopUp;
    NSButton*		sizableSwitch;
    NSPopUpButton*	sortTypePopUp;
    NSPopUpButton*	sortDirectionPopUp;
    NSPopUpButton*	titleModePopUp;
    NSButton*		titlesSwitch;
    NSButton*		upButton;
    NSButton*		userSizeableSwitch;
    NSMatrix*		alignMatrix;
    MiscTableScroll*	slotScroll;
    NSTextField*	sizeField;
    NSTextField*	sizeMaxField;
    NSTextField*	sizeMinField;
    NSTextField*	titleField;
    NSTextField*	uniformSizeField;
    NSColorWell*	colorText;
    NSColorWell*	colorTextSelected;
    NSColorWell*	colorBack;
    NSColorWell*	colorBackSelected;
    NSTextField*	sampleTextNormal;
    NSTextField*	sampleTextSelected;
    int			slot;		// Currently selected slot, or -1.
    int			numSlots;	// Total number of columns.
    MiscBorderType	borderType;
    MiscTableBorder*	border;
    BOOL		dirty;
    }

- (id)init;
- (void)ok:(id)sender;
- (void)revert:(id)sender;

@end

#endif	// __MiscTableScrollInspector_h
