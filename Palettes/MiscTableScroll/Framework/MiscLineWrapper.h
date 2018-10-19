#ifndef __MiscLineWrapper_h
#define __MiscLineWrapper_h
#ifdef __GNUC__
#pragma interface
#endif
//=============================================================================
//
//	Copyright (C) 1996-1997 by Paul S. McCarthy and Eric Sunshine.
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
// MiscLineWrapper.h
//
//	A C++ object for calculating line breaks in text.
//
// NOTE *PARTIAL*
//	"Partial" lines are lines that do not fit completely within the 
//	height of the drawing rectangle.  For example, if you have 3 lines 
//	of text, but the drawing rectangle is only 2.5 lines tall, the 
//	third line of text is a partial line.  The caller can decide 
//	whether or not to draw these partial lines.  Default behavior draws 
//	partial lines.  
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscLineWrapper.h,v 1.2 96/12/30 03:11:26 sunshine Exp $
// $Log:	MiscLineWrapper.h,v $
// Revision 1.2  96/12/30  03:11:26  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:56:41  sunshine
// A C++ object for calculating line breaks in text.
//-----------------------------------------------------------------------------
#include <bool.h>
extern "Objective-C" {
#import	<AppKit/NSFont.h>
#import	<Foundation/NSGeometry.h>	// NSRect
}
extern "C" {
#include <limits.h>		// INT_MAX
}


class MiscLineWrapper
	{
public:
	int const	MAX_TEXT_LENGTH		= (INT_MAX / 2);
static	float const	DEFAULT_LEFT_MARGIN;
static	float const	DEFAULT_TOP_MARGIN;
static	float const	DEFAULT_RIGHT_MARGIN;
static	float const	DEFAULT_BOTTOM_MARGIN;
	struct Line
		{
		float	width;
		int	start;
		int	len;
		};
private:
	int	text_len;
	int	text_max;
	char*	text;
	NSFont*	font;
	int	alignment;
	int	num_lines;
	int	max_lines;
	Line*	lines;
	NSRect	rect;
	float	left_margin;
	float	top_margin;
	float	right_margin;
	float	bottom_margin;
	float	ascender;
	float	descender;
	float	line_height;
	bool	char_wrap;
	bool	no_partial;				// NOTE *PARTIAL*
	bool	needs_wrap;

	MiscLineWrapper( MiscLineWrapper const& ) {}	// No copy constructor.
	void operator=( MiscLineWrapper const& ) {}	// No assign operator.
	void do_wrap();
	void wrap_segment( int seg_start, int seg_end );
	float calc_width( int start_pos, int lim ) const;
	bool width_check() const;
	bool has_tabs( Line const& line ) const;
	void draw( float x, float y, int start, int len );
	void draw_tabs( float x, float y, Line const& line );
public:
	MiscLineWrapper();
	~MiscLineWrapper();

	void		setText( NSString* );
	void		setFont( NSFont* );
	void		setRect( NSRect );
	void		setLeftMargin( float );
	void		setTopMargin( float );
	void		setRightMargin( float );
	void		setBottomMargin( float );
	void		setAlignment( int );
	void		setCharWrap( bool );
	void		setNoPartialLines( bool b ) { no_partial = b; }

	char const*	getText() const		{ return text; }
	NSFont*		getFont() const		{ return font; }
	NSRect const&	getRect() const		{ return rect; }
	float		getLeftMargin() const	{ return left_margin; }
	float		getTopMargin() const	{ return top_margin; }
	float		getRightMargin() const	{ return right_margin; }
	float		getBottomMargin() const	{ return bottom_margin; }
	int		getAlignment() const	{ return alignment; }
	bool		getCharWrap() const	{ return char_wrap; }
	bool		getNoPartialLines() const { return no_partial; }

	bool		needsWrap() const	{ return needs_wrap; }
	int		numLines() const	{ return num_lines; }
	Line const&	lineAt( int i ) const	{ return lines[i]; }

	void		wrap();
	void 		draw();
	void		dump() const;
	};

#endif // __MiscLineWrapper_h
