//=============================================================================
//
//  Copyright (C) 1995,1996,1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscDrawList.cc
//
//	An extensible array of specifications for drawing cell contents.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscDrawList.cc,v 1.9 98/03/29 23:43:01 sunshine Exp $
// $Log:	MiscDrawList.cc,v $
// Revision 1.9  98/03/29  23:43:01  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// 
// Revision 1.8  98/03/22  13:20:33  sunshine
// v133.1: Added draw_clipped_text flag.
// 
// Revision 1.7  97/06/18  10:25:56  sunshine
// v125.9: highlightTextColor --> selectedTextColor
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscDrawList.h"
#include "MiscLineWrapper.h"
#include <MiscTableScroll/MiscTableCell.h>
#import	<AppKit/NSCell.h>
#import	<AppKit/NSFont.h>
#import	<AppKit/NSImage.h>
#import	<AppKit/NSText.h>	// NSLeftTextAlignment
#import <AppKit/NSGraphicsContext.h>
#include <cmath>
#include <cstdlib>

//-----------------------------------------------------------------------------
// get_char_wrap
//-----------------------------------------------------------------------------
inline static bool get_char_wrap( id cell ) { return ![cell wraps]; }


//-----------------------------------------------------------------------------
// append
//-----------------------------------------------------------------------------
void MiscDrawList::append( NSRect frame_rect, id cell, BOOL lit,
                          NSColor* default_text_color, NSFont* default_font )
{
    NSString* txt = 0;
    NSImage* img = 0;

    if (cell != 0)
    {
        if ([cell respondsToSelector:@selector(image)])
            img = [cell image];

        if (img == 0){
            if ([cell respondsToSelector:@selector(title)]) {
                txt = [cell title];
            } else if ([cell respondsToSelector:@selector(stringValue)]) {
                txt = [cell stringValue];
			}
		}

        if (img != 0 || (txt != 0 && [txt length] != 0))
        {
            if (num_recs >= max_recs)
            {
                max_recs += max_recs;
                recs = (Rec*) realloc( recs, max_recs * sizeof(*recs) );
            }
            Rec& r = recs[ num_recs++ ];
            
            if (img != 0)
            {
                r.image = [img retain];
                r.image_rect = [cell imageRectForBounds:frame_rect];
            }
            else
                r.image = 0;

            if (txt != 0 && [txt length] != 0)
            {
                r.text = [txt copy];
                r.text_rect = [cell titleRectForBounds:frame_rect];

                r.font = 0;
                if ([cell respondsToSelector:@selector(font)])
                    r.font = [cell font];
                if (r.font == 0)
                    r.font = default_font;
                [r.font retain];

                NSColor* color;
                if (lit &&
                    [cell respondsToSelector:@selector(selectedTextColor)])
                    color = [cell selectedTextColor];
                else if ([cell respondsToSelector:@selector(textColor)])
                    color = [cell textColor];
                else
                    color = default_text_color;

                r.text_color = color_list.store( color );

                NSUInteger flags;
                if ([cell respondsToSelector:@selector(alignment)])
                    flags = ([cell alignment] << 1);
                else
					flags = (NSTextAlignmentLeft << 1);
                if (get_char_wrap( cell ))
                    flags |= 1;
                r.flags = flags;
            }
            else
            {
                r.text = 0;
                r.font = 0;
                r.text_color = -1;
            }
        }
    }
}


//-----------------------------------------------------------------------------
// Rec::draw_image
//-----------------------------------------------------------------------------
void MiscDrawList::Rec::draw_image()
{
    NSPoint p;
    p.x = image_rect.origin.x;
    p.y = image_rect.origin.y + image_rect.size.height;

    NSRect r;
    r.origin.x = 0;
    r.origin.y = 0;
    r.size = [image size];

    float const dx = image_rect.size.width - r.size.width;
    if (dx < 0)
        r.size.width = image_rect.size.width;
    else if (dx > 0)
        p.x = floor( p.x + dx / 2 );

    float const dy = image_rect.size.height - r.size.height;
    if (dy < 0)
        r.size.height = image_rect.size.height;
    else if (dy > 0)
        p.y = floor( p.y - dy / 2 );

	[image drawAtPoint:p fromRect:r operation:NSCompositingOperationSourceOver fraction:1];
}


//-----------------------------------------------------------------------------
// Rec::draw_text
//-----------------------------------------------------------------------------
void MiscDrawList::Rec::draw_text( MiscLineWrapper& lw ) const
{
    lw.setText( text );
    lw.setRect( text_rect );
    lw.setCharWrap( flags & 1 );
    lw.setAlignment( NSTextAlignment(flags >> 1) );
    lw.draw();
}


//-----------------------------------------------------------------------------
// draw_images
//-----------------------------------------------------------------------------
void MiscDrawList::draw_images()
{
    for (int i = 0; i < num_recs; i++)
    {
        Rec& r = recs[i];
        if (r.image != 0)
            r.draw_image();
    }
}


//-----------------------------------------------------------------------------
// draw_text
//-----------------------------------------------------------------------------
void MiscDrawList::draw_text()
{
    MiscLineWrapper lw;
    lw.setNoPartialLines( !draw_clipped_text );
    for (int i = 0; i < num_recs; i++)		// For each font...
    {
        if (recs[i].font != 0)
        {
            NSFont* const font = recs[i].font;
            NSFont* screenFont = 0;
            if ([[NSGraphicsContext currentContext] isDrawingToScreen] &&
                (screenFont = [font screenFont]) != 0)
            {
                [screenFont set];
                lw.setFont( screenFont );
            }
            else
            {
                [font set];
                lw.setFont( font );
            }

            for (int j = i; j < num_recs; j++)	// For each font-color pair...
            {
                if (recs[j].text_color >= 0)
                {
                    int const color_id = recs[j].text_color;
                    [color_list[ color_id ] set];
                    
                    for (int k = j; k < num_recs; k++)	// For each record...
                    {
                        Rec& r = recs[k];
                        if (r.font == font && r.text_color == color_id)
                        {
                            r.font = 0;			// Mark record "used".
                            r.text_color = -1;
                            r.draw_text( lw );
                        }
                    }
                }
            }
        }
    }
}


//-----------------------------------------------------------------------------
// draw
//-----------------------------------------------------------------------------
void MiscDrawList::draw()
{
    if (num_recs > 0)
    {
        draw_images();
        draw_text();
        empty();
    }
}


//-----------------------------------------------------------------------------
// empty
//-----------------------------------------------------------------------------
void MiscDrawList::empty()
{
    for (int i = 0; i < num_recs; i++)
    {
        Rec const& r = recs[i];
        if (r.text  != 0) [r.text  release];
        if (r.font  != 0) [r.font  release];
        if (r.image != 0) [r.image release];
    }
    num_recs = 0;
}


//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
MiscDrawList::~MiscDrawList()
{
    empty();
    free( recs );
}


//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
MiscDrawList::MiscDrawList( bool b )
{
    num_recs = 0;
    max_recs = 16;
    recs = (Rec*) malloc( max_recs * sizeof( *recs ) );
    draw_clipped_text = b;
}
