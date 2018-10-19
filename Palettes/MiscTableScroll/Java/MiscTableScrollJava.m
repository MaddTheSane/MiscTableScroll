//=============================================================================
//
//	Copyright (C) 1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollJava.m
//
//	Private Java implementation which extends MiscTableScroll in order to
//	properly export it to Java.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollJava.m,v 1.1 99/06/14 18:46:06 sunshine Exp $
// $Log:	MiscTableScrollJava.m,v $
// Revision 1.1  99/06/14  18:46:06  sunshine
// v140.1: Extensions to MiscTableScroll to support Java exposure. 
// 
//-----------------------------------------------------------------------------
#import "MiscTableScrollJava.h"

//-----------------------------------------------------------------------------
// Provide replacements for methods which return, via reference, row & column.  
// Cheat by using NSRange as a two-value container on the Objective-C side to 
// avoid having to write "native" type conversion functions.  (They already 
// exist for NSRange.)  Each of the overloaded methods returns a BOOL value 
// indicating whether or not it was able to compute the row & column values.  
// This return value is encoded into the NSRange by returning {~0,0} upon 
// failure.  These methods are exposed as "private".  On the Java side, we 
// provide "public" Java methods which translate the NSRange into a 
// TableScroll.Location object and return that to the caller.  If the range 
// indicates a failure then "null" is returned.  
//-----------------------------------------------------------------------------
@implementation MiscTableScroll(JavaExtensions)

static NSRange const NULL_RANGE = { ~0, 0 };

- (NSRange)javaNextEditLocationInDirection:(BOOL)forward
    {
    int r,c;
    if ([self getNext:forward editRow:&r column:&c])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

- (NSRange)javaNextEditLocation
    {
    int r,c;
    if ([self getNextEditRow:&r column:&c])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

- (NSRange)javaPreviousEditLocation
    {
    int r,c;
    if ([self getPreviousEditRow:&r column:&c])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

- (NSRange)javaLocationForPoint:(NSPoint)point
    {
    int r,c;
    if ([self getRow:&r column:&c forPoint:point])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

- (NSRange)javaLocationOfCell:(NSCell*)cell
    {
    int r,c;
    if ([self getRow:&r column:&c ofCell:cell])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

- (NSRange)javaLocationOfCellWithTag:(int)n
    {
    int r,c;
    if ([self getRow:&r column:&c ofCellWithTag:n])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

- (NSRange)javaLocationOfCellWithRepresentedObject:(id)p
    {
    int r,c;
    if ([self getRow:&r column:&c ofCellWithRepresentedObject:p])
	return NSMakeRange(r,c);
    return NULL_RANGE;
    }

@end
