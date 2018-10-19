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
// MiscRectColorList.h
//
//	An extensible array of rectangles and colors for rendering a whole
//	list of rectangles with a single trip to the display server.
//
// NOTE *1*
//	The rects[] array also provides storage space for the temporary
//	rectangle array needed by NSRectFillList(), so there is always
//	capacity to hold a copy of the entire rectangle list.  Allocating
//	the two arrays together like this reduces the overhead costs, and
//	reduces memory fragmentation.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRectColorList.cc,v 1.2 96/12/30 03:12:22 sunshine Exp $
// $Log:	MiscRectColorList.cc,v $
// Revision 1.2  96/12/30  03:12:22  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:57:10  sunshine
// An extensible array of rectangles and colors for rendering a whole
// list of rectangles with a single trip to the display server.
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscRectColorList.h"

extern "C" {
#include <stdio.h>
#include <stdlib.h>	// malloc(), realloc(), free()
}

//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
MiscRectColorList::MiscRectColorList()
    {
    num_rects = 0;
    max_rects = 16;				// NOTE *1*
    rects = (NSRect*) malloc( max_rects * sizeof(*rects) * 2 );
    colors = (int*) malloc( max_rects * sizeof(*colors) );
    }


//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
MiscRectColorList::~MiscRectColorList()
    {
    free( rects );
    free( colors );
    }


//-----------------------------------------------------------------------------
// append
//-----------------------------------------------------------------------------
void MiscRectColorList::append( NSRect r, NSColor* c )
    {
    if (num_rects >= max_rects)
	{
	max_rects += max_rects;					// NOTE *1*
	rects = (NSRect*) realloc( rects, max_rects * sizeof(*rects) * 2 );
	colors = (int*) realloc( colors, max_rects * sizeof(*colors) );
	}
    rects[ num_rects ] = r;
    colors[ num_rects ] = color_list.store( c );
    num_rects++;
    }


//-----------------------------------------------------------------------------
// draw
//-----------------------------------------------------------------------------
void MiscRectColorList::draw()
    {
    int const num_colors = color_list.count();
    if (num_colors > 0)
	{
	NSRect* const v = rects + num_rects;	// NOTE *1*

	for (int i = 0; i < num_colors; i++)
	    {
	    int vj = 0;
	    
	    for (int j = 0; j < num_rects; j++)
		if (colors[j] == i)
		    v[vj++] = rects[j];

	    [color_list[i] set];
	    NSRectFillList( v, vj );
	    }

	empty();
	}
    }
