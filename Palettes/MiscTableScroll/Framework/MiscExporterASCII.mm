//=============================================================================
//
//	Copyright (C) 1996,1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscExporterASCII.M
//
//	Routines that export the contents of an MiscTableScroll to
//	various ASCII text formats.
//
// TODO:
//	* Genericize for use with Matrix, DBTableView.
//	* Maybe provide option for <CR><LF> line terminators.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporterASCII.M,v 1.4 98/03/29 23:44:11 sunshine Exp $
// $Log:	MiscExporterASCII.M,v $
// Revision 1.4  98/03/29  23:44:11  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// 
// Revision 1.3  97/03/11  05:33:04  sunshine
// v114.1: colGrid --> columnGrid, colTitleMode --> columnTitleMode
// 
// Revision 1.2  97/02/07  13:53:28  sunshine
// v108: Ported to OPENSTEP 4.1 (gamma).
//-----------------------------------------------------------------------------
#import "MiscExporterPrivate.h"
#import	<MiscTableScroll/MiscTableScroll.h>
#include <stdbool.h>
#import	<AppKit/NSCell.h>
#import	<AppKit/NSText.h>
#include <cstdio>


//=============================================================================
// UTILITY ROUTINES
//=============================================================================
//-----------------------------------------------------------------------------
// colgrid
//-----------------------------------------------------------------------------
inline static void colgrid( MiscExportGridMode grid, FILE* fp, char ch = '|' )
{
    if (grid == MISC_EXPORT_GRID_LINE)
        fputc( ch, fp );
    else if (grid == MISC_EXPORT_GRID_SPACE)
        fputc( ' ', fp );
}


//-----------------------------------------------------------------------------
// endline
//-----------------------------------------------------------------------------
inline static void endline( MiscExportGridMode grid, FILE* fp, char ch = '|' )
{
    colgrid( grid, fp, ch );
    fputc( '\n', fp );
}


//-----------------------------------------------------------------------------
// rowTitleHeader
//-----------------------------------------------------------------------------
inline static void rowTitleHeader( int len, MiscExportGridMode grid, FILE* fp )
{
    if (len > 0)
    {
        colgrid( grid, fp );
        pad( len, fp );
    }
}


//-----------------------------------------------------------------------------
// rowgrid
//-----------------------------------------------------------------------------
static void rowgrid( MiscExportGridMode row_grid, MiscExportGridMode col_grid,
			int row_title_width,
			int ncols, int const* widths, FILE* fp )
{
    if (row_grid != MISC_EXPORT_GRID_OFF)
    {
        char row_grid_ch = ' ';
        char col_grid_ch = ' ';
        
        if (row_grid == MISC_EXPORT_GRID_LINE)
        {
            row_grid_ch = '-';
            if (col_grid == MISC_EXPORT_GRID_LINE)
                col_grid_ch = '+';
        }
        else if (col_grid == MISC_EXPORT_GRID_LINE)
            col_grid_ch = '|';
        
        if (row_title_width > 0)
        {
            colgrid( col_grid, fp, col_grid_ch );
            repchar( row_title_width, row_grid_ch, fp );
        }
        
        int const* w = widths;
        for (int c = 0; c < ncols; c++,w++)
        {
            colgrid( col_grid, fp, col_grid_ch );
            repchar( *w, row_grid_ch, fp );
        }
        
        endline( col_grid, fp, col_grid_ch );
    }
}


//-----------------------------------------------------------------------------
// cell_alignment
//-----------------------------------------------------------------------------
static int cell_alignment( id cell )
{
    int rc = NSLeftTextAlignment;
    if (cell != 0 && [cell respondsToSelector:@selector(alignment)])
        rc = [cell alignment];
    return rc;
}


//-----------------------------------------------------------------------------
// cell_str
//-----------------------------------------------------------------------------
static NSString* cell_str( id cell )
{
    NSString* s = @"";
    if (cell != 0 && [cell respondsToSelector:@selector(stringValue)])
        s = [cell stringValue];
    return s;
}



//=============================================================================
// CHAR FILTER
//=============================================================================

//-----------------------------------------------------------------------------
// MiscCharFilter
//	Base class for the output character filters.
//	Base class is unfiltered.
//-----------------------------------------------------------------------------
class MiscCharFilter
{
protected:
    FILE* fp;
    char const* s;
    int len;
    int pos;
public:
    MiscCharFilter( FILE* f ): fp(f), s(0), len(0), pos(0) {}
    virtual	~MiscCharFilter();
    virtual	char nextChar();
    void reset( char const* t, int n ) { s = t; len = n; pos = 0; }
    void reset( char const* t ) { s = t; len = safe_strlen(s); pos = 0; }
    void reset( NSString* t ) { reset( [t lossyCString] ); }
    void reset()			{ pos = 0; }
    int length() const		{ return len; }
    bool done() const		{ return pos >= len; }
    bool more() const		{ return pos < len; }
    virtual	void write();
    void write( int field_width );
    void left( int field_width );
    void center( int field_width );
    void right( int field_width );
    static	void pad( int n, FILE* f, char ch=' ' );
    void pad( int n, char ch=' ' )	{ pad( n, fp, ch ); }
};

MiscCharFilter::~MiscCharFilter() {}
char MiscCharFilter::nextChar()
{
    char c = '\0';
    if (pos < len)
        c = s[pos++];
    return c;
}


void MiscCharFilter::pad( int n, FILE* fp, char ch )
{
    while (n-- > 0)
        fputc( ch, fp );
}


void MiscCharFilter::write()
{
    while (more())
        fputc( nextChar(), fp );
}


void MiscCharFilter::write( int w )
{
    while (w-- > 0)
        fputc( nextChar(), fp );
}


void MiscCharFilter::left( int w )
{
    int const delta = w - length();
    if (delta <= 0)
        write( w );
    else
    {
        write();
        pad( delta );
    }
}


void MiscCharFilter::center( int w )
{
    int const delta = w - length();
    if (delta <= 0)
        write( w );
    else
    {
        int const left_pad = (delta >> 1);
        int const right_pad = delta - left_pad;
        pad( left_pad );
        write();
        pad( right_pad );
    }
}


void MiscCharFilter::right( int w )
{
    int const delta = w - length();
    if (delta <= 0)
        write( w );
    else
    {
        pad( delta );
        write();
    }
}


//-----------------------------------------------------------------------------
// MiscTabFilter
//	Output character filter for the ASCII fixed and tab-separated formats
//	Converts tabs, carriage-returns and newlines into space characters.
//-----------------------------------------------------------------------------
class MiscTabFilter : public MiscCharFilter
{
public:
    MiscTabFilter( FILE* f ): MiscCharFilter(f) {}
    virtual	char nextChar();
};

char MiscTabFilter::nextChar()
{
    char c = '\0';
    if (pos < len)
    {
        c = s[pos++];
        if (c == '\t' || c == '\n' || c == '\r')
            c = ' ';
    }
    return c;
}



//-----------------------------------------------------------------------------
// MiscDelimFilter
//	Output character filter for the ASCII delimited format.
//	Converts carriage-returns and newlines into space characters.
//	Converts double-quote characters into single quote characters.
//-----------------------------------------------------------------------------
class MiscDelimFilter : public MiscCharFilter
{
public:
    MiscDelimFilter( FILE* f ): MiscCharFilter(f) {}
    virtual	char nextChar();
    virtual	void write();
};

char MiscDelimFilter::nextChar()
{
    char c = '\0';
    if (pos < len)
    {
        c = s[pos++];
        if (c == '\n' || c == '\r')
            c = ' ';
        else if (c == '"')
            c = '\'';
    }
    return c;
}

void MiscDelimFilter::write()
{
    if (s != 0)
    {
        fputc( '"', fp );
        MiscCharFilter::write();
        fputc( '"', fp );
    }
}




//=============================================================================
// MiscExporter(ASCII)
//=============================================================================
@implementation MiscExporter(ASCII)

//-----------------------------------------------------------------------------
// fixedWidths:::
//-----------------------------------------------------------------------------
- (int*)fixedWidths:(int)nrows :(int)ncols :(int const*)map
{
    int* const widths = (int*) calloc( ncols, sizeof(*widths) );

    for (int r = 0; r < nrows; r++)
    {
        int* w = widths;
        for (int c = 0; c < ncols; c++,w++)
        {
            int const len = safe_strlen( str_at(r, map[c], tableScroll) );
            if (*w < len)
                *w = len;
        }
    }

    return widths;
}


//-----------------------------------------------------------------------------
// fixedHeadersOn:::::
//-----------------------------------------------------------------------------
- (void)fixedHeadersOn:(int)row_title_width :(int)ncols
			:(int const*)map :(int*)widths :(FILE*)fp
{
    int c;
    int* wp = widths;
    for (c = 0; c < ncols; c++,wp++)
    {
        int const len = safe_strlen( col_title(map[c], tableScroll) );
        if (*wp < len)
            *wp = len;
    }

    rowgrid( rowGrid, columnGrid, row_title_width, ncols, widths, fp );

    rowTitleHeader( row_title_width, columnGrid, fp );

    MiscTabFilter filt( fp );
    int const* w = widths;
    for (c = 0; c < ncols; c++,w++)
    {
        colgrid( columnGrid, fp );
        filt.reset( col_title( map[c], tableScroll ) );
        filt.center( *w );
    }

    endline( columnGrid, fp );
}



//-----------------------------------------------------------------------------
// fixedHeadersWrap:::::
//-----------------------------------------------------------------------------
- (void)fixedHeadersWrap:(int)row_title_width :(int)ncols
			:(int const*)map :(int*)widths :(FILE*)fp
{
    int c;
    int max_lines = 1;

    int* wp = widths;
    for (c = 0; c < ncols; c++,wp++)
    {
        int const len = safe_strlen( col_title(map[c], tableScroll) );
        if (len > *wp)
        {
            if (*wp == 0)
                *wp = 1;
            int const num_lines = (len + (*wp - 1)) / *wp;
            if (max_lines < num_lines)
                max_lines = num_lines;
        }
    }

    rowgrid( rowGrid, columnGrid, row_title_width, ncols, widths, fp );

    MiscTabFilter filt( fp );
    for (int i = 0; i < max_lines; i++)
    {
        rowTitleHeader( row_title_width, columnGrid, fp );
        int const* w = widths;
        for (c = 0; c < ncols; c++,w++)
        {
            colgrid( columnGrid, fp );
            NSString* const s = col_title( map[c], tableScroll );
            char const* const cs = [s lossyCString];
            int const len = safe_strlen( cs );
            bool skip = true;
            if (len > 0)
            {
                int const num_lines = (len + (*w - 1)) / *w;
                int const first_line = max_lines - num_lines;
                if (i >= first_line)
                {
                    skip = false;
                    if (len < *w)
                    {
                        filt.reset( cs, len );
                        filt.center( *w );
                    }
                    else
                    {
                        int const start_pos = (i - first_line) * *w;
                        filt.reset( cs + start_pos, len - start_pos );
                        filt.left( *w );
                    }
                }
            }
            if (skip)
                filt.pad( *w );
        }
        endline( columnGrid, fp );
    }
}



//-----------------------------------------------------------------------------
// fixedHeadersTrunc:::::
//-----------------------------------------------------------------------------
- (void)fixedHeadersTrunc:(int)row_title_width :(int)ncols 
			:(int const*)map :(int const*)widths :(FILE*)fp
{
    rowgrid( rowGrid, columnGrid, row_title_width, ncols, widths, fp );

    rowTitleHeader( row_title_width, columnGrid, fp );

    MiscTabFilter filt(fp);
    int const* w = widths;
    for (int c = 0; c < ncols; c++,w++)
    {
        colgrid( columnGrid, fp );
        filt.reset( col_title( map[c], tableScroll ) );
        filt.center( *w );
    }

    endline( columnGrid, fp );
}



//-----------------------------------------------------------------------------
// fixedHeaders:::::
//-----------------------------------------------------------------------------
- (void)fixedHeaders:(int)row_title_width
			:(int)ncols :(int const*)map :(int*)widths :(FILE*)fp
{
    switch (columnTitleMode)
    {
        default:
        case MISC_EXPORT_TITLES_ON:
            [self fixedHeadersOn:row_title_width:ncols:map:widths:fp];
            break;
        case MISC_EXPORT_TITLES_WRAP:
            [self fixedHeadersWrap:row_title_width:ncols:map:widths:fp];
            break;
        case MISC_EXPORT_TITLES_TRUNCATE:
            [self fixedHeadersTrunc:row_title_width:ncols:map:widths:fp];
            break;
        case MISC_EXPORT_TITLES_OFF:
            break;
    }
    if (columnTitleMode != MISC_EXPORT_TITLES_OFF)
        rowgrid( MISC_EXPORT_GRID_LINE,
                columnGrid, row_title_width, ncols, widths, fp );
}


//-----------------------------------------------------------------------------
// exportFixed: [public]
//-----------------------------------------------------------------------------
- (void)exportFixed:(FILE*)fp
{
    int const nrows = [tableScroll numberOfRows];
    int const ncols = [tableScroll numberOfColumns];
    int* col_map = [self makeColMap:ncols];
    int* widths = [self fixedWidths:nrows:ncols:col_map];
    int const row_title_width = [self rowTitleCharWidth:nrows];

    [self fixedHeaders:row_title_width:ncols:col_map:widths:fp];

    MiscTabFilter filt(fp);
    for (int r = 0; r < nrows; r++)
    {
        int const pr = row_at( r, tableScroll );
        if (row_title_width > 0)
        {
            colgrid( columnGrid, fp );
            filt.reset( row_title( pr, tableScroll ) );
            filt.center( row_title_width );
        }
        int const* w = widths;
        for (int c = 0; c < ncols; c++,w++)
        {
            colgrid( columnGrid, fp );
            id cell = cell_at( pr, col_map[c], tableScroll );
            filt.reset( cell_str( cell ) );
            switch (cell_alignment( cell ))
            {
                default:
                case NSLeftTextAlignment:   filt.left( *w );	break;
                case NSRightTextAlignment:  filt.right( *w );	break;
                case NSCenterTextAlignment: filt.center( *w );	break;
            }
        }
        endline( columnGrid, fp );
        rowgrid( rowGrid, columnGrid, row_title_width, ncols, widths, fp );
    }

    free( widths );
    free( col_map );
}


//-----------------------------------------------------------------------------
// exportDelimited:
//-----------------------------------------------------------------------------
- (void)exportDelimited:(FILE*)fp :(MiscCharFilter*)filt :(char) separator
{
    int const nrows = [tableScroll numberOfRows];
    int const ncols = [tableScroll numberOfColumns];
    BOOL const row_titles = (rowTitleMode != MISC_EXPORT_TITLES_OFF);

    int* col_map = [self makeColMap:ncols];

    if (columnTitleMode != MISC_EXPORT_TITLES_OFF)
    {
        if (row_titles)
        {
            NSString* rt = @"Row Titles";
            filt->reset( rt );
            filt->write();
            fputc( separator, fp );
        }
        for (int c = 0; c < ncols; c++)
        {
            if (c > 0)
                fputc( separator, fp );
            filt->reset( col_title( col_map[c], tableScroll ) );
            filt->write();
        }
        fputc( '\n', fp );
    }

    for (int r = 0; r < nrows; r++)
    {
        int const pr = row_at( r, tableScroll );
        if (row_titles)
        {
            filt->reset( row_title( pr, tableScroll ) );
            filt->write();
            fputc( separator, fp );
        }
        for (int c = 0; c < ncols; c++)
        {
            if (c > 0)
                fputc( separator, fp );
            filt->reset( str_at( pr, col_map[c], tableScroll ) );
            filt->write();
        }
        fputc( '\n', fp );
    }

    free( col_map );
}


//-----------------------------------------------------------------------------
// exportTab: [public]
//-----------------------------------------------------------------------------
- (void)exportTab:(FILE*)fp
{
    MiscTabFilter filt( fp );
    [self exportDelimited:fp:&filt:'\t'];
}


//-----------------------------------------------------------------------------
// exportDelimited: [public]
//-----------------------------------------------------------------------------
- (void)exportDelimited:(FILE*)fp
{
    MiscDelimFilter filt( fp );
    [self exportDelimited:fp:&filt:','];
}

@end
