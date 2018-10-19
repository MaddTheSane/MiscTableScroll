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
// MiscExporterAccessoryView.M
//
//	Object that exports the contents of an MiscTableScroll in
//	various useful formats.
//
// BUGS:
//	* Enable / disable save controls based on format.
// TODO:
//	* Add more export formats: rtf0, Lotus 1-2-3, Quattro, Excel, etc.
//	* Maybe provide option for <CR><LF> line terminators.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporterAccessoryView.M,v 1.4 98/03/29 23:45:25 sunshine Exp $
// $Log:	MiscExporterAccessoryView.M,v $
// Revision 1.4  98/03/29  23:45:25  sunshine
// v138.1: Accessory view is now loaded from a nib rather than constructed
// programatically.  Control titles are no longer compiled in.
// 
// Revision 1.3  97/03/10  10:28:49  sunshine
// v113.1: For OpenStep conformance, many 'col' methods rename to 'column'.
// 
// Revision 1.2  97/02/07  13:53:25  sunshine
// v108: Ported to OPENSTEP 4.1 (gamma).
//-----------------------------------------------------------------------------
#import "MiscExporterAccessoryView.h"
#import <AppKit/NSNibLoading.h>
#import	<AppKit/NSPopUpButton.h>
#import <AppKit/NSWindow.h>

//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscExporterAccessoryView

- (NSView*)view { return [window contentView]; }
- (MiscExportFormat)format
{ return MiscExportFormat( [[formatPop selectedItem] tag] ); }
- (MiscExportTitleMode)rowTitleMode;
{ return MiscExportTitleMode( [[rowTitlePop selectedItem] tag] ); }
- (MiscExportTitleMode)columnTitleMode;
{ return MiscExportTitleMode( [[colTitlePop selectedItem] tag] ); }
- (MiscExportGridMode)rowGrid;
{ return MiscExportGridMode( [[rowGridPop selectedItem] tag] ); }
- (MiscExportGridMode)colGrid;
{ return MiscExportGridMode( [[colGridPop selectedItem] tag] ); }


//-----------------------------------------------------------------------------
// - select:itemWithTag: -- If 'tag' not found then selects item 0.
//-----------------------------------------------------------------------------
- (void)select:(NSPopUpButton*)popup itemWithTag:(int)tag
{
    unsigned int i = [popup numberOfItems];
    NSParameterAssert( i != 0 );
    while (i-- > 1)
        if (tag == [[popup itemAtIndex:i] tag])
            break;
    [popup selectItemAtIndex:i];
}


//-----------------------------------------------------------------------------
// -initWithFormat:rowTitle:colTitle:rowGrid:colGrid:
//-----------------------------------------------------------------------------
- (MiscExporterAccessoryView*)
    initWithFormat:(MiscExportFormat)format
    rowTitle:(MiscExportTitleMode)rowTitle
    colTitle:(MiscExportTitleMode)colTitle
    rowGrid:(MiscExportGridMode)rowGrid
    colGrid:(MiscExportGridMode)colGrid
{
    [super init];
    [NSBundle loadNibNamed:@"MiscExporterAccessoryView" owner:self];
    [self select:formatPop   itemWithTag:format  ];
    [self select:rowTitlePop itemWithTag:rowTitle];
    [self select:colTitlePop itemWithTag:colTitle];
    [self select:rowGridPop  itemWithTag:rowGrid ];
    [self select:colGridPop  itemWithTag:colGrid ];
    return self;
}


//-----------------------------------------------------------------------------
// -dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
{
    [window release];
    [super dealloc];
}

@end
