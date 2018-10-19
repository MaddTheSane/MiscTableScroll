#ifndef __MiscDelegateFlags_h
#define __MiscDelegateFlags_h
#ifdef __GNUC__
#pragma interface
#endif
//=============================================================================
//
//	Copyright (C) 1995-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscDelegateFlags.h
//
//	Flags indicating which selectors a delegate responds to.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscDelegateFlags.h,v 1.11 99/06/15 02:33:25 sunshine Exp $
// $Log:	MiscDelegateFlags.h,v $
// Revision 1.11  99/06/15  02:33:25  sunshine
// v140.1: Many delegate messages changed to notification style messages.
// Added delegate messages for becoming and resigning first responder.
// Renamed: DEL_WILL_EDIT_AT to DEL_WILL_EDIT, DEL_DID_EDIT_AT to DEL_DID_EDIT
// For better OpenStep conformance, renamed: -tableScroll:getISearchColumn: to
// -tableScrollGetIncrementalSearchColumn:.
// 
// Revision 1.10  1998/03/29 23:42:18  sunshine
// v138.1: Added -tableScroll:shouldDelayWindowOrderingForEvent:.
//
// Revision 1.9  98/03/23  07:46:41  sunshine
// v134.1: Eliminated -tableScroll:edit:atRow:column:.
//-----------------------------------------------------------------------------
#include <stdbool.h>
#import <Foundation/NSObject.h>

class MiscDelegateFlags
{
public:
    enum Selector
	{
	DEL_SLOT_DRAGGED,		// tableScrollSlotDragged:
	DEL_SLOT_REVERSED,		// tableScrollSlotSortReversed:
	DEL_SLOT_RESIZED,		// tableScrollSlotResized:
	DEL_CHANGE_FONT,		// tableScrollChangeFont:
	DEL_FONT_CHANGED,		// tableScrollFontChanged:
	DEL_BACK_COLOR_CHANGED,		// tableScrollBackgroundColorChanged:
	DEL_BACK_SEL_COLOR_CHANGED,	// tableScrollSelectedBackgroundColo...
	DEL_TEXT_COLOR_CHANGED,		// tableScrollTextColorChanged:
	DEL_TEXT_SEL_COLOR_CHANGED,	// tableScrollSelectedTextColorChang...
	DEL_GET_ISEARCH_COL,		// tableScroll:getISearchColumn:
	DEL_BUFFER_COUNT,		// tableScrollBufferCount:
	DEL_SLOT_PROTOTYPE,		// tableScroll:border:slotPrototype:
	DEL_SLOT_TITLE,			// tableScroll:border:slotTitle:
	DEL_CELL_AT,			// tableScroll:cellAtRow:column:
	DEL_REVIVE_CELL,		// tableScroll:reviveCell:atRow:column:
	DEL_RETIRE_CELL,		// tableScroll:retireCell:atRow:column:
	DEL_TAG_AT,			// tableScroll:tagAtRow:column:
	DEL_INT_VALUE_AT,		// tableScroll:intValueAtRow:column:
	DEL_FLOAT_VALUE_AT,		// tableScroll:floatValueAtRow:column:
	DEL_DOUBLE_VALUE_AT,		// tableScroll:doubleValueAtRow:column:
	DEL_STRING_VALUE_AT,		// tableScroll:stringValueAtRow:column:
	DEL_TITLE_AT,			// tableScroll:titleAtRow:column:
	DEL_STATE_AT,			// tableScroll:stateAtRow:column:
	DEL_REGISTER_SERVICE_TYPES,	// tableScrollRegisterServicesTypes:
	DEL_VALID_REQUESTOR,		// tableScroll:validRequestorForSend...
	DEL_CAN_WRITE_PB_TYPE,		// tableScroll:canWritePboardType:
	DEL_STRING_FOR_PB_TYPE,		// tableScroll:stringForPboardType:
	DEL_WRITE_SEL_TO_PB_TYPES,	// tableScroll:writeSelectionToPaste...
	DEL_READ_SEL_FROM_PB,		// tableScroll:readSelectionFromPast...
	DEL_ALLOW_DRAG,			// tableScroll:allowDragOperationAtR...
	DEL_PREPARE_PB_FOR_DRAG,	// tableScroll:preparePasteboard:for...
	DEL_IMAGE_FOR_DRAG,		// tableScroll:imageForDragOperation...
	DEL_DRAG_OP_MASK,		// tableScroll:draggingSourceOperati...
	DEL_DRAG_IGNORE_MODIFIERS,	// tableScrollIgnoreModifierKeysWhil...
	DEL_DRAG_DELAY_WIN_ORDERING,	// tableScroll:shouldDelayWindowOrde...
	DEL_WILL_PRINT,			// tableScrollWillPrint:
	DEL_DID_PRINT,			// tableScrollDidPrint:
	DEL_PRINT_PAGE_HEADER,		// tableScrollWillPrintPageHeader:
	DEL_PRINT_PAGE_FOOTER,		// tableScrollWillPrintPageFooter:
	DEL_CAN_EDIT_AT,		// tableScroll:canEdit:atRow:column:
	DEL_SET_STRINGVALUE_AT,		// tableScroll:setStringValue:atRow:...
	DEL_ABORT_EDIT_AT,		// tableScroll:abortEditAtRow:column:
	DEL_WILL_EDIT,			// tableScrollWillEdit:
	DEL_DID_EDIT,			// tableScrollDidEdit:
	DEL_TEXT_DID_END,		// controlTextDidEndEditing:
	DEL_TEXT_DID_CHANGE,		// controlTextDidBeginEditing:
	DEL_TEXT_DID_GET_KEYS,		// controlTextDidChange:
	DEL_TEXT_WILL_CHANGE,		// control:textShouldBeginEditing:
	DEL_TEXT_WILL_END,		// control:textShouldEndEditing:
	DEL_DID_BECOME_FIRST_RESP,	// tableScrollDidBecomeFirstResponder:
	DEL_DID_RESIGN_FIRST_RESP,	// tableScrollDidResignFirstResponder:

	MAX_DEL_ENUM,
	BAD_DEL_ENUM = -1
	};

private:
    static int const SET_SIZE = ((MAX_DEL_ENUM - 1) / 8) + 1;
    unsigned char set[ SET_SIZE ];

public:
    MiscDelegateFlags( id delegate = 0 ) { setDelegate( delegate ); }
    void setDelegate( id delegate );
    bool respondsTo( Selector ) const;

    static SEL selToObjc( Selector );
    static Selector objcToSel( SEL );	// Returns BAD_DEL_ENUM if not found.
};

#endif // __MiscDelegateFlags_h
