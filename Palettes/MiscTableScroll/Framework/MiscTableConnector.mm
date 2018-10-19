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
// MiscTableConnector.M
//
//	A custom sublcass of the Interface Builder NSNibControlConnector
//	that works for doubleTarget & doubleAction.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableConnector.M,v 1.8 99/06/15 02:49:47 sunshine Exp $
// $Log:	MiscTableConnector.M,v $
// Revision 1.8  99/06/15  02:49:47  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// As of MacOS/X Server DR2, nib connector classes are now published; we now
// conditionally declare connector classes based on platform; NSIBConnector
// in AppKit was renamed to NSNibConnector.
// Now uses NSStringFromClass() in place of +[NSObject description].
// 
// Revision 1.7  1997/06/18 10:21:04  sunshine
// v125.9: Worked around Objective-C++ compiler crash in OPENSTEP 4.2 for NT
// when sending message to 'super' from within a category in a permanent
// fashion.
//
//  Revision 1.6  97/04/15  09:06:59  sunshine
//  v0.125.8: Hacked around OPENSTEP 4.2 (prerelease) compiler bug.  Compiler
//  crashes if a message is sent to 'super' from within a category.
//  Temporarily moved affected code from MiscTableConnector.M to this file.
//-----------------------------------------------------------------------------
#import	"MiscTableConnector.h"
extern "Objective-C" {
#import <objc/objc-class.h>
Ivar object_setInstanceVariable( id, char const* name, void const* );
}

int const MISC_CONN_VERSION_0    = 0;	 // First NEXTSTEP 3.3 version.
int const MISC_CONN_VERSION_1000 = 1000; // First OpenStep version (4.0 PR2)
int const MISC_CONN_VERSION      = MISC_CONN_VERSION_1000;

@interface NSNibConnector(MiscTableConnector_42NT)
// See *FIXME* OPENSTEP 4.2 for NT at bottom of file.
- (id)initSource:(id)src destination:(id)dst label:(id)lbl;
@end

#if defined(MISC_OLD_IB_CONNECTORS)

@interface NSNibConnector(MiscTableConnector)
- (NSString*)label;
@end
@implementation NSIBConnector(MiscTableConnector)
- (NSString*)label { return label; }
@end

#endif // MISC_OLD_IB_CONNECTORS

//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableConnector

//-----------------------------------------------------------------------------
// +initialize
//-----------------------------------------------------------------------------
+ (void)initialize
    {
    if (self == [MiscTableConnector class])
	[self setVersion:MISC_CONN_VERSION];
    }


//-----------------------------------------------------------------------------
// -dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    [outletName release];
    [actionName release];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// -readCStringWithCoder:
//-----------------------------------------------------------------------------
- (NSString*)readCStringWithCoder:(NSCoder*)decoder
    {
    NSString* ret = @"";
    char* s = 0;
    [decoder decodeValueOfObjCType:@encode(char*) at:&s];
    if (s != 0)
	{
	ret = [NSString stringWithCString:s];
	NSZoneFree( [decoder objectZone], s );
	}
    return ret;
    }


//-----------------------------------------------------------------------------
// -initWithCoder_v0:
//-----------------------------------------------------------------------------
- (void)initWithCoder_v0:(NSCoder*)decoder
    {
    outletName = [[self readCStringWithCoder:decoder] retain];
    actionName = [[self readCStringWithCoder:decoder] retain];
    [self readCStringWithCoder:decoder]; // Duplicate "label" no longer needed.
    }


//-----------------------------------------------------------------------------
// -initWithCoder_v1000:
//-----------------------------------------------------------------------------
- (void)initWithCoder_v1000:(NSCoder*)decoder
    {
    outletName = [[decoder decodeObject] retain];
    actionName = [[decoder decodeObject] retain];
    }


//-----------------------------------------------------------------------------
// -initWithCoder:
//-----------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder*)decoder
    {
    self = [super initWithCoder:decoder];
    unsigned int const ver = [decoder versionForClassName:
	NSStringFromClass( [MiscTableConnector class] )];
    switch (ver)
	{
	case MISC_CONN_VERSION_0:    [self initWithCoder_v0:   decoder]; break;
	case MISC_CONN_VERSION_1000: [self initWithCoder_v1000:decoder]; break;
	default:
	    [NSException raise:NSGenericException
			format:@"Cannot read: unknown version %d", ver];
	    break;
	}
    return self;
    }


//-----------------------------------------------------------------------------
// -setInstanceVariable:of:to:
//-----------------------------------------------------------------------------
- (void)setInstanceVariable:(NSString*)var of:(id)obj to:(id)val
    {
    if (var != 0 && [var length] > 0)
	object_setInstanceVariable( obj, [var cString], val );
    }


//-----------------------------------------------------------------------------
// -establishConnection
//-----------------------------------------------------------------------------
- (void)establishConnection
    {
    id const src = [self source];
    id const dst = [self destination];
    if (src != 0 && dst != 0 && [outletName length] > 0)
	{
	[self setInstanceVariable:outletName of:src to:dst];
	if ([actionName length] > 0 && [[self label] length] > 0)
	    {
	    SEL aSel = NSSelectorFromString([self label]);
	    if (aSel != 0)
		[self setInstanceVariable:actionName of:src to:(id)aSel];
	    }
	} 
    }


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
- (id)superInitSource:(id)s destination:(id)d label:(NSString*)l
	{ return [super initSource:s destination:d label:l]; }
- (void)superEncodeWithCoder:(NSCoder*)c
	{ [super encodeWithCoder:c]; }

@end
