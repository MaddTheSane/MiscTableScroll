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
// MiscTableViewPrint.M
//
//	Printing support for MiscTableScroll.
//
// FIXME: Move most of this junk up into table scroll.
// FIXME: Separate computing the number of pages from doing all the
//	other work, so that hopefully, we can do all the other work
//	only if the user proceeds with a print operation.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableViewPrint.M,v 1.11 99/07/15 12:38:08 sunshine Exp $
// $Log:	MiscTableViewPrint.M,v $
// Revision 1.11  99/07/15  12:38:08  sunshine
// v140.1: Fixed bug: Was ignoring scaling factor during printing.  The scale
// input field moved from the page layout panel to the print panel between
// NextStep and OpenStep, which means that as of OpenStep the scaling factor
// is only available *after* the print panel has been dismissed, but this code
// was not taking that into account.
// 
// Revision 1.10  99/06/15  04:07:10  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Removed unused and buggy -getWidth which was incorrectly testing the
// incoming object to see if it responded to -size: when it should have been
// testing for response to -size.
// Now sends notifications instead of sending delegate message directly.
//
// Revision 1.9  1998/03/22 13:12:07  sunshine
// v133.1: Now prints corner view.
//-----------------------------------------------------------------------------
#import "MiscTableView.h"
#import "MiscBorderView.h"
#import "MiscCornerView.h"
#import "MiscGeometry.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import	<AppKit/NSApplication.h>
#import	<AppKit/NSImage.h>
#import	<AppKit/NSPrintInfo.h>
#import <AppKit/NSPrintOperation.h>
#import	<AppKit/NSPrintPanel.h>
//#import <AppKit/psops.h>
#include <cmath>	// floor()

@implementation MiscTableView(Print)

//-----------------------------------------------------------------------------
// getPrintInfo
//-----------------------------------------------------------------------------
- (MiscTablePrintInfo const*)getPrintInfo
{
    return (pages != 0) ? &(pages->info) : 0;
}


//-----------------------------------------------------------------------------
// getHeight:
//-----------------------------------------------------------------------------
- (float)getHeight:(id)obj
{
    if (obj != 0)
    {
        if ([obj respondsToSelector:@selector(frame)])
            return [obj frame].size.height;
        else if ([obj respondsToSelector:@selector(size)])
            return [obj size].height;
    }
    return 0;
}


//-----------------------------------------------------------------------------
// numPagesForBorder:pageSize:
//-----------------------------------------------------------------------------
- (int)numPagesForBorder:(MiscBorderType)bt pageSize:(float)scaled_page_size
{
    int npages = 0;

    // FIXME: Borders with uniform size slots should be much simpler
    // than this.

    MiscPixels const page_size = (MiscPixels)floor(scaled_page_size);

    NSParameterAssert( page_size > 0 );

    MiscTableBorder* const border =
    (bt == MISC_COL_BORDER ? colBorder : rowBorder);

    MiscPixels sz_sum = 0;
    MiscCoord_V const numSlots = border->count();
    for (MiscCoord_V vslot = 0; vslot < numSlots; vslot++)
    {
        MiscPixels sz = border->effectiveSize(vslot);
        if (sz <= page_size)
        {
            sz_sum += sz;
            if (sz_sum > page_size)
            {
                sz_sum = sz;
                npages++;
            }
        }
        else
        {
            if (sz_sum > 0)
                npages++;
            npages += sz / page_size;
            sz_sum = sz % page_size;
        }
    }
    
    if (sz_sum >= 0)
        npages++;

    return npages;
}


//-----------------------------------------------------------------------------
// append
//-----------------------------------------------------------------------------
static void append( MiscPixels w, MiscTSPageBreak& bk, MiscTSPageBreak bks[],
			int n, int num_breaks )
{
    NSCParameterAssert( n < num_breaks );
    bk.size = w;
    bks[ n ] = bk;
    bk.offset += w;
}


//-----------------------------------------------------------------------------
// border:pageSize:numPages:calcBreaks:
//-----------------------------------------------------------------------------
- (void)border:(MiscBorderType)bt
	pageSize:(float)pageSize
	numPages:(int)nPages
	clip:(BOOL)do_clip
	calcBreaks:(MiscTSPageBreak*)bks
{
    MiscPixels const page_size = (MiscPixels)floor(pageSize);

    // FIXME: Borders with uniform size slots should be much simpler
    // than this.

    NSParameterAssert( page_size > 0 );

    MiscTableBorder* const border =
    (bt == MISC_COL_BORDER ? colBorder : rowBorder);

    MiscTSPageBreak bk;
    bk.offset = 0;
    bk.size = 0;
    bk.first = 0;
    bk.last = 0;

    int pg = 0;
    MiscPixels sz_sum = 0;

    MiscCoord_V const numSlots = border->count();
    for (MiscCoord_V vslot = 0; vslot < numSlots; vslot++)
    {
        MiscPixels sz = border->effectiveSize(vslot);
        if (sz <= page_size)
        {
            sz_sum += sz;
            if (sz_sum > page_size)
            {
                bk.last = (vslot - 1);
                append( sz_sum - sz, bk, bks, pg++, nPages );
                if (do_clip) goto clip_exit;
                bk.first = vslot;
                sz_sum = sz;
            }
        }
        else
        {
            if (sz_sum > 0)
            {
                bk.last = (vslot - 1);
                append( sz_sum, bk, bks, pg++, nPages );
                if (do_clip) goto clip_exit;
            }
            bk.first = vslot;
            bk.last = ~vslot;
            do  {
                append( page_size, bk, bks, pg++, nPages );
                if (do_clip) goto clip_exit;
                bk.first = ~vslot;
                sz -= page_size;
            }
            while (sz > page_size);
            sz_sum = sz;
        }
    }

    if (sz_sum >= 0)
    {
        bk.last = numSlots - 1;
        append( sz_sum, bk, bks, pg++, nPages );
    }

clip_exit:

    NSParameterAssert( pg == nPages );
}


//-----------------------------------------------------------------------------
// - getImageForView:inRect:
//
//	This method gets called in the middle of MiscTableView's print
//	operation while the pages are being calculated by -calcPages.
//	However, -dataWithEPSInsideRect: throws an exception if it is called
//	while another print operation is already in progress.  To work around
//	this problem, we temporarily set the current print operation to nil.
//	The reason it is necessary to call -calcPages after initiation of the
//	print operation is that it needs to know the scaling factor specified
//	via the print panel.  Under NextStep, the scaling factor was specified
//	via the page layout panel rather than the print panel, and was
//	therefore accessible without having to initiate a print operation.
//	Consequently, under NextStep, MiscTableView calls -calcPages before
//	initiating the print operation, thus avoiding this particular hassle
//	altogether.
//-----------------------------------------------------------------------------
- (NSImage*)getImageForView:(NSView*)view inRect:(NSRect)rect
{
    NSPrintOperation* op = [[NSPrintOperation currentOperation] retain];
    [NSPrintOperation setCurrentOperation:0];
    NSImage* image = [[NSImage alloc] initWithData:
                      [view dataWithPDFInsideRect:rect]];
    [NSPrintOperation setCurrentOperation:op];
    [op release];
    return [image autorelease];
}


//-----------------------------------------------------------------------------
// - getImageForView:
//-----------------------------------------------------------------------------
- (NSImage*)getImageForView:(NSView*)view
{
    return [self getImageForView:view inRect:[view bounds]];
}


//-----------------------------------------------------------------------------
// sendNotification:withView:info:
//-----------------------------------------------------------------------------
- (void)sendNotification:(NSString*)name withView:(NSView*)view
    info:(MiscTablePrintInfo const*)info
    {
#define NUMOBJ(TYPE,VAL) [NSNumber numberWith##TYPE:VAL]
    [[NSNotificationCenter defaultCenter]
	postNotificationName:name object:[self scroll]
	userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
	    view, @"View",
	    NUMOBJ(Float,info->page_size.width), @"PageWidth",
	    NUMOBJ(Float,info->page_size.height), @"PageHeight",
	    NUMOBJ(Float,info->print_rect.origin.x), @"PrintRectX",
	    NUMOBJ(Float,info->print_rect.origin.y), @"PrintRectY",
	    NUMOBJ(Float,info->print_rect.size.width), @"PrintRectWidth",
	    NUMOBJ(Float,info->print_rect.size.height), @"PrintRectHeight",
	    NUMOBJ(Int,info->first_print_row), @"FirstPrintRow",
	    NUMOBJ(Int,info->last_print_row), @"LastPrintRow",
	    NUMOBJ(Int,info->first_print_col), @"FirstPrintColumn",
	    NUMOBJ(Int,info->last_print_col), @"LastPrintColumn",
	    NUMOBJ(Int,info->print_page), @"PrintPage",
	    NUMOBJ(Int,info->print_row), @"PrintRow",
	    NUMOBJ(Int,info->print_col), @"PrintColumn",
	    NUMOBJ(Int,info->num_print_pages), @"NumberOfPrintPages",
	    NUMOBJ(Int,info->num_print_rows), @"NumberOfPrintRows",
	    NUMOBJ(Int,info->num_print_cols), @"NumberOfPrintColumns",
	    NUMOBJ(Double,info->scale_factor), @"ScaleFactor",
	    NUMOBJ(Bool,info->is_scaled), @"IsScaled", nil]];
#undef NUMOBJ
    }


//-----------------------------------------------------------------------------
// getImages:info:
//-----------------------------------------------------------------------------
- (void)getImages:(MiscTSPageImages*)img
	info:(MiscTablePrintInfo const*)info
{
    img->page_header = 0;
    img->page_footer = 0;
    img->col_titles = 0;
    img->row_titles = 0;
    img->corner_view = 0;

    if (pages->pageHeader != 0)
    {
        [self sendNotification:MiscTableScrollWillPrintPageHeaderNotification
                      withView:pages->pageHeader info:info];
        // FIXME: Need to shrink/grow/center/position.
        img->page_header = [[self getImageForView:pages->pageHeader] retain];
    }

    if (pages->pageFooter != 0)
    {
        [self sendNotification:MiscTableScrollWillPrintPageFooterNotification
                      withView:pages->pageFooter info:info];
        // FIXME: Need to shrink/grow/center/position.
        img->page_footer = [[self getImageForView:pages->pageFooter] retain];
    }

    if (pages->colTitles != 0)
    {
        NSRect r = info->print_rect;
        r.origin.y = 0;
        r.size.height = pages->col_titles_height;
        img->col_titles =
        [[self getImageForView:pages->colTitles inRect:r] retain];
    }

    if (pages->rowTitles != 0)
    {
        NSRect r = info->print_rect;
        r.origin.x = 0;
        r.size.width = pages->row_titles_width;
        img->row_titles =
        [[self getImageForView:pages->rowTitles inRect:r] retain];
    }

    if (pages->cornerView != 0)
    {
        NSRect r;
        r.origin.x = 0;
        r.origin.y = 0;
        r.size.width = pages->row_titles_width;
        r.size.height = pages->col_titles_height;
        img->corner_view =
        [[self getImageForView:pages->cornerView inRect:r] retain];
    }
}


//-----------------------------------------------------------------------------
// calcPages
//-----------------------------------------------------------------------------
- (void)calcPages
{
    id const scroll = [self scroll];

    pages = new MiscTablePages;

    pages->pageHeader = [scroll getPageHeader];
    pages->pageFooter = [scroll getPageFooter];
    pages->page_header_height = [self getHeight:pages->pageHeader];
    pages->page_footer_height = [self getHeight:pages->pageFooter];

    pages->colTitles = [scroll colTitles];
    pages->rowTitles = [scroll rowTitles];
    if (pages->colTitles != 0 && pages->rowTitles != 0)
        pages->cornerView = [scroll cornerView];
    else
        pages->cornerView = 0;
    pages->col_titles_height = [scroll columnTitlesHeight];
    pages->row_titles_width  = [scroll rowTitlesWidth ];

    CGFloat scroll_width = [scroll totalWidth];
    CGFloat scroll_height = [scroll totalHeight];
    CGFloat total_width  = scroll_width  + pages->row_titles_width;
    CGFloat total_height = scroll_height + pages->col_titles_height;

    NSPrintInfo* printInfo = [[NSPrintOperation currentOperation] printInfo];
    NSSize const paperSize = [printInfo paperSize];

    CGFloat page_width = paperSize.width -
    [printInfo leftMargin] - [printInfo rightMargin];
    CGFloat page_height = paperSize.height -
    [printInfo topMargin] - [printInfo bottomMargin] -
    pages->page_header_height -
    pages->page_footer_height;

    int const hPagination = [printInfo horizontalPagination];
    int const vPagination = [printInfo verticalPagination];

    BOOL hScaled = NO;	double hScaler = 1.0;
    BOOL vScaled = NO;	double vScaler = 1.0;
    BOOL isScaled = NO;	double scaleFactor = 1.0;

    if (hPagination == NSFitPagination && total_width > page_width)
    {
        hScaled = YES;
        hScaler = double(page_width) / double(total_width);
    }

    if (vPagination == NSFitPagination && total_height > page_height)
    {
        vScaled = YES;
        vScaler = double(page_height) / double(total_height);
    }

    if (hScaled || vScaled)
    {
        isScaled = YES;
        if (vScaler < hScaler)
            scaleFactor = vScaler;
        else
            scaleFactor = hScaler;
    }

    CGFloat const EPSILON = 0.0001;
    CGFloat pScaler = 1.0;
    id val = [[printInfo dictionary] objectForKey:NSPrintScalingFactor];
    if (val != 0)
        pScaler = [val floatValue];
    if (pScaler < (1.0 - EPSILON) || (1.0 + EPSILON) < pScaler)
    {
        if (isScaled)
            scaleFactor *= pScaler;
        else
        {
            scaleFactor = pScaler;
            isScaled = YES;
        }
    }

    pages->info.is_scaled = isScaled;
    pages->info.scale_factor = scaleFactor;

    CGFloat scaled_page_width = page_width;
    CGFloat scaled_page_height = page_height;

    if (isScaled)
    {
        scaled_page_width = double(page_width) / scaleFactor;
        scaled_page_height = double(page_height) / scaleFactor;
    }

    scaled_page_width -= pages->row_titles_width;
    scaled_page_height -= pages->col_titles_height;


    //--- Calculate the number of rows/cols/pages -------------------------

    int ncols = 1;
    int nrows = 1;

    if (hPagination != NSClipPagination && scroll_width > scaled_page_width)
        ncols = [self numPagesForBorder:MISC_COL_BORDER
                               pageSize:scaled_page_width];

    if (vPagination != NSClipPagination && scroll_height > scaled_page_height)
        nrows = [self numPagesForBorder:MISC_ROW_BORDER
                               pageSize:scaled_page_height];

    NSParameterAssert( nrows > 0 );  NSParameterAssert( ncols > 0 );

    int const npages = nrows * ncols;


    //--- Allocate arrays -------------------------------------------------

    pages->col_breaks = (MiscTSPageBreak*)
    malloc( (ncols + nrows) * sizeof(MiscTSPageBreak) );
    pages->row_breaks = pages->col_breaks + ncols;

    MiscTSPageImages* images = (MiscTSPageImages*)
    malloc( npages * sizeof(*images) );
    pages->images = images;


    //--- Prepare print rectangles and border images ----------------------

    [self border:MISC_COL_BORDER
        pageSize:scaled_page_width
        numPages:ncols
            clip:(hPagination == NSClipPagination)
      calcBreaks:pages->col_breaks];

    [self border:MISC_ROW_BORDER
        pageSize:scaled_page_height
        numPages:nrows
            clip:(vPagination == NSClipPagination)
      calcBreaks:pages->row_breaks];


    MiscTablePrintInfo& info = pages->info;
    info.page_size = paperSize;
    info.num_print_pages = npages;
    info.num_print_rows = nrows;
    info.num_print_cols = ncols;
    info.scale_factor = scaleFactor;
    info.is_scaled = isScaled;

    int pg = 0;
    MiscTSPageImages* img = images;
    MiscTSPageBreak const* rbk = pages->row_breaks;
    for (int r = 0; r < nrows; r++,rbk++)
    {
        info.print_rect.origin.y = rbk->offset;
        info.print_rect.size.height = rbk->size;
        info.first_print_row = rbk->first;
        info.last_print_row = rbk->last;
        
        MiscTSPageBreak const* cbk = pages->col_breaks;
        for (int c = 0; c < ncols; c++,cbk++,img++)
        {
            info.print_rect.origin.x = cbk->offset;
            info.print_rect.size.width = cbk->size;
            info.first_print_col = cbk->first;
            info.last_print_col = cbk->last;
            info.print_page = ++pg;
            
            [self getImages:img info:&info];
        }
    }
}


//-----------------------------------------------------------------------------
// freePages
//-----------------------------------------------------------------------------
- (void)freePages
{
    if (pages != 0)
    {
        if (pages->col_breaks != 0)
        {
            free( pages->col_breaks );
            pages->col_breaks = 0;
        }
        if (pages->images != 0)
        {
            for (int i = pages->info.num_print_pages; i-- > 0; )
            {
                MiscTSPageImages const& img = pages->images[i];
                if (img.page_header != 0) [img.page_header release];
                if (img.page_footer != 0) [img.page_footer release];
                if (img.col_titles  != 0) [img.col_titles  release];
                if (img.row_titles  != 0) [img.row_titles  release];
                if (img.corner_view != 0) [img.corner_view release];
            }
            free( pages->images );
            pages->images = 0;
        }
        delete pages;
        pages = 0;
    }
}


//-----------------------------------------------------------------------------
// print:
//-----------------------------------------------------------------------------
- (void)print:(id)sender
{
    id const scroll = [self scroll];
    [[NSNotificationCenter defaultCenter] postNotificationName:
     MiscTableScrollWillPrintNotification object:scroll];

    [self superPrint:sender];
    [self freePages];

    [[NSNotificationCenter defaultCenter] postNotificationName:
     MiscTableScrollDidPrintNotification object:scroll];
}


//-----------------------------------------------------------------------------
// knowsPagesFirst:last:
//-----------------------------------------------------------------------------
- (BOOL)knowsPagesFirst:(int*)first last:(int*)last
{
    NSParameterAssert( pages == 0 );
    [self calcPages];
    *first = 1;
    *last = pages->info.num_print_pages;
    return YES;
}


//-----------------------------------------------------------------------------
// rectForPage:
//-----------------------------------------------------------------------------
- (NSRect)rectForPage:(int)n
{
    NSParameterAssert( pages != 0 );
    MiscTablePrintInfo const& info = pages->info;
    if (0 < n && n <= info.num_print_pages)
    {
        n--;
        int const r = (n / info.num_print_cols);
        int const c = (n % info.num_print_cols);
        MiscTSPageBreak const& cbk = pages->col_breaks[c];
        MiscTSPageBreak const& rbk = pages->row_breaks[r];
        return NSMakeRect( cbk.offset, rbk.offset, cbk.size, rbk.size );
    }
    return NSZeroRect;
}


//-----------------------------------------------------------------------------
// locationOfPrintRect:
//-----------------------------------------------------------------------------
- (NSPoint)locationOfPrintRect:(NSRect)rect
{
    NSPrintInfo* printInfo = [[NSPrintOperation currentOperation] printInfo];
    NSSize const paperSize = [printInfo paperSize];
    CGFloat ml = [printInfo leftMargin];
    CGFloat mr = [printInfo rightMargin];
    CGFloat mt = [printInfo topMargin];
    CGFloat mb = [printInfo bottomMargin];

    CGFloat x = 0;
    CGFloat y = 0;
    CGFloat h = paperSize.height;
    CGFloat w = paperSize.width;
    CGFloat rh = rect.size.height;
    CGFloat rw = rect.size.width;
    CGFloat tw = pages->row_titles_width;
    CGFloat th = pages->col_titles_height;
    CGFloat hh = pages->page_header_height;

    NSParameterAssert( pages != 0 );

    MiscTablePrintInfo const& info = pages->info;
    if (info.is_scaled)
    {
        CGFloat const k = info.scale_factor;
        x /= k;
        y /= k;
        h /= k;
        w /= k;
        ml /= k;
        mr /= k;
        mt /= k;
        mb /= k;
    }

    NSPoint pt = NSMakePoint( x + ml + tw, y + h - mt - rh - hh - th );

    if ([printInfo isHorizontallyCentered])
    {
        float dx = w - ml - mr - tw - rw;
        if (dx > 0)
            pt.x += dx / 2;
    }

    if ([printInfo isVerticallyCentered])
    {
        CGFloat dy = h - mt - mb - th - rh;
        if (dy > 0)
            pt.y -= dy / 2;
    }

    return pt;
}


//-----------------------------------------------------------------------------
// drawImage:at:
//-----------------------------------------------------------------------------
- (void)drawImage:(NSImage*)img at:(NSPoint)pt
{
    NSRect r;
    r.size = [img size];
    r.origin.x = pt.x;
    r.origin.y = pt.y - r.size.height;
    [img drawRepresentation:[[img representations] lastObject] inRect:r];
}


//-----------------------------------------------------------------------------
// drawPageBorderWithSize:
//-----------------------------------------------------------------------------
- (void)drawPageBorderWithSize:(NSSize)borderSize
{
    NSParameterAssert( pages != 0 );
    MiscTablePrintInfo const& info = pages->info;

    NSInteger n = [[NSPrintOperation currentOperation] currentPage] - 1;
    NSParameterAssert( 0 <= n );
    NSParameterAssert( n < info.num_print_pages );
    MiscTSPageImages const& img = pages->images[n];

    NSPrintInfo* printInfo = [[NSPrintOperation currentOperation] printInfo];
    CGFloat const ml = [printInfo leftMargin];
    CGFloat const mr = [printInfo rightMargin];
    CGFloat const mb = [printInfo bottomMargin];
    CGFloat const mt = [printInfo topMargin];

    NSPoint const page_origin = NSZeroPoint;
    NSSize const page_size = info.page_size;
    CGFloat bottom = page_origin.y + mb;
    CGFloat top = page_origin.y + page_size.height - mt;
    CGFloat left = page_origin.x + ml;
    CGFloat right = page_origin.x + page_size.width - mr;

    if (info.is_scaled)
    {
        CGFloat const k = info.scale_factor;
        PSscale( k, k );
        bottom /= k;
        top /= k;
        left /= k;
        right /= k;
    }

    if (img.page_header != 0)
    {
        [self drawImage:img.page_header at:NSMakePoint(top, left)];
        top -= pages->page_header_height;
    }

    if (img.page_footer != 0)
    {
        bottom += pages->page_footer_height;
        [self drawImage:img.page_footer at:NSMakePoint(left, bottom)];
    }

    float dx = 0;
    float dy = 0;

    if ([printInfo isHorizontallyCentered])
    {
        int const c = (n % info.num_print_cols);
        dx = right - left - pages->row_titles_width
        - pages->col_breaks[c].size;
        if (dx > 0)
            dx /= 2;
        else
            dx = 0;
    }

    if ([printInfo isVerticallyCentered])
    {
        NSInteger const r = (n / info.num_print_cols);
        dy = top - bottom - pages->col_titles_height
        - pages->row_breaks[r].size;
        if (dy > 0)
            dy /= 2;
        else
            dy = 0;
    }

    if (img.corner_view != 0)
    {
        NSPoint pt;
        pt.x = left + dx;
        pt.y = top - dy;
        [self drawImage:img.corner_view at:pt];
    }

    if (img.row_titles != 0)
    {
        NSPoint pt;
        pt.x = left + dx;
        pt.y = top - pages->col_titles_height - dy;
        [self drawImage:img.row_titles at:pt];
    }

    if (img.col_titles != 0)
    {
        NSPoint pt;
        pt.x = left + pages->row_titles_width + dx;
        pt.y = top - dy;
        [self drawImage:img.col_titles at:pt];
    }
}

@end
