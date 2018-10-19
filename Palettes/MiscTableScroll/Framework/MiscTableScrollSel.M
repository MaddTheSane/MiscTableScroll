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
// MiscTableScrollSel.M
//
//	Selection management methods for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollSel.M,v 1.3 99/06/15 03:43:53 sunshine Exp $
// $Log:	MiscTableScrollSel.M,v $
// Revision 1.3  99/06/15  03:43:53  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// For clarity and better OpenStep conformance, these methods were renamed:
// trackingBy --> selectsByRows
// trackBy: --> setSelectsByRows:
// tracking --> isTrackingMouse
// setTracking; --> setIsTrackingMouse:
// select...:byExtension: --> select...:byExtendingSelection:
// select{Slot|Row|Column}Tags: --> select{Slots|Rows|Columns}WithTags:
// deselect{Slot|Row|Column}Tags: --> deselect{Slots|Rows|Columns}WithTags:
// Changed return type of -numberOfSelected{Slots|Rows|Columns} from
// (unsigned int) to (int) to agree with other -numberOf... methods.  Also,
// since Java only deals with signed numbers, the unsigned ints would have
// been promoted to eight byte values on the Java side which is undesirable.
// 
// Revision 1.2  1998/03/29 23:57:42  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscColView.h"
#import "MiscRowView.h"
#import "MiscTableView.h"
#import "MiscTableBorder.h"

@implementation MiscTableScroll(Selection)
//-----------------------------------------------------------------------------
// Enabled
//-----------------------------------------------------------------------------
- (BOOL)isEnabled			{ return enabled; }
- (void)setEnabled:(BOOL)flag		{ enabled = flag; }


//-----------------------------------------------------------------------------
// Selection
//-----------------------------------------------------------------------------
- (void)selectionChanged
    {
    [rowInfo.view selectionChanged];
    [colInfo.view selectionChanged];
    [tableView selectionChanged];
    }

- (void)resetSelection
    {
    [tableView resetSelection];
    [rowInfo.view resetSelection];
    [colInfo.view resetSelection];
    }

- (void)setSelectsByRows:(BOOL)flag { [tableView setSelectsByRows:flag]; }
- (BOOL)selectsByRows { return [tableView selectsByRows]; }
- (BOOL)isTrackingMouse { return trackingMouse; }
- (void)setIsTrackingMouse:(BOOL)flag { trackingMouse = flag; }

- (MiscSelectionMode)selectionMode { return mode; }
- (void)setSelectionMode:(MiscSelectionMode)x
    {
    if (x != mode)
	{
	[self clearSelection];
	mode = x;
	[colInfo.view setSelectionMode:mode];
	[rowInfo.view setSelectionMode:mode];
	[tableView setSelectionMode:mode];
	}
    }

- (id)selectedCell
    {
    MiscCoord_P const col = [self selectedColumn];
    MiscCoord_P const row = [self selectedRow];
    return (col >= 0 && row >= 0) ? [self cellAtRow:row column:col] : 0;
    }

- (BOOL)hasSlotSelection:(MiscBorderType)b
	{ return info[b]->border->hasSelection(); }
- (BOOL)hasRowSelection { return [self hasSlotSelection:MISC_ROW_BORDER]; }
- (BOOL)hasColumnSelection { return [self hasSlotSelection:MISC_COL_BORDER]; }

- (BOOL)hasMultipleSlotSelection:(MiscBorderType)b
	{ return info[b]->border->hasMultipleSelection(); }
- (BOOL)hasMultipleRowSelection
	{ return [self hasMultipleSlotSelection:MISC_ROW_BORDER]; }
- (BOOL)hasMultipleColumnSelection
	{ return [self hasMultipleSlotSelection:MISC_COL_BORDER]; }

- (int)numberOfSelectedSlots:(MiscBorderType)b
	{ return info[b]->border->numSelected(); }
- (int)numberOfSelectedRows
	{ return [self numberOfSelectedSlots:MISC_ROW_BORDER]; }
- (int)numberOfSelectedColumns
	{ return [self numberOfSelectedSlots:MISC_COL_BORDER]; }

- (BOOL)border:(MiscBorderType)b slotIsSelected:(MiscCoord_P)slot
	{
	MiscTableBorder const* bp = info[b]->border;
	return bp->goodPos( slot ) && bp->isSelected_P( slot );
	}
- (BOOL)rowIsSelected:(MiscCoord_P)row
	{ return [self border:MISC_ROW_BORDER slotIsSelected:row]; }
- (BOOL)columnIsSelected:(MiscCoord_P)col
	{ return [self border:MISC_COL_BORDER slotIsSelected:col]; }
- (BOOL)cellIsSelectedAtRow:(MiscCoord_P)r column:(MiscCoord_P)c
	{ return ([self rowIsSelected:r] || [self columnIsSelected:c]); }

- (MiscCoord_P)selectedSlot:(MiscBorderType)b
	{ return info[b]->border->selectedSlot_P(); }
- (MiscCoord_P)selectedRow
	{ return [self selectedSlot:MISC_ROW_BORDER]; }
- (MiscCoord_P)selectedColumn
	{ return [self selectedSlot:MISC_COL_BORDER]; }

- (NSArray*)selectedSlotTags:(MiscBorderType)b
	{ return info[b]->border->selectedTags(); }
- (NSArray*)selectedRowTags
	{ return [self selectedSlotTags:MISC_ROW_BORDER]; }
- (NSArray*)selectedColumnTags
	{ return [self selectedSlotTags:MISC_COL_BORDER]; }

- (NSArray*)selectedSlots:(MiscBorderType)b
	{ return info[b]->border->selectedSlots(); }
- (NSArray*)selectedRows { return [self selectedSlots:MISC_ROW_BORDER]; }
- (NSArray*)selectedColumns { return [self selectedSlots:MISC_COL_BORDER]; }

- (void)border:(MiscBorderType)b selectSlot:(MiscCoord_P)p_slot
	byExtendingSelection:(BOOL)extend
	{
	BOOL changed = NO;
	MiscTableBorder* const ob = info[ MISC_OTHER_BORDER(b) ]->border;
	if (ob->hasSelection())
	    {
	    ob->selectNone();
	    changed = YES;
	    }
	MiscTableBorder* const bp = info[b]->border;
	if (!extend && bp->numSelected() > 0)
	    {
	    bp->selectNone();
	    changed = YES;
	    }
	if (bp->goodPos( p_slot ))
	    {
	    MiscCoord_V const v_slot = bp->physicalToVisual( p_slot );
	    if (!bp->isSelected( v_slot ))
		{
		if (mode == MISC_RADIO_MODE)
		    bp->selectOne( v_slot );
		else
		    bp->select( v_slot );
		changed = YES;
		}
	    }
	if (changed)
	    [self selectionChanged];
	}
- (void)border:(MiscBorderType)b selectSlot:(MiscCoord_P)p_slot
	{ [self border:b selectSlot:p_slot byExtendingSelection:NO]; }
- (void)selectRow:(MiscCoord_P)r byExtendingSelection:(BOOL)f
	{ [self border:MISC_ROW_BORDER selectSlot:r byExtendingSelection:f]; }
- (void)selectRow:(MiscCoord_P)row
	{ [self selectRow:row byExtendingSelection:NO]; }
- (void)selectColumn:(MiscCoord_P)c byExtendingSelection:(BOOL)f
	{ [self border:MISC_COL_BORDER selectSlot:c byExtendingSelection:f]; }
- (void)selectColumn:(MiscCoord_P)col
	{ [self selectColumn:col byExtendingSelection:NO]; }

- (void)border:(MiscBorderType)b selectSlotsWithTags:(NSArray*)tags
	byExtendingSelection:(BOOL)extend
	{
	info[b]->border->selectTags( tags, extend );
	[self selectionChanged];
	}
- (void)border:(MiscBorderType)b selectSlotsWithTags:(NSArray*)tags
	{ [self border:b selectSlotsWithTags:tags byExtendingSelection:NO]; }
- (void)selectRowsWithTags:(NSArray*)tags byExtendingSelection:(BOOL)flag
	{ [self border:MISC_ROW_BORDER selectSlotsWithTags:tags
	    byExtendingSelection:flag]; }
- (void)selectRowsWithTags:(NSArray*)tags
	{ [self selectRowsWithTags:tags byExtendingSelection:NO]; }
- (void)selectColumnsWithTags:(NSArray*)tags byExtendingSelection:(BOOL)flag
	{ [self border:MISC_COL_BORDER selectSlotsWithTags:tags
	    byExtendingSelection:flag]; }
- (void)selectColumnsWithTags:(NSArray*)tags
	{ [self selectColumnsWithTags:tags byExtendingSelection:NO]; }

- (void)border:(MiscBorderType)b selectSlots:(NSArray*)slots
	byExtendingSelection:(BOOL)extend
	{
	info[b]->border->selectSlots( slots, extend );
	[self selectionChanged];
	}
- (void)border:(MiscBorderType)b selectSlots:(NSArray*)slots
	{ [self border:b selectSlots:slots byExtendingSelection:NO]; }
- (void)selectRows:(NSArray*)r byExtendingSelection:(BOOL)f
	{ [self border:MISC_ROW_BORDER selectSlots:r byExtendingSelection:f]; }
- (void)selectRows:(NSArray*)rows
	{ [self selectRows:rows byExtendingSelection:NO]; }
- (void)selectColumns:(NSArray*)c byExtendingSelection:(BOOL)f
	{ [self border:MISC_COL_BORDER selectSlots:c byExtendingSelection:f]; }
- (void)selectColumns:(NSArray*)cols
	{ [self selectColumns:cols byExtendingSelection:NO]; }

- (void)selectAllSlots:(MiscBorderType)b
	{
	if (mode == MISC_LIST_MODE || mode == MISC_HIGHLIGHT_MODE)
	    {
	    info[b]->border->selectAll();
	    [self selectionChanged];
	    }
	}
- (void)selectAllRows { [self selectAllSlots:MISC_ROW_BORDER]; }
- (void)selectAllColumns { [self selectAllSlots:MISC_COL_BORDER]; }
- (void)selectAll:(id)sender
	{
	[self selectAllRows];
	[self sendActionIfEnabled];
	}

- (void)border:(MiscBorderType)b deselectSlot:(MiscCoord_P)p_slot
	{
	MiscTableBorder* const bp = info[b]->border;
	if (bp->goodPos( p_slot ))
	    {
	    MiscCoord_V const v_slot = bp->physicalToVisual( p_slot );
	    if (bp->isSelected( v_slot ))
		{
		bp->unselect( v_slot );
		[self selectionChanged];
		}
	    }
	}
- (void)deselectRow:(MiscCoord_P)row
	{ [self border:MISC_ROW_BORDER deselectSlot:row]; }
- (void)deselectColumn:(MiscCoord_P)col
	{ [self border:MISC_COL_BORDER deselectSlot:col]; }

- (void)border:(MiscBorderType)b deselectSlotsWithTags:(NSArray*)tags
	{
	info[b]->border->unselectTags( tags );
	[self selectionChanged];
	}
- (void)deselectRowsWithTags:(NSArray*)tags
	{ [self border:MISC_ROW_BORDER deselectSlotsWithTags:tags]; }
- (void)deselectColumnsWithTags:(NSArray*)tags
	{ [self border:MISC_COL_BORDER deselectSlotsWithTags:tags]; }

- (void)border:(MiscBorderType)b deselectSlots:(NSArray*)slots
	{
	info[b]->border->unselectSlots( slots );
	[self selectionChanged];
	}
- (void)deselectRows:(NSArray*)rows
	{ [self border:MISC_ROW_BORDER deselectSlots:rows]; }
- (void)deselectColumns:(NSArray*)cols
	{ [self border:MISC_COL_BORDER deselectSlots:cols]; }

- (void)clearSlotSelection:(MiscBorderType)b
	{
	info[b]->border->selectNone();
	[self selectionChanged];
	}
- (void)clearRowSelection { [self clearSlotSelection:MISC_ROW_BORDER]; }
- (void)clearColumnSelection { [self clearSlotSelection:MISC_COL_BORDER]; }
- (void)clearSelection
	{
	[self clearRowSelection];
	[self clearColumnSelection];
	}
- (void)deselectAll:(id)sender
	{
	[self clearSelection];
	[self sendActionIfEnabled];
	}


//-----------------------------------------------------------------------------
// Clicked slot stuff
//-----------------------------------------------------------------------------
- (MiscCoord_P)clickedSlot:(MiscBorderType)b
	{ return info[b]->border->clickedSlot_P(); }
- (MiscCoord_P)clickedRow
	{ return [self clickedSlot:MISC_ROW_BORDER]; }
- (MiscCoord_P)clickedColumn
	{ return [self clickedSlot:MISC_COL_BORDER]; }
- (id)clickedCell
	{
	MiscCoord_P const r = [self clickedRow];
	MiscCoord_P const c = [self clickedColumn];
	return (r >= 0 && c >= 0 ? [self cellAtRow:r column:c] : 0);
	}

- (void)border:(MiscBorderType)b setClickedSlot:(MiscCoord_P)n
	{ info[b]->border->setClickedSlot_P(n); }
- (void)setClickedRow:(MiscCoord_P)r column:(MiscCoord_P)c
	{
	[self border:MISC_ROW_BORDER setClickedSlot:r];
	[self border:MISC_COL_BORDER setClickedSlot:c];
	}

- (void)borderClearClickedSlot:(MiscBorderType)b
	{ info[b]->border->clearClickedSlot(); }
- (void)clearClicked
	{
	[self borderClearClickedSlot:MISC_ROW_BORDER];
	[self borderClearClickedSlot:MISC_COL_BORDER];
	}


//-----------------------------------------------------------------------------
// Keyboard cursor stuff
//-----------------------------------------------------------------------------
- (void)reflectCursor { [tableView reflectCursor]; }
- (MiscCoord_P)cursorSlot:(MiscBorderType)b
	{ return info[b]->border->getCursor_P(); }
- (MiscCoord_P)cursorRow { return [self cursorSlot:MISC_ROW_BORDER]; }
- (MiscCoord_P)cursorColumn { return [self cursorSlot:MISC_COL_BORDER]; }

- (void)border:(MiscBorderType)b setCursorSlot:(MiscCoord_P)slot
	{ info[b]->border->setCursor_P( slot ); [self reflectCursor]; }
- (void)setCursorRow:(MiscCoord_P)row
	{ [self border:MISC_ROW_BORDER setCursorSlot:row]; }
- (void)setCursorColumn:(MiscCoord_P)col
	{ [self border:MISC_COL_BORDER setCursorSlot:col]; }

- (void)clearCursorSlot:(MiscBorderType)b
	{ info[b]->border->clearCursor(); [self reflectCursor]; }
- (void)clearCursorRow { [self clearCursorSlot:MISC_ROW_BORDER]; }
- (void)clearCursorColumn { [self clearCursorSlot:MISC_COL_BORDER]; }
- (void)clearCursor { [self clearCursorRow]; [self clearCursorColumn]; }

- (BOOL)hasValidCursorSlot:(MiscBorderType)b
	{ return info[b]->border->hasValidCursor(); }
- (BOOL)hasValidCursorRow
	{ return [self hasValidCursorSlot:MISC_ROW_BORDER]; }
- (BOOL)hasValidCursorColumn
	{ return [self hasValidCursorSlot:MISC_COL_BORDER]; }

- (BOOL)isCursorEnabled { return [tableView isCursorEnabled]; }
- (void)disableCursor
    {
    if ([self isCursorEnabled] && [tableView shouldDrawCursor])
	[tableView eraseCursor];
    [tableView disableCursor];
    [self displayIfNeeded];
    }

- (void)enableCursor
    {
    [tableView enableCursor];
    if ([self isCursorEnabled] && [tableView shouldDrawCursor])
	[tableView drawCursor];
    [self displayIfNeeded];
    }

@end
