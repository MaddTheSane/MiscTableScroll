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
// MiscTableScrollInspector.M
//
//	Interface Builder inspector for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollInspector.M,v 1.20 99/06/14 19:16:04 sunshine Exp $
// $Log:	MiscTableScrollInspector.M,v $
// Revision 1.20  99/06/14  19:16:04  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Converted slot list from a matrix of buttons to MiscTableScroll.
// Reworked color controls so that user can preview color combinations.  This
// is accomplished by the addition of two text fields.  One displays the
// foreground and background color for unselected slots; the other selected
// slots.  This configuration makes better use of screen real estate.
// 
// Revision 1.19  1998/03/30 00:06:01  sunshine
// v138.1: Ditched unnecessary "align title" text field since under OPENSTEP,
// buttons are correctly dimmed when disabled.  Consequently I don't have to
// worry about figuring out correct enabled/disabled colors for the field.
// Fixed bug: Pressing "new slot" would draw and highlight the new cell, but
// wouldn't redraw the old selected cell.
//-----------------------------------------------------------------------------
#import "MiscTableScrollInspector.h"
#import "MiscTableBorder.h"
#import <MiscTableScroll/MiscTableScroll.h>

//=============================================================================
// IB-ONLY METHODS FOR MiscTableScroll
//=============================================================================
@interface MiscTableScroll(IB)
- (NSString*)inspectorClassName;
- (void)editSelf:(id)sender in:(id)owner;
@end

@implementation MiscTableScroll(IB)
- (NSString*)inspectorClassName
    {
    NSString* s = @"MiscTableScrollInspector";
    return s;
    }
// Prevent double-click from editing NSScrollView in IB
- (void)editSelf:(id)sender in:(id)owner {}
@end


//=============================================================================
// CONVENIENCE CATAGORIES
//=============================================================================
@interface NSPopUpButton(MiscTableScroll)
- (int)popUpTag;
- (void)setPopUpTag:(int)new_tag;
@end

@implementation NSPopUpButton(MiscTableScroll)

- (int)popUpTag { return [[self selectedItem] tag]; }

- (void)setPopUpTag:(int)new_tag
    {
    NSArray* items = [self itemArray];
    for (int i = [items count]; i-- > 0; )
	{
	id<NSMenuItem> item = (id<NSMenuItem>)[items objectAtIndex:i];
	if ([item tag] == new_tag)
	    {
	    [self selectItemWithTitle:[item title]];
	    break;
	    }
	}
    }

@end


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@interface MiscTableScrollInspector(Forward)
- (void)doSlot:(id)sender;
- (void)doTitleMode:(id)sender;
@end

@implementation MiscTableScrollInspector

- (BOOL)wantsButtons { return NO; }
- (void)ok:(id)sender { [super ok:sender]; }


//-----------------------------------------------------------------------------
// initSlotScroll
//-----------------------------------------------------------------------------
- (void)initSlotScroll
    {
    [slotScroll setAutoSortRows:NO];
    [slotScroll setSelectionMode:MISC_RADIO_MODE];
    [slotScroll setDraggableColumns:NO];
    [slotScroll setDelegate:self];
    [slotScroll setTarget:self];
    [slotScroll setAction:@selector(doSlot:)];
    [slotScroll addColumn];
    [slotScroll setColumn:0 title:@"Slots"];
    [slotScroll setColumn:0 autosize:YES];
    }


//-----------------------------------------------------------------------------
// init
//-----------------------------------------------------------------------------
- (id)init
    {
    [super init];
    [NSBundle loadNibNamed:[[self class] description] owner:self];
    [self initSlotScroll];
    [[upButton cell] setImageDimsWhenDisabled:YES];
    [[downButton cell] setImageDimsWhenDisabled:YES];
    borderType = MISC_COL_BORDER;
    dirty = NO;
    return self;
    }


//-----------------------------------------------------------------------------
// setTitleControls
//-----------------------------------------------------------------------------
- (void)setTitleControls
    {
    id o = [self object];
    if ([o slotTitlesOn:borderType])
	{
	[titlesSwitch setState:1];
	[sizableSwitch setEnabled:YES];
	[sizableSwitch setState:border->isSizeable()];
	[draggableSwitch setEnabled:YES];
	[draggableSwitch setState:border->isDraggable()];
	[titleModePopUp setEnabled:YES];
	[titleModePopUp setPopUpTag:(int)[o slotTitleMode:borderType]];
	}
    else
	{
	[titlesSwitch setState:0];
	[sizableSwitch setEnabled:NO];
	[sizableSwitch setState:0];
	[draggableSwitch setEnabled:NO];
	[draggableSwitch setState:0];
	[titleModePopUp setEnabled:NO];
	[titleModePopUp setPopUpTag:(int)[o slotTitleMode:borderType]];
	}
    [uniformSizeField setEnabled:YES];
    [uniformSizeField setIntValue:(int)[o uniformSizeSlots:borderType]];
    }


//-----------------------------------------------------------------------------
// fillScroll
//-----------------------------------------------------------------------------
- (void)fillScroll
    {
    id o = [self object];
    numSlots = [o numberOfSlots:borderType];
    if (numSlots == 0)
	[slotScroll empty];
    else
	{
	[slotScroll renewRows:numSlots];
	for (int i = 0; i < numSlots; i++)
	    {
	    int const pslot = [o border:borderType slotAtPosition:i];
	    [[slotScroll cellAtRow:i column:0]
		setStringValue:[o border:borderType slotTitle:pslot]];
	    }
	}
    [slotScroll sizeToCells];

    if (numSlots > 0)
	{
	if (slot < 0) slot = 0;
	[slotScroll selectRow:slot];
	[slotScroll scrollRowToVisible:slot];
	}
    else
	slot = -1;

    [slotScroll setNeedsDisplay:YES]; // Needed after pressing "Add".
    [self doSlot:self];
    }


//-----------------------------------------------------------------------------
// doEnabled:
//-----------------------------------------------------------------------------
- (void)doEnabled:(id)sender
    {
    [[self object] setEnabled:[enabledSwitch state]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doLazy:
//-----------------------------------------------------------------------------
- (void)doLazy:(id)sender
    {
    [[self object] setLazy:[lazySwitch state]];
    [self ok:sender];
    [self revert:sender];
    }


//-----------------------------------------------------------------------------
// doMode:
//-----------------------------------------------------------------------------
- (void)doMode:(id)sender
    {
    [[self object] setSelectionMode:MiscSelectionMode([modePopUp popUpTag])];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doBorder:
//-----------------------------------------------------------------------------
- (void)doBorder:(id)sender
    {
    MiscBorderType bt = MiscBorderType([borderPopUp popUpTag]);
    if (bt != borderType)
	{
	borderType = bt;
	[self revert:sender];
	}
    }


//-----------------------------------------------------------------------------
// doTitles:
//-----------------------------------------------------------------------------
- (void)doTitles:(id)sender
    {
    BOOL const isOn = [titlesSwitch state];
    [[self object] border:borderType setSlotTitlesOn:isOn];
    [self setTitleControls];
    [self doSlot:self];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doSizable:
//-----------------------------------------------------------------------------
- (void)doSizable:(id)sender
    {
    [[self object] border:borderType setSizeableSlots:[sizableSwitch state]];
    [self doSlot:0];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doDraggable:
//-----------------------------------------------------------------------------
- (void)doDraggable:(id)sender
    {
    [[self object] border:borderType
		setDraggableSlots:[draggableSwitch state]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doAutoSort:
//-----------------------------------------------------------------------------
- (void)doAutoSort:(id)sender
    {
    [[self object] border:borderType setAutoSortSlots:[autoSortSwitch state]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doTitleMode:
//-----------------------------------------------------------------------------
- (void)doTitleMode:(id)sender
    {
    [[self object] border:borderType
	setSlotTitleMode:(MiscTableTitleMode)[titleModePopUp popUpTag]];
    [self fillScroll];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doDelete:
//-----------------------------------------------------------------------------
- (void)doDelete:(id)sender
    {
    id o = [self object];
    [o border:borderType
		removeSlot:[o border:borderType slotAtPosition:slot]];
    [o tile];
    [o display];
    slot--;
    numSlots--;
    if (slot < 0 && numSlots > 0)
	slot = 0;
    [self fillScroll];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doNew:
//-----------------------------------------------------------------------------
- (void)doNew:(id)sender
    {
    id o = [self object];
    [o addSlot:borderType];
    [o sizeToCells];
    slot = numSlots;
    [self fillScroll];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doUserSizeable:
//-----------------------------------------------------------------------------
- (void)doUserSizeable:(id)sender
    {
    id o = [self object];
    [o border:borderType setSlot:[o border:borderType slotAtPosition:slot]
		sizeable:[userSizeableSwitch state]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doAlign:
//-----------------------------------------------------------------------------
- (void)doAlign:(id)sender
    {
    id o = [self object];
    int const pslot = [o border:borderType slotAtPosition:slot];
    if ([o border:borderType slotCellType:pslot] == MISC_TABLE_CELL_TEXT)
	{
	id const proto = [o border:borderType slotCellPrototype:pslot];
	id const cell = [alignMatrix selectedCell];
	[proto setAlignment:(NSTextAlignment)[cell tag]];
	}
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doAutosize:
//-----------------------------------------------------------------------------
- (void)doAutosize:(id)sender
    {
    id o = [self object];
    [o border:borderType setSlot:[o border:borderType slotAtPosition:slot]
		autosize:[autosizeSwitch state]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doCellClass:
//-----------------------------------------------------------------------------
- (void)doCellClass:(id)sender
    {
    id o = [self object];
    int const pslot = [o border:borderType slotAtPosition:slot];
    int const old_val = (int)[o border:borderType slotCellType:pslot];
    int const new_val = [cellClassPopUp popUpTag];

    if (old_val != new_val)
	{
	[o border:borderType setSlot:pslot
		cellType:(MiscTableCellStyle)new_val];
	if (new_val == MISC_TABLE_CELL_TEXT)
	    {
	    [alignMatrix setEnabled:YES];
	    id const cell = [o border:borderType slotCellPrototype:pslot];
	    [alignMatrix selectCellWithTag:[cell alignment]];
	    }
	else if (old_val == MISC_TABLE_CELL_TEXT)
	    [alignMatrix setEnabled:NO];
	}

    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doSortType:
//-----------------------------------------------------------------------------
- (void)doSortType:(id)sender
    {
    id o = [self object];
    [o border:borderType setSlot:[o border:borderType slotAtPosition:slot]
		sortType:(MiscSortType)[sortTypePopUp popUpTag]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doSortDirection:
//-----------------------------------------------------------------------------
- (void)doSortDirection:(id)sender
    {
    id o = [self object];
    [o border:borderType setSlot:[o border:borderType slotAtPosition:slot]
	sortDirection:(MiscSortDirection)[sortDirectionPopUp popUpTag]];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doSlot:
//-----------------------------------------------------------------------------
- (void)doSlot:(id)sender
    {
    slot = [slotScroll selectedRow];
    if (slot >= 0)
	{
	id o = [self object];
	BOOL const titlesOn = [o slotTitlesOn:borderType];
	BOOL const notUniform = ([o uniformSizeSlots:borderType] == 0);
	int pslot = [o border:borderType slotAtPosition:slot];
	[deleteButton setEnabled:YES];
	[upButton setEnabled:(slot > 0)];
	[downButton setEnabled:(slot < numSlots - 1)];
	int const ctype = (int)[o border:borderType slotCellType:pslot];
	[cellClassPopUp setEnabled:YES];
	[cellClassPopUp setPopUpTag:ctype];
	[sortTypePopUp setEnabled:YES];
	[sortTypePopUp setPopUpTag:
		(int)[o border:borderType slotSortType:pslot]];
	[sortDirectionPopUp setEnabled:YES];
	[sortDirectionPopUp setPopUpTag:
		(int)[o border:borderType slotSortDirection:pslot]];
	if (ctype == MISC_TABLE_CELL_TEXT)
	    {
	    [alignMatrix setEnabled:YES];
	    id const cell = [o border:borderType slotCellPrototype:pslot];
	    [alignMatrix selectCellWithTag:[cell alignment]];
	    }
	else
	    [alignMatrix setEnabled:NO];
	[autosizeSwitch setEnabled:notUniform];
	[autosizeSwitch setState:[o border:borderType slotIsAutosize:pslot]];
	BOOL const enabled = titlesOn && notUniform &&
		[[self object] sizeableSlots:borderType];
	[userSizeableSwitch setEnabled:enabled];
	[userSizeableSwitch setState:
		enabled && [o border:borderType slotIsSizeable:pslot]];
	[sizeField setEnabled:notUniform];
	[sizeField setIntValue:(int)[o border:borderType slotSize:pslot]];
	[sizeMinField setEnabled:notUniform];
	[sizeMinField setIntValue:
		(int)[o border:borderType slotMinSize:pslot]];
	[sizeMaxField setEnabled:notUniform];
	[sizeMaxField setIntValue:
		(int)[o border:borderType slotMaxSize:pslot]];
	[titleField setEnabled:titlesOn &&
		([o slotTitleMode:borderType] == MISC_CUSTOM_TITLE)];
	[titleField setStringValue:[o border:borderType slotTitle:pslot]];
	}
    else
	{
	[deleteButton setEnabled:NO];
	[upButton setEnabled:NO];
	[downButton setEnabled:NO];
	[cellClassPopUp setEnabled:NO];
	[cellClassPopUp setPopUpTag:0];
	[sortTypePopUp setEnabled:NO];
	[sortTypePopUp setPopUpTag:0];
	[sortDirectionPopUp setEnabled:NO];
	[sortDirectionPopUp setPopUpTag:0];
	[alignMatrix setEnabled:NO];
	[alignMatrix selectCellWithTag:0];
	[autosizeSwitch setEnabled:NO];
	[autosizeSwitch setState:0];
	[userSizeableSwitch setEnabled:NO];
	[userSizeableSwitch setState:0];
	[sizeField setEnabled:NO];
	[sizeField setStringValue:@""];
	[sizeMinField setEnabled:NO];
	[sizeMinField setStringValue:@""];
	[sizeMaxField setEnabled:NO];
	[sizeMaxField setStringValue:@""];
	[titleField setEnabled:NO];
	[titleField setStringValue:@""];
	} 
    }


//-----------------------------------------------------------------------------
// swapSlots::
//-----------------------------------------------------------------------------
- (void)swapSlots:(int)from_slot :(int)to_slot
    {
    border->swapSlots( from_slot, to_slot );
    [[self object] display];
    slot = to_slot;
    [self fillScroll];
    [self ok:self];
    }


//-----------------------------------------------------------------------------
// doUp:
//-----------------------------------------------------------------------------
- (void)doUp:(id)sender
    {
    if (slot > 0)
	[self swapSlots:slot :slot-1];
    }


//-----------------------------------------------------------------------------
// doDown:
//-----------------------------------------------------------------------------
- (void)doDown:(id)sender
    {
    if (slot < numSlots - 1)
	[self swapSlots:slot :slot+1];
    }


//-----------------------------------------------------------------------------
// getPhysSlot
//	Get the physical slot-id of the current slot.
//-----------------------------------------------------------------------------
- (int)getPhysSlot
    {
    return [[self object] border:borderType slotAtPosition:slot];
    }


//-----------------------------------------------------------------------------
// controlTextDidBeginEditing:
//-----------------------------------------------------------------------------
- (void)controlTextDidBeginEditing:(NSNotification*)n
    {
    dirty = YES;
    }


//-----------------------------------------------------------------------------
// controlTextDidEndEditing:
//-----------------------------------------------------------------------------
- (void)controlTextDidEndEditing:(NSNotification*)n
    {
    if (dirty)
	{
	dirty = NO;
	id o = [self object];
	NSTextField* field = [n object];
	if (field == titleField)
	    {
	    int const pslot = [self getPhysSlot];
	    [o border:borderType setSlot:pslot
			title:[titleField stringValue]];
	    [[slotScroll cellAtRow:slot column:0]
			setStringValue:[titleField stringValue]];
	    [slotScroll setNeedsDisplay:YES];
	    }
	else if (field == uniformSizeField)
	    {
	    int old_size = (int)[o uniformSizeSlots:borderType];
	    int new_size = [uniformSizeField intValue];
	    if (new_size != 0)
		{
		if (new_size < MISC_MIN_PIXELS_SIZE)
		    new_size = MISC_MIN_PIXELS_SIZE;
		if (new_size > MISC_MAX_PIXELS_SIZE)
		    new_size = MISC_MAX_PIXELS_SIZE;
		[uniformSizeField setIntValue:new_size];
		}
	    if (old_size != new_size)
		{
		[o border:borderType setUniformSizeSlots:(float)new_size];
		[self ok:self];
		[self revert:self];
		}
	    }
	else if (field == sizeField)
	    {
	    int const pslot = [self getPhysSlot];
	    int i = [sizeField intValue];
	    int const imin = (int)[o border:borderType slotMinSize:pslot];
	    int const imax = (int)[o border:borderType slotMaxSize:pslot];

	    if (i < imin || i > imax)
		{
		if (i < imin) i = imin;
		if (i > imax) i = imax;
		[sizeField setIntValue:i];
		}
	    [o border:borderType setSlot:pslot size:i];
	    }
	else if (field == sizeMinField)
	    {
	    int const pslot = [self getPhysSlot];
	    int const i = (int)[o border:borderType slotSize:pslot];
	    int imin = [sizeMinField intValue];
	    int const imax = (int)[o border:borderType slotMaxSize:pslot];

	    if (imin < MISC_MIN_PIXELS_SIZE)
		imin = MISC_MIN_PIXELS_SIZE;
	    else if (imin > imax)
		imin = imax;
	    if (imin > i)	// Not an 'else if'
		imin = i;

	    [sizeMinField setIntValue:imin];
	    [o border:borderType setSlot:pslot minSize:imin];
	    }
	else if (field == sizeMaxField)
	    {
	    int const pslot = [self getPhysSlot];
	    int const i = (int)[o border:borderType slotSize:pslot];
	    int const imin = (int)[o border:borderType slotMinSize:pslot];
	    int imax = [sizeMaxField intValue];

	    if (imax > MISC_MAX_PIXELS_SIZE)
		imax = MISC_MAX_PIXELS_SIZE;
	    else if (imax < imin)
		imax = imin;
	    if (imax < i)	// Not an 'else if'
		imax = i;

	    [sizeMaxField setIntValue:imax];
	    [o border:borderType setSlot:pslot maxSize:imax];
	    }
	[self ok:self];
	}
    }


//-----------------------------------------------------------------------------
// doColorText:
//-----------------------------------------------------------------------------
- (void)doColorText:(id)sender
    {
    NSColor* const c = [sender color];
    [[self object] setTextColor:c];
    [sampleTextNormal setTextColor:c];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doColorBack:
//-----------------------------------------------------------------------------
- (void)doColorBack:(id)sender
    {
    NSColor* const c = [sender color];
    [[self object] setBackgroundColor:c];
    [sampleTextNormal setBackgroundColor:c];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doColorTextSelected:
//-----------------------------------------------------------------------------
- (void)doColorTextSelected:(id)sender
    {
    NSColor* const c = [sender color];
    [[self object] setSelectedTextColor:c];
    [sampleTextSelected setTextColor:c];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// doColorBackSelected:
//-----------------------------------------------------------------------------
- (void)doColorBackSelected:(id)sender
    {
    NSColor* const c = [sender color];
    [[self object] setSelectedBackgroundColor:c];
    [sampleTextSelected setBackgroundColor:c];
    [self ok:sender];
    }


//-----------------------------------------------------------------------------
// -FG:::
//-----------------------------------------------------------------------------
- (void)FG:(NSColor*)c :(NSTextField*)f :(NSColorWell*)w
    {
    [f setTextColor:c];
    [w setColor:c];
    }


//-----------------------------------------------------------------------------
// -BG:::
//-----------------------------------------------------------------------------
- (void)BG:(NSColor*)c :(NSTextField*)f :(NSColorWell*)w
    {
    [f setBackgroundColor:c];
    [w setColor:c];
    }


//-----------------------------------------------------------------------------
// revert:
//-----------------------------------------------------------------------------
- (void)revert:(id)sender
    {
    dirty = NO;
    id o = [self object];
    [super revert:sender];

    border = [o border:borderType];
    [autoSortSwitch setState:[o autoSortSlots:borderType]];
    [self setTitleControls];

    [enabledSwitch setState:[o isEnabled]];
    [lazySwitch setState:[o isLazy]];
    [modePopUp setPopUpTag:(int) [o selectionMode]];

    [self FG:[o textColor              ]:sampleTextNormal  :colorText        ];
    [self BG:[o backgroundColor        ]:sampleTextNormal  :colorBack        ];
    [self FG:[o selectedTextColor      ]:sampleTextSelected:colorTextSelected];
    [self BG:[o selectedBackgroundColor]:sampleTextSelected:colorBackSelected];

    slot = -1;
    [self fillScroll];
    }

@end
