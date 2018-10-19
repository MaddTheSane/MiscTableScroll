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
// MiscTableScroll.M
//
//	ScrollView class that displays a 2-D table of cells.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScroll.M,v 1.47 99/06/15 06:08:02 sunshine Exp $
// $Log:	MiscTableScroll.M,v $
// Revision 1.47  99/06/15  06:08:02  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows. Exposed to Java.
// Fixed bug: -sizeToFit was not taking intercell grid spacing into account.
// Fixed bug: -sizeToFit was incorrectly checking if cells responded to
// -cellSize: rather than -cellSize.  Consequently sizing failed completely.
// Fixed bug: When registering delegate to receive standard control-text-
// editing notifications, was incorrectly specifying MiscTableView as sender
// even though MiscTableScroll actually sends them.  Consequently delegates
// were never receiving these notifications.
// Fixed bug: -changeFont: was sending -convertFont: directly to the shared
// NSFontManager rather than the "sender" as documented.
// Removed unnecessary header #imports.
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
// 
// Revision 1.46  1998/03/29 23:53:12  sunshine
// v138.1: Removed useless 'if' from -borderSetSlotOrder:.
// Fixed bug: Wasn't checking -canDraw before applying -lockFocus in:
// -drawCellAtRow:column:, -drawRow:, -drawColumn:, -drawSlotTitle:.
// Now uses NSColor's "system" colors for text, background, selected text,
// selected background by default.
// Worked around OPENSTEP 4.2 for NT bug where compiler crashes when sending
// a message to 'super' from within a category.  Bug afflicted
// MiscTableScrollIO.M.
//
// Revision 1.45  98/03/23  21:41:42  sunshine
// v137.1: -border:setSlotOrder: now accepts a null pointer or empty list to
// "unsort" the slots.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import <MiscTableScroll/MiscTableCell.h>
#import "MiscColView.h"
#import "MiscCornerView.h"
#import "MiscRowView.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import "MiscTableView.h"
#import	<new.h>

extern "Objective-C" {
#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSClipView.h>
#import <AppKit/NSControl.h>	// Control-text notifications
#import <AppKit/NSFont.h>
#import <AppKit/NSFontManager.h>
#import <AppKit/NSScroller.h>
}

typedef MiscDelegateFlags DF;

#define MISC_STRINGIFY(Q) #Q
#define MISC_NOTIFICATION(Q) NSString* const MiscTableScroll##Q##Notification \
    = @MISC_STRINGIFY(MiscTableScroll##Q##Notification)

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
#undef MISC_STRINGIFY

//-----------------------------------------------------------------------------
// Delegate Notifications
//-----------------------------------------------------------------------------
static NSArray* DEL_NOTIFICATIONS = 0;	// Array of MiscNotification objects.

@interface MiscNotification : NSObject
    {
    DF::Selector selector;
    NSString* name;
    }
+ (MiscNotification*)notificationWithSelector:(DF::Selector)s
	name:(NSString*)n;
- (id)initWithSelector:(DF::Selector)s name:(NSString*)n;
- (void)dealloc;
- (DF::Selector)selector;
- (NSString*)name;
@end

@implementation MiscNotification
+ (MiscNotification*)notificationWithSelector:(DF::Selector)s name:(NSString*)n
    { return [[[self alloc] initWithSelector:s name:n] autorelease]; }
- (id)initWithSelector:(DF::Selector)s name:(NSString*)n
    { [super init]; selector = s; name = [n retain]; return self; }
- (void)dealloc { [name release]; [super dealloc]; }
- (DF::Selector)selector { return selector; }
- (NSString*)name { return name; }
@end


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableScroll

- (int)tag		{ return tag; }
- (void)setTag:(int)x	{ tag = x; }

- (id)representedObject	{ return representedObject; }
- (void)setRepresentedObject:(id)p
    {
    if (p != representedObject)
	{
	[representedObject release];
	representedObject = [p retain];
	}
    }

//-----------------------------------------------------------------------------
// + registerNotifications
//-----------------------------------------------------------------------------
+ (void)registerNotifications
    {
#define NOTIFY(X,Y) \
    [MiscNotification notificationWithSelector:(DF::DEL_ ## X) \
    name:Y ## Notification]
#define TX_NOTIFY(X,Y) NOTIFY(X, NSControlText ## Y)
#define MY_NOTIFY(X,Y) NOTIFY(X, MiscTableScroll ## Y)
    DEL_NOTIFICATIONS = [[NSArray arrayWithObjects:
	MY_NOTIFY( SLOT_DRAGGED, SlotDragged ),
	MY_NOTIFY( SLOT_REVERSED, SlotSortReversed ),
	MY_NOTIFY( SLOT_RESIZED, SlotResized ),
	MY_NOTIFY( CHANGE_FONT, ChangeFont ),
	MY_NOTIFY( FONT_CHANGED, FontChanged ),
	MY_NOTIFY( BACK_COLOR_CHANGED, BackgroundColorChanged ),
	MY_NOTIFY( BACK_SEL_COLOR_CHANGED, SelectedBackgroundColorChanged ),
	MY_NOTIFY( BACK_SEL_COLOR_CHANGED, SelectedTextColorChanged ),
	MY_NOTIFY( TEXT_COLOR_CHANGED, TextColorChanged ),
	MY_NOTIFY( WILL_PRINT, WillPrint ),
	MY_NOTIFY( DID_PRINT, DidPrint ),
	MY_NOTIFY( PRINT_PAGE_HEADER, WillPrintPageHeader ),
	MY_NOTIFY( PRINT_PAGE_FOOTER, WillPrintPageFooter ),
	MY_NOTIFY( WILL_EDIT, WillEdit ),
	MY_NOTIFY( DID_EDIT, DidEdit ),
	TX_NOTIFY( TEXT_DID_END, DidEndEditing ),
	TX_NOTIFY( TEXT_DID_CHANGE, DidBeginEditing ),
	TX_NOTIFY( TEXT_DID_GET_KEYS, DidChange ),
	MY_NOTIFY( DID_BECOME_FIRST_RESP, DidBecomeFirstResponder ),
	MY_NOTIFY( DID_RESIGN_FIRST_RESP, DidResignFirstResponder ),
	0] retain];
#undef TX_NOTIFY
#undef MY_NOTIFY
#undef NOTIFY
    }


//-----------------------------------------------------------------------------
// + initialize
//-----------------------------------------------------------------------------
+ (void)initialize
    {
    if (self == [MiscTableScroll class])
	{
	[self setVersion:MISC_TS_VERSION];
	[self registerNotifications];
	}
    }


//-----------------------------------------------------------------------------
// Multicast Messages
//-----------------------------------------------------------------------------
- (void)sendAction:(SEL)aSel to:(id)obj forAllCells:(BOOL)flag
    {
    int const rlim = num_rows;
    int const clim = num_cols;
    for (int r = 0;  r < rlim;  r++)
	for (int c = 0;  c < clim;  c++)
	    if (flag || [self cellIsSelectedAtRow:r column:c])
		if (![obj performSelector:aSel
		    withObject:[self cellAtRow:r column:c]])
		    break;
    }

- (int)makeCellsPerformSelector:(SEL)s with:(id)p1 with:(id)p2
    selectedOnly:(BOOL)f
    {
    int count = 0;
    int const rlim = num_rows;
    int const clim = num_cols;
    for (int r = 0;  r < rlim;  r++)
	for (int c = 0;  c < clim;  c++)
	    if (!f || [self cellIsSelectedAtRow:r column:c])
		{
		id cell = [self cellAtRow:r column:c];
		if ([cell respondsToSelector:s])
		    if ([cell performSelector:s
			withObject:p1 withObject:p2])
			count++;
		    else
			return count;
		}
    return count;
    }

- (int)makeCellsPerformSelector:(SEL)aSel with:(id)p1 selectedOnly:(BOOL)flag
    { return [self makeCellsPerformSelector:aSel with:p1 with:0
	selectedOnly:flag]; }
- (int)makeCellsPerformSelector:(SEL)aSel selectedOnly:(BOOL)flag
    { return [self makeCellsPerformSelector:aSel with:0 with:0
	selectedOnly:flag]; }

- (int)makeCellsPerformSelector:(SEL)aSel
    { return [self makeCellsPerformSelector:aSel selectedOnly:NO]; }
- (int)makeCellsPerformSelector:(SEL)aSel with:(id)p1
    { return [self makeCellsPerformSelector:aSel with:p1 selectedOnly:NO]; }
- (int)makeCellsPerformSelector:(SEL)aSel with:(id)p1 with:(id)p2
    { return [self makeCellsPerformSelector:aSel with:p1 with:p2
	selectedOnly:NO];}


//-----------------------------------------------------------------------------
// FINDING CELLS
//-----------------------------------------------------------------------------
- (int)border:(MiscBorderType)b slotWithTag:(int)x
	{
	int const lim = (int) [self numberOfSlots:b];
	for (int i = 0;  i < lim;  i++)
	    if ([self border:b slotTag:i] == x)
		return i;
	return -1;
	}
- (int)columnWithTag:(int)x
	{ return [self border:MISC_COL_BORDER slotWithTag:x]; }
- (int)rowWithTag:(int)x
	{ return [self border:MISC_ROW_BORDER slotWithTag:x]; }

- (int)border:(MiscBorderType)b slotWithRepresentedObject:(id)x
	{
	int const lim = (int) [self numberOfSlots:b];
	for (int i = 0;  i < lim;  i++)
	    if ([x isEqual:[self border:b slotRepresentedObject:i]])
		return i;
	return -1;
	}
- (int)columnWithRepresentedObject:(id)x
	{ return [self border:MISC_COL_BORDER slotWithRepresentedObject:x]; }
- (int)rowWithRepresentedObject:(id)x
	{ return [self border:MISC_ROW_BORDER slotWithRepresentedObject:x]; }

- (BOOL)getRow:(int*)row column:(int*)col ofCell:(NSCell*)cell
    {
    int const NRows = [self numberOfRows];
    int const NCols = [self numberOfColumns];
    for (int r = 0;  r < NRows;  r++)
	for (int c = 0;  c < NCols;  c++)
	    if ([self cellAtRow:r column:c] == cell)
		{
		*row = r;
		*col = c;
		return YES;
		}
    *row = -1;
    *col = -1;
    return NO;
    }

- (BOOL)getRow:(int*)row column:(int*)col ofCellWithTag:(int)x
    {
    int const NRows = [self numberOfRows];
    int const NCols = [self numberOfColumns];
    for (int r = 0;  r < NRows;  r++)
	for (int c = 0;  c < NCols;  c++)
	    {
	    id const cell = [self cellAtRow:r column:c];
	    if (cell && [cell respondsToSelector:@selector(tag)] &&
		[cell tag] == x)
		{
		*row = r;
		*col = c;
		return YES;
		}
	    }
    *row = -1;
    *col = -1;
    return NO;
    }

- (id)cellWithTag:(int)x
    {
    int r, c;
    return ([self getRow:&r column:&c ofCellWithTag:x] ?
	    [self cellAtRow:r column:c] : 0);
    }

- (BOOL)getRow:(int*)row column:(int*)col ofCellWithRepresentedObject:(id)x
    {
    int const NRows = [self numberOfRows];
    int const NCols = [self numberOfColumns];
    for (int r = 0;  r < NRows;  r++)
	for (int c = 0;  c < NCols;  c++)
	    {
	    id const cell = [self cellAtRow:r column:c];
	    if (cell && [cell respondsToSelector:@selector(representedObject)]
		&& [x isEqual:[cell representedObject]])
		{
		*row = r;
		*col = c;
		return YES;
		}
	    }
    *row = -1;
    *col = -1;
    return NO;
    }

- (id)cellWithRepresentedObject:(id)x
    {
    int r, c;
    return ([self getRow:&r column:&c ofCellWithRepresentedObject:x] ?
	    [self cellAtRow:r column:c] : 0);
    }


//-----------------------------------------------------------------------------
// - documentClipRect
//-----------------------------------------------------------------------------
- (NSRect)documentClipRect { return [[self contentView] frame]; }


//-----------------------------------------------------------------------------
// Delegate Stuff
//-----------------------------------------------------------------------------
- (void)registerDelegateNotifications:(id)del
    flags:(MiscDelegateFlags const*)flags
    {
    NSNotificationCenter* const nc = [NSNotificationCenter defaultCenter];
    for (unsigned int i = [DEL_NOTIFICATIONS count]; i-- > 0; )
	{
	MiscNotification* const n = [DEL_NOTIFICATIONS objectAtIndex:i];
	DF::Selector const s = [n selector];
	if (flags->respondsTo(s))
	    [nc addObserver:del selector:flags->selToObjc(s)
			name:[n name] object:self];
	}
    }

- (void)cancelDelegateNotifications:(id)del
    flags:(MiscDelegateFlags const*)flags
    {
    NSNotificationCenter* const nc = [NSNotificationCenter defaultCenter];
    for (unsigned int i = [DEL_NOTIFICATIONS count]; i-- > 0; )
	{
	MiscNotification* const n = [DEL_NOTIFICATIONS objectAtIndex:i];
	if (flags->respondsTo( [n selector] ))
	    [nc removeObserver:del name:[n name] object:self];
	}
    }

- (void)replaceDelegate:(id*)old_del with:(id)new_del
    flags:(MiscDelegateFlags*)flags
    {
    if (*old_del != 0)
	[self cancelDelegateNotifications:*old_del flags:flags];
    *old_del = new_del;
    flags->setDelegate( new_del );
    if (new_del != 0)
	[self registerDelegateNotifications:new_del flags:flags];
    }

- (id)delegate			{ return delegate; }
- (id)dataDelegate		{ return dataDelegate; }
- (void)setDelegate:(id)obj
    { [self replaceDelegate:&delegate with:obj flags:delegateFlags]; }
- (void)setDataDelegate:(id)obj
    { [self replaceDelegate:&dataDelegate with:obj flags:dataDelegateFlags]; }

- (id)responsibleDelegate:(DF::Selector)cmd
    {
    id del = 0;
    if (delegate != 0 && delegateFlags->respondsTo(cmd))
	del = delegate;
    else if (dataDelegate != 0 && dataDelegateFlags->respondsTo(cmd))
	del = dataDelegate;
    return del;
    }


//-----------------------------------------------------------------------------
// - freeBorder:
//-----------------------------------------------------------------------------
- (void)freeBorder:(MiscBorderInfo*)p
    {
    [p->view removeFromSuperview];
    [p->view release];
    [p->clip removeFromSuperview];
    [p->clip release];
    delete p->border;
    }


//-----------------------------------------------------------------------------
// - dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    NSWindow* win = [self window];
    if (win != 0 && [win firstResponder] == tableView)
	[win makeFirstResponder:win];
    [self emptyAndReleaseCells];
    [cornerView removeFromSuperview];
    [cornerView release];
    [tableView removeFromSuperview];
    [tableView release];
    [self freeBorder:&colInfo];
    [self freeBorder:&rowInfo];
    if (delegate != 0)
	[self cancelDelegateNotifications:delegate flags:delegateFlags];
    if (dataDelegate != 0)
	[self cancelDelegateNotifications:dataDelegate flags:dataDelegateFlags];
    delete delegateFlags;
    delete dataDelegateFlags;
    [representedObject release];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// - totalSize / totalWidth / totalHeight
//-----------------------------------------------------------------------------
- (float)totalSize:(MiscBorderType)b
	{ return (float) info[b]->border->totalSize(); }
- (float)totalWidth
	{ return [self totalSize:MISC_COL_BORDER]; }
- (float)totalHeight
	{ return [self totalSize:MISC_ROW_BORDER]; }


//-----------------------------------------------------------------------------
// - constrainSize
//-----------------------------------------------------------------------------
- (void)constrainSize
    {
    MiscTableBorder* b;
    NSRect r = [self documentClipRect];

    b = colInfo.border;
    if (b->numSpringy() != 0)
	b->setMinTotalSize( (MiscPixels) r.size.width );

    b = rowInfo.border;
    if (b->numSpringy() != 0)
	b->setMinTotalSize( (MiscPixels) r.size.height );

    [rowInfo.view adjustSize];
    [colInfo.view adjustSize];
    [tableView adjustSize];
    }


//-----------------------------------------------------------------------------
// - sizeToCells
//-----------------------------------------------------------------------------
- (void)sizeToCells
    {
    [self constrainSize];
    }


//-----------------------------------------------------------------------------
// set_sizes
//-----------------------------------------------------------------------------
static void set_sizes( MiscTableBorder* b, float const* v, float lim )
    {
    int const n = b->count();
    if (!b->isUniformSize())
	{
	for (int i = 0; i < n; i++)
	    {
	    MiscPixels x = (MiscPixels) v[i];
	    MiscPixels const xmin = b->getMinSize_P(i);
	    MiscPixels const xmax = b->getMaxSize_P(i);
	    if (x < xmin) x = xmin;
	    if (x > xmax) x = xmax;
	    b->setSize_P( i, (MiscPixels) x );
	    }
	}
    else if (lim != 0)
	b->setUniformSize( (MiscPixels) lim );
    }


//-----------------------------------------------------------------------------
// - sizeToFit
//-----------------------------------------------------------------------------
- (void)sizeToFit
    {
    float const BORDER_THICKNESS = 1;
    float* const vw = (float*)calloc( (num_rows + num_cols), sizeof(*vw) );
    float* const vh = vw + num_cols;
    float max_h = 0;
    float max_w = 0;
    for (int r = 0; r < num_rows; r++)
	{
	float h = 0;
	for (int c = 0; c < num_cols; c++)
	    {
	    id const cell = [self cellAtRow:r column:c];
	    if (cell != 0 && [cell respondsToSelector:@selector(cellSize)])
		{
		NSSize sz = [cell cellSize];
		sz.width  = ceil( sz.width  + BORDER_THICKNESS );
		sz.height = ceil( sz.height + BORDER_THICKNESS );
		if (vw[c] < sz.width) vw[c] = sz.width;
		if (max_w < sz.width) max_w = sz.width;
		if (h < sz.height) h = sz.height;
		}
	    }
	if (vh[r] < h) vh[r] = h;
	if (max_h < h) max_h = h;
	}

    set_sizes( colInfo.border, vw, max_w );
    set_sizes( rowInfo.border, vh, max_h );
    free( vw );

    [self sizeToCells];
    }


//-----------------------------------------------------------------------------
// - setFrameSize:
//-----------------------------------------------------------------------------
- (void)setFrameSize:(NSSize)s
    {
    [super setFrameSize:s];
    [self constrainSize];
    }


//-----------------------------------------------------------------------------
// - forwardBGColor
//-----------------------------------------------------------------------------
- (void)forwardBGColor
    {
    [super setBackgroundColor:backgroundColor];
    [colInfo.clip setBackgroundColor:backgroundColor];
    [rowInfo.clip setBackgroundColor:backgroundColor];
    }


//-----------------------------------------------------------------------------
// - initBorder:type:
//-----------------------------------------------------------------------------
- (void)initBorder:(MiscBorderInfo*)p type:(MiscBorderType)type
    {
    NSZone* const z = [self zone];
    if (p->border == 0)
	p->border = new( NSZoneMalloc(z,sizeof(*(p->border))) )
			MiscTableBorder( type );
    p->border->setOwner( self );

    if (type == MISC_COL_BORDER)
	p->view = [[MiscColView allocWithZone:z]
			initWithFrame:NSZeroRect scroll:self info:p->border];
    else
	p->view = [[MiscRowView allocWithZone:z]
			initWithFrame:NSZeroRect scroll:self info:p->border];

    p->clip = [[NSClipView allocWithZone:z] initWithFrame:NSZeroRect];
    [p->clip setDocumentView:p->view];
    if (p->isOn)
	{
	[self addSubview:p->clip];
	[[self window] invalidateCursorRectsForView:p->view];
	}
    }


//-----------------------------------------------------------------------------
// - doInit:cornerTitle:
//-----------------------------------------------------------------------------
- (void)doInit:(int)ver cornerTitle:(NSString*)s
    {
    editInfo.editing = NO;
    trackingMouse = NO;

    [self setBorderType:NSBezelBorder];
    [super setHasHorizontalScroller:YES];
    [super setHasVerticalScroller:YES];

    info[ MISC_COL_BORDER ] = &colInfo;
    info[ MISC_ROW_BORDER ] = &rowInfo;

    [self initBorder:&colInfo type:MISC_COL_BORDER];
    [self initBorder:&rowInfo type:MISC_ROW_BORDER];

    NSZone* const z = [self zone];

    delegateFlags =
	new( NSZoneMalloc(z,sizeof(*delegateFlags)) ) MiscDelegateFlags;
    dataDelegateFlags =
	new( NSZoneMalloc(z,sizeof(*dataDelegateFlags)) ) MiscDelegateFlags;

    tableView = [[MiscTableView allocWithZone:z] initWithFrame:NSZeroRect
		scroll:self colInfo:colInfo.border rowInfo:rowInfo.border];

    cornerView = [[MiscCornerView allocWithZone:z] initWithFrame:NSZeroRect];
    [self setCornerTitle:s];

    if (colInfo.isOn && rowInfo.isOn)
	[self addSubview:cornerView];

    [self setDocumentView:tableView];
    [self tile];
    [self constrainSize];
    [self forwardBGColor];

    [self registerServicesTypes];
    }


//-----------------------------------------------------------------------------
// - initWithFrame:
//-----------------------------------------------------------------------------
- (id)initWithFrame:(NSRect)frameRect
    {
    [super initWithFrame:frameRect];

    tag = 0;
    enabled = YES;
    delegate = 0;
    dataDelegate = 0;
    representedObject = 0;

    colInfo.border = 0;
    colInfo.isOn = YES;

    rowInfo.border = 0;
    rowInfo.isOn = NO;

    id classObj = [self class];
    font = [[classObj defaultFont] retain];
    textColor = [[classObj defaultTextColor] retain];
    backgroundColor = [[classObj defaultBackgroundColor] retain];
    selectedTextColor = [[classObj defaultSelectedTextColor] retain];
    selectedBackgroundColor =
		[[classObj defaultSelectedBackgroundColor] retain];

    [self doInit:MISC_TS_VERSION cornerTitle:@""];
    return self;
    }


//-----------------------------------------------------------------------------
// - setFrame:
//-----------------------------------------------------------------------------
- (void)setFrame:(NSRect)frameRect
    {
    [super setFrame:frameRect];
    [self constrainSize];
    }


//-----------------------------------------------------------------------------
// - tile
//-----------------------------------------------------------------------------
- (void)tile
    {
    static NSClipView* dummy = 0;
    if (dummy == 0)
	dummy = [[NSClipView alloc] initWithFrame:NSZeroRect];

    NSClipView* const old = [self contentView];
    _contentView = dummy;
    [super tile];
    _contentView = old;

    NSRect docRect = [dummy frame];

    if (colInfo.isOn != rowInfo.isOn)		// One on, one off.
	{
	MiscBorderInfo& b = (colInfo.isOn ? colInfo : rowInfo);
	NSRectEdge const edge = (colInfo.isOn ? NSMinYEdge : NSMinXEdge);
	float height = [b.view frameHeight];
	NSRect rect;

	NSDivideRect( docRect, &rect, &docRect, height, edge );

	[b.clip setFrame:rect];
	[[self contentView] setFrame:docRect];
	[[self window] invalidateCursorRectsForView:b.view];
	}
    else if (colInfo.isOn && rowInfo.isOn)	// Both on.
	{
	float colHeight = [colInfo.view frameHeight];
	float rowWidth  = [rowInfo.view frameHeight];
	NSRect gapRect;
	NSRect colRect;
	NSRect rowRect;

	NSDivideRect( docRect, &colRect, &docRect, colHeight, NSMinYEdge );
	NSDivideRect( colRect, &gapRect, &colRect, rowWidth,  NSMinXEdge );
	NSDivideRect( docRect, &rowRect, &docRect, rowWidth,  NSMinXEdge );

	[cornerView setFrame:gapRect];
	[colInfo.clip setFrame:colRect];
	[rowInfo.clip setFrame:rowRect];
	[[self contentView] setFrame:docRect];
	[[self window] invalidateCursorRectsForView:colInfo.view];
	[[self window] invalidateCursorRectsForView:rowInfo.view];
	}
    else					// Both off.
	{
	[[self contentView] setFrame:docRect];
	}
    }


//-----------------------------------------------------------------------------
// - reflectScroll:
//-----------------------------------------------------------------------------
- (void)reflectScrolledClipView:(NSClipView*)aView
    {
    if (aView == [self contentView]) // only reflect position of contentView
	[super reflectScrolledClipView:aView];
    }


//-----------------------------------------------------------------------------
// - scrollClip:to:
//-----------------------------------------------------------------------------
- (void)scrollClipView:(NSClipView*)aClipView toPoint:(NSPoint)aPoint
    {
    if (aClipView == [self contentView])	// contentView only.
	{
	NSRect rect;
	NSWindow* win = [self window];
	[win disableFlushWindow];

	[aClipView scrollToPoint:aPoint];		// Scroll content

	if (colInfo.isOn)
	    {
	    rect = [colInfo.clip bounds];	// Maybe scroll col headings.
	    if (rect.origin.x != aPoint.x)
		{
		rect.origin.x = aPoint.x;
		[colInfo.clip scrollToPoint:rect.origin];
		[[self window] invalidateCursorRectsForView:colInfo.view];
		}
	    }

	if (rowInfo.isOn)
	    {
	    rect = [rowInfo.clip bounds];	// Maybe scroll row labels.
	    if (rect.origin.y != aPoint.y)
		{
		rect.origin.y = aPoint.y;
		[rowInfo.clip scrollToPoint:rect.origin];
		[[self window] invalidateCursorRectsForView:rowInfo.view];
		}
	    }

	[win enableFlushWindow];
	[win flushWindow];
	}
    else
	{
	BOOL ok = YES;
	NSView* const cv = [self contentView];
	NSRect rect = [cv bounds];
	if (aClipView == (id)colInfo.clip)
	    rect.origin.x = aPoint.x;
	else if (aClipView == (id)rowInfo.clip)
	    rect.origin.y = aPoint.y;
	else
	    ok = NO;
	if (ok)
	    {
	    [self scrollClipView:cv toPoint:rect.origin];
	    [self reflectScrolledClipView:cv];
	    }
	}
    }


//-----------------------------------------------------------------------------
// First Responder notifications
//-----------------------------------------------------------------------------
- (void)didBecomeFirstResponder
    {
    [[NSFontManager sharedFontManager]
	setSelectedFont:[self font] isMultiple:NO];
    [[NSNotificationCenter defaultCenter]
	postNotificationName:MiscTableScrollDidBecomeFirstResponderNotification
	object:self userInfo:0];
    }

- (void)didResignFirstResponder
    {
    [[NSNotificationCenter defaultCenter]
	postNotificationName:MiscTableScrollDidResignFirstResponderNotification
	object:self userInfo:0];
    }


//-----------------------------------------------------------------------------
// Border stuff
//-----------------------------------------------------------------------------
- (NSString*)border:(MiscBorderType)b getDelegateSlotTitle:(int)slot
    {
    id del = [self responsibleDelegate:DF::DEL_SLOT_TITLE];
    if (del != 0)
	return [del tableScroll:self border:b slotTitle:slot];

    NSString* s = @"";
    return s;
    }

- (id)border:(MiscBorderType)b getDelegateSlotPrototype:(int)s
    {
    id del = [self responsibleDelegate:DF::DEL_SLOT_PROTOTYPE];
    if (del != 0)
	return [del tableScroll:self border:b slotPrototype:s];
    return 0;
    }

- (void)border:(MiscBorderType)b slotDragged:(int)fromPos toSlot:(int)toPos
    {
    MiscBorderType const ob = otherBorder(b);
    if ([self autoSortSlots:ob])
	{
	int const slot = [self border:b slotAtPosition:toPos];
	if ([self border:b slotSortType:slot] != MISC_SORT_SKIP ||
	    [self border:b slotSortFunction:slot] != 0)
	    [self sortSlots:ob]; // Don't resort if it doesn't affect ordering.
	}
    [[NSNotificationCenter defaultCenter]
	postNotificationName:MiscTableScrollSlotDraggedNotification object:self
	userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
	    [NSNumber numberWithInt:b], @"Border",
	    [NSNumber numberWithInt:fromPos], @"OldSlot",
	    [NSNumber numberWithInt:toPos], @"NewSlot", 0]];
    }

- (void)border:(MiscBorderType)b slotSortReversed:(int)n
    {
    MiscBorderType const ob = otherBorder(b);
    if ([self autoSortSlots:ob])
	[self sortSlots:ob];		// Assume it affects sorting.
    int const phys = [self border:b slotAtPosition:n];
    [[NSNotificationCenter defaultCenter]
	postNotificationName:MiscTableScrollSlotSortReversedNotification
	object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
	    [NSNumber numberWithInt:b], @"Border",
	    [NSNumber numberWithInt:phys], @"Slot", 0]];
    }

- (void)border:(MiscBorderType)b slotResized:(int)n
    {
    int const phys = [self border:b slotAtPosition:n];
    [[NSNotificationCenter defaultCenter]
	postNotificationName:MiscTableScrollSlotResizedNotification object:self
	userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
	    [NSNumber numberWithInt:b], @"Border",
	    [NSNumber numberWithInt:phys], @"Slot", 0]];
    }


//-----------------------------------------------------------------------------
// Target / Action
//-----------------------------------------------------------------------------
- (id)target				{ return target; }
- (void)setTarget:(id)obj		{ target = obj; }
- (id)doubleTarget			{ return doubleTarget; }
- (void)setDoubleTarget:(id)obj		{ doubleTarget = obj; }
- (SEL)action				{ return action; }
- (void)setAction:(SEL)new_sel		{ action = new_sel; }
- (void)setDoubleAction:(SEL)new_sel	{ doubleAction = new_sel; }
- (SEL)doubleAction			{ return doubleAction; }

- (BOOL)sendAction:(SEL)aSel to:(id)obj
	{
	if (aSel == 0)
	    aSel = action;
	if (obj == 0)
	    obj = target;
	return [NSApp sendAction:aSel to:obj from:self];
	}

- (BOOL)sendAction
	{ return [self sendAction:action to:target]; }

- (BOOL)sendDoubleAction
	{ return [self sendAction:doubleAction to:doubleTarget]; }

- (BOOL)sendActionIfEnabled
	{
	if ([self isEnabled]) { [self sendAction]; return YES; }
	return NO;
	}

- (BOOL)sendDoubleActionIfEnabled
	{
	if ([self isEnabled]) { [self sendDoubleAction]; return YES; }
	return NO;
	}


//-----------------------------------------------------------------------------
// FONT
//-----------------------------------------------------------------------------
+ (NSFont*)defaultFont { return [NSFont userFontOfSize:12.0]; }
- (NSFont*)font { return font; }


static double get_height( NSFont* font )
    {
    double const LINE_SPACING = 1.20;
    double const size = [font pointSize];
    return size * LINE_SPACING;
    }


- (void)setFont:(NSFont*)newFont
    {
    if (![newFont isEqual:font])
	{
	NSFont* oldFont = [font autorelease];
	font = [newFont retain];
	float old_size = [self uniformSizeRows];
	if (old_size != 0)
	    {
	    // FIXME: Handle this better.  Different cell-types will have
	    // different amounts of "fixed-size" border stuff.
	    float const BORDER_THICKNESS = 1;
	    old_size -= BORDER_THICKNESS;
	    float const new_size =
		floor(	0.5 + (double(old_size) *
			(get_height( newFont ) / get_height( oldFont ))));
	    if (new_size != old_size)
		[self setUniformSizeRows:(new_size + BORDER_THICKNESS)];
	    }
	// FIXME: Set font in all existing prototype cells.
	// WARNING: Currently, just asking the border for a prototype
	// in a given slot allocates and initializes an array of prototypes.
	if (![self isLazy])		// Eager beaver sets all cells now.
	    {
	    int const NRows = num_rows;
	    int const NCols = num_cols;
	    for (int r = 0;  r < NRows;  r++)
		{
		for (int c = 0;  c < NCols;  c++)
		    {
		    id cell = [self cellAtRow:r column:c];
		    if (cell != 0)
			{
			if ([cell respondsToSelector:@selector(setOwnerFont:)])
			    [cell setOwnerFont:newFont];
			else if ([cell respondsToSelector:@selector(setFont:)])
			    [cell setFont:newFont];
			}
		    }
		}
	    }
	[[NSNotificationCenter defaultCenter]
	    postNotificationName:MiscTableScrollFontChangedNotification
	    object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
		oldFont, @"OldFont", newFont, @"NewFont", 0]];

	[self setNeedsDisplay:YES];
	}
    }


- (void)changeFont:(id)sender
    {
    NSFont* newFont = [sender convertFont:[sender selectedFont]];
    if (newFont != 0 && ![newFont isEqual:font])
	{
	[self suspendEditing];
	NSFont* oldFont = [[font retain] autorelease];
	[self setFont:newFont];
	[[NSNotificationCenter defaultCenter]
	    postNotificationName:MiscTableScrollChangeFontNotification
	    object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
		oldFont, @"OldFont", newFont, @"NewFont", 0]];
	if (editInfo.editing)
	    [editInfo.cell setFont:newFont];
	[self resumeEditing];
	}
    }


//-----------------------------------------------------------------------------
// COLOR
//
// The following macros expand into the implementations for these functions.
// Their names are listed so they can be found when searched for.
// setBackgroundColor:, setTextColor:, setSelectedBackgroundColor:,
// setSelectedTextColor:
//-----------------------------------------------------------------------------
+ (NSColor*)defaultBackgroundColor
	{ return [NSColor controlBackgroundColor];}
+ (NSColor*)defaultTextColor
	{ return [NSColor controlTextColor]; }
+ (NSColor*)defaultSelectedBackgroundColor
	{ return [NSColor selectedControlColor]; }
+ (NSColor*)defaultSelectedTextColor
	{ return [NSColor selectedControlTextColor]; }

- (NSColor*)backgroundColor		{ return backgroundColor; }
- (NSColor*)textColor			{ return textColor; }
- (NSColor*)selectedBackgroundColor	{ return selectedBackgroundColor; }
- (NSColor*)selectedTextColor		{ return selectedTextColor; }

- (void)setColor:(NSColor*)value	{ [self setBackgroundColor:value]; }
- (NSColor*)color			{ return [self backgroundColor]; }

- (void)setColor:(NSColor*)x		// New color value
	var:(NSColor**)v		// Instance variable for the color
	sel1:(SEL)sel1			// "setOwner...Color:" message for cell
	sel2:(SEL)sel2			// "set...Color:" message for cell
	notification:(NSString*)notification // "...ColorChangedNotification"
    {
    if (![x isEqual:*v])
	{
	[*v autorelease];
	*v = [x retain];
	if (v == &backgroundColor) [self forwardBGColor];

	if (![self isLazy])
	    {
	    int const NRows = num_rows;
	    int const NCols = num_cols;
	    for (int r = 0; r < NRows;  r++)
		for (int c = 0;  c < NCols;  c++)
		    {
		    id cell = [self cellAtRow:r column:c];
		    if (cell != 0)
			{
			if ([cell respondsToSelector:sel1])
			    (*[cell methodForSelector:sel1])( cell, sel1, x );
			else if ([cell respondsToSelector:sel2])
			    (*[cell methodForSelector:sel2])( cell, sel2, x );
			}
		    }
	    }

	[[NSNotificationCenter defaultCenter]
	    postNotificationName:notification object:self userInfo:
	    [NSDictionary dictionaryWithObjectsAndKeys:x, @"Color", 0]];

	[self setNeedsDisplay:YES];
	}
    }


#define MISC_SET_COLOR_FUNC(LNAME,CNAME)\
- (void)set##CNAME##Color:(NSColor*)value\
    { [self setColor:value\
	    var:& LNAME##Color\
	    sel1:@selector(setOwner##CNAME##Color:)\
	    sel2:@selector(set##CNAME##Color:)\
	    notification:MiscTableScroll##CNAME##ColorChangedNotification]; }

MISC_SET_COLOR_FUNC( background, Background )
MISC_SET_COLOR_FUNC( text, Text )
MISC_SET_COLOR_FUNC( selectedBackground, SelectedBackground )
MISC_SET_COLOR_FUNC( selectedText, SelectedText )
#undef MISC_SET_COLOR_FUNC


//=============================================================================
// SAVE / RESTORE
//=============================================================================

- (NSString*)stringFromIntArray:(NSArray*)array
    {
    NSMutableString* s = [[[NSMutableString alloc] init] autorelease];
    for (int i = 0, lim = [array count]; i < lim; i++)
	{
	if (i > 0) [s appendString:@" "];
	[s appendString:[[array objectAtIndex:i] stringValue]];
	}
    return s;
    }

- (NSArray*)intArrayFromString:(NSString*)s
    {
    NSMutableArray* array = [NSMutableArray array];
    NSScanner* scanner = [NSScanner scannerWithString:s];
    int i;
    while (![scanner isAtEnd])
	if ([scanner scanInt:&i])
	    [array addObject:[NSNumber numberWithInt:i]];
    return array;
    }


//-----------------------------------------------------------------------------
// SLOT ORDER
//-----------------------------------------------------------------------------
- (NSArray*)slotOrder:(MiscBorderType)b
    {
    NSMutableArray* array = [NSMutableArray array];
    MiscTableBorder const* const bp = info[b]->border;
	MiscCoord_P const* const vmap = bp->getP2VMap();
    int const lim = bp->count();
    for (int i = 0;  i < lim;  i++)
	{
	int v = (vmap ? vmap[i] : i);
	if (bp->getSortDirection(v) == MISC_SORT_DESCENDING)
	    v = ~v;
	[array addObject:[NSNumber numberWithInt:v]];
	}
    return array;
    }
- (NSArray*)columnOrder { return [self slotOrder:MISC_COL_BORDER]; }
- (NSArray*)rowOrder { return [self slotOrder:MISC_ROW_BORDER]; }

- (BOOL)border:(MiscBorderType)b setSlotOrder:(NSArray*)array
    {
    BOOL ret = NO;
    MiscTableBorder* const bp = info[b]->border;
    if (array != 0 && [array count] != 0)
	{
	unsigned int const lim = bp->count();
	if ([array count] == lim)
	    {
	    unsigned int const nbytes = lim * sizeof(int) + lim * sizeof(bool);
	    int* const map = (int*) malloc( nbytes );
	    NSParameterAssert( map != 0 );
	    bool* const desc = (bool*) (map + lim);

	    for (unsigned int i = 0; i < lim; i++)
		{
		int const j = [[array objectAtIndex:i] intValue];
		map[i] = (desc[i] = (j < 0)) ? ~j : j;
		}

	    if (bp->setP2VMap( map ))
		{
		for (unsigned int i = 0; i < lim; i++)
		    {
		    MiscSortDirection const dir =
			(desc[i] ? MISC_SORT_DESCENDING : MISC_SORT_ASCENDING);
		    if (dir != bp->getSortDirection( map[i] ))
			bp->setSortDirection( map[i], dir );
		    }

		    MiscBorderType const ob = otherBorder(b);
		    if ([self autoSortSlots:ob])
			[self sortSlots:ob];
		    ret = YES;
		    }

	    free( map );
	    }
	}
    else
	{
	bp->setP2VMap(0);
	bp->clearSortDirection();
	ret = YES;
	}

    return ret;
    }

- (BOOL)setColumnOrder:(NSArray*)list
    { return [self border:MISC_COL_BORDER setSlotOrder:list]; }
- (BOOL)setRowOrder:(NSArray*)list
    { return [self border:MISC_ROW_BORDER setSlotOrder:list]; }

- (NSString*)slotOrderAsString:(MiscBorderType)b
    { return [self stringFromIntArray:[self slotOrder:b]]; }
- (NSString*)columnOrderAsString;
    { return [self slotOrderAsString:MISC_COL_BORDER]; }
- (NSString*)rowOrderAsString
    { return [self slotOrderAsString:MISC_ROW_BORDER]; }

- (BOOL)border:(MiscBorderType)b setSlotOrderFromString:(NSString*)s
    { return [self border:b setSlotOrder:[self intArrayFromString:s]]; }
- (BOOL)setColumnOrderFromString:(NSString*)s
    { return [self border:MISC_COL_BORDER setSlotOrderFromString:s]; }
- (BOOL)setRowOrderFromString:(NSString*)s
    { return [self border:MISC_ROW_BORDER setSlotOrderFromString:s]; }


//-----------------------------------------------------------------------------
// SLOT SIZES
//-----------------------------------------------------------------------------
- (NSArray*)slotSizes:(MiscBorderType)b
    {
    NSMutableArray* array = [NSMutableArray array];
    MiscTableBorder const* const bp = info[b]->border;
    int const lim = bp->count();
    for (int i = 0;  i < lim;  i++)
	[array addObject:[NSNumber numberWithInt:(int)bp->getSize_P(i)]];
    return array;
    }
- (NSArray*)columnSizes { return [self slotSizes:MISC_COL_BORDER]; }
- (NSArray*)rowSizes { return [self slotSizes:MISC_ROW_BORDER]; }

- (BOOL)border:(MiscBorderType)b setSlotSizes:(NSArray*)array
    {
    BOOL ret = NO;
    if (array != 0)
	{
	MiscTableBorder* const bp = info[b]->border;
	unsigned int const lim = bp->count();
	if ([array count] == lim)
	    {
	    for (unsigned int i = 0; i < lim; i++)
		{
		MiscPixels const min_size =
				MiscPixels( [self border:b slotMinSize:i] );
		MiscPixels const max_size =
				MiscPixels( [self border:b slotMaxSize:i] );
		MiscPixels s = MiscPixels([[array objectAtIndex:i] intValue]);
		if (s < min_size)
		    s = min_size;
		else if (s > max_size)
		    s = max_size;
		bp->setSize_P( i, s );
		}
	    [self constrainSize];
	    ret = YES;
	    }
	}
    return ret;
    }
- (BOOL)setColumnSizes:(NSArray*)list
    { return [self border:MISC_COL_BORDER setSlotSizes:list]; }
- (BOOL)setRowSizes:(NSArray*)list
    { return [self border:MISC_ROW_BORDER setSlotSizes:list]; }

- (NSString*)slotSizesAsString:(MiscBorderType)b
    { return [self stringFromIntArray:[self slotSizes:b]]; }
- (NSString*)columnSizesAsString
    { return [self slotSizesAsString:MISC_COL_BORDER]; }
- (NSString*)rowSizesAsString
    { return [self slotSizesAsString:MISC_ROW_BORDER]; }

- (BOOL)border:(MiscBorderType)b setSlotSizesFromString:(NSString*)s
    { return [self border:b setSlotSizes:[self intArrayFromString:s]]; }
- (BOOL)setColumnSizesFromString:(NSString*)s
    { return [self border:MISC_COL_BORDER setSlotSizesFromString:s]; }
- (BOOL)setRowSizesFromString:(NSString*)s
    { return [self border:MISC_ROW_BORDER setSlotSizesFromString:s]; }



//-----------------------------------------------------------------------------
// Border Views
//-----------------------------------------------------------------------------
- (MiscCornerView*)cornerView		{ return cornerView; }
- (NSString*)cornerTitle		{ return [cornerView title]; }
- (void)setCornerTitle:(NSString*)s	{ [cornerView setTitle:s]; }

- (BOOL)setBorder:(MiscBorderType)type on:(BOOL)on
    {
    MiscBorderInfo& b = *(info[type]);
    if (b.isOn != on)
	{
	BOOL const other_border_is_on = info[otherBorder(type)]->isOn;
	b.isOn = on;
	if (on)
	    {
	    if (other_border_is_on)
		[self addSubview:cornerView];
	    [self addSubview:b.clip];
	    NSRect r = [b.clip bounds];
	    NSRect c = [[self contentView] bounds];
	    if (type == MISC_COL_BORDER)
		{
		if (r.origin.x != c.origin.x)
		    {
		    r.origin.x = c.origin.x;
		    [b.clip scrollToPoint:r.origin];
		    }
		}
	    else
		{
		if (r.origin.y != c.origin.y)
		    {
		    r.origin.y = c.origin.y;
		    [b.clip scrollToPoint:r.origin];
		    }
		}
	    }
	else
	    {
	    [b.clip removeFromSuperview];
	    if (other_border_is_on)
		[cornerView removeFromSuperview];
	    }
	[self tile];
	[self constrainSize];
	[self setNeedsDisplay:YES];
	return YES;
	}
    return NO;
    }


//-----------------------------------------------------------------------------
// SLOT methods
//-----------------------------------------------------------------------------
- (MiscTableBorder*)border:(MiscBorderType)b
	{ return info[b]->border; }
- (BOOL)border:(MiscBorderType)b setSlotTitlesOn:(BOOL)on_off
	{ return [self setBorder:b on:on_off]; }
- (BOOL)slotTitlesOn:(MiscBorderType)b
	{ return info[b]->isOn; }
- (MiscTableTitleMode)slotTitleMode:(MiscBorderType)b
	{ return info[b]->border->getTitleMode(); }
- (void)border:(MiscBorderType)b setSlotTitleMode:(MiscTableTitleMode)x
	{
	MiscBorderInfo* const ip = info[b];
	if (ip->border->setTitleMode(x) && ip->isOn && ip->border->count() > 0)
	    [ip->view setNeedsDisplay:YES];
	}

- (float)slotTitlesSize:(MiscBorderType)b
	{ return info[b]->isOn ? [info[b]->view frameHeight] : 0; }
- (void)border:(MiscBorderType)b setSlotTitlesSize:(float)x
	{
	[info[b]->view setFrameHeight:(MiscPixels)floor(x)];
	[self tile];
	}

- (void)border:(MiscBorderType)b moveSlot:(int)fromPos toSlot:(int)toPos
	{
	info[b]->border->moveFromTo( fromPos, toPos );
	[self selectionChanged];
	}
- (int)border:(MiscBorderType)b slotPosition:(int)n
	{ return info[b]->border->physicalToVisual(n); }
- (int)border:(MiscBorderType)b slotAtPosition:(int)n
	{ return info[b]->border->visualToPhysical(n); }

- (NSArray*)border:(MiscBorderType)b physicalToVisual:(NSArray*)p_array
	{
	NSMutableArray* v_array = [NSMutableArray array];
	for (unsigned int i = 0, lim = [p_array count]; i < lim; i++)
	    {
	    MiscCoord_P const p = [[p_array objectAtIndex:i] intValue];
	    MiscCoord_V const v = [self border:b slotPosition:p];
	    [v_array addObject:[NSNumber numberWithInt:v]];
	    }
	return v_array;
	}

- (NSArray*)border:(MiscBorderType)b visualToPhysical:(NSArray*)v_array
	{
	NSMutableArray* p_array = [NSMutableArray array];
	for (unsigned int i = 0, lim = [v_array count]; i < lim; i++)
	    {
	    MiscCoord_V const v = [[v_array objectAtIndex:i] intValue];
	    MiscCoord_P const p = [self border:b slotAtPosition:v];
	    [p_array addObject:[NSNumber numberWithInt:p]];
	    }
	return p_array;
	}


- (BOOL)sizeableSlots:(MiscBorderType)b
	{ return info[b]->border->isSizeable(); }
- (BOOL)draggableSlots:(MiscBorderType)b
	{ return info[b]->border->isDraggable(); }
- (BOOL)modifierDragSlots:(MiscBorderType)b
	{ return info[b]->border->isModifierDrag(); }
- (float)uniformSizeSlots:(MiscBorderType)b
	{ return (float) info[b]->border->getUniformSize(); }
- (float)minUniformSizeSlots:(MiscBorderType)b
	{ return (float) info[b]->border->getMinUniformSize(); }
- (float)maxUniformSizeSlots:(MiscBorderType)b
	{ return (float) info[b]->border->getMaxUniformSize(); }

- (float)border:(MiscBorderType)b slotAdjustedSize:(int)n
	{ return (float) info[b]->border->effectiveSize_P(n); }
- (float)border:(MiscBorderType)b slotSize:(int)n
	{ return (float) info[b]->border->getSize_P(n); }
- (float)border:(MiscBorderType)b slotMinSize:(int)n
	{ return (float) info[b]->border->getMinSize_P(n); }
- (float)border:(MiscBorderType)b slotMaxSize:(int)n
	{ return (float) info[b]->border->getMaxSize_P(n); }
- (BOOL)border:(MiscBorderType)b slotIsSizeable:(int)n
	{ return info[b]->border->isSizeable_P(n); }
- (BOOL)border:(MiscBorderType)b slotIsAutosize:(int)n
	{ return info[b]->border->isSpringy_P(n); }
- (NSString*)border:(MiscBorderType)b slotTitle:(int)n
	{ return info[b]->border->getTitle_P(n); }
- (int)border:(MiscBorderType)b slotTag:(int)n
	{ return info[b]->border->getTag_P(n); }
- (id)border:(MiscBorderType)b slotRepresentedObject:(int)n
	{ return info[b]->border->getRepresentedObject_P(n); }
- (MiscTableCellStyle)border:(MiscBorderType)b slotCellType:(int)n
	{ return info[b]->border->getStyle_P(n); }
- (id)border:(MiscBorderType)b slotCellPrototype:(int)n
	{ return info[b]->border->getPrototype_P(n); }

- (void)border:(MiscBorderType)b setSizeableSlots:(BOOL)flag
	{ info[b]->border->setSizeable( flag ); }
- (void)border:(MiscBorderType)b setDraggableSlots:(BOOL)flag
	{ info[b]->border->setDraggable( flag ); }
- (void)border:(MiscBorderType)b setModifierDragSlots:(BOOL)flag
	{ info[b]->border->setModifierDrag( flag ); }
- (void)border:(MiscBorderType)b setUniformSizeSlots:(float)uniform_size
	{
	MiscBorderInfo* const ip = info[b];
	if (ip->border->setUniformSize((MiscPixels)floor(uniform_size)))
	    {
	    [self constrainSize];
	    if (b == MISC_ROW_BORDER)
		{
		float const scr_size = uniform_size != 0 ?
			uniform_size : ip->border->getDefaultSize();
		[self setLineScroll:scr_size];
		[self setPageScroll:scr_size];
		}
	    [self setNeedsDisplay:YES];
	    }
	}

- (void)border:(MiscBorderType)b setMinUniformSizeSlots:(float)size
	{ info[b]->border->setMinUniformSize( (MiscPixels)floor(size) ); }
- (void)border:(MiscBorderType)b setMaxUniformSizeSlots:(float)size
	{ info[b]->border->setMaxUniformSize( (MiscPixels)floor(size) ); }

- (void)border:(MiscBorderType)b setSlot:(int)n size:(float)size
	{
	info[b]->border->setSize_P( n, (MiscPixels)floor(size) );
	[self constrainSize];
	}
- (void)border:(MiscBorderType)b setSlot:(int)n minSize:(float)size
	{
	info[b]->border->setMinSize_P( n, (MiscPixels)floor(size) );
	[self constrainSize];
	}
- (void)border:(MiscBorderType)b setSlot:(int)n maxSize:(float)size
	{
	info[b]->border->setMaxSize_P( n, (MiscPixels)floor(size) );
	[self constrainSize];
	}
- (void)border:(MiscBorderType)b setSlot:(int)n sizeable:(BOOL)flag
	{ info[b]->border->setSizeable_P( n, flag ); }
- (void)border:(MiscBorderType)b setSlot:(int)n autosize:(BOOL)flag
	{
	info[b]->border->setSpringy_P( n, flag );
	[self constrainSize];
	}

- (void)border:(MiscBorderType)b setSlot:(int)n title:(NSString*)title
	{
	MiscBorderInfo* const ip = info[b];
	if (ip->border->setTitle_P( n, title ) && ip->isOn)
	    [ip->view setNeedsDisplay:YES];
	}

- (void)border:(MiscBorderType)b setSlot:(int)n tag:(int)x
	{ info[b]->border->setTag_P( n, x ); }
- (void)border:(MiscBorderType)b setSlot:(int)n representedObject:(id)x
	{ info[b]->border->setRepresentedObject_P( n, x ); }
- (void)border:(MiscBorderType)b setSlot:(int)n
		cellType:(MiscTableCellStyle)type
	{ info[b]->border->setStyle_P(n,type); }
- (void)border:(MiscBorderType)b setSlot:(int)n cellPrototype:(id)p
	{ info[b]->border->setPrototype_P(n,p); }



//-----------------------------------------------------------------------------
// COLUMN methods
//-----------------------------------------------------------------------------
- (MiscTableBorder*)columnBorder
	{ return colInfo.border; }
- (BOOL)columnTitlesOn
	{ return [self slotTitlesOn:MISC_COL_BORDER]; }
- (BOOL)setColumnTitlesOn:(BOOL)x
	{ return [self setBorder:MISC_COL_BORDER on:x]; }
- (MiscTableTitleMode)columnTitleMode
	{ return [self slotTitleMode:MISC_COL_BORDER]; }
- (void)setColumnTitleMode:(MiscTableTitleMode)x
	{ [self border:MISC_COL_BORDER setSlotTitleMode:x]; }
- (float)columnTitlesHeight
	{ return [self slotTitlesSize:MISC_COL_BORDER]; }
- (void)setColumnTitlesHeight:(float)x
	{ [self border:MISC_COL_BORDER setSlotTitlesSize:x]; }
- (MiscBorderView*)colTitles
	{ return ([self columnTitlesOn] ? colInfo.view : 0); }

- (void)moveColumn:(int)fromPos toColumn:(int)toPos
	{ [self border:MISC_COL_BORDER moveSlot:fromPos toSlot:toPos]; }
- (int)columnPosition:(int)n
	{ return [self border:MISC_COL_BORDER slotPosition:n]; }
- (int)columnAtPosition:(int)n
	{ return [self border:MISC_COL_BORDER slotAtPosition:n]; }

- (BOOL)sizeableColumns
	{ return [self sizeableSlots:MISC_COL_BORDER]; }
- (BOOL)draggableColumns
	{ return [self draggableSlots:MISC_COL_BORDER]; }
- (BOOL)modifierDragColumns
	{ return [self modifierDragSlots:MISC_COL_BORDER]; }
- (float)uniformSizeColumns
	{ return [self uniformSizeSlots:MISC_COL_BORDER]; }
- (float)minUniformSizeColumns
	{ return [self minUniformSizeSlots:MISC_COL_BORDER]; }
- (float)maxUniformSizeColumns
	{ return [self maxUniformSizeSlots:MISC_COL_BORDER]; }

- (float)columnAdjustedSize:(int)n
	{ return [self border:MISC_COL_BORDER slotAdjustedSize:n]; }
- (float)columnSize:(int)n
	{ return [self border:MISC_COL_BORDER slotSize:n]; }
- (float)columnMinSize:(int)n
	{ return [self border:MISC_COL_BORDER slotMinSize:n]; }
- (float)columnMaxSize:(int)n
	{ return [self border:MISC_COL_BORDER slotMaxSize:n]; }
- (BOOL)columnIsSizeable:(int)n
	{ return [self border:MISC_COL_BORDER slotIsSizeable:n]; }
- (BOOL)columnIsAutosize:(int)n
	{ return [self border:MISC_COL_BORDER slotIsAutosize:n]; }
- (NSString*)columnTitle:(int)n
	{ return [self border:MISC_COL_BORDER slotTitle:n]; }
- (int)columnTag:(int)n
	{ return [self border:MISC_COL_BORDER slotTag:n]; }
- (id)columnRepresentedObject:(int)n
	{ return [self border:MISC_COL_BORDER slotRepresentedObject:n]; }
- (MiscTableCellStyle)columnCellType:(int)n
	{ return [self border:MISC_COL_BORDER slotCellType:n]; }
- (id)columnCellPrototype:(int)n
	{ return [self border:MISC_COL_BORDER slotCellPrototype:n]; }

- (void)setSizeableColumns:(BOOL)flag
	{ [self border:MISC_COL_BORDER setSizeableSlots:flag]; }
- (void)setDraggableColumns:(BOOL)flag
	{ [self border:MISC_COL_BORDER setDraggableSlots:flag]; }
- (void)setModifierDragColumns:(BOOL)flag
	{ [self border:MISC_COL_BORDER setModifierDragSlots:flag]; }
- (void)setUniformSizeColumns:(float)size
	{ [self border:MISC_COL_BORDER setUniformSizeSlots:size]; }
- (void)setMinUniformSizeColumns:(float)size
	{ [self border:MISC_COL_BORDER setMinUniformSizeSlots:size]; }
- (void)setMaxUniformSizeColumns:(float)size
	{ [self border:MISC_COL_BORDER setMaxUniformSizeSlots:size]; }

- (void)setColumn:(int)n size:(float)size
	{ [self border:MISC_COL_BORDER setSlot:n size:size]; }
- (void)setColumn:(int)n minSize:(float)size
	{ [self border:MISC_COL_BORDER setSlot:n minSize:size]; }
- (void)setColumn:(int)n maxSize:(float)size
	{ [self border:MISC_COL_BORDER setSlot:n maxSize:size]; }
- (void)setColumn:(int)n sizeable:(BOOL)flag
	{ [self border:MISC_COL_BORDER setSlot:n sizeable:flag]; }
- (void)setColumn:(int)n autosize:(BOOL)flag
	{ [self border:MISC_COL_BORDER setSlot:n autosize:flag]; }
- (void)setColumn:(int)n title:(NSString*)title
	{ [self border:MISC_COL_BORDER setSlot:n title:title]; }
- (void)setColumn:(int)n tag:(int)x
	{ [self border:MISC_COL_BORDER setSlot:n tag:x]; }
- (void)setColumn:(int)n representedObject:(id)x
	{ [self border:MISC_COL_BORDER setSlot:n representedObject:x]; }
- (void)setColumn:(int)n cellType:(MiscTableCellStyle)x
	{ [self border:MISC_COL_BORDER setSlot:n cellType:x]; }
- (void)setColumn:(int)n cellPrototype:(id)p
	{ [self border:MISC_COL_BORDER setSlot:n cellPrototype:p]; }


//-----------------------------------------------------------------------------
// ROW methods
//-----------------------------------------------------------------------------
- (MiscTableBorder*)rowBorder
	{ return rowInfo.border; }
- (BOOL)rowTitlesOn
	{ return [self slotTitlesOn:MISC_ROW_BORDER]; }
- (BOOL)setRowTitlesOn:(BOOL)x
	{ return [self setBorder:MISC_ROW_BORDER on:x]; }
- (MiscTableTitleMode)rowTitleMode
	{ return [self slotTitleMode:MISC_ROW_BORDER]; }
- (void)setRowTitleMode:(MiscTableTitleMode)x
	{ [self border:MISC_ROW_BORDER setSlotTitleMode:x]; }
- (float)rowTitlesWidth
	{ return [self slotTitlesSize:MISC_ROW_BORDER]; }
- (void)setRowTitlesWidth:(float)x
	{ [self border:MISC_ROW_BORDER setSlotTitlesSize:x]; }
- (MiscBorderView*)rowTitles
	{ return ([self rowTitlesOn] ? rowInfo.view : 0); }

- (void)moveRow:(int)fromPos toRow:(int)toPos
	{ [self border:MISC_ROW_BORDER moveSlot:fromPos toSlot:toPos]; }
- (int)rowPosition:(int)n
	{ return [self border:MISC_ROW_BORDER slotPosition:n]; }
- (int)rowAtPosition:(int)n
	{ return [self border:MISC_ROW_BORDER slotAtPosition:n]; }

- (BOOL)sizeableRows
	{ return [self sizeableSlots:MISC_ROW_BORDER]; }
- (BOOL)draggableRows
	{ return [self draggableSlots:MISC_ROW_BORDER]; }
- (BOOL)modifierDragRows
	{ return [self modifierDragSlots:MISC_ROW_BORDER]; }
- (float)uniformSizeRows
	{ return [self uniformSizeSlots:MISC_ROW_BORDER]; }
- (float)minUniformSizeRows
	{ return [self minUniformSizeSlots:MISC_ROW_BORDER]; }
- (float)maxUniformSizeRows
	{ return [self maxUniformSizeSlots:MISC_ROW_BORDER]; }

- (float)rowAdjustedSize:(int)n
	{ return [self border:MISC_ROW_BORDER slotAdjustedSize:n]; }
- (float)rowSize:(int)n
	{ return [self border:MISC_ROW_BORDER slotSize:n]; }
- (float)rowMinSize:(int)n
	{ return [self border:MISC_ROW_BORDER slotMinSize:n]; }
- (float)rowMaxSize:(int)n
	{ return [self border:MISC_ROW_BORDER slotMaxSize:n]; }
- (BOOL)rowIsSizeable:(int)n
	{ return [self border:MISC_ROW_BORDER slotIsSizeable:n]; }
- (BOOL)rowIsAutosize:(int)n
	{ return [self border:MISC_ROW_BORDER slotIsAutosize:n]; }
- (NSString*)rowTitle:(int)n
	{ return [self border:MISC_ROW_BORDER slotTitle:n]; }
- (int)rowTag:(int)n
	{ return [self border:MISC_ROW_BORDER slotTag:n]; }
- (id)rowRepresentedObject:(int)n
	{ return [self border:MISC_ROW_BORDER slotRepresentedObject:n]; }
- (MiscTableCellStyle)rowCellType:(int)n
	{ return [self border:MISC_ROW_BORDER slotCellType:n]; }
- (id)rowCellPrototype:(int)n
	{ return [self border:MISC_ROW_BORDER slotCellPrototype:n]; }

- (void)setSizeableRows:(BOOL)flag
	{ [self border:MISC_ROW_BORDER setSizeableSlots:flag]; }
- (void)setDraggableRows:(BOOL)flag
	{ [self border:MISC_ROW_BORDER setDraggableSlots:flag]; }
- (void)setModifierDragRows:(BOOL)flag
	{ [self border:MISC_ROW_BORDER setModifierDragSlots:flag]; }
- (void)setUniformSizeRows:(float)size
	{ [self border:MISC_ROW_BORDER setUniformSizeSlots:size]; }
- (void)setMinUniformSizeRows:(float)size
	{ [self border:MISC_ROW_BORDER setMinUniformSizeSlots:size]; }
- (void)setMaxUniformSizeRows:(float)size
	{ [self border:MISC_ROW_BORDER setMaxUniformSizeSlots:size]; }

- (void)setRow:(int)n size:(float)size
	{ [self border:MISC_ROW_BORDER setSlot:n size:size]; }
- (void)setRow:(int)n minSize:(float)size
	{ [self border:MISC_ROW_BORDER setSlot:n minSize:size]; }
- (void)setRow:(int)n maxSize:(float)size
	{ [self border:MISC_ROW_BORDER setSlot:n maxSize:size]; }
- (void)setRow:(int)n sizeable:(BOOL)flag
	{ [self border:MISC_ROW_BORDER setSlot:n sizeable:flag]; }
- (void)setRow:(int)n autosize:(BOOL)flag
	{ [self border:MISC_ROW_BORDER setSlot:n autosize:flag]; }
- (void)setRow:(int)n title:(NSString*)title
	{ [self border:MISC_ROW_BORDER setSlot:n title:title]; }
- (void)setRow:(int)n tag:(int)x
	{ [self border:MISC_ROW_BORDER setSlot:n tag:x]; }
- (void)setRow:(int)n representedObject:(id)x
	{ [self border:MISC_ROW_BORDER setSlot:n representedObject:x]; }
- (void)setRow:(int)n cellType:(MiscTableCellStyle)x
	{ [self border:MISC_ROW_BORDER setSlot:n cellType:x]; }
- (void)setRow:(int)n cellPrototype:(id)p
	{ [self border:MISC_ROW_BORDER setSlot:n cellPrototype:p]; }


//-----------------------------------------------------------------------------
// DRAWING
//	FIXME: This should all be routed through the -display::: mechanism
//	so that the lockFocus can be done automatically, and so that
//	subviews will have an opportunity to draw themselves.
//-----------------------------------------------------------------------------

- (void)drawCellAtRow:(int)row column:(int)col
    {
    if ([tableView canDraw])
	{
	[tableView lockFocus];
	[tableView drawCellAtRow:row column:col];
	[tableView unlockFocus];
	[[self window] flushWindow];
	}
    }

- (void)drawRow:(int)row
    {
    if ([tableView canDraw])
	{
	[tableView lockFocus];
	[tableView drawRow:row];
	[tableView unlockFocus];
	[[self window] flushWindow];
	}
    }

- (void)drawColumn:(int)col
    {
    if ([tableView canDraw])
	{
	[tableView lockFocus];
	[tableView drawColumn:col];
	[tableView unlockFocus];
	[[self window] flushWindow];
	}
    }

- (void)border:(MiscBorderType)b drawSlot:(int)n
    { if (b == MISC_COL_BORDER) [self drawColumn:n]; else [self drawRow:n]; }

- (void)border:(MiscBorderType)b drawSlotTitle:(int)n	// physical position.
    {
    MiscBorderInfo* const ip = info[b];
    if (ip->isOn)					// visual position.
	{
	MiscBorderView* const v = ip->view;
	if ([v canDraw])
	    {
	    [v lockFocus];
	    [v drawSlot:[self border:b slotPosition:n]];
	    [v unlockFocus];
	    [[self window] flushWindow];
	    }
	}
    }
- (void)drawRowTitle:(int)n
    { [self border:MISC_ROW_BORDER drawSlotTitle:n]; }
- (void)drawColumnTitle:(int)n
    { [self border:MISC_COL_BORDER drawSlotTitle:n]; }

- (BOOL)drawsClippedText		{ return drawsClippedText; }
- (void)setDrawsClippedText:(BOOL)x
    {
    if (drawsClippedText != x)
	{
	drawsClippedText = x;
	[self setNeedsDisplay:YES];
	}
    }

//-----------------------------------------------------------------------------
// VISIBLE / SCROLLING
//-----------------------------------------------------------------------------

- (void)scrollCellToVisibleAtRow:(int)row column:(int)col
	{ [tableView scrollCellToVisibleAtRow:row column:col]; }
- (void)scrollRowToVisible:(int)row { [tableView scrollRowToVisible:row]; }
- (void)scrollColumnToVisible:(int)col
	{ [tableView scrollColumnToVisible:col]; }
- (void)scrollSelectionToVisible
    {
    if ([self hasRowSelection])
	[self scrollRowToVisible:[self selectedRow]];
    else if ([self hasColumnSelection])
	[self scrollColumnToVisible:[self selectedColumn]];
    }


- (int)numberOfVisibleSlots:(MiscBorderType)b
	{ return [tableView numberOfVisibleSlots:b]; }
- (int)firstVisibleSlot:(MiscBorderType)b
	{ return [tableView firstVisibleSlot:b]; }
- (int)lastVisibleSlot:(MiscBorderType)b
	{ return [tableView lastVisibleSlot:b]; }
- (BOOL)border:(MiscBorderType)b slotIsVisible:(int)n
	{ return [tableView border:b slotIsVisible:n]; }
- (void)border:(MiscBorderType)b setFirstVisibleSlot:(int)n
	{ [tableView border:b setFirstVisibleSlot:n]; }
- (void)border:(MiscBorderType)b setLastVisibleSlot:(int)n
	{ [tableView border:b setLastVisibleSlot:n]; }

- (int)numberOfVisibleColumns
	{ return [self numberOfVisibleSlots:MISC_COL_BORDER]; }
- (int)firstVisibleColumn
	{ return [self firstVisibleSlot:MISC_COL_BORDER]; }
- (int)lastVisibleColumn
	{ return [self lastVisibleSlot:MISC_COL_BORDER]; }
- (BOOL)columnIsVisible:(int)n
	{ return [self border:MISC_COL_BORDER slotIsVisible:n]; }
- (void)setFirstVisibleColumn:(int)n
	{ [self border:MISC_COL_BORDER setFirstVisibleSlot:n]; }
- (void)setLastVisibleColumn:(int)n
	{ [self border:MISC_COL_BORDER setLastVisibleSlot:n]; }

- (int)numberOfVisibleRows
	{ return [self numberOfVisibleSlots:MISC_ROW_BORDER]; }
- (int)firstVisibleRow
	{ return [self firstVisibleSlot:MISC_ROW_BORDER]; }
- (int)lastVisibleRow
	{ return [self lastVisibleSlot:MISC_ROW_BORDER]; }
- (BOOL)rowIsVisible:(int)n
	{ return [self border:MISC_ROW_BORDER slotIsVisible:n]; }
- (void)setFirstVisibleRow:(int)n
	{ [self border:MISC_ROW_BORDER setFirstVisibleSlot:n]; }
- (void)setLastVisibleRow:(int)n
	{ [self border:MISC_ROW_BORDER setLastVisibleSlot:n]; }


//-----------------------------------------------------------------------------
// *FIXME*
//	OPENSTEP 4.2 Objective-C++ compiler for NT (final release) crashes
//	whenever a message is sent to 'super' from within a category.  This
//	bug also afflicts the 4.2 (prerelease) compiler for Mach and NT.
//	Work around it by providing stub methods in the main (non-category)
//	implementation which merely forward the appropriate message to 'super'
//	on behalf of the categories.  Though ugly, it works, is very
//	localized, and simple to remove when the bug is finally fixed.
//-----------------------------------------------------------------------------
- (id)superInitWithCoder:(NSCoder*)coder
        { return [super initWithCoder:coder]; }
- (void)superEncodeWithCoder:(NSCoder*)coder
	{ [super encodeWithCoder:coder]; }
- (void)superKeyDown:(NSEvent*)p
	{ [super keyDown:p]; }
- (id)superValidRequestorForSendType:(NSString*)s returnType:(NSString*)r
	{ return [super validRequestorForSendType:s returnType:r]; }

@end
