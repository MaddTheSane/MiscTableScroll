#ifndef __MiscDrawList_h
#define __MiscDrawList_h
#ifdef __GNUC__
#pragma interface
#endif
//=============================================================================
//
//	Copyright (C) 1995-1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscDrawList.h
//
//	An extensible array of specifications for drawing cell contents.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscDrawList.h,v 1.3 98/03/22 13:20:22 sunshine Exp $
// $Log:	MiscDrawList.h,v $
// Revision 1.3  98/03/22  13:20:22  sunshine
// v133.1: Added draw_clipped_text flag.
// 
// Revision 1.2  96/12/30  03:10:10  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:52:40  sunshine
// An extensible array of specifications for drawing cell contents.
//-----------------------------------------------------------------------------
#include "MiscColorList.h"
#include <bool.h>
extern "Objective-C" {
#import <Foundation/NSGeometry.h>
}
@class NSColor, NSFont, NSImage;
class MiscLineWrapper;

struct MiscDrawList
	{
public:
	struct Rec
		{
		NSRect    text_rect;
		NSRect    image_rect;
		NSString* text;
		NSFont*   font;
		NSImage*  image;
		int       text_color;
		int       flags;	// (alignment << 1) | (char_wrap)
		void      draw_image();
		void      draw_text( MiscLineWrapper& ) const;
		};
private:
	MiscColorList color_list;
	int num_recs;
	int max_recs;
	Rec*	recs;
	bool	draw_clipped_text;

	MiscDrawList( MiscDrawList const& ) {}		// No copy constructor.
	void operator=( MiscDrawList const& ) {}	// No assign operator.
	void draw_images();
	void draw_text();
public:
	MiscDrawList( bool i_draw_clipped_text );
	~MiscDrawList();
	int count() const	{ return num_recs; }
	void empty();
	void append( NSRect frame_rect, id cell,
			BOOL is_highlighted,
			NSColor* default_text_color,
			NSFont* default_font );
	void draw();
	};

#endif // __MiscDrawList_h
