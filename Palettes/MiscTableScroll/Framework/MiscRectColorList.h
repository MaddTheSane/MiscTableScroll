#ifndef __MiscRectColorList_h
#define __MiscRectColorList_h
#ifdef __GNUC__
#pragma interface
#endif
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
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRectColorList.h,v 1.2 96/12/30 03:12:20 sunshine Exp $
// $Log:	MiscRectColorList.h,v $
// Revision 1.2  96/12/30  03:12:20  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:57:12  sunshine
// An extensible array of rectangles and colors for rendering a whole
// list of rectangles with a single trip to the display server.
//-----------------------------------------------------------------------------
#include "MiscColorList.h"

#import	<Foundation/NSGeometry.h>	// NSRect

struct MiscRectColorList
{
private:
    MiscColorList color_list;
    int num_rects;
    int max_rects;
    NSRect*	rects;
    int*	colors;
    MiscRectColorList( MiscRectColorList const& ) {} // No copy constructor
    void operator=( MiscRectColorList const& ) {}	 // No assign operator
public:
    MiscRectColorList();
    ~MiscRectColorList();
    int count() const	{ return num_rects; }
    void empty()		{ color_list.empty(); num_rects = 0; }
    void append( NSRect r, NSColor* c );
    void draw();
};

#endif // __MiscRectColorList_h
