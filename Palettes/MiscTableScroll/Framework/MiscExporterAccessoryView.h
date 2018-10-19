#ifndef __MiscExporterAccessoryView_h
#define __MiscExporterAccessoryView_h
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
// MiscExporterAccessoryView.h
//
//	SavePanel accessory view for use by the MiscExporter class.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporterAccessoryView.h,v 1.5 98/03/29 23:45:29 sunshine Exp $
// $Log:	MiscExporterAccessoryView.h,v $
// Revision 1.5  98/03/29  23:45:29  sunshine
// v138.1: Accessory view is now loaded from a nib rather than constructed
// programatically.  Control titles are no longer compiled in.
// 
//  Revision 1.4  97/04/15  08:57:51  sunshine
//  v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
//  framework organization.
//  
//  Revision 1.3  97/03/10  10:28:46  sunshine
//  v113.1: For OpenStep conformance, many 'col' methods rename to 'column'.
//-----------------------------------------------------------------------------
#import	<Foundation/NSObject.h>
#import <MiscTableScroll/MiscExporter.h>
@class NSBox, NSPopUpButton, NSView, NSWindow;

@interface MiscExporterAccessoryView : NSObject
{
	NSWindow*	window;
	NSPopUpButton*	formatPop;
	NSPopUpButton*	rowTitlePop;
	NSPopUpButton*	colTitlePop;
	NSPopUpButton*	rowGridPop;
	NSPopUpButton*	colGridPop;
	NSBox*		formatBox;
	NSBox*		rowTitleBox;
	NSBox*		colTitleBox;
	NSBox*		rowGridBox;
	NSBox*		colGridBox;
}

- (MiscExporterAccessoryView*)
	initWithFormat:(MiscExportFormat)format
	rowTitle:(MiscExportTitleMode)rowTitle
	colTitle:(MiscExportTitleMode)colTitle
	rowGrid:(MiscExportGridMode)rowGrid
	colGrid:(MiscExportGridMode)colGrid;
- (void)dealloc;
- (NSView*)view;
- (MiscExportFormat)format;
- (MiscExportTitleMode)rowTitleMode;
- (MiscExportTitleMode)columnTitleMode;
- (MiscExportGridMode)rowGrid;
- (MiscExportGridMode)colGrid;

@end

#endif // __MiscExporterAccessoryView_h
