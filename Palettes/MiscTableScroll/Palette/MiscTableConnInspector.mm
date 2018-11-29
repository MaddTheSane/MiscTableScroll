//=============================================================================
//
//	Copyright (C) 1996-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableConnInspector.M
//
//	A custom Interface Builder connection inspector so that the
//	doubleTarget and doubleAction can be set.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableConnInspector.M,v 1.13 99/06/30 09:24:10 sunshine Exp $
// $Log:	MiscTableConnInspector.M,v $
// Revision 1.13  99/06/30  09:24:10  sunshine
// v140.1: Ported to MacOS/X Server in which -outletsOfClass: and
// -actionsOfClass: have been deprectaed in favor of new methods
// -outletNamesOfClass: and -actionNamesOfClass:, respectively.  Uses
// -respondsToSelector: to determine if new messages should be sent, or old.
// 
// Revision 1.12  99/06/14  19:25:18  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Nib connector classes changed name in MacOS/X Server from NSIBConnector,
// to NSIBOutletConnector, and NSIBControlConnector to NSNibConnector,
// NSNibOutletConnector, and NSNibControlConnector, respectively.
// The "Name" column on the outlet and action MiscTableScrolls now autosizes
// since the old hardcoded size is inappropriate for MacOS/X Server DR.
// Worked around problem introduced in MacOS/X Server and YellowBox DR2.
// Symptom was that method in action list for action and doubleAction was
// not being selected when inspected for nibs which had been loaded from a
// file.  Problem was that -[IBClassData actionsOfClass:] no longer appends
// a colon ":" to returned action names, as it did previously.  We were doing
// a simple string comparison to locate the name in the action list which
// consequently failed.  Now canonicalizes names before comparison.
// Now uses NSStringFromClass() in place of +[NSObject description].
// Added extra explanatory comments.
//-----------------------------------------------------------------------------
#import "MiscTableConnInspector.h"
#import "MiscTableConnector.h"
#import	<MiscTableScroll/MiscTableScroll.h>

extern "C" {
#import <AppKit/NSImage.h>
#import <AppKit/NSApplication.h>
#import	<Foundation/NSArray.h>
#import	<Foundation/NSBundle.h>
#import	<Foundation/NSDictionary.h>
#import	<Foundation/NSString.h>
}

enum MiscTSOutletSlot
	{
	MISC_TS_NAME_OS,
	MISC_TS_CONN_OS,
	MISC_TS_PTR_OS
	};

enum MiscTSActionSlot
	{
	MISC_TS_NAME_AS,
	MISC_TS_CONN_AS
	};


#define ICON_DIMPLE @"MiscTableDimple"
#define ICON_ARROW  @"MiscTableRightArrow"
#define ICON_BLANK  @"MiscBlankImage"

static NSImage* IMAGE_DIMPLE;
static NSImage* IMAGE_ARROW;
static NSImage* IMAGE_BLANK;

static NSString*	OUTLET_ACTION_FILE = @"MiscTableConnector";
static NSDictionary*	OUTLET_ACTION_DICT = 0;

static id		FIRST_RESP = (id)~0;
static NSString*	FIRST_RESP_NAME = @"FirstResponder";


//=============================================================================
// PRIVATE IB METHODS
//=============================================================================
@interface IBDocument: NSObject
- (id)classData;	// (IBClassData)
@end

@interface IBClassData: NSObject
- (id)outletsOfClass:(NSString*)s;	// Pre-MacOX/S Server
- (id)actionsOfClass:(NSString*)s;	// Pre-MacOX/S Server
- (id)outletNamesOfClass:(NSString*)s;	// MacOS/X Server
- (id)actionNamesOfClass:(NSString*)s;	// MacOS/X Server
@end


//=============================================================================
// CATEGORIES OF PRIVATE IB CONNECTION CLASSES
// Add useful utility methods which are otherwise absent.
//=============================================================================

@interface NSNibConnector(MiscTableConnInspector)
- (id)initSource:(id)src destination:(id)dst label:(id)lbl;
- (NSString*)outletName;
- (NSString*)actionName;
- (NSString*)actionValue;
@end

@implementation NSNibConnector(MiscTableConnInspector)
- (id)initSource:(id)src destination:(id)dst label:(id)lbl
    {
    [self init];
    [self setSource:src];
    [self setDestination:dst];
    [self setLabel:lbl];
    return self;
    }
- (NSString*)outletName	 { return [self label]; }
- (NSString*)actionName	 { return 0; }
- (NSString*)actionValue { return 0; }
@end

@interface NSNibControlConnector(MiscTableConnInspector)
- (NSString*)outletName;
- (NSString*)actionName;
- (NSString*)actionValue;
@end

@implementation NSNibControlConnector(MiscTableConnInspector)
- (NSString*)outletName	 { NSString* s = @"target"; return s; }
- (NSString*)actionName	 { NSString* s = @"action"; return s; }
- (NSString*)actionValue { return [self label]; }
@end


//=============================================================================
// TABLE SCROLL CATEGORY
//=============================================================================
@interface MiscTableScroll(MiscTableConnInspector)
- (NSString*)connectInspectorClassName;
@end

@implementation MiscTableScroll(MiscTableConnInspector)
- (NSString*)connectInspectorClassName
	{ NSString* s = @"MiscTableConnInspector"; return s; }
@end


//=============================================================================
// TABLE CONNECTOR CATEGORY
// Add methods for creation and encoding of MiscTableConnector.  This code is
// only available in the palette, and complements the code in the framework
// which allows only immutable access to the connector.
//=============================================================================
@interface MiscTableConnector(MiscTableConnInspector)
- (NSString*)outletName;
- (NSString*)actionName;
- (id)initSource:(id)src destination:(id)dst label:(NSString*)lbl
	outlet:(NSString*)out action:(NSString*)act;
- (void)encodeWithCoder:(NSCoder*)aCoder;
- (NSString*)nibLabel;
@end

@implementation MiscTableConnector(MiscTableConnInspector)

- (NSString*)outletName { return outletName; }
- (NSString*)actionName { return actionName; }

- (id)initSource:(id)src destination:(id)dst label:(NSString*)lbl
    outlet:(NSString*)out action:(NSString*)act
    {
    [self superInitSource:src destination:dst label:lbl];
    outletName = [out retain];
    actionName = [act retain];
    return self;
    }

- (void)encodeWithCoder:(NSCoder*)coder
    {
    [self superEncodeWithCoder:coder];
    [coder encodeObject:outletName];
    [coder encodeObject:actionName];
    }

- (NSString*)nibLabel
    {
    return [NSString stringWithFormat:
		@"%@/%@", [self outletName], [self actionValue] ];
    }

@end


//=============================================================================
// TABLE CONNECTOR INSPECTOR IMPLEMENTATION
//=============================================================================
@implementation MiscTableConnInspector

//-----------------------------------------------------------------------------
// +initialize
//-----------------------------------------------------------------------------
+ (void)initialize
    {
    NSString* path;
    NSBundle* bundle = [NSBundle bundleForClass:self];

    path = [bundle pathForImageResource:ICON_DIMPLE];
    IMAGE_DIMPLE = [[NSImage alloc] initByReferencingFile:path];
    [IMAGE_DIMPLE setName:ICON_DIMPLE];

    path = [bundle pathForImageResource:ICON_ARROW];
    IMAGE_ARROW = [[NSImage alloc] initByReferencingFile:path];
    [IMAGE_ARROW setName:ICON_ARROW];

    IMAGE_BLANK = [[NSImage alloc] init];
    [IMAGE_BLANK setName:ICON_BLANK];

    path = [bundle pathForResource:OUTLET_ACTION_FILE ofType:@"strings"];
    OUTLET_ACTION_DICT =
		[[NSDictionary dictionaryWithContentsOfFile:path] retain];
    }


//-----------------------------------------------------------------------------
// +actionForOutlet:
//-----------------------------------------------------------------------------
+ (NSString*)actionForOutlet:(NSString*)name
    {
    return [OUTLET_ACTION_DICT objectForKey:name];
    }


//-----------------------------------------------------------------------------
// -actionForOutlet:
//-----------------------------------------------------------------------------
- (NSString*)actionForOutlet:(NSString*)name
    {
    return [OUTLET_ACTION_DICT objectForKey:name];
    }


//-----------------------------------------------------------------------------
// -dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    [punctuation release];
    [connList release];
    [curout release];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// -initScroll:numCols:
//-----------------------------------------------------------------------------
- (void)initScroll:(MiscTableScroll*)scroll numCols:(int)numCols
    {
    [scroll setAutoSortRows:YES];
    [scroll setSelectionMode:MISC_RADIO_MODE];
    [scroll setDelegate:self];
    [scroll setTarget:self];
    [scroll setDoubleTarget:self];
    for (int i = 0; i < numCols; i++)
	[scroll addColumn];
    }


//-----------------------------------------------------------------------------
// -init
//-----------------------------------------------------------------------------
- (id)init
    {
    [super init];

    connList = [[NSArray array] retain];

    [NSBundle loadNibNamed:[[self class] description] owner:self];

    [self initScroll:outletScroll numCols:3];
    [outletScroll setAction:@selector(outletClick:)];
    [outletScroll setDoubleAction:@selector(outletDblClick:)];
    [outletScroll setColumn:MISC_TS_NAME_OS autosize:YES];
    [outletScroll setColumn:MISC_TS_NAME_OS title:@"Outlets"];
    [outletScroll setColumn:MISC_TS_CONN_OS size:13];
    [outletScroll setColumn:MISC_TS_CONN_OS sizeable:NO];
    [outletScroll setColumn:MISC_TS_CONN_OS cellType:MISC_TABLE_CELL_IMAGE];
    [outletScroll setColumn:MISC_TS_CONN_OS sortType:MISC_SORT_TAG];
    [outletScroll setColumn:MISC_TS_PTR_OS size:13];
    [outletScroll setColumn:MISC_TS_PTR_OS sizeable:NO];
    [outletScroll setColumn:MISC_TS_PTR_OS cellType:MISC_TABLE_CELL_IMAGE];
    [outletScroll setColumn:MISC_TS_PTR_OS sortType:MISC_SORT_TAG];
    [outletScroll setColumn:MISC_TS_PTR_OS sortDirection:MISC_SORT_DESCENDING];

    [self initScroll:actionScroll numCols:2];
    [actionScroll setAction:@selector(actionClick:)];
    [actionScroll setDoubleAction:@selector(actionDblClick:)];
    [actionScroll setColumn:MISC_TS_NAME_AS autosize:YES];
    [actionScroll setColumn:MISC_TS_NAME_AS title:@"Actions"];
    [actionScroll setColumn:MISC_TS_CONN_AS size:13];
    [actionScroll setColumn:MISC_TS_CONN_AS sizeable:NO];
    [actionScroll setColumn:MISC_TS_CONN_AS cellType:MISC_TABLE_CELL_IMAGE];
    [actionScroll setColumn:MISC_TS_CONN_AS sortType:MISC_SORT_TAG];
    [actionScroll setColumn:MISC_TS_CONN_AS sortDirection:MISC_SORT_DESCENDING];

    [outletScroll setNextKeyView:actionScroll];
    [actionScroll setNextKeyView:outletScroll];

    punctuation = [[NSCharacterSet punctuationCharacterSet] retain];
    return self;
    }


//-----------------------------------------------------------------------------
// classNameOf:
//-----------------------------------------------------------------------------
- (NSString*)classNameOf:(id)obj
    {
    if ([obj respondsToSelector:@selector(className)])
	return [obj performSelector:@selector(className)];
    else
	return NSStringFromClass( [obj class] );
    }


//-----------------------------------------------------------------------------
// -getConnList
//-----------------------------------------------------------------------------
- (void)getConnList
    {
    [connList autorelease];
    connList = [[[NSApp activeDocument]
		connectorsForSource:[self object]] retain];
    }


//-----------------------------------------------------------------------------
// -findConnectionForOutlet:
//	Note: this method is only accurate when connList is valid.
//-----------------------------------------------------------------------------
- (id)findConnectionForOutlet:(NSString*)outletName
    {
    unsigned int const lim = [connList count];
    for (unsigned int i = 0; i < lim; i++)
	{
	id conn = [connList objectAtIndex:i];
	if ([outletName isEqualToString:[conn outletName]])
	    return conn;
	}
    return 0;
    }


//-----------------------------------------------------------------------------
// -connectionForOutlet:
//-----------------------------------------------------------------------------
- (id)connectionForOutlet:(NSString*) outletName
    {
    [self getConnList];
    return [self findConnectionForOutlet:outletName];
    }


//-----------------------------------------------------------------------------
// virtualDestFor:
//-----------------------------------------------------------------------------
- (id)virtualDestFor:(id)dest
    {
    if (dest == 0 || [[self classNameOf:dest] isEqualToString:FIRST_RESP_NAME])
	return FIRST_RESP;
    return dest;
    }


//-----------------------------------------------------------------------------
// realDestFor:
//-----------------------------------------------------------------------------
- (id)realDestFor:(id)dest
    {
    return (dest == FIRST_RESP ? 0 : dest);
    }


//-----------------------------------------------------------------------------
// -set:outlet:
//	Note: this method is only accurate when connList is valid.
//-----------------------------------------------------------------------------
- (void)set:(int)row outlet:(NSString*)name
    {
    id cell;
    id conn = [self findConnectionForOutlet:name];
    id dest = (conn == 0 ? 0 : [self virtualDestFor:[conn destination]]);

    [outletScroll setRow:row tag:int(dest)];

    [[outletScroll cellAtRow:row column:MISC_TS_NAME_OS] setStringValue:name];

    BOOL const is_connected = (conn != 0);
    cell = [outletScroll cellAtRow:row column:MISC_TS_CONN_OS];
    [cell setImage:(is_connected ? IMAGE_DIMPLE : IMAGE_BLANK)];
    [cell setTag:int(is_connected)];

    BOOL const has_action = ([self actionForOutlet:name] != 0);
    cell = [outletScroll cellAtRow:row column:MISC_TS_PTR_OS];
    [cell setImage:(has_action ? IMAGE_ARROW : IMAGE_BLANK)];
    [cell setTag:int(has_action)];
    }


//-----------------------------------------------------------------------------
// -loadOutlets
//	Note: this method is only accurate when connList is valid.
//
//	Note: For some silly reason, the -outletsOfClass: method filters
//	out the "target" outlet.  (Who knows why -- must be more hardcoded
//	internal IB junk.)  Therefore, we need to add it back in, manually.
//-----------------------------------------------------------------------------
- (void)loadOutlets
    {
    NSString* className = [self classNameOf:[self object]];
    id doc = [NSApp activeDocument];
    id data = [doc classData];
    id list;
    if ([data respondsToSelector:@selector(outletNamesOfClass:)])
	list = [data outletNamesOfClass:className];	// MacOS/X Server
    else
	list = [data outletsOfClass:className];		// Pre-MacOS/X Server
    unsigned int const lim = [list count];
    if (lim > 0)
	{
	id str;
	[outletScroll renewRows:lim + 1];	// Add one for target.
	NSEnumerator* enu = [list objectEnumerator];
	for (int i = 0; (str = [enu nextObject]) != 0; i++)
	    [self set:i outlet:str];
	[self set:lim outlet:@"target"];
	[outletScroll sortRows];
	}
    else
	[outletScroll empty];
    }


//-----------------------------------------------------------------------------
// -selectedOutletName
//-----------------------------------------------------------------------------
- (NSString*)selectedOutletName
    {
    NSString* s = 0;
    int const r = [outletScroll selectedRow];
    if (r >= 0)
	s = [outletScroll stringValueAtRow:r column:MISC_TS_NAME_OS];
    return s;
    }


//-----------------------------------------------------------------------------
// -shouldShowActions:
//-----------------------------------------------------------------------------
- (BOOL)shouldShowActions:(id*)old_dest
    {
    int const r = [outletScroll selectedRow];
    if (r >= 0 && [outletScroll tagAtRow:r column:MISC_TS_PTR_OS] != 0)
	{
	*old_dest = (id)[outletScroll rowTag:r];
	return YES;
	}
    return NO;
    }


//-----------------------------------------------------------------------------
// canonicalAction:
//	Prior to MacOS/X Server & YellowBox DR2, action names returned by 
//	-[IBClassData actionsOfClass:] were always suffixed with a colon ":".  
//	Since Java uses "()" rather than ":", as of DR2, -actionsOfClass: 
//	simply returns the base name of each action, sans ":" or "()".  
//	However, NSNibControlConnector still returns the action name with a 
//	trailing colon, so we need to canonicalize the names prior to 
//	comparing them.  
//-----------------------------------------------------------------------------
- (NSString*)canonicalAction:(NSString*)s
    {
    if (s != 0)
	{
	NSRange const r = [s rangeOfCharacterFromSet:punctuation];
	if (r.length != 0)
	    s = [s substringWithRange:NSMakeRange(0, r.location)];
	}
    return s;
    }


//-----------------------------------------------------------------------------
// -loadActions
//-----------------------------------------------------------------------------
- (void)loadActions
    {
    [actionScroll empty];
    id old_dest = 0;
    if ([self shouldShowActions:&old_dest])
	{
	int sel_row = -1;
	id dest = (curdst != 0 ? curdst : old_dest);
	if (dest == 0 && [NSApp isConnecting])
	    dest = [self virtualDestFor:[NSApp connectDestination]];
	if (dest != 0)
	    {
	    NSString* lbl = 0;
	    if (dest == old_dest)
		{
		NSString* oname = [self selectedOutletName];
		id conn = [self connectionForOutlet:oname];
		if (conn != 0)
		    lbl = [self canonicalAction:[conn label]];
		}

	    NSString* className = (dest == FIRST_RESP ?
				FIRST_RESP_NAME : [self classNameOf:dest]);
	    id doc = [NSApp activeDocument];
	    id data = [doc classData];
	    id list;
	    if ([data respondsToSelector:@selector(actionNamesOfClass:)])
		list = [data actionNamesOfClass:className]; // MacOS/X Server
	    else
		list = [data actionsOfClass:className]; // Pre-MacOS/X Server
	    unsigned int const lim = [list count];
	    [actionScroll renewRows:lim];
	    id str;
	    NSEnumerator* enu = [list objectEnumerator];
	    for (int i = 0; (str = [enu nextObject]) != 0; i++)
		{
		[[actionScroll cellAtRow:i column:MISC_TS_NAME_AS]
				setStringValue:str];
		BOOL const connected = lbl != 0 &&
			[lbl isEqualToString:[self canonicalAction:str]];
		id cell = [actionScroll cellAtRow:i column:MISC_TS_CONN_AS];
		[cell setImage:(connected ? IMAGE_DIMPLE : IMAGE_BLANK)];
		[cell setTag:int(connected)];
		if (connected)
		    sel_row = i;
		}
	    }
	if ([actionScroll numberOfRows] > 0)
	    {
	    [actionScroll sortRows];
	    if (sel_row >= 0)
		{
		[actionScroll selectRow:sel_row];
		[actionScroll scrollRowToVisible:sel_row];
		}
	    }
	}
    }


//-----------------------------------------------------------------------------
// -selectOutlet:
//-----------------------------------------------------------------------------
- (void)selectOutlet:(NSString*)name
    {
    int row = -1;
    if (name != 0 && [name length] > 0)
	{
	int const lim = [outletScroll numberOfRows];
	for (int i = 0; i < lim; i++)
	    {
	    int const j = [outletScroll rowAtPosition:i];
	    NSString* t = [outletScroll stringValueAtRow:j
				column:MISC_TS_NAME_OS];
	    if (t != 0 && [t isEqualToString:name])
		{
		row = j;
		break;
		}
	    }
	}
    [outletScroll selectRow:row];
    if (row >= 0)
	[outletScroll scrollRowToVisible:row];
    [self loadActions];
    }


//-----------------------------------------------------------------------------
// -setCurout:
//-----------------------------------------------------------------------------
- (void)setCurout:(NSString*)newout
    {
    [curout autorelease];
    curout = newout;
    [curout retain];
    }


//-----------------------------------------------------------------------------
// -outletClick:
//-----------------------------------------------------------------------------
- (void)outletClick:(id)sender
    {
    int const r = [outletScroll selectedRow];
    if (r >= 0)
	{
	NSString* s = [outletScroll stringValueAtRow:r column:MISC_TS_NAME_OS];
	cursrc = [self object];
	[self setCurout:s];
	id conn = [self connectionForOutlet:s];
	if (conn != 0)
	    {
	    id dst = [conn destination];
	    curdst = [self virtualDestFor:dst];
	    //[NSApp displayConnectionBetween:[conn source] and:dst];
	    }
	else
	    curdst = 0;
	}
    [self loadActions];
    }


//-----------------------------------------------------------------------------
// -outletDblClick:
//	NOTE *1* The only action allowed on the outlet column for 
//	target/action style outlets is breaking "old" connections that
//	do not have an action set.
//-----------------------------------------------------------------------------
- (void)outletDblClick:(id)sender
    {
    int const r = [outletScroll selectedRow];
    if (r >= 0)
	{
	id old_dest = 0;
	id new_dest = 0;
	id doc = [NSApp activeDocument];

	NSString* outletName =
		[outletScroll stringValueAtRow:r column:MISC_TS_NAME_OS];
	id conn = [self connectionForOutlet:outletName];

	BOOL do_break = NO;
	BOOL do_make = NO;
	BOOL const has_action =
		(BOOL) [outletScroll tagAtRow:r column:MISC_TS_PTR_OS];
	if (has_action)
	    {
	    do_break = (conn != 0 && [conn actionName] == 0);	// NOTE *1*
	    }
	else
	    {
	    do_break = (conn != 0);
	    old_dest = [self virtualDestFor:[conn destination]];
	    new_dest = [self virtualDestFor:[NSApp connectDestination]];
	    do_make = (new_dest != FIRST_RESP && new_dest != old_dest);
	    }

	if (do_break)
	    [doc removeConnector:conn];

	if (do_make)
	    {
	    conn = [[NSNibOutletConnector alloc]
			initSource:[self object]
			destination:[self realDestFor:new_dest]
			label:outletName];
	    [doc addConnector:conn];
	    }

	if (do_break || do_make)
	    [self ok:0];
	}
    }


//-----------------------------------------------------------------------------
// -actionClick:
//-----------------------------------------------------------------------------
- (void)actionClick:(id)sender
    {
    }


//-----------------------------------------------------------------------------
// -actionDblClick:
//	*1* FIXME: Stop this cycle of stupidity!  If we can get a better,
//	more generic subclass to work, that accepts the name of the outlet,
//	the name of the action-variable as part of the constructor, then we
//	should do that.
//-----------------------------------------------------------------------------
- (void)actionDblClick:(id)sender
    {
    int const r = [actionScroll selectedRow];
    if (r >= 0)
	{
	id doc = [NSApp activeDocument];
	id dest = [self virtualDestFor:[NSApp connectDestination]];
	NSString* outletName = [self selectedOutletName];
	id conn = [self connectionForOutlet:outletName];
	if (conn != 0)
	    [doc removeConnector:conn];

	int const tag = [actionScroll tagAtRow:r column:MISC_TS_CONN_AS];
	if (tag == 0)
	    {
	    NSString* s = [actionScroll stringValueAtRow:r
				column:MISC_TS_NAME_AS];
	    id realDest = [self realDestFor:dest];
	    if ([outletName isEqualToString:@"target"])
		{
		conn = [[NSNibControlConnector alloc]
			initSource:[self object] destination:realDest label:s];
		}
	    else
		{
		conn = [[MiscTableConnector alloc]
			initSource:[self object] destination:realDest label:s
			outlet:outletName
			action:[self actionForOutlet:outletName]];
		}
	    if (conn != 0)
		{
		[self setCurout:outletName];
		[doc addConnector:conn];
		}
	    }
	[self ok:0];
	}
    }


//-----------------------------------------------------------------------------
// findRowWithTag
//	Find the first row (in visual-order) with the given tag.
//-----------------------------------------------------------------------------
static int findRowWithTag( MiscTableScroll* scroll, int tag )
    {
    unsigned int const lim = [scroll numberOfRows];
    for (unsigned int i = 0; i < lim; i++)
	{
	int const r = [scroll rowAtPosition:i];
	if ([scroll rowTag:r] == tag)
	    return r;
	}
    return -1;
    }


//-----------------------------------------------------------------------------
// -preselectOutlet
//-----------------------------------------------------------------------------
- (NSString*)preselectOutlet
    {
    int row = findRowWithTag( outletScroll, int(curdst) );
    if (row < 0)
	{
	row = findRowWithTag( outletScroll, 0 );
	if (row < 0)
	    row = 0;
	}

    return [outletScroll stringValueAtRow:row column:MISC_TS_NAME_OS];
    }


//-----------------------------------------------------------------------------
// -preselect
//-----------------------------------------------------------------------------
- (void)preselect
    {
    if ([outletScroll numberOfRows] > 0)
	{
	id oldsrc = cursrc;
	id olddst = curdst;
	if ([NSApp isConnecting])
	    {
	    cursrc = [NSApp connectSource];
	    curdst = [self virtualDestFor:[NSApp connectDestination]];
	    }
	else
	    {
	    cursrc = [self object];
	    curdst = 0;
	    }
    
	if (oldsrc != cursrc || olddst != curdst)
	    [self setCurout:[self preselectOutlet]];
    
	[self selectOutlet:curout];
	}
    }


//-----------------------------------------------------------------------------
// -revert:
//-----------------------------------------------------------------------------
- (void)revert:(id)sender
    {
    [super revert:sender];
    [self getConnList];
    [self loadOutlets];
    [self loadActions];
    [self preselect];
    }


//-----------------------------------------------------------------------------
// -ok:
//-----------------------------------------------------------------------------
- (void)ok:(id)sender
    {
    [super ok:sender];
    [self revert:0];
    }


//-----------------------------------------------------------------------------
// -wantsButtons
//-----------------------------------------------------------------------------
- (BOOL)wantsButtons
    {
    return NO;
    }

@end
