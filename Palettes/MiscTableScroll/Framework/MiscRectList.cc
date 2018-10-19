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
// MiscRectList.h
//
//	An extensible array of rectangles for rendering a whole list
//	of rectangles with a single trip to the display server.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRectList.cc,v 1.2 96/12/30 03:12:17 sunshine Exp $
// $Log:	MiscRectList.cc,v $
// Revision 1.2  96/12/30  03:12:17  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:57:26  sunshine
// An extensible array of rectangles for rendering a whole list
// of rectangles with a single trip to the display server
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscRectList.h"
extern "Objective-C" {
#import <AppKit/NSColor.h>
}
extern "C" {
#include <stdlib.h>	// malloc(), realloc(), free()
}

//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
MiscRectList::MiscRectList()
    {
    num_rects = 0;
    max_rects = 16;
    rects = (NSRect*) malloc( max_rects * sizeof(*rects) );
    }


//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
MiscRectList::~MiscRectList()
    {
    free( rects );
    }


//-----------------------------------------------------------------------------
// append
//-----------------------------------------------------------------------------
void MiscRectList::append( NSRect r )
    {
    if (num_rects >= max_rects)
	{
	max_rects += max_rects;
	rects = (NSRect*) realloc( rects, max_rects * sizeof(*rects) );
	}
    rects[ num_rects++ ] = r;
    }


//-----------------------------------------------------------------------------
// draw
//-----------------------------------------------------------------------------
void MiscRectList::draw( NSColor* c )
    {
    if (num_rects > 0)
	{
	[c set];
	NSRectFillList( rects, num_rects );
	empty();
	}
    }
