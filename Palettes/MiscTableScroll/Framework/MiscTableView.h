#ifndef __MiscTableView_h
#define __MiscTableView_h
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
// MiscTableView.h
//
//	General-purpose 2-D display object that works with the
//	MiscTableScroll to provide row/column sizing and dragging.
//
//	This object is responsible for drawing, mouse and keyboard
//	events in the content portion of the display.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableView.h,v 1.18 99/06/15 03:56:30 sunshine Exp $
// $Log:	MiscTableView.h,v $
// Revision 1.18  99/06/15  03:56:30  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Methods renamed: trackBy: to setSelectsByRows:, trackingBy to selectsByRows
// Page header and footer are now strongly typed as NSView rather than id.
// The strong typing extends to the Java environment more cleanly.
// 
// Revision 1.17  1998/03/22 13:13:03  sunshine
// v133.1: Now prints corner view.
//
//  Revision 1.16  97/11/23  07:41:24  sunshine
//  v130.1: Broke off MiscTableViewDrag.M and MiscTableViewCursor.M
//-----------------------------------------------------------------------------
#import <AppKit/NSView.h>
#import <MiscTableScroll/MiscTableTypes.h>

@class MiscBorderView, MiscCornerView, MiscMouseTracker, MiscTableScroll;
@class NSCell, NSText;
class MiscSparseSet;
class MiscTableBorder;

struct MiscTSPageBreak
{
    MiscPixels		offset;
    MiscPixels		size;
    MiscCoord_V		first;	// One's comp if started on earlier page.
    MiscCoord_V		last;	// One's comp if ends on later page.
};

struct MiscTSPageImages
{
    NSImage*		page_header;
    NSImage*		page_footer;
    NSImage*		col_titles;
    NSImage*		row_titles;
    NSImage*		corner_view;
};

struct MiscTablePages
{
    MiscTablePrintInfo	info;
    MiscTSPageBreak*	col_breaks;
    MiscTSPageBreak*	row_breaks;
    MiscTSPageImages*	images;
    NSView*		pageHeader;
    NSView*		pageFooter;
    MiscBorderView*	colTitles;
    MiscBorderView*	rowTitles;
    MiscCornerView*	cornerView;
    float		page_header_height;
    float		page_footer_height;
    float		col_titles_height;
    float		row_titles_width;
};


@interface MiscTableView : NSView
{
    MiscTableBorder*	colBorder;
    MiscTableBorder*	rowBorder;
    MiscBorderType	trackerBorder;
    MiscMouseTracker*	tracker;
    MiscSparseSet*	oldColSel;
    MiscSparseSet*	oldRowSel;
    MiscTablePages*	pages;
    unsigned int	inhibitCursor;
    MiscCoord_V		cursorSlot;
}

- (id)initWithFrame:(NSRect)r
	scroll:(MiscTableScroll*)s
	colInfo:(MiscTableBorder*)colBorder
	rowInfo:(MiscTableBorder*)rowBorder;
- (void)adjustSize;
- (id)scroll;

- (NSRect)cellInsideAtRow:(MiscCoord_P)row column:(MiscCoord_P)col;
- (NSRect)cellFrameAtRow:(int)row column:(int)col;	// Physical coords
- (BOOL)getRow:(int*)row column:(int*)col		// Physical coords
	forPoint:(NSPoint)point;

- (void)drawCellAtRow:(int)row column:(int)col;		// Physical coords
- (void)drawRow:(int)row;				// Physical coord
- (void)drawColumn:(int)col;				// Physical coord

- (void)scrollCellToVisibleAtRow:(int)row column:(int)col; // Physical coords
- (void)scrollRowToVisible:(int)row;			// Physical coord
- (void)scrollColumnToVisible:(int)col;			// Physical coord

- (NSInteger)numberOfVisibleSlots:(MiscBorderType)b;		// All physical coords.
- (NSInteger)firstVisibleSlot:(MiscBorderType)b;
- (NSInteger)lastVisibleSlot:(MiscBorderType)b;
- (BOOL)border:(MiscBorderType)b slotIsVisible:(NSInteger)n;
- (void)border:(MiscBorderType)b setFirstVisibleSlot:(NSInteger)n;
- (void)border:(MiscBorderType)b setLastVisibleSlot:(NSInteger)n;

- (void)setSelectionMode:(MiscSelectionMode)mode;
- (void)selectionChanged;
- (void)resetSelection;
- (void)setSelectsByRows:(BOOL)flag;
- (BOOL)selectsByRows;

- (BOOL)sendAction:(SEL)cmd to:(id)obj;
- (void)mouseDown:(NSEvent*)event;

- (void)superPrint:(id)sender;	// See implementation for explanation.

@end

// KEYBOARD CURSOR ------------------------------------------------------------
@interface MiscTableView(Cursor)
- (void)reflectCursor;

- (void)disableCursor;		// Can nest.
- (void)enableCursor;
- (BOOL)isCursorEnabled;
- (void)drawCursor;
- (void)eraseCursor;
- (BOOL)shouldDrawCursor;

- (void)keyboardSelect:(NSEvent*)p;
- (void)moveCursorBy:(int)delta;
@end

// PRINTING -------------------------------------------------------------------
@interface MiscTableView(Print)
- (void)print:(id)sender;
- (BOOL)knowsPagesFirst:(int*)first last:(int*)last;
- (NSRect)rectForPage:(int)n;
- (NSPoint)locationOfPrintRect:(NSRect)rect;
- (void)drawPageBorderWithSize:(NSSize)size;
- (MiscTablePrintInfo const*)getPrintInfo;
@end

#endif // __MiscTableView_h
