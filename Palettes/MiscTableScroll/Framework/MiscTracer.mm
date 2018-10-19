//=============================================================================
//
//	Copyright (C) 1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTracer.h
//
//	Simple C++ class that helps generate function enter/exit
//	trace messages.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTracer.cc,v 1.2 98/03/23 07:48:25 sunshine Exp $
// $Log:	MiscTracer.cc,v $
// Revision 1.2  98/03/23  07:48:25  sunshine
// v134.1: Ported from NEXTSTEP to OPENSTEP/Rhapsody.
// 
//  Revision 1.1  97/12/22  22:00:33  zarnuk
//  v134: Utility class to create function enter/exit messages.
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscTracer.h"
extern "Objective-C" {
#include <Foundation/NSAutoreleasePool.h>
#include <Foundation/NSUtilities.h>
}

int MiscTracer::TRACE_DEPTH = 0;

//-----------------------------------------------------------------------------
// dump
//-----------------------------------------------------------------------------
void MiscTracer::dump( char const* s ) const
    {
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    NSMutableString* pad = [NSMutableString string];
    for (int i = 0; i < TRACE_DEPTH; i++)
	[pad appendString:@" "];
    NSLog( @"%@%s %s", pad, s, msg );
    [pool release];
    }
