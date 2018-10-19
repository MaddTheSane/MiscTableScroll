#ifndef __MiscExporter_h
#define __MiscExporter_h
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
// MiscExporter.h
//
//	Object that exports the contents of an MiscTableScroll in
//	various useful formats.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporter.h,v 1.5 97/04/15 08:57:36 sunshine Exp $
// $Log:	MiscExporter.h,v $
// Revision 1.5  97/04/15  08:57:36  sunshine
// v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
// framework organization.
// 
//  Revision 1.4  97/03/10  10:27:52  sunshine
//  v113.1: For OpenStep conformance, many 'col' methods rename to 'column'.
//  
//  Revision 1.3  97/02/07  13:53:31  sunshine
//  v108: Ported to OPENSTEP 4.1 (gamma).
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableTypes.h>
#import <Foundation/NSObject.h>

@class MiscTableScroll;

typedef enum
{
    MISC_EXPORT_ASCII_FIXED,
    MISC_EXPORT_ASCII_TAB,
    MISC_EXPORT_ASCII_DELIMITED,
    MISC_EXPORT_DBF
} MiscExportFormat;

#define	MISC_EXPORT_FORMAT_FIRST	MISC_EXPORT_ASCII_FIXED
#define	MISC_EXPORT_FORMAT_LAST		MISC_EXPORT_DBF
#define	MISC_EXPORT_FORMAT_DEFAULT	MISC_EXPORT_ASCII_FIXED


typedef enum				// For ASCII formats only.
{
    MISC_EXPORT_TITLES_OFF,		// No titles.
    MISC_EXPORT_TITLES_ON,		// Full width, expand column if needed.
    MISC_EXPORT_TITLES_WRAP,	// Wrap titles within data width.
    MISC_EXPORT_TITLES_TRUNCATE,	// Truncate titles to data width.
} MiscExportTitleMode;

#define	MISC_EXPORT_TITLES_FIRST	MISC_EXPORT_TITLES_OFF
#define	MISC_EXPORT_TITLES_LAST		MISC_EXPORT_TITLES_TRUNCATE
#define	MISC_EXPORT_TITLES_ROW_DEFAULT	MISC_EXPORT_TITLES_OFF
#define	MISC_EXPORT_TITLES_COL_DEFAULT	MISC_EXPORT_TITLES_ON


typedef enum
{
    MISC_EXPORT_GRID_OFF,		// No grid
    MISC_EXPORT_GRID_LINE,		// Lines, col-grid='|', row-grid='-'
    MISC_EXPORT_GRID_SPACE,		// Spaces col-grid=' ', row-grid=' '
} MiscExportGridMode;

#define	MISC_EXPORT_GRID_FIRST		MISC_EXPORT_GRID_OFF
#define	MISC_EXPORT_GRID_LAST		MISC_EXPORT_GRID_SPACE
#define	MISC_EXPORT_GRID_ROW_DEFAULT	MISC_EXPORT_GRID_OFF
#define	MISC_EXPORT_GRID_COL_DEFAULT	MISC_EXPORT_GRID_LINE


@interface MiscExporter : NSObject
{
    MiscTableScroll*	tableScroll;	// Defaults
    MiscExportFormat	exportFormat;	// MISC_EXPORT_ASCII_FIXED
    MiscExportTitleMode	rowTitleMode;	// MISC_EXPORT_TITLES_OFF
    MiscExportTitleMode	columnTitleMode;// MISC_EXPORT_TITLES_ON
    MiscExportGridMode	rowGrid;	// MISC_EXPORT_GRID_OFF
    MiscExportGridMode	columnGrid;	// MISC_EXPORT_GRID_LINE
}

- (id)init;

- (int)exportTableScroll:(MiscTableScroll*)ts;	// Run SavePanel.
- (int)exportTableScroll:(MiscTableScroll*)ts toFilename:(NSString*)name;

- (void)setExportFormat:(MiscExportFormat)exportFormat;
- (void)setRowExportTitleMode:(MiscExportTitleMode)rowTitleMode;
- (void)setColumnExportTitleMode:(MiscExportTitleMode)columnTitleMode;
- (void)setRowExportGridMode:(MiscExportGridMode)rowExportGridMode;
- (void)setColumnExportGridMode:(MiscExportGridMode)columnExportGridMode;

- (MiscExportFormat)getExportFormat;
- (MiscExportTitleMode)getRowExportTitleMode;
- (MiscExportTitleMode)getColumnExportTitleMode;
- (MiscExportGridMode)getRowExportGridMode;
- (MiscExportGridMode)getColumnExportGridMode;

+ (MiscExporter*)commonInstance;

@end

#endif // __MiscExporter_h
