#ifndef __MiscRectList_h
#define __MiscRectList_h
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
// MiscRectList.h
//
//	An extensible array of rectangles for rendering a whole list
//	of rectangles with a single trip to the display server.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscRectList.h,v 1.2 96/12/30 03:12:14 sunshine Exp $
// $Log:	MiscRectList.h,v $
// Revision 1.2  96/12/30  03:12:14  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:57:29  sunshine
// An extensible array of rectangles for rendering a whole list
// of rectangles with a single trip to the display server
//-----------------------------------------------------------------------------
extern "C" {
#import <Foundation/NSGeometry.h>	// NSRect
}
@class NSColor;

struct MiscRectList
	{
private:
	int num_rects;
	int max_rects;
	NSRect*	rects;
	MiscRectList( MiscRectList const& ) {}		// No copy constructor.
	void operator=( MiscRectList const& ) {}	// No assign operator.
public:
	MiscRectList();
	~MiscRectList();
	int count() const	{ return num_rects; }
	void empty()		{ num_rects = 0; }
	void append( NSRect r );
	void draw( NSColor* c );
	};

#endif // __MiscRectList_h
