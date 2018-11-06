//=============================================================================
//
//	Copyright (C) 1996-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollPrint.M
//
//	Printing support for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollPrint.M,v 1.4 99/06/15 03:34:42 sunshine Exp $
// $Log:	MiscTableScrollPrint.M,v $
// Revision 1.4  99/06/15  03:34:42  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Page header and footer are now strongly typed as NSView rather than id.
// The strong typing extends to the Java environment more cleanly.
// 
// Revision 1.3  1997/03/20 19:15:15  sunshine
// v123.1: Fixed bug: Delegate methods -tableScrollWillPrint: &
// -tableScrollDidPrint: were getting subverted when -print: was sent
// to first-responder (which is the MiscTableView, not the MiscTableScroll).
// Connecting Print... item to first-responder in IB can cause this.
// Was fixed by sending them in MiscTableViewPrint.M rather than here.
//
// Revision 1.2  97/02/09  07:41:03  sunshine
// v110: Ported to OPENSTEP 4.1 (gamma).
//-----------------------------------------------------------------------------
#import "MiscTableScrollPrivate.h"
#import "MiscDelegateFlags.h"
#import "MiscTableView.h"
#import "MiscBorderView.h"
#import	<AppKit/NSApplication.h>
#import	<AppKit/NSPrintInfo.h>
#import	<AppKit/NSPrintPanel.h>


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableScroll(Print)

- (NSView*)getPageHeader		{ return pageHeader; }
- (NSView*)getPageFooter		{ return pageFooter; }
- (void)setPageHeader:(NSView*)obj	{ pageHeader = obj; }
- (void)setPageFooter:(NSView*)obj	{ pageFooter = obj; }

- (MiscTablePrintInfo const*)getPrintInfo { return [tableView getPrintInfo]; }

//-----------------------------------------------------------------------------
// dumpPrintInfo:
//-----------------------------------------------------------------------------
- (void)dumpPrintInfo:(NSPrintInfo*)pinfo
{
    fprintf( stderr, "printInfo=%p\n", pinfo );
    fprintf( stderr, "paperType:[%s]\n", [[pinfo paperName] UTF8String] );
    fprintf( stderr, "paperSize:%s\n",
            [NSStringFromSize([pinfo paperSize]) UTF8String] );
    fprintf( stderr, "margins: left=%g right=%g top=%g bottom=%g\n",
            [pinfo leftMargin], [pinfo rightMargin],
            [pinfo topMargin], [pinfo bottomMargin] );
    fprintf( stderr, "scalingFactor=%g\n",
            [[[pinfo dictionary] objectForKey:NSPrintScalingFactor] floatValue] );
    fprintf( stderr, "orientation=%d\n", (int)[pinfo orientation] );
    fprintf( stderr, "isHorizontallyCentered=%d\n",
            (int)[pinfo isHorizontallyCentered] );
    fprintf( stderr, "isVerticallyCentered=%d\n",
            (int)[pinfo isVerticallyCentered] );
	fprintf( stderr, "horizontalPagination=%lu\n",
			(unsigned long)[pinfo horizontalPagination] );
	fprintf( stderr, "verticalPagination=%lu\n",
			(unsigned long)[pinfo verticalPagination] );
    fprintf( stderr, "isAllPages=%d\n",
            (int)[[[pinfo dictionary] objectForKey:NSPrintAllPages] boolValue] );
    fprintf( stderr, "firstPage=%d\n",
            [[[pinfo dictionary] objectForKey:NSPrintFirstPage] intValue] );
    fprintf( stderr, "lastPage=%d\n",
            [[[pinfo dictionary] objectForKey:NSPrintLastPage] intValue] );
    fprintf( stderr, "copies=%d\n",
            [[[pinfo dictionary] objectForKey:NSPrintCopies] intValue] );
    fprintf( stderr, "pagesPerSheet=%d\n",
            [[[pinfo dictionary] objectForKey:NSPrintPagesPerSheet] intValue] );
    fprintf( stderr, "reversePageOrder=%d\n",
            [[[pinfo dictionary] objectForKey:NSPrintReversePageOrder] boolValue]);
    // There are also job features...
}


//-----------------------------------------------------------------------------
// print:
//-----------------------------------------------------------------------------
- (void)print:(id)sender
{
    [tableView print:sender];
}

@end
