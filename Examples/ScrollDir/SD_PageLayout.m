//=============================================================================
//
//	Copyright (C) 1996,1997,1999 by Paul S. McCarthy and Eric Sunshine.
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
// SD_PageLayout.m
//
//	Custom subclass of AppKit's NSPageLayout panel that adds user controls
//	for margins, pagination, & centering.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: SD_PageLayout.m,v 1.3 99/06/14 16:11:27 sunshine Exp $
// $Log:	SD_PageLayout.m,v $
// Revision 1.3  99/06/14  16:11:27  sunshine
// v35.1: Removed unused +launch:.  Fixed up comments.  No longer makes an
// effort to supply missing NSPageLayout methods on Windows.  Now the entire
// implementation of the class is conditionally compiled as appropriate,
// instead of piecemeal.
// 
// Revision 1.2  1997/04/15 22:20:11  sunshine
// 29.3: Ported to OPENSTEP 4.2 prerelease for Windows NT by working around
// incompatiblities between Mach and NT NSPageLayout implementations.
//-----------------------------------------------------------------------------
#import	"SD_PageLayout.h"

#import	<AppKit/NSApplication.h>
#import	<AppKit/NSButton.h>
#import	<AppKit/NSMatrix.h>
#import	<AppKit/NSPrintInfo.h>
#import	<AppKit/NSTextField.h>
#import	<Foundation/NSBundle.h>

@implementation SD_PageLayout

#if defined(SD_USE_PAGE_LAYOUT)

//-----------------------------------------------------------------------------
// loadAccessoryView
//-----------------------------------------------------------------------------
- (void)loadAccessoryView
    {
    NSView* v;
    [NSBundle loadNibNamed:@"SD_PageLayout" owner:self];
    v = [[[accessoryWindow contentView] retain] autorelease];

    [accessoryWindow setContentView:0];
    [accessoryWindow close];
    [accessoryWindow release];
    [self setAccessoryView:v];
    }


//-----------------------------------------------------------------------------
// pageLayout
//-----------------------------------------------------------------------------
+ (NSPageLayout*)pageLayout
    {
    static id p = 0;
    if (p == 0)
	{
	p = [[super pageLayout] retain];
	[p loadAccessoryView];
	}
    return p;
    }


//-----------------------------------------------------------------------------
// pickedUnits:
//-----------------------------------------------------------------------------
- (void)pickedUnits:(id)sender
    {
    float old_factor, new_factor, scaler;

    [self convertOldFactor:&old_factor newFactor:&new_factor];
    scaler = new_factor / old_factor;

    [leftMarginField   setFloatValue:[leftMarginField   floatValue] * scaler];
    [rightMarginField  setFloatValue:[rightMarginField  floatValue] * scaler];
    [topMarginField    setFloatValue:[topMarginField    floatValue] * scaler];
    [bottomMarginField setFloatValue:[bottomMarginField floatValue] * scaler];

    [super pickedUnits:sender];
    }


//-----------------------------------------------------------------------------
// pagination_to_slot
//-----------------------------------------------------------------------------
static int pagination_to_slot( int pg )
    {
    int slot = 1;
    if (pg == NSFitPagination)
	slot = 0;
    else if (pg == NSClipPagination)
	slot = 2;
    return slot;
    }


//-----------------------------------------------------------------------------
// slot_to_pagination
//-----------------------------------------------------------------------------
static int slot_to_pagination( int slot )
    {
    int pg = NSAutoPagination;
    if (slot == 0)
	pg = NSFitPagination;
    else if (slot == 2)
	pg = NSClipPagination;
    return pg;
    }


//-----------------------------------------------------------------------------
// readPrintInfo
//-----------------------------------------------------------------------------
- (void)readPrintInfo
    {
    NSPrintInfo* pinfo;
    int pg_row, pg_col;
    float old_factor, new_factor;
    [super readPrintInfo];
    pinfo = [self printInfo];

    [self convertOldFactor:&old_factor newFactor:&new_factor];

    [leftMarginField	setFloatValue:new_factor * [pinfo leftMargin  ]];
    [rightMarginField	setFloatValue:new_factor * [pinfo rightMargin ]];
    [topMarginField	setFloatValue:new_factor * [pinfo topMargin   ]];
    [bottomMarginField	setFloatValue:new_factor * [pinfo bottomMargin]];

    [centerMatrix selectCellAtRow:(int)[pinfo isVerticallyCentered]
			   column:(int)[pinfo isHorizontallyCentered]];

    pg_row = pagination_to_slot( [pinfo verticalPagination] );
    pg_col = pagination_to_slot( [pinfo horizontalPagination] );
    [paginationMatrix selectCellAtRow:pg_row column:pg_col];
    }


//-----------------------------------------------------------------------------
// writePrintInfo
//-----------------------------------------------------------------------------
- (void)writePrintInfo
    {
    NSPrintInfo* pinfo;
    float old_factor, new_factor;
    [super writePrintInfo];
    pinfo = [self printInfo];

    [self convertOldFactor:&old_factor newFactor:&new_factor];

    [pinfo setLeftMargin:  [leftMarginField   floatValue] / old_factor];
    [pinfo setRightMargin: [rightMarginField  floatValue] / old_factor];
    [pinfo setTopMargin:   [topMarginField    floatValue] / old_factor];
    [pinfo setBottomMargin:[bottomMarginField floatValue] / old_factor];

    [pinfo setVerticallyCentered:  [centerMatrix selectedRow   ]];
    [pinfo setHorizontallyCentered:[centerMatrix selectedColumn]];

    [pinfo setHorizontalPagination:
		slot_to_pagination([paginationMatrix selectedColumn])];
    [pinfo setVerticalPagination:
		slot_to_pagination([paginationMatrix selectedRow])];
    }

#endif // SD_USE_PAGE_LAYOUT

@end
