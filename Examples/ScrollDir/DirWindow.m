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
// $Id: DirWindow.m,v 1.14 99/08/12 23:06:27 sunshine Exp $
// $Log:	DirWindow.m,v $
// Revision 1.14  99/08/12  23:06:27  sunshine
// v35.1: Fixed bug: -getParent did not work correctly on Windows.
// Added -fullPathOf: which appends the input argument to "path" in order to
// generate a full path, except when the input argument is "..", in which
// case -getParent is called.  This fixes a number of problem areas where ".."
// was being appended to "C:\" on Windows and failing.
// 
// Revision 1.13  99/06/14  16:31:16  sunshine
// v35.1: Ported to MacOS/X Server DR2 for Mach and Windows.
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
// 
// Revision 1.12  1998/03/30 09:21:07  sunshine
// v34.1: Worked around PPC compiler for Rhapsody DR1 compiler bug.  Compiler
// claimed "totalBytes" was being accessed uninitialized.
//
// Revision 1.11  98/03/30  00:41:25  sunshine
// v34.1: Now uses NSColor's "system" color by default for window rather than
// hard-wired light-gray.
//-----------------------------------------------------------------------------
#import "DirWindow.h"
#import "Defaults.h"
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

static NSString* const DA_SHORT_NAME = @"ShortName";
static NSString* const DA_SOFT_LINK = @"SoftLink";
static NSString* const DA_IS_DIRECTORY = @"IsDirectory";
static NSString* const DA_IS_LOCKED = @"IsLocked";
static NSString* const DA_CAN_TOGGLE_LOCK = @"CanToggleLock";
static NSString* const DA_SCALED_ICON = @"ScaledIcon";
static NSString* const DA_UNSCALED_ICON = @"UnscaledIcon";


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
// dir_writable
//-----------------------------------------------------------------------------
static BOOL dir_writable( NSString* path )
    {
    return [[NSFileManager defaultManager] isWritableFileAtPath:path];
    }


//-----------------------------------------------------------------------------
// dir_sticky
//-----------------------------------------------------------------------------
static BOOL dir_sticky( NSDirectoryEnumerator* enumerator )
    {
    int const STICKY_BIT = 01000;
    unsigned long n = [[enumerator directoryAttributes] filePosixPermissions];
    return ((n & STICKY_BIT) != 0);
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
    NSImage* i = [dict objectForKey:DA_SCALED_ICON];

    w = [ts columnSize:ICON_SLOT];	if (w == 0) w = 18;
    h = [ts uniformSizeRows];		if (h == 0) h = 18;
    s = (w < h ? w : h) - 1.0;

    [i setSize:NSMakeSize( s, s )];
    [cell setImage:i];
    [cell setRepresentedObject:[dict objectForKey:DA_UNSCALED_ICON]];
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
    NSDate* d = [dict fileModificationDate];
    [cell setStringValue:str_date(d)];
    [cell setTag:(int)[d timeIntervalSinceReferenceDate]];
    }


//-----------------------------------------------------------------------------
// fmt_perms
//-----------------------------------------------------------------------------
static void fmt_perms( MiscTableScroll* ts, NSDictionary* dict, id cell )
    {
    [cell setStringValue:
	str_perms( [dict filePosixPermissions], [dict fileType])];
    [cell setTag:[[dict objectForKey:DA_IS_DIRECTORY] boolValue]];
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
	DEFAULT_AUTO_SORT = [Defaults getBool:SORT_DEF fallback:YES];
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
// - getParent
//	Unfortunately -stringByDeletingLastPathComponent does not work as
//	documented when operating on a root directory.  On Mach, when handed
//	"/", it returns "" rather than "/" as documented.  On Windows, when
//	handed "C:\", it returns "C:" rather than "C:\" as documented.
//	Therefore, we use -isAbsolutePath as a sneaky way to detect this
//	anomalous condition.
//-----------------------------------------------------------------------------
- (NSString*)getParent
    {
    NSString* s = [path stringByDeletingLastPathComponent];
    return ([s isAbsolutePath] ? s : path);
    }


//-----------------------------------------------------------------------------
// - fullPathOf:
//-----------------------------------------------------------------------------
- (NSString*)fullPathOf:(NSString*)file
    {
    return [file isEqualToString:@".."] ?
	[self getParent] : [path stringByAppendingPathComponent:file];
    }


//-----------------------------------------------------------------------------
// - isDir:
//-----------------------------------------------------------------------------
- (BOOL)isDir:(int)r
    {
    return [scroll tagAtRow:r column:PERMS_SLOT];
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
// - setRow:useOwner:color:
//-----------------------------------------------------------------------------
- (void)setRow:(int)r useOwner:(BOOL)useOwner color:(NSColor*)color
    {
    int i;
    for (i = MAX_SLOT; i-- >= 0; )
	{
	id cell = [scroll cellAtRow:r column:i];
	if (useOwner &&
	    [cell respondsToSelector:@selector(setUseOwnerBackgroundColor:)])
	    {
	    [cell setUseOwnerBackgroundColor:YES];
	    if ([cell respondsToSelector:@selector(setOwnerBackgroundColor:)])
		[cell setOwnerBackgroundColor:color];
	    }
	else if ([cell respondsToSelector:@selector(setBackgroundColor:)])
	    [cell setBackgroundColor:color];
	}
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
// - highlight:row:
//-----------------------------------------------------------------------------
- (void)highlight:(BOOL)flag row:(int)r
    {
    if (flag)
	[self setRow:r useOwner:NO color:[NSColor cyanColor]];
    else
        [self setRow:r useOwner:YES color:[self scrollColor]];
    }


//-----------------------------------------------------------------------------
// - highlightDirs:
//-----------------------------------------------------------------------------
- (void)highlightDirs:(BOOL)flag
    {
    int i;
    for (i = [scroll numberOfRows]; i-- > 0; )
	if ([self isDir:i])
	    [self highlight:flag row:i];
    }


//-----------------------------------------------------------------------------
// - releaseImages
//-----------------------------------------------------------------------------
- (void)releaseImages
    {
    int i;
    for (i = [scroll numberOfRows]; i-- > 0; )
	{
	id cell = [scroll cellAtRow:i column:ICON_SLOT];
	[cell setImage:0];		// Scaled image.
	[cell setRepresentedObject:0];	// Unscaled image.
	}
    }


//-----------------------------------------------------------------------------
// - tableScrollChangeFont:
//-----------------------------------------------------------------------------
- (void)tableScrollChangeFont:(NSNotification*)n
    {
    [DEFAULT_FONT autorelease];
    DEFAULT_FONT = [[[n userInfo] objectForKey:@"NewFont"] retain];
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
		[[ts cellAtRow:row column:LOCK_SLOT] state] != 0);
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
    NSString* file = [self fullPathOf:[s stringValueAtRow:r column:NAME_SLOT]];
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
    id cell = [s cellAtRow:r column:c];
    return (dragUnscaled ? [cell representedObject] : 0);
    }


//-----------------------------------------------------------------------------
// - extendedAttributes:forFile:dirSticky:username:
//-----------------------------------------------------------------------------
- (NSDictionary*)extendedAttributes:(NSDictionary*)attributes
	forFile:(NSString*)file
	dirSticky:(BOOL)sticky
	username:(NSString*)username
    {
    NSImage* image;
    NSFileManager* const manager = [NSFileManager defaultManager];
    NSString* const longName = [file isEqualToString:@".."] ?
	[self getParent] : [path stringByAppendingPathComponent:file];
    BOOL const canToggle = writable && ![file isEqualToString:@".."] &&
	(!sticky || [[attributes fileOwnerAccountName]
	isEqualToString:username]);
    BOOL const isLink = [[attributes fileType]
	isEqualToString:NSFileTypeSymbolicLink];
    NSDictionary* const deepAttributes = !isLink ? attributes :
	[manager fileAttributesAtPath:longName traverseLink:YES];
    BOOL const isDir = [[deepAttributes fileType]
	isEqualToString:NSFileTypeDirectory];
    NSMutableDictionary* const dict = [[attributes mutableCopy] autorelease];
    [dict setObject:file forKey:DA_SHORT_NAME];
    [dict setObject:isLink ?
	[manager pathContentOfSymbolicLinkAtPath:longName] : @""
	forKey:DA_SOFT_LINK];
    [dict setObject:[NSNumber numberWithBool:isDir] forKey:DA_IS_DIRECTORY];
    [dict setObject:[NSNumber numberWithBool:canToggle]
	forKey:DA_CAN_TOGGLE_LOCK];
    [dict setObject:[NSNumber numberWithBool:!canToggle] forKey:DA_IS_LOCKED];
    image = [[NSWorkspace sharedWorkspace] iconForFile:longName];
    [dict setObject:[[image copy] autorelease] forKey:DA_UNSCALED_ICON];
    [image setScalesWhenResized:YES];
    [dict setObject:image forKey:DA_SCALED_ICON];
    return dict;
    }


//-----------------------------------------------------------------------------
// - addFile:attributes:dirSticky:username:
//-----------------------------------------------------------------------------
- (void)addFile:(NSString*)file attributes:(NSDictionary*)attributes
	dirSticky:(BOOL)sticky username:(NSString*)username
    {
    int r,c;
    NSDictionary* dict = [self extendedAttributes:attributes forFile:file
				dirSticky:sticky username:username];
    [scroll addRow];
    r = [scroll numberOfRows] - 1;
    for (c = 0; c < MAX_SLOT; c++)
	format_cell( scroll, dict, [scroll cellAtRow:r column:c], c );

    if (highlightDirs && [[dict objectForKey:DA_IS_DIRECTORY] boolValue])
	[self highlight:YES row:r];
    }


//-----------------------------------------------------------------------------
// - fillScroll
//	NOTE *1*: Ugly work around for PPC compiler bug in Rhapsody DR1.
//	Compiler erroneously reports "totalBytes" used when uninitialized.
//-----------------------------------------------------------------------------
- (void)fillScroll
    {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator* enumerator = [manager enumeratorAtPath:path];
    unsigned long long totalBytes;
    *(&totalBytes) = 0;			// NOTE *1*

    [self releaseImages];
    [scroll empty];

    if (enumerator == 0)
	NSRunAlertPanel( @"Can't Read",
		@"Cannot read directory, %@", @"OK", 0, 0, path );
    else
	{
	NSString* file;
	NSString* username = [[NSUserName() retain] autorelease];
	BOOL const sticky = dir_sticky( enumerator );
	writable = dir_writable( path );

	[self addFile:@".." attributes:
		[manager fileAttributesAtPath:[self getParent]
		traverseLink:NO] dirSticky:sticky username:username];

	while ((file = [enumerator nextObject]) != 0)
	    {
	    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	    NSDictionary* attributes = [enumerator fileAttributes];
	    if (showHidden || [file characterAtIndex:0] != '.')
		{
		totalBytes += [attributes fileSize];
		[self addFile:file attributes:attributes dirSticky:sticky
			username:username];
		}
	    if ([[attributes fileType] isEqualToString:NSFileTypeDirectory])
		[enumerator skipDescendents];
	    [pool release];
	    }
	}

    if ([scroll autoSortRows])
	[scroll sortRows];
    [scroll sizeToCells];
    
    [countField setStringValue:
		[NSString stringWithFormat:@"%d files   %lu bytes",
		[scroll numberOfRows], totalBytes]];

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
// - load:
//-----------------------------------------------------------------------------
- (void)load:(NSString*)dirname
    {
    [self setPath:dirname];
    [self fillScroll];
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
	    NSString* s =
		[self fullPathOf:[scroll stringValueAtRow:r column:NAME_SLOT]];
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
    if (writable && [scroll hasRowSelection])
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
		NSString* s = [self fullPathOf:
			[scroll stringValueAtRow:row column:NAME_SLOT]];
		[manager removeFileAtPath:s handler:0];
		}
	    [self fillScroll];
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

    oldName = [[scroll cellAtRow:r column:c] stringValue];
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
    [scroll abortEditing];
    [self fillScroll];
    }


//-----------------------------------------------------------------------------
// - cdPressed:
//-----------------------------------------------------------------------------
- (void)cdPressed:(id)sender
    {
    [scroll abortEditing];
    if ([scroll numberOfSelectedRows] == 1)
	{
	MiscCoord_P const row = [scroll selectedRow];
	if ([self isDir:row])
	    [self load:normalize_path( [self fullPathOf:
			[scroll stringValueAtRow:row column:NAME_SLOT]] )];
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
	[self fillScroll];
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
	[self highlightDirs:highlightDirs];
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
    if ([sender autoSortRows])
	[sender sortRow:[sender clickedRow]];
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
    [self initSlots];
    [self initDefaults];
    [self loadDefaults];
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
    [self releaseImages];
    [window release];
    [path release];
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
