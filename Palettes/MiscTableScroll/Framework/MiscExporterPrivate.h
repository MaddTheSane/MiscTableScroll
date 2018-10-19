#ifndef __MiscExporterPrivate_h
#define __MiscExporterPrivate_h
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
// MiscExporterPrivate.h
//
//	Private, internal communication and utility routines for the
//	MiscExporter class.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporterPrivate.h,v 1.4 97/04/15 08:58:07 sunshine Exp $
// $Log:	MiscExporterPrivate.h,v $
// Revision 1.4  97/04/15  08:58:07  sunshine
// v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
// framework organization.
// 
//  Revision 1.3  97/03/10  10:29:16  sunshine
//  v113.1: For OpenStep conformance, many 'col' methods renamed to 'column'.
//  
//  Revision 1.2  97/02/07  13:53:11  sunshine
//  v108: Ported to OPENSTEP 4.1 (gamma).
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscExporter.h>
#import	<MiscTableScroll/MiscTableScroll.h>
#import	<AppKit/NSCell.h>
#include <cstdio>
#include <cstring>


@interface MiscExporter(Private)
- (int*)makeColMap:(int)ncols;
- (int)rowTitleCharWidth:(int) nrows;
@end

@interface MiscExporter(ASCII)
- (void)exportFixed:(FILE*)fp;
- (void)exportTab:(FILE*)fp;
- (void)exportDelimited:(FILE*)fp;
@end

@interface MiscExporter(DBF)
- (void)exportDBF:(FILE*)fp;
@end

//-----------------------------------------------------------------------------
// safe_strlen
//-----------------------------------------------------------------------------
inline static int safe_strlen( NSString* s )
{
    return (s != 0 ? [s length] : 0);
}


//-----------------------------------------------------------------------------
// safe_strlen
//-----------------------------------------------------------------------------
inline static int safe_strlen( char const* s )
{
    return (s != 0 ? strlen(s) : 0);
}


//-----------------------------------------------------------------------------
// repchar
//-----------------------------------------------------------------------------
inline static void repchar( int rep, char c, FILE* fp )
{
    for (int i = 0; i < rep; i++)
        fputc( c, fp );
}


//-----------------------------------------------------------------------------
// pad
//-----------------------------------------------------------------------------
inline static void pad( int len, FILE* fp )
{
    repchar( len, ' ', fp );
}


inline static int row_at( int visual_pos, id obj )
{ return [obj rowAtPosition:visual_pos]; }


inline static int col_at( int visual_pos, id obj )
{ return [obj columnAtPosition:visual_pos]; }


inline static id cell_at( int r, int c, id obj )
{ return [obj cellAtRow:r column:c]; }


inline static NSString* str_at( int r, int c, id obj )
{ return [obj stringValueAtRow:r column:c]; }


inline static NSString* col_title( int c, id obj )
{ return [obj columnTitle:c]; }


inline static NSString* row_title( int r, id obj )
{ return [obj rowTitle:r]; }


#endif // __MiscExporterPrivate_h
