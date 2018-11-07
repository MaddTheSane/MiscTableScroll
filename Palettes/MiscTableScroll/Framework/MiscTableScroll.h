#ifndef __MiscTableScroll_h
#define __MiscTableScroll_h
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
// <MiscTableScroll.h>
//
//	ScrollView class that displays a 2-D table of cells.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScroll.h,v 1.32 99/06/15 05:58:56 sunshine Exp $
// $Log:	MiscTableScroll.h,v $
// Revision 1.32  99/06/15  05:58:56  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows. Exposed to Java.
// Added support for represented object:
// -representedObject, -setRepresentedObject:
// -border:slotRepresentedObject:, -border:setSlot:representedObject:
// -columnRepresentedObject:, -setColumn:representedObject:
// -rowRepresentedObject:, -setRow:representedObject:
// -border:slotWithRepresentedObject:
// -columnWithRepresentedObject:
// -rowWithRepresentedObject:
// -cellWithRepresentedObject:
// -getRow:column:ofCellWithRepresentedObject:
// For clarity and better OpenStep conformance, renamed:
// -drawClippedText --> -drawsClippedText
// -setDrawClippedText: --> -setDrawsClippedText:
// -...ISearchColumn: --> -...IncrementalSearchColumn:
// -select...:byExtension: --> -select...:byExtendingSelection:
// -select{Slot|Row|Column}Tags: --> -select{Slots|Rows|Columns}WithTags:
// -deselect{Slot|Row|Column}Tags: --> -deselect{Slots|Rows|Columns}WithTags:
// -trackBy: --> setSelectsByRows:
// -trackingBy --> selectsByRows
// -tracking --> -isTrackingMouse
// -stringForNSTabularTextPBoardType --> -stringForNSTabularTextPboardType
// Renamed variable: tracking --> trackingMouse
// Renamed variable: drawClippedText --> drawsClippedText
// Java exposure requires a one-to-one mapping between Objective-C selectors
// and Java methods.  AppKit already has a method for moving columns around,
// so MiscTableScroll has to match that name.  For consistency renamed other
// similar methods as well:
// -border:moveSlotFrom:to: --> -border:moveSlot:toSlot:
// -moveColumnFrom:to: --> -moveColumn:toColumn:
// -moveRowFrom:to: --> moveRow:toRow:
// -border:slotDraggedFrom:to: --> border:slotDragged:toSlot:
// Added MiscTableScroll-specific notifications which are sent to the default
// notification center in place of sending certain old-style delegate
// messages.  The delegates are automatically registered to listen for any
// notifications which they can receive.  Consequently renamed numerous
// delegate messages to handle notifications:
// -tableScroll:border:slotDraggedFrom:to: --> -tableScrollSlotDragged:
// -tableScroll:border:slotResized: --> -tableScrollSlotResized:
// -tableScroll:border:slotSortReversed: --> -tableScrollSlotSortReversed:
// -tableScroll:changeFont:to: --> -tableScrollChangeFont:
// -tableScroll:fontChangedFrom:to: --> -tableScrollFontChanged:
// -tableScroll:...ColorChangedTo: --> -tableScroll...ColorChanged:
// -tableScroll:willPrint: --> -tableScrollWillPrint:
// -tableScroll:didPrint: --> -tableScrollDidPrint:
// -tableScroll:willPrintPageHeader:info: --> -tableScrollWillPrintPageHeader:
// -tableScroll:willPrintPageFooter:info: --> -tableScrollWillPrintPageFooter:
// -tableScroll:willEditAtRow:column: --> -tableScrollWillEdit:
// -tableScroll:didEdit:atRow:column: --> -tableScrollDidEdit:
// Added -didBecomeFirstResponder & -didResignFirstResponder.  These are sent
// by MiscTableView to MiscTableScroll at appropriate times.  When becoming
// first responder, -didBecomeFirstResponder notifies NSFontManager of the
// current font setting and sends the did-become-first-responder notification.
// -didResignFirstResponder sends the did-resign-first-responder notification.
// Added new delegate messages -tableScrollDidBecomeFirstResponder: and
// -tableScrollDidResignFirstResponder:.
// Return type of -numberOfSelected{Slots|Rows|Columns} changed from (unsigned
// int) to (int) to be consistent with other similarly named methods.  Also,
// since Java only deals with signed numbers, unsigned int would have been
// promoted to eight bytes on the Java side with is undesirable.
// Added two new categories to MiscTableScroll: DataSource & Notifications.
// Moved data-source related delegate messages into DataSource and
// notification related messages into Notifications.  These categories are
// required by the Java bridging tools in order to expose the contained
// methods as members of a Java "interface".
// Page header and footer are now strongly typed as NSView* rather than id.
// Strong typing extends more cleanly to the Java side.
// 
// Revision 1.31  1998/03/29 23:54:21  sunshine
// v138.1: Added -tableScroll:shouldDelayWindowOrderingForEvent:.
// Worked around OPENSTEP 4.2 for NT bug where compiler crashes when
// sending a message to 'super' from within a category.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableTypes.h>

MISC_TS_EXTERN_BEGIN( "Objective-C" )
#import <AppKit/NSScrollView.h>
#import <AppKit/NSCell.h>
MISC_TS_EXTERN_END

MISC_TS_CLASS_DEF( MiscTableBorder );
MISC_TS_CLASS_DEF( MiscDelegateFlags );
@class MiscTableScroll, MiscTableView, MiscBorderView, MiscCornerView;
@class NSCell, NSClipView, NSFont, NSText;


typedef struct MiscCellEditInfo
{
	BOOL			editing;	// Is editing in progress?
	MiscCoord_P		row;		// Coords of edited cell.
	MiscCoord_P		col;
	NSText*			editor;		// Field editor.
	id			cell;		// Temporary editing cell.
	int			suspended;	// Suspend/resume counter.
} MiscCellEditInfo;


typedef struct MiscBorderInfo
{
	MiscTableBorder*	border;
	MiscBorderView*		view;
	NSClipView*		clip;
	NSArray*		sort_vector;
	BOOL			isOn;
	BOOL			autoSort;
} MiscBorderInfo;

@protocol MiscTableScrollDelegate;
@protocol MiscTableScrollDataSource;

@interface MiscTableScroll : NSScrollView
{
@private
    MiscTableView*	tableView;
    MiscBorderInfo*	info[2];	// { &colInfo, &rowInfo }
    MiscBorderInfo	colInfo;
    MiscBorderInfo	rowInfo;
    MiscCornerView*	cornerView;
    NSFont*		font;
    NSColor*	textColor;
    NSColor*	backgroundColor;
    NSColor*	selectedTextColor;
    NSColor*	selectedBackgroundColor;
    __unsafe_unretained id<MiscTableScrollDelegate>			delegate;
    __unsafe_unretained id<MiscTableScrollDataSource>		dataDelegate;
    MiscDelegateFlags*		delegateFlags;
    MiscDelegateFlags*		dataDelegateFlags;
	__unsafe_unretained id	target;
	__unsafe_unretained id	doubleTarget;
    SEL			action;
    SEL			doubleAction;
    NSInteger	tag;
    MiscCompareEntryFunc sort_entry_func;
    MiscCompareSlotFunc	sort_slot_func;
    MiscSelectionMode	mode;
    int			num_cols;	// Currently active number of
    int			num_rows;	// columns and rows.
    int			max_rows;	// Highwater mark for Cell allocations.
    int			max_cells;
    id*			cells;
    NSView*		pageHeader;
    NSView*		pageFooter;
    MiscCellEditInfo	editInfo;
    BOOL		trackingMouse;
    BOOL		enabled;
    BOOL		lazy;
    BOOL		drawsClippedText;
    id			representedObject;
}

- (id)initWithFrame:(NSRect)frameRect;
- (void)dealloc;


// DELEGATE / TAG -------------------------------------------------------------
@property (assign) id<MiscTableScrollDelegate> delegate;
@property (assign) id<MiscTableScrollDataSource> dataDelegate;

@property NSInteger tag;

@property (retain) id representedObject;


// TARGET / ACTION ------------------------------------------------------------
@property (assign) id target;
@property (assign) id doubleTarget;
@property SEL action;
@property SEL doubleAction;

- (BOOL)sendAction:(SEL)theAction to:(id)theTarget;
- (BOOL)sendAction;
- (BOOL)sendActionIfEnabled;
- (BOOL)sendDoubleAction;
- (BOOL)sendDoubleActionIfEnabled;


// FONT -----------------------------------------------------------------------
- (NSFont*)font;
- (void)setFont:(NSFont*)newFont;
- (void)changeFont:(id)sender;
+ (NSFont*)defaultFont;


// COLOR ----------------------------------------------------------------------
- (NSColor*)backgroundColor;
- (void)setBackgroundColor:(NSColor*)value;		// Sent to all cells.
- (NSColor*)textColor;
- (void)setTextColor:(NSColor*)value;			// Sent to all cells.
- (NSColor*)selectedBackgroundColor;
- (void)setSelectedBackgroundColor:(NSColor*)value;	// Sent to all cells.
- (NSColor*)selectedTextColor;
- (void)setSelectedTextColor:(NSColor*)value;		// Sent to all cells.

- (void)setColor:(NSColor*)value;	// Alias for -setBackgroundColor:
- (NSColor*)color;			// Alias for -backgroundColor

+ (NSColor*)defaultBackgroundColor;
+ (NSColor*)defaultTextColor;
+ (NSColor*)defaultSelectedBackgroundColor;
+ (NSColor*)defaultSelectedTextColor;


// SLOT ORDER -----------------------------------------------------------------
- (NSArray*)slotOrder:(MiscBorderType)b;
- (NSArray*)columnOrder;
- (NSArray*)rowOrder;

- (BOOL)border:(MiscBorderType)b setSlotOrder:(NSArray*)list;
- (BOOL)setColumnOrder:(NSArray*)list;
- (BOOL)setRowOrder:(NSArray*)list;

- (NSString*)slotOrderAsString:(MiscBorderType)b;
- (NSString*)columnOrderAsString;
- (NSString*)rowOrderAsString;

- (BOOL)border:(MiscBorderType)b setSlotOrderFromString:(NSString*)s;
- (BOOL)setColumnOrderFromString:(NSString*)s;
- (BOOL)setRowOrderFromString:(NSString*)s;


// SLOT SIZES -----------------------------------------------------------------
- (NSArray*)slotSizes:(MiscBorderType)b;
- (NSArray*)columnSizes;
- (NSArray*)rowSizes;

- (BOOL)border:(MiscBorderType)b setSlotSizes:(NSArray*)list;
- (BOOL)setColumnSizes:(NSArray*)list;
- (BOOL)setRowSizes:(NSArray*)list;

- (NSString*)slotSizesAsString:(MiscBorderType)b;
- (NSString*)columnSizesAsString;
- (NSString*)rowSizesAsString;

- (BOOL)border:(MiscBorderType)b setSlotSizesFromString:(NSString*)s;
- (BOOL)setColumnSizesFromString:(NSString*)s;
- (BOOL)setRowSizesFromString:(NSString*)s;


// MULTICAST MESSAGES ---------------------------------------------------------
- (void)sendAction:(SEL)aSelector to:(id)anObject forAllCells:(BOOL)flag;

- (int)makeCellsPerformSelector:(SEL)aSel selectedOnly:(BOOL)flag;
- (int)makeCellsPerformSelector:(SEL)aSel with:(id)arg1 selectedOnly:(BOOL)f;
- (int)makeCellsPerformSelector:(SEL)aSel with:(id)arg1 with:(id)arg2
		selectedOnly:(BOOL)flag;

- (int)makeCellsPerformSelector:(SEL)aSel;
- (int)makeCellsPerformSelector:(SEL)aSel with:(id)arg1;
- (int)makeCellsPerformSelector:(SEL)aSel with:(id)arg1 with:(id)arg2;


// FINDING CELLS --------------------------------------------------------------
- (int)border:(MiscBorderType)b slotWithTag:(int)x;
- (int)border:(MiscBorderType)b slotWithRepresentedObject:(id)object;
- (int)columnWithTag:(int)x;
- (int)columnWithRepresentedObject:(id)x;
- (int)rowWithTag:(int)x;
- (int)rowWithRepresentedObject:(id)x;
- (id)cellWithTag:(int)x;
- (id)cellWithRepresentedObject:(id)x;
- (BOOL)getRow:(int*)row column:(int*)col ofCellWithTag:(int)x;
- (BOOL)getRow:(int*)row column:(int*)col ofCellWithRepresentedObject:(id)obj;
- (BOOL)getRow:(int*)row column:(int*)col ofCell:(NSCell*)cell;


// TOTAL SIZE -----------------------------------------------------------------
- (float)totalSize:(MiscBorderType)b;
- (float)totalWidth;
- (float)totalHeight;

- (void)constrainSize;		// Applies constraints, updates views.


// CORNER VIEW ----------------------------------------------------------------
- (NSString*)cornerTitle;
- (void)setCornerTitle:(NSString*)s;


// SLOTS ----------------------------------------------------------------------
- (MiscTableBorder*)border:(MiscBorderType)b;
- (BOOL)slotTitlesOn:(MiscBorderType)b;
- (BOOL)border:(MiscBorderType)b setSlotTitlesOn:(BOOL)on_off;
	// -border:setTitlesOn: Returns YES if changed.
- (MiscTableTitleMode)slotTitleMode:(MiscBorderType)b;
- (void)border:(MiscBorderType)b setSlotTitleMode:(MiscTableTitleMode)x;
- (float)slotTitlesSize:(MiscBorderType)b;
- (void)border:(MiscBorderType)b setSlotTitlesSize:(float)x;

- (void)border:(MiscBorderType)b moveSlot:(int)fromPos toSlot:(int)toPos;
- (int)border:(MiscBorderType)b slotPosition:(int)slot;
- (int)border:(MiscBorderType)b slotAtPosition:(int)pos;
- (NSArray*)border:(MiscBorderType)b physicalToVisual:(NSArray*)list;
- (NSArray*)border:(MiscBorderType)b visualToPhysical:(NSArray*)list;

- (BOOL)sizeableSlots:(MiscBorderType)b;
- (BOOL)draggableSlots:(MiscBorderType)b;
- (BOOL)modifierDragSlots:(MiscBorderType)b;
- (CGFloat)uniformSizeSlots:(MiscBorderType)b;
- (CGFloat)minUniformSizeSlots:(MiscBorderType)b;
- (CGFloat)maxUniformSizeSlots:(MiscBorderType)b;

- (CGFloat)border:(MiscBorderType)b slotAdjustedSize:(int)slot;
- (CGFloat)border:(MiscBorderType)b slotSize:(int)slot;
- (CGFloat)border:(MiscBorderType)b slotMinSize:(int)slot;
- (CGFloat)border:(MiscBorderType)b slotMaxSize:(int)slot;
- (BOOL)border:(MiscBorderType)b slotIsSizeable:(int)slot;
- (BOOL)border:(MiscBorderType)b slotIsAutosize:(int)slot;
- (NSString*)border:(MiscBorderType)b slotTitle:(int)slot;
- (NSInteger)border:(MiscBorderType)b slotTag:(int)slot;
- (id)border:(MiscBorderType)b slotRepresentedObject:(int)slot;
- (MiscTableCellStyle)border:(MiscBorderType)b slotCellType:(int)slot;
- (id)border:(MiscBorderType)b slotCellPrototype:(int)slot;

- (void)border:(MiscBorderType)b setSizeableSlots:(BOOL)flag;
- (void)border:(MiscBorderType)b setDraggableSlots:(BOOL)flag;
- (void)border:(MiscBorderType)b setModifierDragSlots:(BOOL)flag;
- (void)border:(MiscBorderType)b setUniformSizeSlots:(CGFloat)uniform_size;
- (void)border:(MiscBorderType)b setMinUniformSizeSlots:(CGFloat)size;
- (void)border:(MiscBorderType)b setMaxUniformSizeSlots:(CGFloat)size;

- (void)border:(MiscBorderType)b setSlot:(int)n size:(CGFloat)size;
- (void)border:(MiscBorderType)b setSlot:(int)n minSize:(CGFloat)size;
- (void)border:(MiscBorderType)b setSlot:(int)n maxSize:(CGFloat)size;
- (void)border:(MiscBorderType)b setSlot:(int)n sizeable:(BOOL)flag;
- (void)border:(MiscBorderType)b setSlot:(int)n autosize:(BOOL)flag;
- (void)border:(MiscBorderType)b setSlot:(int)n title:(NSString*)title;
- (void)border:(MiscBorderType)b setSlot:(int)n tag:(NSInteger)tag;
- (void)border:(MiscBorderType)b setSlot:(int)n representedObject:(id)object;
- (void)border:(MiscBorderType)b setSlot:(int)n cellType:(MiscTableCellStyle)t;
- (void)border:(MiscBorderType)b setSlot:(int)n cellPrototype:(id)cell;


// COLS -----------------------------------------------------------------------
- (MiscTableBorder*)columnBorder;
@property (readonly) BOOL columnTitlesOn;
- (BOOL)setColumnTitlesOn:(BOOL)on_off;	// Returns YES if changed.
@property MiscTableTitleMode columnTitleMode;
- (float)columnTitlesHeight;
- (void)setColumnTitlesHeight:(float)x;

- (void)moveColumn:(int)fromPos toColumn:(int)toPos;
- (int)columnPosition:(int)col;
- (int)columnAtPosition:(int)pos;

- (float)uniformSizeColumns;
- (float)minUniformSizeColumns;
- (float)maxUniformSizeColumns;
- (BOOL)sizeableColumns;
- (BOOL)draggableColumns;
- (BOOL)modifierDragColumns;
- (float)columnAdjustedSize:(int)col;
- (float)columnSize:(int)col;
- (float)columnMinSize:(int)col;
- (float)columnMaxSize:(int)col;
- (BOOL)columnIsSizeable:(int)col;
- (BOOL)columnIsAutosize:(int)col;
- (NSString*)columnTitle:(int)col;
- (NSInteger)columnTag:(int)col;
- (id)columnRepresentedObject:(int)col;
- (MiscTableCellStyle)columnCellType:(int)col;
- (id)columnCellPrototype:(int)col;

- (void)setSizeableColumns:(BOOL)flag;
- (void)setDraggableColumns:(BOOL)flag;
- (void)setModifierDragColumns:(BOOL)flag;
- (void)setUniformSizeColumns:(float)uniform_size;
- (void)setMinUniformSizeColumns:(float)size;
- (void)setMaxUniformSizeColumns:(float)size;

- (void)setColumn:(int)col size:(float)size;
- (void)setColumn:(int)col minSize:(float)size;
- (void)setColumn:(int)col maxSize:(float)size;
- (void)setColumn:(int)col sizeable:(BOOL)flag;
- (void)setColumn:(int)col autosize:(BOOL)flag;
- (void)setColumn:(int)col title:(NSString*)title;
- (void)setColumn:(int)col tag:(int)tag;
- (void)setColumn:(int)col representedObject:(id)object;
- (void)setColumn:(int)col cellType:(MiscTableCellStyle)type;
- (void)setColumn:(int)col cellPrototype:(id)cell;

- (NSInteger)numberOfVisibleColumns;
- (NSInteger)firstVisibleColumn;
- (NSInteger)lastVisibleColumn;
- (BOOL)columnIsVisible:(NSInteger)n;
- (void)setFirstVisibleColumn:(NSInteger)n;
- (void)setLastVisibleColumn:(NSInteger)n;


// ROWS -----------------------------------------------------------------------
- (MiscTableBorder*)rowBorder;
- (BOOL)rowTitlesOn;
- (BOOL)setRowTitlesOn:(BOOL)on_off;
- (MiscTableTitleMode)rowTitleMode;
- (void)setRowTitleMode:(MiscTableTitleMode)x;
- (float)rowTitlesWidth;
- (void)setRowTitlesWidth:(float)x;

- (void)moveRow:(int)fromPos toRow:(int)toPos;
- (int)rowPosition:(int)row;
- (int)rowAtPosition:(int)pos;

@property BOOL sizeableRows;
@property BOOL draggableRows;
@property BOOL modifierDragRows;
@property CGFloat uniformSizeRows;
@property CGFloat minUniformSizeRows;
@property CGFloat maxUniformSizeRows;
- (CGFloat)rowAdjustedSize:(NSInteger)row;
- (CGFloat)rowSize:(NSInteger)row;
- (CGFloat)rowMinSize:(NSInteger)row;
- (CGFloat)rowMaxSize:(NSInteger)row;
- (BOOL)rowIsSizeable:(NSInteger)row;
- (BOOL)rowIsAutosize:(NSInteger)row;
- (NSString*)rowTitle:(NSInteger)row;
- (NSInteger)rowTag:(NSInteger)row;
- (id)rowRepresentedObject:(NSInteger)row;
- (MiscTableCellStyle)rowCellType:(NSInteger)row;
- (id)rowCellPrototype:(NSInteger)row;

- (void)setRow:(NSInteger)row size:(CGFloat)size;
- (void)setRow:(NSInteger)row minSize:(CGFloat)size;
- (void)setRow:(NSInteger)row maxSize:(CGFloat)size;
- (void)setRow:(NSInteger)row sizeable:(BOOL)flag;
- (void)setRow:(NSInteger)row autosize:(BOOL)flag;
- (void)setRow:(NSInteger)row title:(NSString*)title;
- (void)setRow:(NSInteger)row tag:(NSInteger)tag;
- (void)setRow:(NSInteger)row representedObject:(id)object;
- (void)setRow:(NSInteger)row cellType:(MiscTableCellStyle)type;
- (void)setRow:(NSInteger)row cellPrototype:(id)cell;

- (NSInteger)numberOfVisibleRows;
- (NSInteger)firstVisibleRow;
- (NSInteger)lastVisibleRow;
- (BOOL)rowIsVisible:(NSInteger)n;
- (void)setFirstVisibleRow:(NSInteger)n;
- (void)setLastVisibleRow:(NSInteger)n;


// DRAWING --------------------------------------------------------------------
- (NSRect)documentClipRect;

- (void)drawCellAtRow:(NSInteger)row column:(NSInteger)col;	// Physical coords

- (void)drawRow:(NSInteger)row;				// Physical coords
- (void)drawColumn:(NSInteger)col;				// Physical coords
- (void)border:(MiscBorderType)b drawSlot:(int)n;

- (NSInteger)numberOfVisibleSlots:(MiscBorderType)b;
- (NSInteger)firstVisibleSlot:(MiscBorderType)b;
- (NSInteger)lastVisibleSlot:(MiscBorderType)b;
- (BOOL)border:(MiscBorderType)b slotIsVisible:(NSInteger)n;
- (void)border:(MiscBorderType)b setFirstVisibleSlot:(NSInteger)n;
- (void)border:(MiscBorderType)b setLastVisibleSlot:(NSInteger)n;

- (void)scrollCellToVisibleAtRow:(NSInteger)row column:(NSInteger)col; // Physical coords
- (void)scrollRowToVisible:(NSInteger)row;			// Physical coord
- (void)scrollColumnToVisible:(NSInteger)col;			// Physical coord
- (void)scrollSelectionToVisible;

- (void)border:(MiscBorderType)b drawSlotTitle:(NSInteger)n;
- (void)drawRowTitle:(NSInteger)n;
- (void)drawColumnTitle:(NSInteger)n;

- (void)sizeToCells;
- (void)sizeToFit;

@property BOOL drawsClippedText;


// INTERNAL COMMUNICATIONS ON USER-ACTIONS FOR SUBCLASSES ONLY ----------------
// Protected: BorderView -> TableScroll
- (void)border:(MiscBorderType)b slotDragged:(int)fromPos toSlot:(int)toPos;
- (void)border:(MiscBorderType)b slotSortReversed:(int)n;
- (void)border:(MiscBorderType)b slotResized:(int)n;
// Protected: TableView -> TableScroll
- (void)didBecomeFirstResponder;
- (void)didResignFirstResponder;


@end


// SELECTION ------------------------------------------------------------------
@interface MiscTableScroll(Selection)
- (MiscSelectionMode)selectionMode;
- (void)setSelectionMode:(MiscSelectionMode)x;

- (BOOL)hasSlotSelection:(MiscBorderType)b;
- (BOOL)hasRowSelection;
- (BOOL)hasColumnSelection;
- (BOOL)hasMultipleSlotSelection:(MiscBorderType)b;
- (BOOL)hasMultipleRowSelection;
- (BOOL)hasMultipleColumnSelection;
- (int)numberOfSelectedSlots:(MiscBorderType)b;
- (int)numberOfSelectedRows;
- (int)numberOfSelectedColumns;
- (BOOL)border:(MiscBorderType)b slotIsSelected:(MiscCoord_P)slot;
- (BOOL)rowIsSelected:(MiscCoord_P)row;
- (BOOL)columnIsSelected:(MiscCoord_P)col;
- (BOOL)cellIsSelectedAtRow:(MiscCoord_P)row column:(MiscCoord_P)col;

- (MiscCoord_P)selectedSlot:(MiscBorderType)b;
- (MiscCoord_P)selectedRow;
- (MiscCoord_P)selectedColumn;
- (id)selectedCell;
- (NSArray*)selectedSlotTags:(MiscBorderType)b;
- (NSArray*)selectedRowTags;
- (NSArray*)selectedColumnTags;
- (NSArray*)selectedSlots:(MiscBorderType)b;
- (NSArray*)selectedRows;
- (NSArray*)selectedColumns;

- (void)border:(MiscBorderType)b selectSlot:(MiscCoord_P)slot
	byExtendingSelection:(BOOL)flag;
- (void)border:(MiscBorderType)b selectSlot:(MiscCoord_P)slot;
- (void)selectRow:(MiscCoord_P)row byExtendingSelection:(BOOL)flag;
- (void)selectRow:(MiscCoord_P)row;
- (void)selectColumn:(MiscCoord_P)col byExtendingSelection:(BOOL)flag;
- (void)selectColumn:(MiscCoord_P)col;
- (void)border:(MiscBorderType)b selectSlotsWithTags:(NSArray*)tags
	 byExtendingSelection:(BOOL)flag;
- (void)border:(MiscBorderType)b selectSlotsWithTags:(NSArray*)tags;
- (void)selectRowsWithTags:(NSArray*)tags byExtendingSelection:(BOOL)flag;
- (void)selectRowsWithTags:(NSArray*)tags;
- (void)selectColumnsWithTags:(NSArray*)tags byExtendingSelection:(BOOL)flag;
- (void)selectColumnsWithTags:(NSArray*)tags;
- (void)border:(MiscBorderType)b selectSlots:(NSArray*)slots
	 byExtendingSelection:(BOOL)flag;
- (void)border:(MiscBorderType)b selectSlots:(NSArray*)slots;
- (void)selectRows:(NSArray*)rows byExtendingSelection:(BOOL)flag;
- (void)selectRows:(NSArray*)rows;
- (void)selectColumns:(NSArray*)cols byExtendingSelection:(BOOL)flag;
- (void)selectColumns:(NSArray*)cols;
- (void)selectAllSlots:(MiscBorderType)b;
- (void)selectAllRows;
- (void)selectAllColumns;
- (void)selectAll:(id)sender;	// -selectAllRows and sends action to target.

- (void)border:(MiscBorderType)b deselectSlot:(MiscCoord_P)slot;
- (void)deselectRow:(MiscCoord_P)row;
- (void)deselectColumn:(MiscCoord_P)col;
- (void)border:(MiscBorderType)b deselectSlotsWithTags:(NSArray*)tags;
- (void)deselectRowsWithTags:(NSArray*)tags;
- (void)deselectColumnsWithTags:(NSArray*)tags;
- (void)border:(MiscBorderType)b deselectSlots:(NSArray*)slots;
- (void)deselectRows:(NSArray*)rows;
- (void)deselectColumns:(NSArray*)cols;
- (void)clearSlotSelection:(MiscBorderType)b;
- (void)clearRowSelection;
- (void)clearColumnSelection;
- (void)clearSelection;
- (void)deselectAll:(id)sender;	// -clearSelection and sends action to target.

- (void)selectionChanged;	// Subclasses may want to override.


// MOUSE & KEYBOARD TRACKING (SELECTION ORIENTATION) --------------------------
- (void)setSelectsByRows:(BOOL)flag;
- (BOOL)selectsByRows;

- (BOOL)isTrackingMouse;
- (MiscCoord_P)clickedSlot:(MiscBorderType)b;
- (MiscCoord_P)clickedRow;
- (MiscCoord_P)clickedColumn;
- (id)clickedCell;


// KEYBOARD CURSOR ------------------------------------------------------------
- (MiscCoord_P)cursorSlot:(MiscBorderType)b;
- (MiscCoord_P)cursorRow;
- (MiscCoord_P)cursorColumn;
- (void)border:(MiscBorderType)b setCursorSlot:(MiscCoord_P)slot;
- (void)setCursorRow:(MiscCoord_P)row;
- (void)setCursorColumn:(MiscCoord_P)col;
- (void)clearCursorSlot:(MiscBorderType)b;
- (void)clearCursorRow;
- (void)clearCursorColumn;
- (void)clearCursor;
- (BOOL)hasValidCursorSlot:(MiscBorderType)b;
- (BOOL)hasValidCursorRow;
- (BOOL)hasValidCursorColumn;
- (void)disableCursor;		// Can nest.
- (void)enableCursor;
- (BOOL)isCursorEnabled;


// ENABLED --------------------------------------------------------------------
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)flag;
@end


// SORTING --------------------------------------------------------------------
@interface MiscTableScroll(Sort)

- (MiscCompareSlotFunc)compareSlotFunction;
- (void)setCompareSlotFunction:(MiscCompareSlotFunc)f;

- (void)sortInfoInit:(MiscSlotSortInfo*)ip border:(MiscBorderType)b;
- (void)sortInfoDone:(MiscSlotSortInfo*)ip;

// Slots
- (BOOL)autoSortSlots:(MiscBorderType)b;
- (void)border:(MiscBorderType)b setAutoSortSlots:(BOOL)flag;
- (NSArray*)slotSortVector:(MiscBorderType)b;
- (void)border:(MiscBorderType)b setSlotSortVector:(NSArray*)v;

- (void)sortSlots:(MiscBorderType)b;
- (BOOL)slotsAreSorted:(MiscBorderType)b;
- (BOOL)border:(MiscBorderType)b sortSlot:(int)n;
- (BOOL)border:(MiscBorderType)b slotIsSorted:(int)n;

- (int)border:(MiscBorderType)b compareSlots:(int)slot1 :(int)slot2
	info:(MiscSlotSortInfo*)ip;
- (int)border:(MiscBorderType)b compareSlots:(int)slot1 :(int)slot2;


- (MiscCompareEntryFunc)border:(MiscBorderType)b slotSortFunction:(int)n;
- (MiscSortDirection)border:(MiscBorderType)b slotSortDirection:(int)n;
- (MiscSortType)border:(MiscBorderType)b slotSortType:(int)n;
- (void)border:(MiscBorderType)b setSlot:(int)n
		sortFunction:(MiscCompareEntryFunc)x;
- (void)border:(MiscBorderType)b setSlot:(int)n
		sortDirection:(MiscSortDirection)x;
- (void)border:(MiscBorderType)b setSlot:(int)n
		sortType:(MiscSortType)x;

// Cols
- (BOOL)autoSortColumns;
- (void)setAutoSortColumns:(BOOL)flag;
- (NSArray*)columnSortVector;
- (void)setColumnSortVector:(NSArray*)v;

- (void)sortColumns;
- (BOOL)columnsAreSorted;
- (BOOL)sortColumn:(int)n;
- (BOOL)columnIsSorted:(int)n;
- (int)compareColumns:(int)c1 :(int)c2 info:(MiscSlotSortInfo*)ip;
- (int)compareColumns:(int)c1 :(int)c2;

- (MiscCompareEntryFunc)columnSortFunction:(int)n;
- (MiscSortDirection)columnSortDirection:(int)n;
- (MiscSortType)columnSortType:(int)n;
- (void)setColumn:(int)n sortFunction:(MiscCompareEntryFunc)x;
- (void)setColumn:(int)n sortDirection:(MiscSortDirection)x;
- (void)setColumn:(int)n sortType:(MiscSortType)x;

// Rows
- (BOOL)autoSortRows;
- (void)setAutoSortRows:(BOOL)flag;
- (NSArray*)rowSortVector;
- (void)setRowSortVector:(NSArray*)v;

- (void)sortRows;
- (BOOL)rowsAreSorted;
- (BOOL)sortRow:(int)n;
- (BOOL)rowIsSorted:(int)n;
- (int)compareRows:(int)r1 :(int)r2 info:(MiscSlotSortInfo*)ip;
- (int)compareRows:(int)r1 :(int)r2;

- (MiscCompareEntryFunc)rowSortFunction:(int)n;
- (MiscSortDirection)rowSortDirection:(int)n;
- (MiscSortType)rowSortType:(int)n;
- (void)setRow:(int)n sortFunction:(MiscCompareEntryFunc)x;
- (void)setRow:(int)n sortDirection:(MiscSortDirection)x;
- (void)setRow:(int)n sortType:(MiscSortType)x;
@end


// DATA MANIPULATION ----------------------------------------------------------
@interface MiscTableScroll(Data)
- (BOOL)isLazy;
- (void)setLazy:(BOOL)flag;

- (id)cellAtRow:(int)row column:(int)col;

// Lazy mode tables that perform multiple-buffering:
- (int)bufferCount;

// Lazy mode asks delegate/dataDelegate first then uses cellAtRow:column:
// Eager mode goes straight to cellAtRow:column:
- (int)tagAtRow:(int)row column:(int)col;
- (int)intValueAtRow:(int)row column:(int)col;
- (float)floatValueAtRow:(int)row column:(int)col;
- (double)doubleValueAtRow:(int)row column:(int)col;
- (NSString*)stringValueAtRow:(int)row column:(int)col;
// For ButtonCells.
- (NSString*)titleAtRow:(int)row column:(int)col;
- (int)stateAtRow:(int)row column:(int)col;

// Invoke delegate methods if possible.
- (id)reviveCell:(id)cell atRow:(int)row column:(int)col;
- (id)retireCell:(id)cell atRow:(int)row column:(int)col;

// Builtin default implementation.
- (id)doReviveCell:(id)cell atRow:(int)row column:(int)col;
- (id)doRetireCell:(id)cell atRow:(int)row column:(int)col;

- (void)addSlot:(MiscBorderType)b;
- (void)border:(MiscBorderType)b insertSlot:(int)pos;
- (void)border:(MiscBorderType)b removeSlot:(int)pos;
- (int)numberOfSlots:(MiscBorderType)b;

- (void)addColumn;
- (void)insertColumn:(int)pos;
- (void)removeColumn:(int)pos;
- (int)numberOfColumns;

- (void)addRow;
- (void)insertRow:(int)pos;
- (void)removeRow:(int)pos;
- (int)numberOfRows;

- (void)renewRows:(int)count;
- (void)empty;					// [self renewRows:0];
- (void)emptyAndReleaseCells;
@end


// READ / WRITE ---------------------------------------------------------------
@interface MiscTableScroll(IO) <NSCoding>
- (void)awakeFromNib;
- (id)initWithCoder:(NSCoder*)coder;
- (void)encodeWithCoder:(NSCoder*)coder;
@end


// PASTEBOARD SUPPORT ---------------------------------------------------------
@interface MiscTableScroll(Pasteboard)
- (void)copy:(id)sender;
- (void)cut:(id)sender;
- (id)validRequestorForSendType:(NSString*)s returnType:(NSString*)r;
- (id)builtinValidRequestorForSendType:(NSString*)s returnType:(NSString*)r;
- (BOOL)canWritePboardType:(NSString*)type;
- (BOOL)builtinCanWritePboardType:(NSString*)type;
- (BOOL)writeSelectionToPasteboard:(NSPasteboard*)pboard types:(NSArray*)types;
- (BOOL)builtinWriteSelectionToPasteboard:(NSPasteboard*)pboard
	types:(NSArray*)types;
- (NSString*)stringForPboardType:(NSString*)type;
- (NSString*)builtinStringForPboardType:(NSString*)type;
- (NSString*)stringForNSStringPboardType;
- (NSString*)stringForNSTabularTextPboardType;
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pboard;
- (BOOL)builtinReadSelectionFromPasteboard:(NSPasteboard*)pboard;
- (void)builtinRegisterServicesTypes;
- (void)registerServicesTypes;
@end


// INCREMENTAL SEARCH ---------------------------------------------------------
@interface MiscTableScroll(IncrementalSearch)
- (BOOL)incrementalSearch:(NSEvent*)p;
- (BOOL)doIncrementalSearch:(NSEvent*)p column:(int)col;
- (BOOL)getIncrementalSearchColumn:(int*)col;
- (BOOL)doGetIncrementalSearchColumn:(int*)col;
@end


// KEYBOARD EVENTS ------------------------------------------------------------
@interface MiscTableScroll(Keyboard)
- (void)keyDown:(NSEvent*)event;
@end


// EDITING --------------------------------------------------------------------
@interface MiscTableScroll(Edit)
- (NSRect)cellFrameAtRow:(int)row column:(int)col;	// Physical coords
- (BOOL)getRow:(int*)row column:(int*)col forPoint:(NSPoint)point; // Physical.
- (BOOL)getPreviousEditRow:(MiscCoord_P*)p_row column:(MiscCoord_P*)p_col;
- (BOOL)getNextEditRow:(MiscCoord_P*)p_row column:(MiscCoord_P*)p_col;
- (BOOL)getNext:(BOOL)foreward
	editRow:(MiscCoord_P*)p_row column:(MiscCoord_P*)p_col;
- (BOOL)isEditing;
- (BOOL)finishEditing;		// Normal, conditional termination.
- (BOOL)abortEditing;		// Forcibly abort the editing session.
- (void)suspendEditing;		// Temporary suspension while resizing.
- (void)resumeEditing;		// Resume editing after resizing.
- (void)textDidEndEditing:(NSNotification*)notification;
- (void)textDidBeginEditing:(NSNotification*)notification;
- (void)textDidChange:(NSNotification*)notification;
- (BOOL)textShouldBeginEditing:(NSText*)sender;
- (BOOL)textShouldEndEditing:(NSText*)sender;
- (void)edit:(NSEvent*)ev atRow:(MiscCoord_P)row column:(MiscCoord_P)col;
- (BOOL)canEdit:(NSEvent*)ev atRow:(MiscCoord_P)row column:(MiscCoord_P)col;
- (BOOL)editIfAble:(NSEvent*)ev atRow:(MiscCoord_P)row column:(MiscCoord_P)col;
- (void)editCellAtRow:(MiscCoord_P)row column:(MiscCoord_P)col;
@end


// PRINTING -------------------------------------------------------------------
@interface MiscTableScroll(Print)
- (void)print:(id)sender;
- (MiscTablePrintInfo const*)getPrintInfo;
- (NSView*)getPageHeader;
- (NSView*)getPageFooter;
- (void)setPageHeader:(NSView*)obj;
- (void)setPageFooter:(NSView*)obj;
@end


// DELEGATE PROTOCOL ----------------------------------------------------------
@protocol MiscTableScrollDelegate <NSObject>
@optional
- (BOOL)tableScroll:(MiscTableScroll*)scroll
	getIncrementalSearchColumn:(int*)col;

- (id)tableScroll:(MiscTableScroll*)scroll
	border:(MiscBorderType)b slotPrototype:(int)slot;
- (NSString*)tableScroll:(MiscTableScroll*)scroll
	border:(MiscBorderType)b slotTitle:(int)slot;

- (BOOL)tableScroll:(MiscTableScroll*)scroll
	allowDragOperationAtRow:(NSInteger)row column:(NSInteger)col;
- (void)tableScroll:(MiscTableScroll*)scroll
	preparePasteboard:(NSPasteboard*)pb
	forDragOperationAtRow:(NSInteger)row column:(NSInteger)col;
- (NSImage*)tableScroll:(MiscTableScroll*)scroll
	imageForDragOperationAtRow:(NSInteger)row column:(NSInteger)col;
- (unsigned int)tableScroll:(MiscTableScroll*)scroll
	draggingSourceOperationMaskForLocal:(BOOL)isLocal;
- (BOOL)tableScrollIgnoreModifierKeysWhileDragging:(MiscTableScroll*)scroll;
- (BOOL)tableScroll:(MiscTableScroll*)scroll
	shouldDelayWindowOrderingForEvent:(NSEvent*)event;

- (void)tableScrollRegisterServicesTypes:(MiscTableScroll*)scroll;
- (id)tableScroll:(MiscTableScroll*)scroll
	validRequestorForSendType:(NSString*)sendType
	returnType:(NSString*)returnType;
- (BOOL)tableScroll:(MiscTableScroll*)scroll 
	canWritePboardType:(NSString*)type;
- (NSString*)tableScroll:(MiscTableScroll*)scroll
	stringForPboardType:(NSString*)type;
- (BOOL)tableScroll:(MiscTableScroll*)scroll
	writeSelectionToPasteboard:(NSPasteboard*)pboard types:(NSArray*)types;
- (BOOL)tableScroll:(MiscTableScroll*)scroll
	readSelectionFromPasteboard:(NSPasteboard*)pboard;

- (BOOL)tableScroll:(MiscTableScroll*)scroll
	canEdit:(NSEvent*)ev atRow:(NSInteger)row column:(NSInteger)col;
- (void)tableScroll:(MiscTableScroll*)scroll
	edit:(NSEvent*)ev atRow:(NSInteger)row column:(NSInteger)col;
- (void)tableScroll:(MiscTableScroll*)scroll
	abortEditAtRow:(NSInteger)row column:(NSInteger)col;
//@end


// DELEGATE NOTIFICATIONS PROTOCOL --------------------------------------------
//@interface NSObject(MiscTableScrollNotifications)
- (void)tableScrollSlotDragged:(NSNotification*)n;
- (void)tableScrollSlotSortReversed:(NSNotification*)n;
- (void)tableScrollSlotResized:(NSNotification*)n;

- (void)tableScrollChangeFont:(NSNotification*)n;
- (void)tableScrollFontChanged:(NSNotification*)n;

- (void)tableScrollBackgroundColorChanged:(NSNotification*)n;
- (void)tableScrollSelectedBackgroundColorChanged:(NSNotification*)n;
- (void)tableScrollSelectedTextColorChanged:(NSNotification*)n;
- (void)tableScrollTextColorChanged:(NSNotification*)n;

- (void)tableScrollWillPrint:(NSNotification*)n;
- (void)tableScrollDidPrint:(NSNotification*)n;
- (void)tableScrollWillPrintPageHeader:(NSNotification*)n;
- (void)tableScrollWillPrintPageFooter:(NSNotification*)n;

- (void)tableScrollWillEdit:(NSNotification*)n;
- (void)tableScrollDidEdit:(NSNotification*)n;

- (void)tableScrollDidBecomeFirstResponder:(NSNotification*)n;
- (void)tableScrollDidResignFirstResponder:(NSNotification*)n;
@end


// DATA DELEGATE PROTOCOL -----------------------------------------------------
@protocol MiscTableScrollDataSource <NSObject>
@optional
- (int)tableScrollBufferCount:(MiscTableScroll*)scroll;

- (id)tableScroll:(MiscTableScroll*)scroll cellAtRow:(NSInteger)row column:(NSInteger)col;
- (id)tableScroll:(MiscTableScroll*)scroll reviveCell:(id)cell
	atRow:(NSInteger)row column:(NSInteger)col;
- (id)tableScroll:(MiscTableScroll*)scroll retireCell:(id)cell
	atRow:(NSInteger)row column:(NSInteger)col;

- (NSInteger)tableScroll:(MiscTableScroll*)scroll
	tagAtRow:(NSInteger)row column:(NSInteger)col;
- (int)tableScroll:(MiscTableScroll*)scroll
	intValueAtRow:(NSInteger)row column:(NSInteger)col;
- (float)tableScroll:(MiscTableScroll*)scroll
	floatValueAtRow:(NSInteger)row column:(NSInteger)col;
- (double)tableScroll:(MiscTableScroll*)scroll
	doubleValueAtRow:(NSInteger)row column:(NSInteger)col;
- (NSString*)tableScroll:(MiscTableScroll*)scroll
	stringValueAtRow:(NSInteger)row column:(NSInteger)col;
- (NSString*)tableScroll:(MiscTableScroll*)scroll
	titleAtRow:(NSInteger)row column:(NSInteger)col;
- (NSControlStateValue)tableScroll:(MiscTableScroll*)scroll
	stateAtRow:(NSInteger)row column:(NSInteger)col;

- (BOOL)tableScroll:(MiscTableScroll*)scroll
	setStringValue:(NSString*)s atRow:(NSInteger)row column:(NSInteger)col;
@end


// DATA CELL PROTOCOL ---------------------------------------------------------
@interface NSObject(MiscTableScrollDataCell)
- (id)tableScroll:(MiscTableScroll*)scroll
	reviveAtRow:(int)row column:(int)col;
- (id)tableScroll:(MiscTableScroll*)scroll
	retireAtRow:(int)row column:(int)col;
@end


// NOTIFICATIONS --------------------------------------------------------------
#define MISC_NOTIFICATION(Q) \
    MISC_TABLE_SCROLL_EXTERN NSNotificationName const MiscTableScroll##Q##Notification

MISC_NOTIFICATION( SlotDragged );
MISC_NOTIFICATION( SlotSortReversed );
MISC_NOTIFICATION( SlotResized );
MISC_NOTIFICATION( ChangeFont );
MISC_NOTIFICATION( FontChanged );
MISC_NOTIFICATION( BackgroundColorChanged );
MISC_NOTIFICATION( SelectedBackgroundColorChanged );
MISC_NOTIFICATION( SelectedTextColorChanged );
MISC_NOTIFICATION( TextColorChanged );
MISC_NOTIFICATION( WillPrint );
MISC_NOTIFICATION( DidPrint );
MISC_NOTIFICATION( WillPrintPageHeader );
MISC_NOTIFICATION( WillPrintPageFooter );
MISC_NOTIFICATION( WillEdit );
MISC_NOTIFICATION( DidEdit );
MISC_NOTIFICATION( DidBecomeFirstResponder );
MISC_NOTIFICATION( DidResignFirstResponder );

#undef MISC_NOTIFICATION

#endif // __MiscTableScroll_h
