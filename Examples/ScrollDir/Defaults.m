//=============================================================================
//
//	Copyright (C) 1995-1997 by Paul S. McCarthy and Eric Sunshine.
//		Written by Paul S. McCarthy and Eric Sunshine.
//			    All Rights Reserved.
//
//	This notice may not be removed from this source code.
//
//	This object is included in the MiscKit by permission from the authors
//	and its use is governed by the MiscKit license, found in the file
//	"License.rtf" in the MiscKit disibution.  Please refer to that file
//	for a list of all applicable permissions and resictions.
//
//=============================================================================
//-----------------------------------------------------------------------------
// Defaults.m
//
//	Simplified interface to NeXT defaults system.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: Defaults.m,v 1.3 97/04/15 22:18:33 sunshine Exp $
// $Log:	Defaults.m,v $
// Revision 1.3  97/04/15  22:18:33  sunshine
// 29.3: assert() --> NSAssert() variations.
// 
// Revision 1.2  97/03/22  22:46:43  sunshine
// v29.1: Reordered headers to be in sync with LazyScrollDir.
// 
// Revision 1.1  97/03/21  18:30:31  sunshine
// v28: Defaults manager.
//-----------------------------------------------------------------------------
#import "Defaults.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSFont.h>
#import <Foundation/NSUserDefaults.h>
#import <limits.h>
#import <stdio.h>

#define FONT_NAME_KEY @"Name"
#define FONT_SIZE_KEY @"Size"


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation Defaults

//-----------------------------------------------------------------------------
// commit
//-----------------------------------------------------------------------------
+ (void)commit
    {
    [[NSUserDefaults standardUserDefaults] synchronize];
    }


//-----------------------------------------------------------------------------
// set:str:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def str:(NSString*)s
    {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:def];
    }


//-----------------------------------------------------------------------------
// getStr:fallback:
//-----------------------------------------------------------------------------
+ (NSString*)getStr:(NSString*)def fallback:(NSString*)fallback
    {
    NSString* s = [[NSUserDefaults standardUserDefaults] stringForKey:def];
    if (s == 0)
	s = fallback;
    return s;
    }


//-----------------------------------------------------------------------------
// set:int:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def int:(int)i
    {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:def];
    }


//-----------------------------------------------------------------------------
// getInt:fallback:
//-----------------------------------------------------------------------------
+ (int)getInt:(NSString*)def fallback:(int)fallback
    {
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    if ([defs objectForKey:def] != 0)
	return [defs integerForKey:def];
    else
	return fallback;
    }


//-----------------------------------------------------------------------------
// getInt:fallback:min:max:
//-----------------------------------------------------------------------------
+ (int)getInt:(NSString*)def fallback:(int)f min:(int)imin max:(int)imax
    {
    int ret;
    NSParameterAssert( imin <= imax );
    ret = [self getInt:def fallback:f];
    if (ret < imin)
	ret = imin;
    else if (ret > imax)
	ret = imax;
    return ret;
    }


//-----------------------------------------------------------------------------
// getInt:fallback:min:
//-----------------------------------------------------------------------------
+ (int)getInt:(NSString*)def fallback:(int)fallback min:(int)imin
    {
    return [self getInt:def fallback:fallback min:imin max:INT_MAX];
    }


//-----------------------------------------------------------------------------
// set:float:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def float:(float)f
    {
    [[NSUserDefaults standardUserDefaults] setFloat:f forKey:def];
    }


//-----------------------------------------------------------------------------
// getFloat:fallback:
//-----------------------------------------------------------------------------
+ (float)getFloat:(NSString*)def fallback:(float)fallback
    {
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    if ([defs objectForKey:def] != 0)
	return [defs floatForKey:def];
    else
	return fallback;
    }


//-----------------------------------------------------------------------------
// set:color:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def color:(NSColor*)c
    {
    NSData* d = [NSArchiver archivedDataWithRootObject:c];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:def];
    }


//-----------------------------------------------------------------------------
// getColor:fallback:
//-----------------------------------------------------------------------------
+ (NSColor*)getColor:(NSString*)def fallback:(NSColor*)fallback
    {
    NSData* d = [[NSUserDefaults standardUserDefaults] dataForKey:def];
    if (d != 0)
	return [NSUnarchiver unarchiveObjectWithData:d];
    else
	return fallback;
    }


//-----------------------------------------------------------------------------
// set:bool:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def bool:(BOOL)b
    {
    [[NSUserDefaults standardUserDefaults] setBool:b forKey:def];
    }


//-----------------------------------------------------------------------------
// getBool:fallback:
//-----------------------------------------------------------------------------
+ (BOOL)getBool:(NSString*)def fallback:(BOOL)fallback
    {
    NSUserDefaults* defs = [NSUserDefaults standardUserDefaults];
    if ([defs objectForKey:def] != 0)
	return [defs boolForKey:def];
    else
	return fallback;
    }


//-----------------------------------------------------------------------------
// set:font:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def font:(NSFont*)f
    {
    NSDictionary* d = [NSDictionary dictionaryWithObjectsAndKeys:
			[f fontName],
			FONT_NAME_KEY,
			[[NSNumber numberWithFloat:[f pointSize]] stringValue],
			FONT_SIZE_KEY, 0];
    [[NSUserDefaults standardUserDefaults] setObject:d forKey:def];
    }


//-----------------------------------------------------------------------------
// getFont:fallback:
//-----------------------------------------------------------------------------
+ (NSFont*)getFont:(NSString*)def fallback:(NSFont*)fallback
    {
    NSFont* font = fallback;
    NSDictionary* d = [[NSUserDefaults standardUserDefaults]
				dictionaryForKey:def];
    if (d != 0)
	{
	NSString* name = [d objectForKey:FONT_NAME_KEY];
	if (name != 0 && [name length] > 0)
	    {
	    NSNumber* size = [d objectForKey:FONT_SIZE_KEY];
	    NSFont* new_font = [NSFont fontWithName:name
				size:[size floatValue]];
	    if (new_font != 0)
		font = new_font;
	    }
	}
    return font;
    }


//-----------------------------------------------------------------------------
// set:size:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def size:(NSSize)s
    {
    NSString* buf = [NSString stringWithFormat:@"%g %g", s.width, s.height];
    [[NSUserDefaults standardUserDefaults] setObject:buf forKey:def];
    }


//-----------------------------------------------------------------------------
// getSize:fallback:
//-----------------------------------------------------------------------------
+ (NSSize)getSize:(NSString*)def fallback:(NSSize)fallback
    {
    NSSize size = fallback;
    NSString* s = [[NSUserDefaults standardUserDefaults] stringForKey:def];
    if (s != 0)
	{
	float w,h;
	NSScanner* scan = [NSScanner scannerWithString:s];
	if ([scan scanFloat:&w] && [scan scanFloat:&h])
	    size = NSMakeSize( w, h );
	}
    return size;
    }


//-----------------------------------------------------------------------------
// set:point:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def point:(NSPoint)p
    {
    NSString* buf = [NSString stringWithFormat:@"%g %g", p.x, p.y];
    [[NSUserDefaults standardUserDefaults] setObject:buf forKey:def];
    }


//-----------------------------------------------------------------------------
// getPoint:fallback:
//-----------------------------------------------------------------------------
+ (NSPoint)getPoint:(NSString*)def fallback:(NSPoint)fallback
    {
    NSPoint point = fallback;
    NSString* s = [[NSUserDefaults standardUserDefaults] stringForKey:def];
    if (s != 0)
	{
	float x,y;
	NSScanner* scan = [NSScanner scannerWithString:s];
	if ([scan scanFloat:&x] && [scan scanFloat:&y])
	    point = NSMakePoint( x, y );
	}
    return point;
    }


//-----------------------------------------------------------------------------
// set:rect:
//-----------------------------------------------------------------------------
+ (void)set:(NSString*)def rect:(NSRect)r
    {
    NSString* buf = [NSString stringWithFormat:@"%g %g %g %g",
			NSMinX(r), NSMinY(r), NSWidth(r), NSHeight(r)];
    [[NSUserDefaults standardUserDefaults] setObject:buf forKey:def];
    }


//-----------------------------------------------------------------------------
// getRect:fallback:
//-----------------------------------------------------------------------------
+ (NSRect)getRect:(NSString*)def fallback:(NSRect)fallback
    {
    NSRect rect = fallback;
    NSString* s = [[NSUserDefaults standardUserDefaults] stringForKey:def];
    if (s != 0)
	{
	float x,y,w,h;
	NSScanner* scan = [NSScanner scannerWithString:s];
	if ([scan scanFloat:&x] && [scan scanFloat:&y] &&
	    [scan scanFloat:&w] && [scan scanFloat:&h])
	    rect = NSMakeRect( x, y, w, h );
	}
    return rect;
    }

@end
