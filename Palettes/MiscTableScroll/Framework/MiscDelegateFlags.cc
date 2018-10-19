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
// MiscDelegateFlags.cc
//
//	Flags indicating which selectors a delegate responds to.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscDelegateFlags.cc,v 1.11 99/06/15 02:33:30 sunshine Exp $
// $Log:	MiscDelegateFlags.cc,v $
// Revision 1.11  99/06/15  02:33:30  sunshine
// v140.1: Many delegate messages changed to notification style messages.
// Added delegate messages for becoming and resigning first responder.
// Renamed: DEL_WILL_EDIT_AT to DEL_WILL_EDIT, DEL_DID_EDIT_AT to DEL_DID_EDIT
// For better OpenStep conformance, renamed: -tableScroll:getISearchColumn: to
// -tableScrollGetIncrementalSearchColumn:.
// 
// Revision 1.10  1998/03/29 23:42:21  sunshine
// v138.1: Added -tableScroll:shouldDelayWindowOrderingForEvent:.
//
// Revision 1.9  98/03/23  07:46:45  sunshine
// v134.1: Eliminated -tableScroll:edit:atRow:column:.
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscDelegateFlags.h"
extern "Objective-C" {
#import <Foundation/NSObject.h>
}
extern "C" {
#include <string.h>	// memset()
}

static inline unsigned int BYTE_NUM( int x )	{ return (x / 8); }
static inline unsigned int BIT_NUM( int x )	{ return (x % 8); }
static inline unsigned char BIT_MASK( int x )	{ return (1 << BIT_NUM(x)); }

#define PSEL(X)	&@selector(X)

// *** MUST MATCH ENUM IN .h FILE ***
static SEL const* const SELECTORS[ MiscDelegateFlags::MAX_DEL_ENUM ] = 
    {
    PSEL(tableScrollSlotDragged:),
    PSEL(tableScrollSlotSortReversed:),
    PSEL(tableScrollSlotResized:),
    PSEL(tableScrollChangeFont:),
    PSEL(tableScrollFontChanged:),
    PSEL(tableScrollBackgroundColorChanged:),
    PSEL(tableScrollSelectedBackgroundColorChanged:),
    PSEL(tableScrollTextColorChanged:),
    PSEL(tableScrollSelectedTextColorChanged:),
    PSEL(tableScroll:getIncrementalSearchColumn:),
    PSEL(tableScrollBufferCount:),
    PSEL(tableScroll:border:slotPrototype:),
    PSEL(tableScroll:border:slotTitle:),
    PSEL(tableScroll:cellAtRow:column:),
    PSEL(tableScroll:reviveCell:atRow:column:),
    PSEL(tableScroll:retireCell:atRow:column:),
    PSEL(tableScroll:tagAtRow:column:),
    PSEL(tableScroll:intValueAtRow:column:),
    PSEL(tableScroll:floatValueAtRow:column:),
    PSEL(tableScroll:doubleValueAtRow:column:),
    PSEL(tableScroll:stringValueAtRow:column:),
    PSEL(tableScroll:titleAtRow:column:),
    PSEL(tableScroll:stateAtRow:column:),
    PSEL(tableScrollRegisterServicesTypes:),
    PSEL(tableScroll:validRequestorForSendType:returnType:),
    PSEL(tableScroll:canWritePboardType:),
    PSEL(tableScroll:stringForPboardType:),
    PSEL(tableScroll:writeSelectionToPasteboard:types:),
    PSEL(tableScroll:readSelectionFromPasteboard:),
    PSEL(tableScroll:allowDragOperationAtRow:column:),
    PSEL(tableScroll:preparePasteboard:forDragOperationAtRow:column:),
    PSEL(tableScroll:imageForDragOperationAtRow:column:),
    PSEL(tableScroll:draggingSourceOperationMaskForLocal:),
    PSEL(tableScrollIgnoreModifierKeysWhileDragging:),
    PSEL(tableScroll:shouldDelayWindowOrderingForEvent:),
    PSEL(tableScrollWillPrint:),
    PSEL(tableScrollDidPrint:),
    PSEL(tableScrollWillPrintPageHeader:),
    PSEL(tableScrollWillPrintPageFooter:),
    PSEL(tableScroll:canEdit:atRow:column:),
    PSEL(tableScroll:setStringValue:atRow:column:),
    PSEL(tableScroll:abortEditAtRow:column:),
    PSEL(tableScrollWillEdit:),
    PSEL(tableScrollDidEdit:),
    PSEL(controlTextDidEndEditing:),
    PSEL(controlTextDidBeginEditing:),
    PSEL(controlTextDidChange:),
    PSEL(control:textShouldBeginEditing:),
    PSEL(control:textShouldEndEditing:),
    PSEL(tableScrollDidBecomeFirstResponder:),
    PSEL(tableScrollDidResignFirstResponder:)
    };

#undef PSEL

//-----------------------------------------------------------------------------
// selToObjc
//-----------------------------------------------------------------------------
SEL MiscDelegateFlags::selToObjc( Selector s )
    {
    return *SELECTORS[s];
    }


//-----------------------------------------------------------------------------
// objcToSel
//-----------------------------------------------------------------------------
MiscDelegateFlags::Selector MiscDelegateFlags::objcToSel( SEL s )
    {
    for (unsigned int i = 0; i < MAX_DEL_ENUM; i++)
	if (s == *SELECTORS[i])
	    return (Selector)i;
    return BAD_DEL_ENUM;
    }


//-----------------------------------------------------------------------------
// setDelegate
//-----------------------------------------------------------------------------
void MiscDelegateFlags::setDelegate( id d )
    {
    if (d == 0)
	memset( set, 0, SET_SIZE );
    else
	{
	for (unsigned int i = 0; i < MAX_DEL_ENUM; i++)
	    {
	    unsigned char& byte = set[ BYTE_NUM(i) ];
	    unsigned char const mask = BIT_MASK(i);
	    if ([d respondsToSelector:(*SELECTORS[i])])
		byte |= mask;
	    else
		byte &= ~mask;
	    }
	}
    }


//-----------------------------------------------------------------------------
// respondsTo
//-----------------------------------------------------------------------------
bool MiscDelegateFlags::respondsTo( Selector s ) const
    {
    return ((set[ BYTE_NUM(s) ] & BIT_MASK(s)) != 0);
    }
