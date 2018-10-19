#ifndef __Defaults_h
#define __Defaults_h
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
//	"License.rtf" in the MiscKit distribution.  Please refer to that file
//	for a list of all applicable permissions and restrictions.
//
//=============================================================================
//-----------------------------------------------------------------------------
// Defaults.h
//
//	Simplified interface to NeXT defaults system.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: Defaults.h,v 1.1 97/03/23 01:58:34 sunshine Exp $
// $Log:	Defaults.h,v $
// Revision 1.1  97/03/23  01:58:34  sunshine
// v13.1: Defaults manager.
// 
//-----------------------------------------------------------------------------
#import <Foundation/NSObject.h>
#import <Foundation/NSGeometry.h>
@class NSColor, NSFont;

@interface Defaults : NSObject

+ (void)set:(NSString*)def str:(NSString*)s;
+ (void)set:(NSString*)def int:(int)i;
+ (void)set:(NSString*)def float:(float)f;
+ (void)set:(NSString*)def color:(NSColor*)c;
+ (void)set:(NSString*)def bool:(BOOL)b;
+ (void)set:(NSString*)def font:(NSFont*)f;
+ (void)set:(NSString*)def size:(NSSize)s;
+ (void)set:(NSString*)def point:(NSPoint)p;
+ (void)set:(NSString*)def rect:(NSRect)r;

+ (NSString*)	getStr:  (NSString*)def fallback:(NSString*)s;
+ (int)		getInt:  (NSString*)def fallback:(int)i;
+ (int)		getInt:  (NSString*)def fallback:(int)i min:(int)n;
+ (int)		getInt:  (NSString*)def fallback:(int)i min:(int)n max:(int)x;
+ (float)	getFloat:(NSString*)def fallback:(float)f;
+ (NSColor*)	getColor:(NSString*)def fallback:(NSColor*)c;
+ (BOOL)	getBool: (NSString*)def fallback:(BOOL)b;
+ (NSFont*)	getFont: (NSString*)def fallback:(NSFont*)f;
+ (NSSize)	getSize: (NSString*)def fallback:(NSSize)s;
+ (NSPoint)	getPoint:(NSString*)def fallback:(NSPoint)p;
+ (NSRect)	getRect: (NSString*)def fallback:(NSRect)r;

+ (void)commit;

@end

#endif // __Defaults_h
