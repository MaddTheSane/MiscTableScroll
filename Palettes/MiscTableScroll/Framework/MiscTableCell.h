#ifndef __MiscTableCell_h
#define __MiscTableCell_h
//=============================================================================
//
//	Copyright (C) 1995-1997 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableCell.h
//
//	Default cell class used by MiscTableScroll to display text.
//
// NOTE:
//	By default, new cells are initialized to useOwner... everything.
//
//	Calling any of the -setFont:, -setTextColor:, -setBackgroundColor:
//	-setSelectedTextColor:, or -setSelectedBackgroundColor:
//	methods implicitly turns off the corresponding "useOwner" value.  In
//	the case of colors, this also causes space to be allocated to store
//	the corresponding color.
//
//	Calling any of the -setOwnerFont:, -setOwnerTextColor:, or 
//	-setOwnerBackgroundColor: methods do *NOT* set these values in the
//	owner, and do not necessarily make any changes in the object.  They
//	are primarily notification messages.  They give the cell the ability
//	to distinguish between cell-specific -setXxx messages and ones that
//	are propagated globally by the owner.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableCell.h,v 1.13 97/06/22 10:19:56 sunshine Exp $
// $Log:	MiscTableCell.h,v $
// Revision 1.13  97/06/22  10:19:56  sunshine
// v127.1: Applied v0.127 NEXTSTEP 3.3 diffs.
// 
// Revision 1.12  97/06/18  10:24:28  sunshine
// v125.9: Color-related methods changed name: "highlight" --> "selected".
// 
// Revision 1.11  97/04/15  09:02:17  sunshine
// v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
// framework organization.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableTypes.h>
MISC_TS_EXTERN_BEGIN( "Objective-C" )
#import <AppKit/NSCell.h>
MISC_TS_EXTERN_END
@class NSImage, NSPasteboard;
@class MiscTableScroll;

#define MISC_TC1_HAS_TAG			(1 << 0)	// Obsolete.
#define MISC_TC1_SELF_FONT			(1 << 1)
#define MISC_TC1_SELF_TEXT_COLOR		(1 << 2)
#define MISC_TC1_SELF_BACKGROUND_COLOR		(1 << 3)
#define MISC_TC1_SELF_TEXT_COLOR_H		(1 << 4)
#define MISC_TC1_SELF_BACKGROUND_COLOR_H	(1 << 5)
#define MISC_TC1_IS_SELECTED			(1 << 6)
#define MISC_TC1_SELF_DRAW			(1 << 7)	// !ownerDraw
#define	MISC_TC1_LAST_BIT			(1 << 7)

@interface MiscTableCell : NSCell <NSCopying,NSCoding>
    {
    id owner;
    int tag;
    unsigned int tc1_flags;
    void* tc1_data;
    }

- (id)initTextCell:(NSString*)s;
- (id)initImageCell:(NSImage*)s;
- (void)dealloc;
- (id)copyWithZone:(NSZone*)zone;
- (id)initWithCoder:(NSCoder*)coder;
- (void)encodeWithCoder:(NSCoder*)coder;

- (void)drawInteriorWithFrame:(NSRect)r inView:(NSView*)v;
- (void)drawWithFrame:(NSRect)r inView:(NSView*)v;
- (void)highlight:(BOOL)flag withFrame:(NSRect)r inView:(NSView*)v;
- (BOOL)isOpaque;

- (void)setSelected:(BOOL)flag;
- (BOOL)isSelected;

- (int)tag;
- (void)setTag:(int)tag;

- (id)owner;
- (void)setOwner:(id)obj;

- (NSFont*)font;
- (void)setFont:(NSFont*)obj;		// Turns off -useOwnerFont

- (NSColor*)textColor;
- (NSColor*)backgroundColor;
- (NSColor*)selectedBackgroundColor;
- (NSColor*)selectedTextColor;
- (void)setTextColor:(NSColor*)c;	// All -set..Color: turn off equivalent
- (void)setBackgroundColor:(NSColor*)c;	// -useOwner...Color flags.
- (void)setSelectedTextColor:(NSColor*)c;
- (void)setSelectedBackgroundColor:(NSColor*)c;

- (BOOL)ownerDraw;
- (BOOL)useOwnerFont;
- (BOOL)useOwnerTextColor;
- (BOOL)useOwnerBackgroundColor;
- (BOOL)useOwnerSelectedTextColor;
- (BOOL)useOwnerSelectedBackgroundColor;
- (void)setOwnerDraw:(BOOL)flag;
- (void)setUseOwnerFont:(BOOL)flag;
- (void)setUseOwnerTextColor:(BOOL)flag;
- (void)setUseOwnerBackgroundColor:(BOOL)flag;
- (void)setUseOwnerSelectedTextColor:(BOOL)flag;
- (void)setUseOwnerSelectedBackgroundColor:(BOOL)flag;

- (void)setOwnerFont:(NSFont*)obj;
- (void)setOwnerTextColor:(NSColor*)c;
- (void)setOwnerBackgroundColor:(NSColor*)c;
- (void)setOwnerSelectedTextColor:(NSColor*)c;
- (void)setOwnerSelectedBackgroundColor:(NSColor*)c;

- (void*)tc1Data;
- (unsigned int)tc1Flags;
- (unsigned int)tc1DataSize;
- (unsigned int)tc1TextColorPos;
- (unsigned int)tc1BackgroundColorPos;
- (unsigned int)tc1SelectedTextColorPos;
- (unsigned int)tc1SelectedBackgroundColorPos;
- (unsigned int)tc1TextColorLen;
- (unsigned int)tc1BackgroundColorLen;
- (unsigned int)tc1SelectedTextColorLen;
- (unsigned int)tc1SelectedBackgroundColorLen;
- (NSColor**)tc1TextColorPtr;
- (NSColor**)tc1BackgroundColorPtr;
- (NSColor**)tc1SelectedTextColorPtr;
- (NSColor**)tc1SelectedBackgroundColorPtr;
- (void*)tc1InsertData:(void const*)data
	pos:(unsigned int)pos len:(unsigned int)len;
- (void)tc1DeleteDataPos:(unsigned int)pos len:(unsigned int)len;
- (void)tc1DestroyData;
- (void)tc1FreeData;

- (NSColor*)fgColor;	// Returns appropriate color based upon -isSelected.
- (NSColor*)bgColor;	// Returns appropriate color based upon -isSelected.

+ (NSFont*)defaultFont;
+ (NSColor*)defaultTextColor;
+ (NSColor*)defaultBackgroundColor;
+ (NSColor*)defaultSelectedTextColor;
+ (NSColor*)defaultSelectedBackgroundColor;

- (id)tableScroll:(MiscTableScroll*)scroll
	reviveAtRow:(int)row column:(int)col;
- (id)tableScroll:(MiscTableScroll*)scroll
	retireAtRow:(int)row column:(int)col;

@end

#endif // __MiscTableCell_h
