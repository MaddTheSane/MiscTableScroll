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
// DirWindow.m
//
//	Manages window which displays directory listing.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirWindow.m,v 1.8 99/06/14 17:41:57 sunshine Exp $
// $Log:	DirWindow.m,v $
// Revision 1.8  99/06/14  17:41:57  sunshine
// v19.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// For clarity, renamed: -open: to -openSelected: & -save: to -export:.
// Now prompts user for confirmation before deleting files in -destroy:.
// Numerous MiscTableScroll delegate methods changed to notification style.
// Fixed bug: Was responding to -tableScrollFontChanged: rather than
// -tableScrollChangeFont:.  The latter is sent in response to user-initiated
// font changes, which is what we are interested in.
// For naming consistency, renamed: -didClick: to -scrollClick: &
// -didDoubleClick: to -scrollDoubleClick:.  This is more consistent with
// other methods such as -lockClick:.
// Fixed bug: Attributes displayed for ".." were actually those of ".".
// Fixed bug: -destroy: was mis-using result of -selectedRows and consequently
// deleting the wrong files.
// Fixed bug: Computed full pathname (DA_LONG_NAME) was incorrect for "..".
// It should have been the current directory's parent, but was instead just
// the current directory.  The result was that double-click on ".." failed.
// Fixed -cdPressed: to use DA_LONG_NAME rather than constructing the long
// name manually from DA_SHORT_NAME and the current path.
// 
// Revision 1.7  1998/03/30 00:19:19  sunshine
// v18.1: Wasn't respecting selected-text color.  Problem was cell's "owner"
// was never getting set.
// Now uses NSColor's "system" color by default for window rather than
// hard-wired light-gray.
// Added -tableScrollIgnoreModifierKeysWhileDragging: returning NO.
// Had to implement -tableScroll:draggingSourceOperationMaskForLocal: since
// in MiscTableScroll v126.1 the default changed from "copy" to "generic".
//
// Revision 1.6  97/11/24  19:50:47  sunshine
// v17.1: Fixed bug: Menu was sending -print: to first-responder even though
// any control can be first-responder, rather than just MiscTableScroll.
// Added row-numbers switch.  Adjusted initial cascade position for NT.
//-----------------------------------------------------------------------------
#import "DirWindow.h"
#import "Defaults.h"
#import "DirArray.h"
#import <MiscTableScroll/MiscExporter.h>
#import <MiscTableScroll/MiscTableScroll.h>
#import <MiscTableScroll/MiscTableCell.h>
#import <AppKit/NSButton.h>
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSPanel.h>
#import <AppKit/NSPasteboard.h>
#import <AppKit/NSTextField.h>
#import <AppKit/NSWorkspace.h>
#import <Foundation/NSFileManager.h>
#import <sys/stat.h>

// MS-Windows doesn't define these:
#ifndef S_ISUID
# define S_ISUID 0004000 /* Set user id on execution */
#endif
#ifndef  S_ISGID
# define S_ISGID 0002000 /* Set group id on execution */
#endif
#ifndef  S_ISVTX
# define S_ISVTX 0001000 /* Save swapped text even after use */
#endif 

enum
    {
    ICON_SLOT,
    NAME_SLOT,
    LOCK_SLOT,
    SIZE_SLOT,
    MODIFIED_SLOT,
    PERMS_SLOT,
    OWNER_SLOT,
    GROUP_SLOT,
    HARDLINKS_SLOT,
    SOFTLINK_SLOT,

    MAX_SLOT
    };

static int const CASCADE_MAX = 10;
static int CASCADE_COUNTER = 0;
static float CASCADE_ORIGIN_X;
static float CASCADE_ORIGIN_Y;
static float CASCADE_DELTA_X;
static float CASCADE_DELTA_Y;

static BOOL DEFAULT_AUTO_SORT;
static BOOL DEFAULT_ROW_NUMBERS;
static BOOL DEFAULT_SHOW_HIDDEN;
static BOOL DEFAULT_HIGHLIGHT_DIRS;
static BOOL DEFAULT_DRAG_UNSCALED;
static NSColor* DEFAULT_COLOR;
static NSSize DEFAULT_WIN_SIZE;
static NSFont* DEFAULT_FONT;
static NSMutableArray* OPEN_DIRS = 0;
static NSImage* LOCKED_IMAGE = 0;
static NSImage* UNLOCKED_IMAGE = 0;

static NSString* const COLOR_DEF = @"DirColor";
static NSString* const SIZE_DEF = @"DirSize";
static NSString* const FONT_DEF = @"DirFont";
static NSString* const SORT_DEF = @"AutoSort";
static NSString* const HIDDEN_DEF = @"ShowHidden";
static NSString* const HLIGHT_DEF = @"HighlightDirs";
static NSString* const UNSCALED_DEF = @"DragUnscaled";
static NSString* const COL_SIZES_DEF = @"ColSizes";
static NSString* const COL_ORDER_DEF = @"ColOrder";
static NSString* const ROW_NUMBERS_DEF = @"RowNumbers";

static NSString* const LOCKED_IMAGE_S = @"Lock.secure";
static NSString* const UNLOCKED_IMAGE_S = @"Lock.insecure";


//-----------------------------------------------------------------------------
// NOTE: USE_PRIVATE_ZONE
//	When set to '1', this program will place each window in a separate
//	NSZone and destroy the zone when the window is closed.  When set to
//	'0' windows are placed in the NSDefaultMallocZone().
//-----------------------------------------------------------------------------
#define	USE_PRIVATE_ZONE 1

#if USE_PRIVATE_ZONE
# define EMPLOY_ZONE()	NSCreateZone( NSPageSize(), NSPageSize(), YES )
# define RETIRE_ZONE(Z)	NSRecycleZone(Z)
#else
# define EMPLOY_ZONE()	NSDefaultMallocZone()
# define RETIRE_ZONE(Z)	(void)(Z)
#endif


//-----------------------------------------------------------------------------
// normalize_path
//-----------------------------------------------------------------------------
static inline NSString* normalize_path( NSString* buff )
    {
    return [buff stringByStandardizingPath];
    }


//-----------------------------------------------------------------------------
// str_date
//-----------------------------------------------------------------------------
static NSString* str_date( NSDate* d )
    {
    return [d descriptionWithCalendarFormat:@"%m/%d/%y %H:%M"
		timeZone:0 locale:0];
    }


//-----------------------------------------------------------------------------
// str_perms
//-----------------------------------------------------------------------------
static NSString* str_perms( unsigned long mode, NSString* file_type )
    {
    char c;
    NSMutableString* s = [NSMutableString string];
    if  ([file_type isEqualToString:NSFileTypeDirectory])
	c = 'd';
    else if ([file_type isEqualToString:NSFileTypeCharacterSpecial])
	c = 'c';
    else if ([file_type isEqualToString:NSFileTypeBlockSpecial])
	c = 'b';
    else if ([file_type isEqualToString:NSFileTypeRegular])
	c = '-';
    else if ([file_type isEqualToString:NSFileTypeSymbolicLink])
	c = 'l';
    else if ([file_type isEqualToString:NSFileTypeSocket])
	c = 's';
    else
	c = '?';
    [s appendFormat:@"%c", c];
    [s appendFormat:@"%c", (mode & 0400) ? 'r' : '-'];
    [s appendFormat:@"%c", (mode & 0200) ? 'w' : '-'];
    [s appendFormat:@"%c", (mode & S_ISUID) ? 's' : (mode & 0100) ? 'x' : '-'];
    [s appendFormat:@"%c", (mode & 0040) ? 'r' : '-'];
    [s appendFormat:@"%c", (mode & 0020) ? 'w' : '-'];
    [s appendFormat:@"%c", (mode & S_ISGID) ? 's' : (mode & 0010) ? 'x' : '-'];
    [s appendFormat:@"%c", (mode & 0004) ? 'r' : '-'];
    [s appendFormat:@"%c", (mode & 0002) ? 'w' : '-'];
    [s appendFormat:@"%c", (mode & S_ISVTX) ? 't' : (mode & 0001) ? 'x' : '-'];

    return s;
    }


//-----------------------------------------------------------------------------
// fmt_icon
//-----------------------------------------------------------------------------
static void fmt_icon( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    float h,w,s;
    NSImage* i = [dict scaledImage];

    w = [ts columnSize:ICON_SLOT];	if (w == 0) w = 18;
    h = [ts uniformSizeRows];		if (h == 0) h = 18;
    s = (w < h ? w : h) - 1.0;

    [i setSize:NSMakeSize( s, s )];
    [cell setImage:i];
    }


//-----------------------------------------------------------------------------
// fmt_lock
//-----------------------------------------------------------------------------
static void fmt_lock( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setState:![[dict objectForKey:DA_IS_LOCKED] boolValue]];
    [cell setEnabled:[[dict objectForKey:DA_CAN_TOGGLE_LOCK] boolValue]];
    }


//-----------------------------------------------------------------------------
// fmt_name
//-----------------------------------------------------------------------------
static void fmt_name( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setStringValue:[dict objectForKey:DA_SHORT_NAME]];
    }


//-----------------------------------------------------------------------------
// fmt_size
//-----------------------------------------------------------------------------
static void fmt_size( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setIntValue:[dict fileSize]];
    }


//-----------------------------------------------------------------------------
// fmt_modified
//-----------------------------------------------------------------------------
static void fmt_modified( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setStringValue:str_date( [dict fileModificationDate] )];
    }


//-----------------------------------------------------------------------------
// fmt_perms
//-----------------------------------------------------------------------------
static void fmt_perms( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setStringValue:
	str_perms( [dict filePosixPermissions], [dict fileType])];
    }


//-----------------------------------------------------------------------------
// fmt_owner
//-----------------------------------------------------------------------------
static void fmt_owner( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    NSString* s = [dict fileOwnerAccountName];
    [cell setStringValue:(s != 0 ? s : @"")];
    }


//-----------------------------------------------------------------------------
// fmt_group
//-----------------------------------------------------------------------------
static void fmt_group( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    NSString* s = [dict fileGroupOwnerAccountName];
    [cell setStringValue:(s != 0 ? s : @"")];
    }


//-----------------------------------------------------------------------------
// fmt_hardlinks
//-----------------------------------------------------------------------------
static void fmt_hardlinks( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setIntValue:
	[[dict objectForKey:NSFileReferenceCount] unsignedLongValue]];
    }


//-----------------------------------------------------------------------------
// fmt_softlink
//-----------------------------------------------------------------------------
static void fmt_softlink( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setStringValue:[dict objectForKey:DA_SOFT_LINK]];
    }


//-----------------------------------------------------------------------------
// FORMAT_FUNC
//-----------------------------------------------------------------------------

typedef void (*FormatFunc)( MiscTableScroll*, NSDictionary*, id );

static FormatFunc FORMAT_FUNC[ MAX_SLOT ] =
	{
	fmt_icon,		// ICON_SLOT,
	fmt_name,		// NAME_SLOT,
	fmt_lock,		// LOCK_SLOT,
	fmt_size,		// SIZE_SLOT,
	fmt_modified,		// MODIFIED_SLOT,
	fmt_perms,		// PERMS_SLOT,
	fmt_owner,		// OWNER_SLOT,
	fmt_group,		// GROUP_SLOT,
	fmt_hardlinks,		// HARDLINKS_SLOT,
	fmt_softlink,		// SOFTLINK_SLOT,
	};


//-----------------------------------------------------------------------------
// format_cell
//-----------------------------------------------------------------------------
static inline void format_cell(
	MiscTableScroll* ts,
	NSDictionary* dict,
	id cell,
	unsigned int col )
    {
    FORMAT_FUNC[ col ]( ts, dict, cell );
    }


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation DirWindow

//-----------------------------------------------------------------------------
// + initCascader
//-----------------------------------------------------------------------------
+ (void)initCascader
    {
    NSSize const s = [[NSScreen mainScreen] frame].size;
    CASCADE_ORIGIN_X = s.width / 4;
    CASCADE_ORIGIN_Y = s.height - 60;
    CASCADE_DELTA_X = 20;
    CASCADE_DELTA_Y = 20;
    }


//-----------------------------------------------------------------------------
// + initialize
//-----------------------------------------------------------------------------
+ (void)initialize
    {
    if (self == [DirWindow class])
	{
	[self initCascader];
	OPEN_DIRS = [[NSMutableArray alloc] init];
	LOCKED_IMAGE   = [[NSImage imageNamed:LOCKED_IMAGE_S] retain];
	UNLOCKED_IMAGE = [[NSImage imageNamed:UNLOCKED_IMAGE_S] retain];
	DEFAULT_COLOR = [[Defaults getColor:COLOR_DEF
			fallback:[NSColor controlColor]] retain];
	DEFAULT_AUTO_SORT = [Defaults getBool:SORT_DEF fallback:NO];
	DEFAULT_SHOW_HIDDEN = [Defaults getBool:HIDDEN_DEF fallback:NO];
	DEFAULT_ROW_NUMBERS = [Defaults getBool:ROW_NUMBERS_DEF fallback:NO];
	DEFAULT_HIGHLIGHT_DIRS = [Defaults getBool:HLIGHT_DEF fallback:NO];
	DEFAULT_DRAG_UNSCALED = [Defaults getBool:UNSCALED_DEF fallback:YES];
	}
    }


//-----------------------------------------------------------------------------
// - cascade
//-----------------------------------------------------------------------------
- (void)cascade
    {
    float top,left;
    left = CASCADE_ORIGIN_X + (CASCADE_DELTA_X * CASCADE_COUNTER);
    top  = CASCADE_ORIGIN_Y - (CASCADE_DELTA_Y * CASCADE_COUNTER);
    [window setFrameTopLeftPoint:NSMakePoint( left, top )];
    if (++CASCADE_COUNTER >= CASCADE_MAX)
	CASCADE_COUNTER = 0;
    }


//-----------------------------------------------------------------------------
// - isDir:
//-----------------------------------------------------------------------------
- (BOOL)isDir:(int)r
    {
    return [[[dirArray objectAtIndex:r]
	objectForKey:DA_IS_DIRECTORY] boolValue];
    }


//-----------------------------------------------------------------------------
// - updateButtons
//-----------------------------------------------------------------------------
- (void)updateButtons
    {
    BOOL const enable = [scroll numberOfSelectedRows] == 1 &&
			[self isDir:[scroll selectedRow]];
    if (enable != [cdButton isEnabled])
	[cdButton setEnabled:enable];
    }


//-----------------------------------------------------------------------------
// - scrollColor
//-----------------------------------------------------------------------------
- (NSColor*)scrollColor
    {
    if ([DEFAULT_COLOR isEqual:[NSColor controlColor]])
        return [MiscTableScroll defaultBackgroundColor];
    else
        return DEFAULT_COLOR;
    }


//-----------------------------------------------------------------------------
// - tableScroll:cellAtRow:column:
//-----------------------------------------------------------------------------
- (id)tableScroll:(MiscTableScroll*)ts cellAtRow:(int)row column:(int)col
    {
    id cell = [lazyRow objectAtIndex:col];
    NSDictionary* dict = [dirArray objectAtIndex:row];
    format_cell( ts, dict, cell, col );
    if ([cell respondsToSelector:@selector(setBackgroundColor:)])
	{
	if (highlightDirs && [self isDir:row])
	    [cell setBackgroundColor:[NSColor cyanColor]];
	else
	    [cell setBackgroundColor:[ts backgroundColor]];
	}
    return cell;
    }


//-----------------------------------------------------------------------------
// - tableScroll:stringValueAtRow:column:
//-----------------------------------------------------------------------------
- (NSString*)tableScroll:(MiscTableScroll*)ts
    stringValueAtRow:(int)r column:(int)c
    {
    NSString* rc = 0;
    if (r < [dirArray count])
	{
	NSDictionary* dict = [dirArray objectAtIndex:r];
	switch (c)
	    {
	    case SIZE_SLOT:
		rc = [[dict objectForKey:NSFileSize] stringValue];
		break;
	    case MODIFIED_SLOT:
		rc = str_date( [dict fileModificationDate] );
		break;
	    case PERMS_SLOT:
		rc = str_perms( [dict filePosixPermissions], [dict fileType] );
		break;
	    case OWNER_SLOT:
		rc = [dict fileOwnerAccountName];
		break;
	    case GROUP_SLOT:
		rc = [dict fileGroupOwnerAccountName];
		break;
	    case HARDLINKS_SLOT:
		rc = [[dict objectForKey:NSFileReferenceCount] stringValue];
		break;
	    case NAME_SLOT:
		rc = [dict objectForKey:DA_SHORT_NAME];
		break;
	    case SOFTLINK_SLOT:
		rc = [dict objectForKey:DA_SOFT_LINK];
		break;
	    case ICON_SLOT:
	    case LOCK_SLOT:
	    default:
		rc = @"";
		break;
	    }
	}
    return (rc != 0 ? rc : @""); // Owner or group may have returned nil.
    }


//-----------------------------------------------------------------------------
// -intValueAtRow:column:
//-----------------------------------------------------------------------------
- (int)intValueAtRow:(int)r column:(int)c
    {
    int rc = 0;
    if (r < [dirArray count])
	{
	NSDictionary* dict = [dirArray objectAtIndex:r];
	switch (c)
	    {
	    case LOCK_SLOT:
		rc = [[dict objectForKey:DA_IS_LOCKED] intValue];
		break;
	    case SIZE_SLOT:
		rc = [dict fileSize];
		break;
	    case MODIFIED_SLOT:
		rc = [[dict fileModificationDate]
			timeIntervalSinceReferenceDate];
		break;
	    case PERMS_SLOT:
		rc = [dict filePosixPermissions];
		break;
	    case HARDLINKS_SLOT:
		rc = [[dict objectForKey:NSFileReferenceCount] intValue];
		break;
	    case OWNER_SLOT:
	    case GROUP_SLOT:
	    case ICON_SLOT:
	    case NAME_SLOT:
	    case SOFTLINK_SLOT:
	    default:
		break;
	    }
	}
    return rc;
    }


//-----------------------------------------------------------------------------
// - tableScroll:intValueAtRow:column:
//-----------------------------------------------------------------------------
- (int)tableScroll:(MiscTableScroll*)ts intValueAtRow:(int)r column:(int)c
    {
    return [self intValueAtRow:r column:c];
    }


//-----------------------------------------------------------------------------
// - tableScroll:tagAtRow:column:
//-----------------------------------------------------------------------------
- (int)tableScroll:(MiscTableScroll*)ts tagAtRow:(int)r column:(int)c
    {
    return [self intValueAtRow:r column:c];
    }


//-----------------------------------------------------------------------------
// - tableScroll:stateAtRow:column:
//-----------------------------------------------------------------------------
- (int)tableScroll:(MiscTableScroll*)ts stateAtRow:(int)r column:(int)c
    {
    return [self intValueAtRow:r column:c];
    }


//-----------------------------------------------------------------------------
// - tableScrollChangeFont:
//-----------------------------------------------------------------------------
- (void)tableScrollChangeFont:(NSNotification*)n
    {
    NSFont* newFont = (NSFont*)[[n userInfo] objectForKey:@"NewFont"];
    int col;
    for (col = 0; col < MAX_SLOT; col++)
	[[lazyRow objectAtIndex:col] setFont:newFont];

    [DEFAULT_FONT autorelease];
    DEFAULT_FONT = [newFont retain];
    [Defaults set:FONT_DEF font:DEFAULT_FONT];
    }


//-----------------------------------------------------------------------------
// - tableScrollSlotResized:
//-----------------------------------------------------------------------------
- (void)tableScrollSlotResized:(NSNotification*)n
    {
    [Defaults set:COL_SIZES_DEF str:[scroll columnSizesAsString]];
    }


//-----------------------------------------------------------------------------
// saveSlotOrder:
//-----------------------------------------------------------------------------
- (void)saveSlotOrder:(NSNotification*)n
    {
    MiscBorderType const b =
	(MiscBorderType)[[[n userInfo] objectForKey:@"Border"] intValue];
    if (b == MISC_COL_BORDER)
	[Defaults set:COL_ORDER_DEF str:[scroll columnOrderAsString]];
    }


//-----------------------------------------------------------------------------
// - tableScrollSlotDragged:
//-----------------------------------------------------------------------------
- (void)tableScrollSlotDragged:(NSNotification*)n
    {
    [self saveSlotOrder:n];
    }


//-----------------------------------------------------------------------------
// - tableScrollSlotSortReversed:
//-----------------------------------------------------------------------------
- (void)tableScrollSlotSortReversed:(NSNotification*)n
    {
    [self saveSlotOrder:n];
    }


//-----------------------------------------------------------------------------
// - tableScroll:canEdit:atRow:column:
//-----------------------------------------------------------------------------
- (BOOL)tableScroll:(MiscTableScroll*)ts
	canEdit:(NSEvent*)ev
	atRow:(int)row column:(int)col
    {
    return ((ev == 0 || [ev clickCount] == 2) && col == NAME_SLOT &&
	![[[dirArray objectAtIndex:row] objectForKey:DA_IS_LOCKED] boolValue]);
    }

 
//-----------------------------------------------------------------------------
// - tableScroll:setStringValue:atRow:column:
//-----------------------------------------------------------------------------
- (BOOL)tableScroll:(MiscTableScroll*)ts
	setStringValue:(NSString*)s
	atRow:(int)row column:(int)col
    {
    NSMutableDictionary* dict = [dirArray objectAtIndex:row];
    [dict setObject:s forKey:DA_SHORT_NAME];
    [dict setObject:[path stringByAppendingPathComponent:s]
	forKey:DA_LONG_NAME];
    return YES;
    }


//-----------------------------------------------------------------------------
// -tableScroll:draggingSourceOperationMaskForLocal:
//-----------------------------------------------------------------------------
- (unsigned int)tableScroll:(MiscTableScroll*)s
	draggingSourceOperationMaskForLocal:(BOOL)isLocal
    {
    return NSDragOperationAll;
    }


//-----------------------------------------------------------------------------
// tableScrollIgnoreModifierKeysWhileDragging:
//-----------------------------------------------------------------------------
- (BOOL)tableScrollIgnoreModifierKeysWhileDragging:(MiscTableScroll*)s
    {
    return NO;
    }


//-----------------------------------------------------------------------------
// - tableScroll:preparePasteboard:forDragOperationAtRow:column:
//-----------------------------------------------------------------------------
- (void)tableScroll:(MiscTableScroll*)s
	preparePasteboard:(NSPasteboard*)pb 
	forDragOperationAtRow:(int)r column:(int)c
    {
    NSString* file = [[dirArray objectAtIndex:r] objectForKey:DA_LONG_NAME];
    [pb declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:0];
    [pb setPropertyList:[NSArray arrayWithObject:file]
		forType:NSFilenamesPboardType];
    }


//-----------------------------------------------------------------------------
// - tableScroll:allowDragOperationAtRow:column:
//-----------------------------------------------------------------------------
- (BOOL)tableScroll:(MiscTableScroll*)s
	allowDragOperationAtRow:(int)r column:(int)c
    {
    return (c == ICON_SLOT);
    }


//-----------------------------------------------------------------------------
// - tableScroll:imageForDragOperationAtRow:column:
//-----------------------------------------------------------------------------
- (NSImage*)tableScroll:(MiscTableScroll*)s
	imageForDragOperationAtRow:(int)r column:(int)c
    {
    NSDictionary* dict = [dirArray objectAtIndex:r];
    return (dragUnscaled ? [dict unscaledImage] : [dict scaledImage]);
    }


//-----------------------------------------------------------------------------
// - fillScroll
//-----------------------------------------------------------------------------
- (void)fillScroll
    {
    [scroll renewRows:[dirArray count]];
    if ([scroll autoSortRows])
	[scroll sortRows];

    [countField setStringValue:
		[NSString stringWithFormat:@"%d files   %lu bytes",
		[dirArray count], [dirArray totalBytes]]];

    [self updateButtons];
    }


//-----------------------------------------------------------------------------
// - setPath:
//-----------------------------------------------------------------------------
- (void)setPath:(NSString*)dirname
    {
    [path autorelease];
    if (dirname == 0) dirname = NSHomeDirectory();
    if ([dirname length] == 0) dirname = @"/";
    path = [dirname retain];
    [window setTitleWithRepresentedFilename:path];
    }


//-----------------------------------------------------------------------------
// - loadDirectory:
//-----------------------------------------------------------------------------
- (void)loadDirectory:(NSString*)dirname
    {
    if (![dirArray loadPath:dirname showHidden:showHidden])
	NSRunAlertPanel( @"Can't Read", @"Cannot read directory, %@",
			 @"OK", 0, 0, path );
    }


//-----------------------------------------------------------------------------
// - reload
//-----------------------------------------------------------------------------
- (void)reload
    {
    [scroll abortEditing];
    [self loadDirectory:path];
    [self fillScroll];
    }


//-----------------------------------------------------------------------------
// - load:
//-----------------------------------------------------------------------------
- (void)load:(NSString*)dirname
    {
    [self setPath:dirname];
    [self reload];
    }


//-----------------------------------------------------------------------------
// - export:
//-----------------------------------------------------------------------------
- (void)export:(id)sender
    {
    [[MiscExporter commonInstance] exportTableScroll:scroll];
    }


//-----------------------------------------------------------------------------
// - printDirectory:
//-----------------------------------------------------------------------------
- (void)printDirectory:(id)sender
    {
    [scroll print:self];
    }


//-----------------------------------------------------------------------------
// - openSelected:
//-----------------------------------------------------------------------------
- (void)openSelected:(id)sender
    {
    if ([scroll hasRowSelection])
	{
	int i;
	NSArray* list = [scroll selectedRows];
	for (i = [list count]; i-- > 0; )
	    {
	    int const r = [[list objectAtIndex:i] intValue];
	    NSString* s = [[dirArray objectAtIndex:r]
				objectForKey:DA_LONG_NAME];
	    if ([self isDir:r])
		[[self class] launchDir:s];
	    else
		[[NSWorkspace sharedWorkspace] openFile:s];
	    }
	}
    }


//-----------------------------------------------------------------------------
// - destroy:
//-----------------------------------------------------------------------------
- (void)destroy:(id)sender
    {
    if ([dirArray writable] && [scroll hasRowSelection])
	{
	if (NSRunAlertPanel( @"Delete Files", @"Delete selected files?",
	    @"Yes", @"No", 0 ) == NSAlertDefaultReturn)
	    {
	    int i;
	    NSArray* list = [scroll selectedRows];
	    NSFileManager* manager = [NSFileManager defaultManager];
	    for (i = [list count]; i-- > 0; )
		{
		int const row = [[list objectAtIndex:i] intValue];
		[manager removeFileAtPath:[[dirArray objectAtIndex:row]
			    objectForKey:DA_LONG_NAME] handler:0];
		}
	    [self reload];
	    }
	}
    }


//-----------------------------------------------------------------------------
// - fileManager:shouldProceedAfterError:
//-----------------------------------------------------------------------------
- (BOOL)fileManager:(NSFileManager*)manager 
	shouldProceedAfterError:(NSDictionary*)errorInfo
    {
    NSRunAlertPanel( @"Error", @"Rename failed: %@.", @"OK", 0, 0, 
			[errorInfo objectForKey:@"Error"]);
    return NO;
    }


//-----------------------------------------------------------------------------
// - rename:to:
//-----------------------------------------------------------------------------
- (BOOL)rename:(NSString*)oldName to:(NSString*)newName
    {
    return [[NSFileManager defaultManager]
	movePath:[path stringByAppendingPathComponent:oldName]
	toPath:[path stringByAppendingPathComponent:newName]
	handler:self];
    }


//-----------------------------------------------------------------------------
// - control:textShouldEndEditing:
//-----------------------------------------------------------------------------
- (BOOL)control:(NSControl*)control textShouldEndEditing:(NSText*)fieldEditor
    {
    BOOL accept = YES;
    NSString* oldName;
    NSString* newName;

    int const r = [scroll clickedRow];
    int const c = [scroll clickedColumn];
    NSParameterAssert( c == NAME_SLOT );

    oldName = [[dirArray objectAtIndex:r] objectForKey:DA_SHORT_NAME];
    newName = [fieldEditor string];

    if (![newName isEqualToString:oldName])
	accept = [self rename:oldName to:newName];

    if (!accept)
	[fieldEditor setString:oldName];

    return accept;
    }


//-----------------------------------------------------------------------------
// - refreshPressed:
//-----------------------------------------------------------------------------
- (void)refreshPressed:(id)sender
    {
    [self reload];
    }


//-----------------------------------------------------------------------------
// - cdPressed:
//-----------------------------------------------------------------------------
- (void)cdPressed:(id)sender
    {
    [scroll abortEditing];
    if ([scroll numberOfSelectedRows] == 1)
	{
	MiscCoord_P const r = [scroll selectedRow];
	if ([self isDir:r])
	    [self load:[[dirArray objectAtIndex:r] objectForKey:DA_LONG_NAME]];
	}
    }


//-----------------------------------------------------------------------------
// - rowNumbersClick:
//-----------------------------------------------------------------------------
- (void)rowNumbersClick:(id)sender
    {
    BOOL const newVal = ([rowNumbersSwitch state] != 0);
    BOOL const oldVal = [scroll rowTitlesOn];
    if (newVal != oldVal)
	{
	DEFAULT_ROW_NUMBERS = newVal;
	[scroll setRowTitlesOn:DEFAULT_ROW_NUMBERS];
	[Defaults set:ROW_NUMBERS_DEF bool:DEFAULT_ROW_NUMBERS];
	}
    }


//-----------------------------------------------------------------------------
// - autoSortClick:
//-----------------------------------------------------------------------------
- (void)autoSortClick:(id)sender
    {
    BOOL const switchState = [autoSortSwitch state];
    [scroll abortEditing];
    if (autoSort != switchState)
	{
	DEFAULT_AUTO_SORT = autoSort = switchState;
	[Defaults set:SORT_DEF bool:DEFAULT_AUTO_SORT];
	[scroll setAutoSortRows:switchState];
	if (switchState)
	    [scroll sortRows];
	}
    }


//-----------------------------------------------------------------------------
// - hiddenFilesClick:
//-----------------------------------------------------------------------------
- (void)hiddenFilesClick:(id)sender
    {
    BOOL const switchState = [hiddenFilesSwitch state];
    [scroll abortEditing];
    if (showHidden != switchState)
	{
	DEFAULT_SHOW_HIDDEN = showHidden = switchState;
	[Defaults set:HIDDEN_DEF bool:DEFAULT_SHOW_HIDDEN];
	[self reload];
	}
    }


//-----------------------------------------------------------------------------
// - highlightClick:
//-----------------------------------------------------------------------------
- (void)highlightClick:(id)sender
    {
    BOOL const switchState = [highlightSwitch state];
    [scroll abortEditing];
    if (highlightDirs != switchState)
	{
	DEFAULT_HIGHLIGHT_DIRS = highlightDirs = switchState;
	[Defaults set:HLIGHT_DEF bool:DEFAULT_HIGHLIGHT_DIRS];
	[scroll setNeedsDisplay:YES];
	}
    }


//-----------------------------------------------------------------------------
// - dragUnscaledClick:
//-----------------------------------------------------------------------------
- (void)dragUnscaledClick:(id)sender
    {
    BOOL const switchState = [dragUnscaledSwitch state];
    if (dragUnscaled != switchState)
	{
	DEFAULT_DRAG_UNSCALED = dragUnscaled = switchState;
	[Defaults set:UNSCALED_DEF bool:DEFAULT_DRAG_UNSCALED];
	}
    }


//-----------------------------------------------------------------------------
// - lockClick:
//-----------------------------------------------------------------------------
- (void)lockClick:(id)sender
    {
    int const row = [sender clickedRow];
    NSMutableDictionary* dict = [dirArray objectAtIndex:row];
    if ([[dict objectForKey:DA_CAN_TOGGLE_LOCK] boolValue])
	{
	BOOL const wasLocked = [[dict objectForKey:DA_IS_LOCKED] boolValue];
	[dict setObject:[NSNumber numberWithBool:!wasLocked]
		forKey:DA_IS_LOCKED];
	if ([sender autoSortRows])
	    [sender sortRow:row];
	}
    }


//-----------------------------------------------------------------------------
// - scrollClick:
//-----------------------------------------------------------------------------
- (void)scrollClick:(id)sender
    {
    [self updateButtons];
    }


//-----------------------------------------------------------------------------
// - scrollDoubleClick:
//-----------------------------------------------------------------------------
- (void)scrollDoubleClick:(id)sender
    {
    [self openSelected:sender];
    }


//-----------------------------------------------------------------------------
// - activateWindow
//-----------------------------------------------------------------------------
- (void)activateWindow
    {
    [window makeKeyAndOrderFront:0];
    }


//-----------------------------------------------------------------------------
// - windowShouldClose:
//-----------------------------------------------------------------------------
- (BOOL)windowShouldClose:(id)sender
    {
    [scroll abortEditing];
    [OPEN_DIRS removeObject:self];
    [self autorelease];
    return YES;
    }


//-----------------------------------------------------------------------------
// - windowDidResize:
//-----------------------------------------------------------------------------
- (void)windowDidResize:(NSNotification*)notification
    {
    NSRect r = [[notification object] frame];
    if (NSWidth (r) != DEFAULT_WIN_SIZE.width ||
	NSHeight(r) != DEFAULT_WIN_SIZE.height)
	{
	DEFAULT_WIN_SIZE = r.size;
	[Defaults set:SIZE_DEF size:DEFAULT_WIN_SIZE];
	}
    }


//-----------------------------------------------------------------------------
// - setDefaultColor:
//-----------------------------------------------------------------------------
- (void)setDefaultColor:(NSColor*)c
    {
    [DEFAULT_COLOR autorelease];
    DEFAULT_COLOR = [c retain];
    [Defaults set:COLOR_DEF color:c];
    }


//-----------------------------------------------------------------------------
// - setColors:
//-----------------------------------------------------------------------------
- (void)setColors:(NSColor*)c
    {
    [window setBackgroundColor:c];
    [scroll setBackgroundColor:[self scrollColor]];
    [window display];
    }


//-----------------------------------------------------------------------------
// - draggingEntered:
//-----------------------------------------------------------------------------
- (unsigned int)draggingEntered:(id<NSDraggingInfo>)sender
    {
    return ([sender draggingSourceOperationMask] & NSDragOperationGeneric);
    }


//-----------------------------------------------------------------------------
// - performDragOperation:
//-----------------------------------------------------------------------------
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
    {
    [self setDefaultColor:
		[NSColor colorFromPasteboard:[sender draggingPasteboard]]];
    [self setColors:DEFAULT_COLOR];
    return YES;
    }


//-----------------------------------------------------------------------------
// - initLazyRow
//	NOTE *1*: NeXT docs say immutable arrays are accessed more efficiently.
//-----------------------------------------------------------------------------
- (NSArray*)initLazyRow
    {
    NSMutableArray* array = [NSMutableArray array];
    NSFont* font = [scroll font];
    NSZone* const z = [self zone];
    int i;
    for (i = 0; i < MAX_SLOT; i++)
	{
	id c = [[[scroll columnCellPrototype:i] copyWithZone:z] autorelease];
	if ([c respondsToSelector:@selector(setOwner:)])
	    [c setOwner:scroll];
	else if ([c respondsToSelector:@selector(setFont:)])
	    [c setFont:font];
	[array addObject:c];
	}
    return [[array copy] autorelease];	// NOTE *1*
    }


//-----------------------------------------------------------------------------
// - initDefaults
//-----------------------------------------------------------------------------
- (void)initDefaults
    {
    static BOOL initialized = NO;
    if (!initialized)
	{
	DEFAULT_WIN_SIZE = [window frame].size;
	DEFAULT_FONT = 
		[[Defaults getFont:FONT_DEF fallback:[scroll font]] retain];
	initialized = YES;
	}
    }


//-----------------------------------------------------------------------------
// - loadDefaults
//-----------------------------------------------------------------------------
- (void)loadDefaults
    {
    NSString* s;

    NSRect r = [window frame];
    r.size = [Defaults getSize:SIZE_DEF fallback:DEFAULT_WIN_SIZE];
    [window setFrame:r display:NO];

    autoSort = DEFAULT_AUTO_SORT;
    showHidden = DEFAULT_SHOW_HIDDEN;
    highlightDirs = DEFAULT_HIGHLIGHT_DIRS;
    dragUnscaled = DEFAULT_DRAG_UNSCALED;

    [autoSortSwitch setState:autoSort];
    [hiddenFilesSwitch setState:showHidden];
    [highlightSwitch setState:highlightDirs];
    [dragUnscaledSwitch setState:dragUnscaled];
    [rowNumbersSwitch setState:DEFAULT_ROW_NUMBERS];

    [scroll setRowTitlesOn:DEFAULT_ROW_NUMBERS];
    [scroll setAutoSortRows:autoSort];
    [scroll setFont:DEFAULT_FONT];
    [self setColors:DEFAULT_COLOR];

    s = [Defaults getStr:COL_SIZES_DEF fallback:0];
    if (s)
	[scroll setColumnSizesFromString:s];

    s = [Defaults getStr:COL_ORDER_DEF fallback:0];
    if (s)
	[scroll setColumnOrderFromString:s];
    }


//-----------------------------------------------------------------------------
// - initLockSlot
//-----------------------------------------------------------------------------
- (void)initLockSlot
    {
    id proto = [scroll columnCellPrototype:LOCK_SLOT];
    [proto setButtonType:NSSwitchButton];
    [proto setImagePosition:NSImageOnly];
    [proto setTarget:self];
    [proto setAction:@selector(lockClick:)];
    [proto setImage:LOCKED_IMAGE];
    [proto setAlternateImage:UNLOCKED_IMAGE];
    }


//-----------------------------------------------------------------------------
// - initNameSlot
//-----------------------------------------------------------------------------
- (void)initNameSlot
    {
    id proto = [scroll columnCellPrototype:NAME_SLOT];
    [proto setEditable:YES];
    [proto setScrollable:YES];
    }


//-----------------------------------------------------------------------------
// - initSlots
//-----------------------------------------------------------------------------
- (void)initSlots
    {
    [self initLockSlot];
    [self initNameSlot];
    [[scroll columnCellPrototype:SIZE_SLOT] setAlignment:NSRightTextAlignment];
    [[scroll columnCellPrototype:HARDLINKS_SLOT]
		setAlignment:NSRightTextAlignment];
    }


//-----------------------------------------------------------------------------
// - initWithDir:
//-----------------------------------------------------------------------------
- (id)initWithDir:(NSString*)dirname
    {
    [super init];
    path = [[NSString alloc] init];
    [NSBundle loadNibNamed:@"DirWindow" owner:self];
    [window registerForDraggedTypes:
		[NSArray arrayWithObject:NSColorPboardType]];
    dirArray = [[DirArray allocWithZone:[self zone]] init];
    [self initSlots];
    [self initDefaults];
    [self loadDefaults];
    lazyRow = [[self initLazyRow] retain];
    [self load:dirname];
    [OPEN_DIRS addObject:self];
    [self cascade];
    return self;
    }


//-----------------------------------------------------------------------------
// - init
//-----------------------------------------------------------------------------
- (id)init
    {
    return [self initWithDir:NSHomeDirectory()];
    }


//-----------------------------------------------------------------------------
// - dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    NSZone* const z = [self zone];
    [window setDelegate:0];
    [window close];
    [window release];
    [path release];
    [dirArray release];
    [lazyRow release];
    [super dealloc];
    RETIRE_ZONE(z);
    }


//-----------------------------------------------------------------------------
// - path
//-----------------------------------------------------------------------------
- (NSString*)path
    {
    return path;
    }


//-----------------------------------------------------------------------------
// + findDir:
//-----------------------------------------------------------------------------
+ (DirWindow*)findDir:(NSString*)normalizedPath
    {
    if (normalizedPath != 0)
	{
	unsigned int i;
	unsigned int const lim = [OPEN_DIRS count];
	for (i = 0;  i < lim;  i++)
	    {
	    DirWindow* p = (DirWindow*)[OPEN_DIRS objectAtIndex:i];
	    NSString* s = [p path];
	    if (s != 0 && [s isEqualToString:normalizedPath])
		return p;
	    }
	}
    return 0;
    }


//-----------------------------------------------------------------------------
// + launchDir:
//-----------------------------------------------------------------------------
+ (void)launchDir:(NSString*)dirname
    {
    DirWindow* p = 0;
    if (dirname == 0) dirname = NSHomeDirectory();
    if (dirname == 0) dirname = @"/";
    dirname = normalize_path( dirname );
    if ((p = [self findDir:dirname]) == 0)
	p = [[self allocWithZone:EMPLOY_ZONE()] initWithDir:dirname];
    [p activateWindow];
    }

@end
