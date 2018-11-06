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
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscLineWrapper.cc,v 1.4 97/04/04 04:57:34 sunshine Exp $
// $Log:	MiscLineWrapper.cc,v $
// Revision 1.4  97/04/04  04:57:34  sunshine
// 0.125.6: Removed unused <assert.h> header.
// 
// Revision 1.3  96/12/30  06:30:23  sunshine
// v105.1: Line height is now based purely on point size.  No longer uses the
// broken NeXT bounding box.
// 
// Revision 1.2  96/12/30  03:11:28  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscLineWrapper.h"
#import	<AppKit/NSText.h>	// NSLeftTextAlignment
#import	<AppKit/NSGraphicsContext.h>
#import	<AppKit/NSStringDrawing.h>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

float const MiscLineWrapper::DEFAULT_LEFT_MARGIN   = 2.0;
float const MiscLineWrapper::DEFAULT_TOP_MARGIN    = 0.0;
float const MiscLineWrapper::DEFAULT_RIGHT_MARGIN  = 2.0;
float const MiscLineWrapper::DEFAULT_BOTTOM_MARGIN = 0.0;


//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
MiscLineWrapper::~MiscLineWrapper()
{
    free( text );
    free( lines );
}


//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
MiscLineWrapper::MiscLineWrapper()
{
    text_len = 0;
    text_max = 1024;
    text = (char*) malloc( text_max );
    font = 0;
    alignment = NSTextAlignmentLeft;
    num_lines = 0;
    max_lines = 16;
    lines = (Line*) malloc( max_lines * sizeof(*lines) );
    rect.origin.x = 0;
    rect.origin.y = 0;
    rect.size.width = 0;
    rect.size.height = 0;
    left_margin = DEFAULT_LEFT_MARGIN;
    top_margin = DEFAULT_TOP_MARGIN;
    right_margin = DEFAULT_RIGHT_MARGIN;
    bottom_margin = DEFAULT_BOTTOM_MARGIN;
    ascender = 0;
    descender = 0;
    line_height = 0;
    char_wrap = false;
    no_partial = false;
    needs_wrap = false;
}


//-----------------------------------------------------------------------------
// setCharWrap
//-----------------------------------------------------------------------------
void MiscLineWrapper::setCharWrap( bool b )
{
    if (char_wrap != b)
    {
        char_wrap = b;
        needs_wrap = true;
    }
}


//-----------------------------------------------------------------------------
// setRect
//-----------------------------------------------------------------------------
void MiscLineWrapper::setRect( NSRect r )
{
    r.origin.x = floor( r.origin.x + left_margin );
    r.origin.y = floor( r.origin.y + top_margin );
    r.size.width = floor( r.size.width - (left_margin + right_margin) );
    r.size.height = floor( r.size.height - (top_margin + bottom_margin) );
    if (r.size.width != rect.size.width)
        needs_wrap = true;
    rect = r;
}


//-----------------------------------------------------------------------------
// setLeftMargin
//-----------------------------------------------------------------------------
void MiscLineWrapper::setLeftMargin( float f )
{
    if (left_margin != f)
    {
        rect.origin.x = floor( rect.origin.x - left_margin + f );
        left_margin = f;
        needs_wrap = true;
    }
}


//-----------------------------------------------------------------------------
// setTopMargin
//-----------------------------------------------------------------------------
void MiscLineWrapper::setTopMargin( float f )
{
    if (top_margin != f)
    {
        rect.origin.y = floor( rect.origin.y - top_margin + f );
        top_margin = f;
        needs_wrap = true;
    }
}


//-----------------------------------------------------------------------------
// setRightMargin
//-----------------------------------------------------------------------------
void MiscLineWrapper::setRightMargin( float f )
{
    if (right_margin != f)
    {
        rect.size.width = floor( rect.size.width - right_margin + f );
        right_margin = f;
        needs_wrap = true;
    }
}


//-----------------------------------------------------------------------------
// setBottomMargin
//-----------------------------------------------------------------------------
void MiscLineWrapper::setBottomMargin( float f )
{
    if (bottom_margin != f)
    {
        rect.size.height = floor( rect.size.height - bottom_margin + f );
        bottom_margin = f;
        needs_wrap = true;
    }
}


//-----------------------------------------------------------------------------
// setText
//-----------------------------------------------------------------------------
void MiscLineWrapper::setText( NSString* str )
{
    char const* t = [str cStringUsingEncoding:NSASCIIStringEncoding]; // FIXME: Not Unicode compliant
    if (t == 0 || *t == 0)
    {
        if (text_len != 0)
            needs_wrap = true;
        text_len = 0;
    }
    else
    {
        size_t len = strlen( t );
        if (len >= MAX_TEXT_LENGTH)
            len = MAX_TEXT_LENGTH - 1;
        if (len != text_len || strncmp( t, text, len ) != 0)
        {
            len++;			// Include space for null byte.
            if (text_max < len)
            {
                while (text_max < len)
                    text_max += text_max;
                text = (char*) realloc( text, text_max );
            }
            len--;			// Don't include null byte in length.
            memcpy( text, t, len );
            text[ len ] = '\0';
            text_len = len;
            needs_wrap = true;
        }
    }
}


//-----------------------------------------------------------------------------
// setFont
//-----------------------------------------------------------------------------
void MiscLineWrapper::setFont( NSFont* f )
{
    if (font != f)
    {
        [font autorelease];
        font = [f retain];
        float const LINE_SPACING = 1.20;
        needs_wrap = true;

        ascender    = ceil( [font ascender] );
        descender   = ceil( - [font descender] );
        line_height = ceil( [font pointSize] * LINE_SPACING );
    }
}


//-----------------------------------------------------------------------------
// setAlignment
//-----------------------------------------------------------------------------
void MiscLineWrapper::setAlignment( NSTextAlignment a )
{
    if (a != NSTextAlignmentCenter && a != NSTextAlignmentRight)
        a = NSTextAlignmentLeft;
    if (alignment != a)
    {
        alignment = a;
        needs_wrap = true;
    }
}

@interface NSFont (deprecated)
- (CGFloat)widthOfString:(NSString*)str1;
- (CGFloat*)widths;
@end

//-----------------------------------------------------------------------------
// calc_width
//-----------------------------------------------------------------------------
float MiscLineWrapper::calc_width( int i, int lim ) const
{
    float w = 0;

    if ([font isFixedPitch])
    {
        int const TAB_STOPS = 8;
        NSInteger n = 0;
        for (int j = i; j < lim; j++)
            if (text[j] == '\t' && alignment == NSTextAlignmentLeft)
                n += TAB_STOPS - (n & (TAB_STOPS - 1));
            else
                n++;
        w = n * [font widthOfString:@"W"];
    }
    else
    {
        float const space_width = [font widthOfString:@" "];
        float const TAB_SIZE = 8 * space_width;

        float sz = [font pointSize];
        CGFloat const* widths = [font widths];
        BOOL const is_screen_font = (font == [font screenFont]);

        for ( ; i < lim; i++)
        {
            unsigned char c = (unsigned char) text[i];
            if (c == '\t')
                if (alignment == NSTextAlignmentLeft)
                    w = (floor(w / TAB_SIZE) + 1.0) * TAB_SIZE;
                else
                    w += space_width;
                else
                {
                    float cw = widths[c];
                    if (!is_screen_font)
                        cw *= sz;
                    w += cw;
                }
        }
    }
    return w;
}


//-----------------------------------------------------------------------------
// wrap_segment
//	Wrap a line segment from the text.  Line segments are determined by
//	explicit newlines in the text.
//
// NOTE *1*
//	This case arises when a single character is wider than the width of
//	the rectangle.  Force the character onto the line even though it
//	exceeds the rectangle width.  Otherwise, the character will never
//	be consumed, and we will go into an infinite loop.
//-----------------------------------------------------------------------------
void MiscLineWrapper::wrap_segment( int seg_start, int seg_end )
{
    bool do_char_wrap = char_wrap && alignment == NSTextAlignmentLeft;
    float max_width = rect.size.width;
    do  {
        if (num_lines >= max_lines)
        {
            max_lines += max_lines;
            lines = (Line*) realloc( lines, max_lines * sizeof(*lines) );
        }

        Line& line = lines[ num_lines++ ];
        line.width = 0;
        line.start = seg_start;
        int white_start = seg_start;
        int black_start = seg_start;
        int black_end   = seg_start;
        while (black_start < seg_end)
        {
            while (black_start < seg_end && !isgraph( text[ black_start ] ))
                black_start++;
            if (black_start < seg_end)
            {
                black_end = black_start;
                while (black_end < seg_end && isgraph( text[ black_end ] ))
                    black_end++;
                
                float black_width = calc_width( seg_start, black_end );

                if (black_width <= max_width)	// Word fits on line.
                {
                    line.width = black_width;
                    white_start = black_end;
                    black_start = black_end;
                }
                else				// Word does not fit.
                {
                    // Line is empty. Split word.
                    if (do_char_wrap || white_start == seg_start)
                    {
                        while (black_end > black_start &&
                               black_width > max_width)
                            black_width = calc_width(seg_start,--black_end);
                        if (black_end == seg_start)
                        {
                            black_end++;	// NOTE *1*
                            black_width = calc_width( seg_start, black_end );
                        }
                        if (black_end > black_start)
                            line.width = black_width;
                        // else there are preceeding whitespace characters on
                        // the line.  The width remains zero, and we move the
                        // whole word to the next line.
                        white_start = black_end;
                        black_start = black_end;
                    }
                    // else line is not empty, move word to next line.
                    
                    break;			// *** BREAK *** finish line
                }
            }
        }

        line.len = white_start - seg_start;	// Trailing spaces not included
        seg_start = black_start;
    }
    while (seg_start < seg_end);
}


//-----------------------------------------------------------------------------
// do_wrap
//-----------------------------------------------------------------------------
void MiscLineWrapper::do_wrap()
{
    int line_start = 0;
    int line_end;
    num_lines = 0;
    while (line_start < text_len) {
        line_end = line_start;
        while (line_end < text_len)
            if (text[line_end++] == '\n')
                break;
        wrap_segment( line_start, line_end );
        line_start = line_end;
    }
}


//-----------------------------------------------------------------------------
// wrap
//-----------------------------------------------------------------------------
void MiscLineWrapper::wrap()
{
    if (needs_wrap) {
        needs_wrap = false;
        do_wrap();
    }
}


//-----------------------------------------------------------------------------
// dump
//-----------------------------------------------------------------------------
void MiscLineWrapper::dump() const
{
    for (int i = 0; i < num_lines; i++) {
        Line& line = lines[i];
        fprintf( stderr, "%2d: w=%g (%.*s)\n", i, line.width,
                line.len, text + line.start );
    }
}


//-----------------------------------------------------------------------------
// width_check
//-----------------------------------------------------------------------------
bool MiscLineWrapper::width_check() const
{
    for (int i = 0; i < num_lines; i++)
        if (lines[i].width > rect.size.width)
            return true;
    return false;
}


//-----------------------------------------------------------------------------
// has_tabs
//-----------------------------------------------------------------------------
bool MiscLineWrapper::has_tabs( Line const& line ) const
{
    int i = line.start;
    int const lim = i + line.len;
    for ( ; i < lim; i++) {
        if (text[i] == '\t') {
            return true;
        }
    }
    return false;
}


//-----------------------------------------------------------------------------
// draw
//-----------------------------------------------------------------------------
void MiscLineWrapper::draw( float x, float y, int start, int len )
{
    int const lim = start + len;
    char const save_ch = text[ lim ];
    text[ lim ] = '\0';
    [@(text + start) drawAtPoint:NSMakePoint(x, y) withAttributes:nil];
    text[ lim ] = save_ch;
}


//-----------------------------------------------------------------------------
// draw_tabs
//	Need to draw tab-separated segments.
//-----------------------------------------------------------------------------
void MiscLineWrapper::draw_tabs( float x0, float y, Line const& line )
{
    int const i0 = line.start;
    int const lim = i0 + line.len;
    int i = i0;
    while (i < lim) {
        while (i < lim && text[i] == '\t') {
            i++;
        }
        int j = i;
        while (i < lim && text[i] != '\t') {
            i++;
        }
        int const n = i - j;
        if (n > 0) {
            float x = x0;
            if (j > i0)
                x += calc_width( i0, j );
            draw( x, y, j, n );
        }
    }
}


//-----------------------------------------------------------------------------
// draw
//-----------------------------------------------------------------------------
void MiscLineWrapper::draw()
{
    wrap();

    CGFloat const wmax = rect.size.width;
    CGFloat const x0 = rect.origin.x;
    CGFloat const xmax = x0 + wmax;
    CGFloat x = x0;
    CGFloat const y0 = rect.origin.y;
    CGFloat const ymax = y0 + rect.size.height;
    CGFloat y = y0 + line_height - descender;

    bool did_clip = false;
    if (width_check()) {
        did_clip = true;
        [NSGraphicsContext saveGraphicsState];
        NSRectClip( rect );
    }

    for (int i = 0; i < num_lines; i++, y += line_height) {
        bool is_partial = y + descender >= ymax;
        if (is_partial && (no_partial || y - ascender >= ymax))
            break;
        Line const& line = lines[i];
        if (line.len > 0) {
            if (is_partial && !did_clip) {
                did_clip = true;
                [NSGraphicsContext saveGraphicsState];
                NSRectClip( rect );
            }
            x = x0;
            if (line.width < wmax) {
                if (alignment == NSTextAlignmentCenter) {
                    x = floor( x0 + (wmax - line.width) / 2 );
                } else if (alignment == NSTextAlignmentRight) {
                    x = floor( xmax - line.width );
                }
            }
            if (alignment == NSTextAlignmentLeft && has_tabs( line ))
                draw_tabs( x, y, line );
            else
                draw( x, y, line.start, line.len );
        }
    }

    if (did_clip)
        [NSGraphicsContext restoreGraphicsState];
}
