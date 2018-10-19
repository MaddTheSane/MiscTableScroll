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
// DirArray.m
//
//	An extensible array of directory entries.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirArray.m,v 1.6 99/08/12 23:04:10 sunshine Exp $
// $Log:	DirArray.m,v $
// Revision 1.6  99/08/12  23:04:10  sunshine
// v19.1: Fixed bug: -getParent did not work correctly on Windows.
// 
// Revision 1.5  99/06/14  17:34:31  sunshine
// v19.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Worked around Foundation bug: -[NSString stringByDeletingLastPathComponent]
// does not handle "/" correctly. It returns "" instead of the documented "/".
// 
// Revision 1.4  1998/03/30 09:12:26  sunshine
// v18.1: Now correctly types totalBytes as unsigned long long; not size_t.
//
// Revision 1.3  97/06/24  07:58:02  sunshine
// v15.1: Removed unused dictionary keys.  Fixed bug: Wasn't taking sticky bit
// into account when computing canToggleLock.
//-----------------------------------------------------------------------------
#import	"DirArray.h"
#import	<AppKit/NSApplication.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSWorkspace.h>
#import <Foundation/NSFileManager.h>

NSString* const DA_SHORT_NAME = @"ShortName";
NSString* const DA_LONG_NAME = @"LongName";
NSString* const DA_SOFT_LINK = @"SoftLink";
NSString* const DA_IS_DIRECTORY = @"IsDirectory";
NSString* const DA_IS_LOCKED = @"IsLocked";
NSString* const DA_CAN_TOGGLE_LOCK = @"CanToggleLock";
static NSString* const DA_SCALED_ICON = @"ScaledIcon";
static NSString* const DA_UNSCALED_ICON = @"UnscaledIcon";


//=============================================================================
// DirArray IMPELEMENTATION
//=============================================================================
@implementation DirArray

- (unsigned int)count			{ return [files count]; }
- (id)objectAtIndex:(unsigned int)n	{ return [files objectAtIndex:n]; }
- (unsigned long long)totalBytes	{ return totalBytes; }
- (BOOL)writable			{ return writable; }
- (BOOL)sticky				{ return sticky; }
- (NSString*)username			{ return username; }

//-----------------------------------------------------------------------------
// init
//-----------------------------------------------------------------------------
- (id)init
    {
    [super init];
    name = [[NSString allocWithZone:[self zone]] init];
    files = [[NSMutableArray allocWithZone:[self zone]] init];
    totalBytes = 0;
    writable = NO;
    sticky = NO;
    username = [NSUserName() retain];
    return self;
    }


//-----------------------------------------------------------------------------
// dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    [files release];
    [name release];
    [username release];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// dirWritable:
//-----------------------------------------------------------------------------
- (BOOL)dirWritable:(NSString*)path
    {
    return [[NSFileManager defaultManager] isWritableFileAtPath:path];
    }


//-----------------------------------------------------------------------------
// dirSticky:
//-----------------------------------------------------------------------------
- (BOOL)dirSticky:(NSDirectoryEnumerator*)enumerator
    {
    int const STICKY_BIT = 01000;
    unsigned long n = [[enumerator directoryAttributes] filePosixPermissions];
    return ((n & STICKY_BIT) != 0);
    }


//-----------------------------------------------------------------------------
// getParent
//	Unfortunately -stringByDeletingLastPathComponent does not work as
//	documented when operating on a root directory.  On Mach, when handed
//	"/", it returns "" rather than "/" as documented.  On Windows, when
//	handed "C:\", it returns "C:" rather than "C:\" as documented.
//	Therefore, we use -isAbsolutePath as a sneaky way to detect this
//	anomalous condition.
//-----------------------------------------------------------------------------
- (NSString*)getParent
    {
    NSString* s = [name stringByDeletingLastPathComponent];
    return ([s isAbsolutePath] ? s : name);
    }


//-----------------------------------------------------------------------------
// addFile:attributes:
//-----------------------------------------------------------------------------
- (void)addFile:(NSString*)file attributes:(NSDictionary*)attributes
    {
    NSFileManager* const manager = [NSFileManager defaultManager];
    NSString* const longName = [file isEqualToString:@".."] ?
	[self getParent] : [name stringByAppendingPathComponent:file];
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
    [dict setObject:longName forKey:DA_LONG_NAME];
    [dict setObject:isLink ? 
	[manager pathContentOfSymbolicLinkAtPath:longName] : @""
	forKey:DA_SOFT_LINK];
    [dict setObject:[NSNumber numberWithBool:isDir] forKey:DA_IS_DIRECTORY];
    [dict setObject:[NSNumber numberWithBool:canToggle]
	forKey:DA_CAN_TOGGLE_LOCK];
    [dict setObject:[NSNumber numberWithBool:!canToggle] forKey:DA_IS_LOCKED];
    [files addObject:dict];
    }


//-----------------------------------------------------------------------------
// loadPath:showHidden:
//-----------------------------------------------------------------------------
- (BOOL)loadPath:(NSString*)path showHidden:(BOOL)showHidden
    {
    NSFileManager* manager = [NSFileManager defaultManager];
    NSDirectoryEnumerator* enumerator = [manager enumeratorAtPath:path];

    [files removeAllObjects];
    [name autorelease];
    name = [path copyWithZone:[self zone]];
    writable = [self dirWritable:path];
    sticky = [self dirSticky:enumerator];
    totalBytes = 0;

    if (enumerator != 0)
	{
	NSString* file;
	[self addFile:@".." attributes:
	    [manager fileAttributesAtPath:[self getParent] traverseLink:NO]];

	while ((file = [enumerator nextObject]) != 0)
	    {
	    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	    NSDictionary* attributes = [enumerator fileAttributes];
	    if (showHidden || [file characterAtIndex:0] != '.')
		{
		totalBytes += [attributes fileSize];
		[self addFile:file attributes:attributes];
		}
	    if ([[attributes fileType] isEqualToString:NSFileTypeDirectory])
		[enumerator skipDescendents];
	    [pool release];
	    }
	}
    return (enumerator != 0);
    }

@end


//=============================================================================
// NSMutableDictionary(DirArray) IMPLEMENTATION
//=============================================================================
@interface NSMutableDictionary(DirArray)
- (void)loadImages;
@end

@implementation NSMutableDictionary(DirArray)

//-----------------------------------------------------------------------------
// loadImages
//-----------------------------------------------------------------------------
- (void)loadImages
    {
    NSImage* image;
    NSString* name = [self objectForKey:DA_LONG_NAME];
    NSParameterAssert( name != 0 );
    image = [[NSWorkspace sharedWorkspace] iconForFile:name];
    [self setObject:[[image copy] autorelease] forKey:DA_UNSCALED_ICON];
    [image setScalesWhenResized:YES];
    [self setObject:image forKey:DA_SCALED_ICON];
    }

@end


//=============================================================================
// NSDictionary(DirArray) IMPLEMENTATION
//=============================================================================
@implementation NSDictionary(DirArray)

//-----------------------------------------------------------------------------
// getImage:
//-----------------------------------------------------------------------------
- (id)getImage:(NSString*)key
    {
    id image = 0;
    if ([self isKindOfClass:[NSMutableDictionary class]])
	{
	if ([self objectForKey:key] == 0)
	    [(NSMutableDictionary*)self loadImages];
	image = [self objectForKey:key];
	}
    return image;
    }


//-----------------------------------------------------------------------------
// [un]scaledImage
//-----------------------------------------------------------------------------
- (id)scaledImage   { return [self getImage:DA_SCALED_ICON  ]; }
- (id)unscaledImage { return [self getImage:DA_UNSCALED_ICON]; }

@end
