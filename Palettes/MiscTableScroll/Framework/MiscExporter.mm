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
// MiscExporter.M
//
//	Object that exports the contents of an MiscTableScroll in
//	various useful formats.
//
// TODO:
//	* Genericize for use with Matrix, DBTableView.
//	* Add more export formats: rtf0, Lotus 1-2-3, Quattro, Excel, etc.
//	* Maybe provide option for <CR><LF> line terminators.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporter.M,v 1.7 98/03/29 23:43:56 sunshine Exp $
// $Log:	MiscExporter.M,v $
// Revision 1.7  98/03/29  23:43:56  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// Interface to MiscExporterAccessoryView changed slightly.
// 
// Revision 1.6  97/04/01  07:46:13  sunshine
// v0.125.5: Ported to OPENSTEP 4.2 prerelease for NT.
// No longer sends -close and -makeKeyAndOrderFront: messages to NSSavePanel
// since it doesn't respond to them under NT.
// 
// Revision 1.5  97/03/10  10:27:31  sunshine
// v113.1: For OpenStep conformance, many 'col' methods rename to 'column'.
//-----------------------------------------------------------------------------
#import "MiscExporterPrivate.h"
#import "MiscExporterAccessoryView.h"
#import	<MiscTableScroll/MiscTableScroll.h>
#import	<AppKit/NSSavePanel.h>
extern "C" {
#import	<errno.h>
}


//=============================================================================
// MiscExporter
//=============================================================================
@implementation MiscExporter

- (MiscExportFormat)getExportFormat		{ return exportFormat; }
- (MiscExportTitleMode)getRowExportTitleMode	{ return rowTitleMode; }
- (MiscExportTitleMode)getColumnExportTitleMode	{ return columnTitleMode; }
- (MiscExportGridMode)getRowExportGridMode	{ return rowGrid; }
- (MiscExportGridMode)getColumnExportGridMode	{ return columnGrid; }

- (void)setExportFormat:(MiscExportFormat)x		{ exportFormat = x; }
- (void)setRowExportTitleMode:(MiscExportTitleMode)x	{ rowTitleMode = x; }
- (void)setColumnExportTitleMode:(MiscExportTitleMode)x	{ columnTitleMode = x; }
- (void)setRowExportGridMode:(MiscExportGridMode)x	{ rowGrid = x; }
- (void)setColumnExportGridMode:(MiscExportGridMode)x	{ columnGrid = x; }


//-----------------------------------------------------------------------------
// rowTitleCharWidth:
//-----------------------------------------------------------------------------
- (int)rowTitleCharWidth:(int)nrows
{
    int max_width = 0;
    if (rowTitleMode != MISC_EXPORT_TITLES_OFF)
        for (int r = 0; r < nrows; r++)
        {
            int const len = [row_title( r, tableScroll ) length];
            if (max_width < len)
                max_width = len;
        }
    return max_width;
}


//-----------------------------------------------------------------------------
// makeColMap:
//-----------------------------------------------------------------------------
- (int*)makeColMap:(int)ncols
{
    int* col_map = (int*) malloc( ncols * sizeof(*col_map) );
    for (int c = 0; c < ncols; c++)
        col_map[c] = col_at( c, tableScroll );
    return col_map;
}


//-----------------------------------------------------------------------------
// exportToFile:
//-----------------------------------------------------------------------------
- (void)exportToFile:(FILE*)fp
{
    switch (exportFormat)
    {
        default:
        case MISC_EXPORT_ASCII_FIXED:	 [self exportFixed:fp];	    break;
        case MISC_EXPORT_ASCII_TAB:	 [self exportTab:fp];	    break;
        case MISC_EXPORT_ASCII_DELIMITED:[self exportDelimited:fp]; break;
        case MISC_EXPORT_DBF:		 [self exportDBF:fp];	    break;
    }
}


//-----------------------------------------------------------------------------
// exportToFilename:
//-----------------------------------------------------------------------------
- (int)exportToFilename:(NSString*)nm
{
    int rc = 0;
    FILE* fp = fopen( [nm lossyCString], "wb" );
    if (fp == 0)
        rc = errno;
    else
    {
        [self exportToFile:fp];
        rc = fclose( fp );
    }
    return rc;
}


//-----------------------------------------------------------------------------
// createAccessoryView
//-----------------------------------------------------------------------------
- (MiscExporterAccessoryView*)createAccessoryView
{
    return [[[MiscExporterAccessoryView alloc]
             initWithFormat:exportFormat
             rowTitle:rowTitleMode
             colTitle:columnTitleMode
             rowGrid:rowGrid
             colGrid:columnGrid]
            autorelease];
}


//-----------------------------------------------------------------------------
// getValuesFromAccessoryView:
//-----------------------------------------------------------------------------
- (void)getValuesFromAccessoryView:(MiscExporterAccessoryView*)accessory
{
    [self setExportFormat:[accessory format]];
    [self setRowExportTitleMode:[accessory rowTitleMode]];
    [self setColumnExportTitleMode:[accessory columnTitleMode]];
    [self setRowExportGridMode:[accessory rowGrid]];
    [self setColumnExportGridMode:[accessory colGrid]];
}


//-----------------------------------------------------------------------------
// exportTableScroll:
//-----------------------------------------------------------------------------
- (int)exportTableScroll:(MiscTableScroll*)ts
{
    int rc = -1;
    if (ts != 0 && [ts numberOfColumns] > 0)
    {
        tableScroll = ts;
        NSSavePanel* panel = [NSSavePanel savePanel];
        MiscExporterAccessoryView* accessory = [self createAccessoryView];
        
        [panel setDelegate:self];
        [panel setAccessoryView:[accessory view]];
        if ([panel runModal] == NSOKButton)
        {
            [self getValuesFromAccessoryView:accessory];
            NSString* name = [panel filename];
            if ((rc = [self exportToFilename:name]) != 0)
                NSRunAlertPanel( @"Error", @"Cannot open %@.\n%s",
                                @"OK", nil, nil, name, strerror(rc));
        }
        [panel setAccessoryView:0];
        [panel setDelegate:0];
    }
    return rc;
}


//-----------------------------------------------------------------------------
// exportTableScroll:toFilename:
//-----------------------------------------------------------------------------
- (int)exportTableScroll:(MiscTableScroll*)ts toFilename:(NSString*)nm
{
    int rc = -1;
    if (nm != 0 && ts != 0 && [ts numberOfColumns] > 0)
    {
        tableScroll = ts;
        rc = [self exportToFilename:nm];
    }
    return rc;
}


//-----------------------------------------------------------------------------
// init
//-----------------------------------------------------------------------------
- (id)init
{
    [super init];
    rowTitleMode = MISC_EXPORT_TITLES_ROW_DEFAULT;
    columnTitleMode = MISC_EXPORT_TITLES_COL_DEFAULT;
    rowGrid = MISC_EXPORT_GRID_ROW_DEFAULT;
    columnGrid = MISC_EXPORT_GRID_COL_DEFAULT;
    return self;
}


//-----------------------------------------------------------------------------
// + commonInstance
//-----------------------------------------------------------------------------
+ (MiscExporter*)commonInstance
{
    static MiscExporter* obj = 0;
    if (obj == 0)
        obj = [[self alloc] init];
    return obj;
}

@end
