//=============================================================================
//
//	Copyright (C) 1995-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableCell.M
//
//	Default cell class used by MiscTableScroll to display text.
//
// NOTE *OPENSTEP-4.x*
//	OPENSTEP 4.x converts NSImageCellType cells to NSTextCellType 
//	cells upon receipt of -setFont: which is not the behavior that we want
//	(nor expect since in previous NEXTSTEP versions -setFont: left the 
//	cell alone if it was not NX_TEXTCELL).
//
// NOTE *SET-OWNER-VALUE*
//	We must implement these methods so that MiscTableScroll will call 
//	these methods instead of the explicit instance -setXxx methods.  
//	However, we don't need to do any work.  We will ask the owner for 
//	it's value whenever we need it.  
//
// FIXME: optional-allocation stuff does not address alignment requirements.
// FIXME: automate most of the optional-allocation stuff.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableCell.M,v 1.22 99/06/15 02:44:46 sunshine Exp $
// $Log:	MiscTableCell.M,v $
// Revision 1.22  99/06/15  02:44:46  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Now uses NSColor's system-colors rather than hard-coded gray, black, white.
// 
// Revision 1.21  97/06/22  10:20:57  sunshine
// v127.1: Now scrollable by default; making setup for editable slots simpler.
// Fixed bug: Was making allocation from wrong zone in -copyWithZone:. 
// 
// Revision 1.20  97/06/18  10:24:02  sunshine
// v125.9: Color-related methods changed name: "highlight" --> "selected".
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableCell.h>
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscTableView.h"
#import "MiscTableScrollPrivate.h"
extern "C" {
#import <AppKit/NSApplication.h> // NSEventTrackingRunLoopMode
#import <AppKit/NSFont.h>
#import <AppKit/NSImage.h>
#import <AppKit/NSPasteboard.h>
}
#include <cmath> // floor()
#include <cstring>

#define	MISC_TC_VERSION_0	0	// Conditional tag.
#define	MISC_TC_VERSION_1	1	// Tag became unconditional.
#define	MISC_TC_VERSION_1000	1000	// First OpenStep version (4.0 PR2).
#define	MISC_TC_VERSION		MISC_TC_VERSION_1000


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableCell

//-----------------------------------------------------------------------------
// + initialize
//-----------------------------------------------------------------------------
+ (void)initialize
    {
    if (self == [MiscTableCell class])
	{
	[self setVersion:MISC_TC_VERSION];
	}
    }


//-----------------------------------------------------------------------------
// + defaultFont
//-----------------------------------------------------------------------------
+ (NSFont*)defaultFont
    {
    return [NSFont userFontOfSize:12.0];
    }


//-----------------------------------------------------------------------------
// initTextCell:
//	NOTE *1*  -[NSCell initTextCell:] invokes -setStringValue: which
//	invokes -setFont:.  This means that this cell will get an explicit
//	-setFont call before we finish initialization, and we need to 
//	restore the useOwnerFont setting.
//-----------------------------------------------------------------------------
- (id)initTextCell:(NSString*)s
    {
    [super initTextCell:s];				// NOTE *1*
    [self setBordered:NO];
    [self setWraps:NO];
    [self setAlignment:NSLeftTextAlignment];
    [self setScrollable:YES];
    [self setUseOwnerFont:YES];				// NOTE *1*
    [self setOwnerFont:[[self class] defaultFont]];
    return self;
    }


//-----------------------------------------------------------------------------
// initImageCell:
//-----------------------------------------------------------------------------
- (id)initImageCell:(NSImage*)s
    {
    [super initImageCell:s];
    [self setBordered:NO];
    return self;
    }


//-----------------------------------------------------------------------------
// isOpaque
//-----------------------------------------------------------------------------
- (BOOL)isOpaque
    {
    return !([self isSelected] ? [self useOwnerSelectedBackgroundColor] :
				 [self useOwnerBackgroundColor]);
    }


//-----------------------------------------------------------------------------
// setSelected:
//-----------------------------------------------------------------------------
- (void)setSelected:(BOOL)flag
    {
    if (flag)
	tc1_flags |= MISC_TC1_IS_SELECTED;
    else
	tc1_flags &= ~MISC_TC1_IS_SELECTED;
    }


//-----------------------------------------------------------------------------
// isSelected
//-----------------------------------------------------------------------------
- (BOOL)isSelected
    {
    return ((tc1_flags & MISC_TC1_IS_SELECTED) != 0);
    }


//-----------------------------------------------------------------------------
// tag
//-----------------------------------------------------------------------------
- (int)tag
    {
    return tag;
    }


//-----------------------------------------------------------------------------
// setTag:
//-----------------------------------------------------------------------------
- (void)setTag:(int)x
    {
    tag = x;
    }


//-----------------------------------------------------------------------------
// owner
//-----------------------------------------------------------------------------
- (id)owner
    {
    return owner;
    }


//-----------------------------------------------------------------------------
// setOwner:
//-----------------------------------------------------------------------------
- (void)setOwner:(id)obj
    {
    if (obj != owner)
	{
	owner = obj;
	if (owner != 0)
	    {
	    if ([owner respondsToSelector:@selector(font)])
		[self setOwnerFont:[owner font]];
	    }
	} 
    }


//-----------------------------------------------------------------------------
// font
//-----------------------------------------------------------------------------
- (NSFont*)font
    {
    return [super font];
    }


//-----------------------------------------------------------------------------
// setFont:
//-----------------------------------------------------------------------------
- (void)setFont:(NSFont*)fontObj
    {
    if ([self type] == NSTextCellType)		// NOTE *OPENSTEP-4.x*
	{
	[self setUseOwnerFont:NO];
	[super setFont:fontObj];
	}
    }


//-----------------------------------------------------------------------------
// tc1Data
//-----------------------------------------------------------------------------
- (void*)tc1Data
    {
    return tc1_data;
    }


//=============================================================================
// TC1 MANIPULATION
//=============================================================================
//-----------------------------------------------------------------------------
// tc1Flags
//-----------------------------------------------------------------------------
- (unsigned int)tc1Flags
    {
    return tc1_flags;
    }


//-----------------------------------------------------------------------------
// tc1DataSize
//-----------------------------------------------------------------------------
- (unsigned int)tc1DataSize
    {
    unsigned int size = 0;
    if (tc1_flags & MISC_TC1_SELF_TEXT_COLOR)
	size += [self tc1TextColorLen];
    if (tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR)
	size += [self tc1BackgroundColorLen];
    if (tc1_flags & MISC_TC1_SELF_TEXT_COLOR_H)
	size += [self tc1SelectedTextColorLen];
    if (tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR_H)
	size += [self tc1SelectedBackgroundColorLen];
    return size;
    }


//-----------------------------------------------------------------------------
// tc1TextColorPos
//-----------------------------------------------------------------------------
- (unsigned int)tc1TextColorPos
    {
    return 0;
    }


//-----------------------------------------------------------------------------
// tc1BackgroundColorPos
//-----------------------------------------------------------------------------
- (unsigned int)tc1BackgroundColorPos
    {
    unsigned int pos = [self tc1TextColorPos];
    if (tc1_flags & MISC_TC1_SELF_TEXT_COLOR)
	pos += [self tc1TextColorLen];
    return pos;
    }


//-----------------------------------------------------------------------------
// tc1SelectedTextColorPos
//-----------------------------------------------------------------------------
- (unsigned int)tc1SelectedTextColorPos
    {
    unsigned int pos = [self tc1BackgroundColorPos];
    if (tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR)
	pos += [self tc1BackgroundColorLen];
    return pos;
    }


//-----------------------------------------------------------------------------
// tc1SelectedBackgroundColorPos
//-----------------------------------------------------------------------------
- (unsigned int)tc1SelectedBackgroundColorPos
    {
    unsigned int pos = [self tc1SelectedTextColorPos];
    if (tc1_flags & MISC_TC1_SELF_TEXT_COLOR_H)
	pos += [self tc1SelectedTextColorLen];
    return pos;
    }


//-----------------------------------------------------------------------------
// tc1TextColorLen
//-----------------------------------------------------------------------------
- (unsigned int)tc1TextColorLen
    {
    return sizeof(NSColor*);
    }


//-----------------------------------------------------------------------------
// tc1BackgroundColorLen
//-----------------------------------------------------------------------------
- (unsigned int)tc1BackgroundColorLen
    {
    return sizeof(NSColor*);
    }


//-----------------------------------------------------------------------------
// tc1SelectedTextColorLen
//-----------------------------------------------------------------------------
- (unsigned int)tc1SelectedTextColorLen
    {
    return sizeof(NSColor*);
    }


//-----------------------------------------------------------------------------
// tc1SelectedBackgroundColorLen
//-----------------------------------------------------------------------------
- (unsigned int)tc1SelectedBackgroundColorLen
    {
    return sizeof(NSColor*);
    }


//-----------------------------------------------------------------------------
// tc1TextColorPtr
//-----------------------------------------------------------------------------
- (NSColor**)tc1TextColorPtr
    {
    return (NSColor**)((char*)tc1_data + [self tc1TextColorPos]);
    }


//-----------------------------------------------------------------------------
// tc1BackgroundColorPtr
//-----------------------------------------------------------------------------
- (NSColor**)tc1BackgroundColorPtr
    {
    return (NSColor**)((char*)tc1_data + [self tc1BackgroundColorPos]);
    }


//-----------------------------------------------------------------------------
// tc1SelectedTextColorPtr
//-----------------------------------------------------------------------------
- (NSColor**)tc1SelectedTextColorPtr
    {
    return (NSColor**)((char*)tc1_data + [self tc1SelectedTextColorPos]);
    }


//-----------------------------------------------------------------------------
// tc1SelectedBackgroundColorPtr
//-----------------------------------------------------------------------------
- (NSColor**)tc1SelectedBackgroundColorPtr
    {
    return (NSColor**)((char*)tc1_data + [self tc1SelectedBackgroundColorPos]);
    }


//-----------------------------------------------------------------------------
// tc1InsertData:len:pos:
//-----------------------------------------------------------------------------
- (void*)tc1InsertData:(void const*)data
	pos:(unsigned int)pos
	len:(unsigned int)len
    {
    if (len > 0)
	{
	unsigned int const old_size = [self tc1DataSize];
	unsigned int const new_size = old_size + len;
	if (old_size == 0)
	    tc1_data = NSZoneMalloc( [self zone], new_size );
	else
	    {
	    tc1_data = NSZoneRealloc( [self zone], tc1_data, new_size );
	    if (pos < old_size)
		memmove( (char*) tc1_data + pos + len,		// Destination
			(char*) tc1_data + pos,			// Source
			old_size - pos );			// # bytes.
	    }
	if (data != 0)
	    memcpy( (char*) tc1_data + pos, data, len );
	else
	    memset( (char*) tc1_data + pos, 0, len );
	return (void*)((char*) tc1_data + pos );
	}
    return 0;
    }


//-----------------------------------------------------------------------------
// tc1DeleteDataPos:len:
//-----------------------------------------------------------------------------
- (void)tc1DeleteDataPos:(unsigned int)pos len:(unsigned int)len
    {
    if (len > 0)
	{
	unsigned int const old_size = [self tc1DataSize];
	unsigned int const new_size = old_size - len;
	if (new_size == 0)
	    {
	    NSZoneFree( [self zone], tc1_data );
	    tc1_data = 0;
	    }
	else
	    {
	    if (pos < new_size)
		memmove( (char*) tc1_data + pos,		// Destination
			(char*) tc1_data + pos + len,		// Source
			new_size - pos );			// # bytes
	    tc1_data = NSZoneRealloc( [self zone], tc1_data, new_size );
	    }
	}
    }


//=============================================================================
// *OWNER* CONTROLS
//=============================================================================
//-----------------------------------------------------------------------------
// useOwnerFont
//-----------------------------------------------------------------------------
- (BOOL)useOwnerFont
    {
    return ((tc1_flags & MISC_TC1_SELF_FONT) == 0);
    }


//-----------------------------------------------------------------------------
// useOwnerTextColor
//-----------------------------------------------------------------------------
- (BOOL)useOwnerTextColor
    {
    return ((tc1_flags & MISC_TC1_SELF_TEXT_COLOR) == 0);
    }


//-----------------------------------------------------------------------------
// useOwnerBackgroundColor
//-----------------------------------------------------------------------------
- (BOOL)useOwnerBackgroundColor
    {
    return ((tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR) == 0);
    }


//-----------------------------------------------------------------------------
// useOwnerSelectedTextColor
//-----------------------------------------------------------------------------
- (BOOL)useOwnerSelectedTextColor
    {
    return ((tc1_flags & MISC_TC1_SELF_TEXT_COLOR_H) == 0);
    }


//-----------------------------------------------------------------------------
// useOwnerSelectedBackgroundColor
//-----------------------------------------------------------------------------
- (BOOL)useOwnerSelectedBackgroundColor
    {
    return ((tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR_H) == 0);
    }


//-----------------------------------------------------------------------------
// setUseOwnerFont:
//-----------------------------------------------------------------------------
- (void)setUseOwnerFont:(BOOL)flag
    {
    if ([self useOwnerFont] != flag)
	{
	if (flag)
	    {
	    tc1_flags &= ~(MISC_TC1_SELF_FONT);
	    if (owner != 0 && [owner respondsToSelector:@selector(font)])
		[self setOwnerFont:[owner font]];
	    }
	else // (!flag)
	    {
	    tc1_flags |= MISC_TC1_SELF_FONT;
	    }
	} 
    }


//-----------------------------------------------------------------------------
// setUseOwnerTextColor:
//-----------------------------------------------------------------------------
- (void)setUseOwnerTextColor:(BOOL)flag
    {
    if ([self useOwnerTextColor] != flag)
	{
	unsigned int const pos = [self tc1TextColorPos];
	unsigned int const len = [self tc1TextColorLen];
	if (flag)
	    {
	    [[self textColor] release];
	    [self tc1DeleteDataPos:pos len:len];
	    tc1_flags &= ~(MISC_TC1_SELF_TEXT_COLOR);
	    }
	else // (!flag)
	    {
	    NSColor* color = [[[self class] defaultTextColor] retain];
	    [self tc1InsertData:&color pos:pos len:len];
	    tc1_flags |= MISC_TC1_SELF_TEXT_COLOR;
	    }
	} 
    }


//-----------------------------------------------------------------------------
// setUseOwnerBackgroundColor:
//-----------------------------------------------------------------------------
- (void)setUseOwnerBackgroundColor:(BOOL)flag
    {
    if ([self useOwnerBackgroundColor] != flag)
	{
	unsigned int const pos = [self tc1BackgroundColorPos];
	unsigned int const len = [self tc1BackgroundColorLen];
	if (flag)
	    {
	    [[self backgroundColor] release];
	    [self tc1DeleteDataPos:pos len:len];
	    tc1_flags &= ~(MISC_TC1_SELF_BACKGROUND_COLOR);
	    }
	else // (!flag)
	    {
	    NSColor* color = [[[self class] defaultBackgroundColor] retain];
	    [self tc1InsertData:&color pos:pos len:len];
	    tc1_flags |= MISC_TC1_SELF_BACKGROUND_COLOR;
	    }
	} 
    }


//-----------------------------------------------------------------------------
// setUseOwnerSelectedTextColor:
//-----------------------------------------------------------------------------
- (void)setUseOwnerSelectedTextColor:(BOOL)flag
    {
    if ([self useOwnerSelectedTextColor] != flag)
	{
	unsigned int const pos = [self tc1SelectedTextColorPos];
	unsigned int const len = [self tc1SelectedTextColorLen];
	if (flag)
	    {
	    [[self selectedTextColor] release];
	    [self tc1DeleteDataPos:pos len:len];
	    tc1_flags &= ~(MISC_TC1_SELF_TEXT_COLOR_H);
	    }
	else // (!flag)
	    {
	    NSColor* color = [[[self class] defaultSelectedTextColor] retain];
	    [self tc1InsertData:&color pos:pos len:len];
	    tc1_flags |= MISC_TC1_SELF_TEXT_COLOR_H;
	    }
	} 
    }


//-----------------------------------------------------------------------------
// setUseOwnerSelectedBackgroundColor:
//-----------------------------------------------------------------------------
- (void)setUseOwnerSelectedBackgroundColor:(BOOL)flag
    {
    if ([self useOwnerSelectedBackgroundColor] != flag)
	{
	unsigned int const pos = [self tc1SelectedBackgroundColorPos];
	unsigned int const len = [self tc1SelectedBackgroundColorLen];
	if (flag)
	    {
	    [[self selectedBackgroundColor] release];
	    [self tc1DeleteDataPos:pos len:len];
	    tc1_flags &= ~(MISC_TC1_SELF_BACKGROUND_COLOR_H);
	    }
	else // (!flag)
	    {
	    NSColor* color =
		[[[self class] defaultSelectedBackgroundColor] retain];
	    [self tc1InsertData:&color pos:pos len:len];
	    tc1_flags |= MISC_TC1_SELF_BACKGROUND_COLOR_H;
	    }
	} 
    }


//-----------------------------------------------------------------------------
// setOwnerFont:
//-----------------------------------------------------------------------------
- (void)setOwnerFont:(NSFont*)fontObj
    {
    if ([self type] == NSTextCellType)		// NOTE *OPENSTEP-4.x*
	if ([self useOwnerFont])
	    [super setFont:fontObj]; 
    }


//-----------------------------------------------------------------------------
// setOwner values...	NOTE *SET-OWNER-VALUE*
//-----------------------------------------------------------------------------
- (void)setOwnerTextColor:(NSColor*)pcolor {}
- (void)setOwnerBackgroundColor:(NSColor*)pcolor {}
- (void)setOwnerSelectedTextColor:(NSColor*)pcolor {}
- (void)setOwnerSelectedBackgroundColor:(NSColor*)pcolor {}


//=============================================================================
// COLOR MANIPULATION
//=============================================================================
//-----------------------------------------------------------------------------
// +defaultBackgroundColor
//-----------------------------------------------------------------------------
+ (NSColor*)defaultBackgroundColor
    {
    return [NSColor controlBackgroundColor];
    }


//-----------------------------------------------------------------------------
// backgroundColor
//-----------------------------------------------------------------------------
- (NSColor*)backgroundColor
    {
    if ([self useOwnerBackgroundColor])
	{
	if (owner != 0 &&
	    [owner respondsToSelector:@selector(backgroundColor)])
	    return [owner backgroundColor];
	return [[self class] defaultBackgroundColor];
	}
    return *[self tc1BackgroundColorPtr];
    }


//-----------------------------------------------------------------------------
// setBackgroundColor
//-----------------------------------------------------------------------------
- (void)setBackgroundColor:(NSColor*)c
    {
    NSColor** p;
    [self setUseOwnerBackgroundColor:NO];
    p = [self tc1BackgroundColorPtr];
    [*p autorelease];
    *p = [c retain];
    }


//-----------------------------------------------------------------------------
// +defaultSelectedBackgroundColor
//-----------------------------------------------------------------------------
+ (NSColor*)defaultSelectedBackgroundColor
    {
    return [NSColor selectedControlColor];
    }


//-----------------------------------------------------------------------------
// selectedBackgroundColor
//-----------------------------------------------------------------------------
- (NSColor*)selectedBackgroundColor
    {
    if ([self useOwnerSelectedBackgroundColor])
	{
	if (owner &&
	    [owner respondsToSelector:@selector(selectedBackgroundColor)])
	    return [owner selectedBackgroundColor];
	return [[self class] defaultSelectedBackgroundColor];
	}
    return *[self tc1SelectedBackgroundColorPtr];
    }


//-----------------------------------------------------------------------------
// setSelectedBackgroundColor
//-----------------------------------------------------------------------------
- (void)setSelectedBackgroundColor:(NSColor*)c
    {
    NSColor** p;
    [self setUseOwnerSelectedBackgroundColor:NO];
    p = [self tc1SelectedBackgroundColorPtr];
    [*p autorelease];
    *p = [c retain]; 
    }


//-----------------------------------------------------------------------------
// +defaultTextColor
//-----------------------------------------------------------------------------
+ (NSColor*)defaultTextColor
    {
    return [NSColor controlTextColor];
    }


//-----------------------------------------------------------------------------
// textColor
//-----------------------------------------------------------------------------
- (NSColor*)textColor
    {
    if ([self useOwnerTextColor])
	{
	if (owner != 0 && [owner respondsToSelector:@selector(textColor)])
	    return [owner textColor];
	return [[self class] defaultTextColor];
	}
    return *[self tc1TextColorPtr];
    }


//-----------------------------------------------------------------------------
// setTextColor
//-----------------------------------------------------------------------------
- (void)setTextColor:(NSColor*)c
    {
    NSColor** p;
    [self setUseOwnerTextColor:NO];
    p = [self tc1TextColorPtr];
    [*p autorelease];
    *p = [c retain];
    }


//-----------------------------------------------------------------------------
// +defaultSelectedTextColor
//-----------------------------------------------------------------------------
+ (NSColor*)defaultSelectedTextColor
    {
    return [NSColor selectedControlTextColor];
    }


//-----------------------------------------------------------------------------
// selectedTextColor
//-----------------------------------------------------------------------------
- (NSColor*)selectedTextColor
    {
    if ([self useOwnerSelectedTextColor])
	{
	if (owner != 0 &&
	    [owner respondsToSelector:@selector(selectedTextColor)])
	    return [owner selectedTextColor];
	return [[self class] defaultSelectedTextColor];
	}
    return *[self tc1SelectedTextColorPtr];
    }


//-----------------------------------------------------------------------------
// setSelectedTextColor
//-----------------------------------------------------------------------------
- (void)setSelectedTextColor:(NSColor*)c
    {
    NSColor** p;
    [self setUseOwnerSelectedTextColor:NO];
    p = [self tc1SelectedTextColorPtr];
    [*p autorelease];
    *p = [c retain]; 
    }


//=============================================================================
// DRAWING
//=============================================================================
//-----------------------------------------------------------------------------
// ownerDraw
//-----------------------------------------------------------------------------
- (BOOL)ownerDraw
    {
    return !(tc1_flags & MISC_TC1_SELF_DRAW);
    }


//-----------------------------------------------------------------------------
// setOwnerDraw:
//-----------------------------------------------------------------------------
- (void)setOwnerDraw:(BOOL)flag
    {
    if (flag)
	tc1_flags &= ~(MISC_TC1_SELF_DRAW);
    else // (!flag)
	tc1_flags |= MISC_TC1_SELF_DRAW;
    }


//-----------------------------------------------------------------------------
// bgColor
//-----------------------------------------------------------------------------
- (NSColor*)bgColor
    {
    return [self isSelected] ?
		[self selectedBackgroundColor] : [self backgroundColor];
    }


//-----------------------------------------------------------------------------
// fgColor
//-----------------------------------------------------------------------------
- (NSColor*)fgColor
    {
    return [self isSelected] ? [self selectedTextColor] : [self textColor];
    }


//-----------------------------------------------------------------------------
// setUpFieldEditorAttributes:
//-----------------------------------------------------------------------------
- (NSText*)setUpFieldEditorAttributes:(NSText*)textObject
    {
    [super setUpFieldEditorAttributes:textObject];
    [textObject setTextColor:[self fgColor]];
    [textObject setBackgroundColor:[self bgColor]];
    return textObject;
    }


//-----------------------------------------------------------------------------
// drawInteriorWithFrame:inView:
//
// NOTE *1*: Our superclass (NSCell) swaps white with gray when highlighted.
//	Since we supply our own highlight colors, we need to subvert NSCell's
//	normal behavior in order to prevent it from munging our colors.
//-----------------------------------------------------------------------------
- (void)drawInteriorWithFrame:(NSRect)rect inView:(NSView*)controlView
    {
    if ([self isOpaque])
	{
	[[self bgColor] set];
	NSRectFill( rect );
	}

    BOOL const wasHighlighted = [self isHighlighted];		// NOTE *1*
    [self setCellAttribute:NSCellHighlighted to:0];

    [super drawInteriorWithFrame:rect inView:controlView];

    [self setCellAttribute:NSCellHighlighted to:wasHighlighted];// NOTE *1*
    }


//-----------------------------------------------------------------------------
// drawWithFrame:inView:
//-----------------------------------------------------------------------------
- (void)drawWithFrame:(NSRect)rect inView:(NSView*)aView
    {
    [self drawInteriorWithFrame:rect inView:aView];
    }


//-----------------------------------------------------------------------------
// highlight:withFrame:inView:
//
//	No need to do any actual drawing since this class does not display
//	itself differently when highlighted.
//-----------------------------------------------------------------------------
- (void)highlight:(BOOL)flag withFrame:(NSRect)rect inView:(NSView *)aView
    {
    if (flag != [self isHighlighted])
	[self setCellAttribute:NSCellHighlighted to:flag];
    }


//=============================================================================
// REVIVE / RETIRE
//=============================================================================
//-----------------------------------------------------------------------------
// tableScroll:reviveAtRow:column:
//
// NOTE *1*
//	This is a performance-critical method.  Therefore, the owner font
//	setting code has been completely in-lined here.  Furthermore, since
//	the owner's font may have changed after the cell was retired, we
//	latch the owner's current font unconditionally here.
//-----------------------------------------------------------------------------
- (id)tableScroll:(MiscTableScroll*)scroll
    reviveAtRow:(int)row column:(int)col
    {
    unsigned int const MASK =
		MISC_TC1_SELF_DRAW |
		MISC_TC1_SELF_TEXT_COLOR |
		MISC_TC1_SELF_BACKGROUND_COLOR |
		MISC_TC1_SELF_TEXT_COLOR_H |
		MISC_TC1_SELF_BACKGROUND_COLOR_H;

    owner = scroll;
    tc1_flags &= ~(MISC_TC1_SELF_FONT);
    [super setFont:[scroll font]];		// NOTE *1*

    if (tc1_flags & MASK)
	{
	if (tc1_flags & MISC_TC1_SELF_DRAW)
	    [self setOwnerDraw:YES];
	if (tc1_flags & MISC_TC1_SELF_TEXT_COLOR)
	    [self setUseOwnerTextColor:YES];
	if (tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR)
	    [self setUseOwnerBackgroundColor:YES];
	if (tc1_flags & MISC_TC1_SELF_TEXT_COLOR_H)
	    [self setUseOwnerSelectedTextColor:YES];
	if (tc1_flags & MISC_TC1_SELF_BACKGROUND_COLOR_H)
	    [self setUseOwnerSelectedBackgroundColor:YES];
	}
    return self;
    }


//-----------------------------------------------------------------------------
// tableScroll:retireAtRow:column:
//-----------------------------------------------------------------------------
- (id)tableScroll:(MiscTableScroll*)scroll
    retireAtRow:(int)row column:(int)col
    {
    if ([self type] == NSTextCellType)
	[self setStringValue:@""];
    return self;
    }


//=============================================================================
// ALLOCATION / DEALLOCATION
//=============================================================================
//-----------------------------------------------------------------------------
// tc1DestroyData
//-----------------------------------------------------------------------------
- (void)tc1DestroyData
    {
    if (![self useOwnerTextColor])
	[[self textColor] release];
    if (![self useOwnerBackgroundColor])
	[[self backgroundColor] release];
    if (![self useOwnerSelectedTextColor])
	[[self selectedTextColor] release];
    if (![self useOwnerSelectedBackgroundColor])
	[[self selectedBackgroundColor] release];

    tc1_flags = 0;
    }


//-----------------------------------------------------------------------------
// tc1FreeData
//-----------------------------------------------------------------------------
- (void)tc1FreeData
    {
    if (tc1_data != 0)
	{
	NSZoneFree( [self zone], tc1_data );
	tc1_data = 0;
	}
    }


//-----------------------------------------------------------------------------
// dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    [self tc1DestroyData];
    [self tc1FreeData];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// copyWithZone:
//-----------------------------------------------------------------------------
- (id)copyWithZone:(NSZone*)zone
    {
    MiscTableCell* clone = [super copyWithZone:zone];
    if (tc1_data != 0)
	{
	unsigned int const size = [self tc1DataSize];
	void* p = NSZoneMalloc( zone, size );
	memcpy( p, tc1_data, size );
	clone->tc1_data = p;

	if (![clone useOwnerTextColor])
	    *[clone tc1TextColorPtr] = [[self textColor] retain];
	if (![clone useOwnerBackgroundColor])
	    *[clone tc1BackgroundColorPtr] = [[self backgroundColor] retain];
	if (![clone useOwnerSelectedTextColor])
	    *[clone tc1SelectedTextColorPtr] =
			[[self selectedTextColor] retain];
	if (![clone useOwnerSelectedBackgroundColor])
	    *[clone tc1SelectedBackgroundColorPtr] =
			[[self selectedBackgroundColor] retain];
	}
    return clone;
    }


//=============================================================================
// ARCHIVING
//=============================================================================
//-----------------------------------------------------------------------------
// initWithCoder_v0:
//-----------------------------------------------------------------------------
- (void)initWithCoder_v0:(NSCoder*)aDecoder
    {
    unsigned int x;

    owner = [[aDecoder decodeObject] retain];

    [aDecoder decodeValueOfObjCType:@encode(unsigned int) at:&x];
    if (x & MISC_TC1_HAS_TAG)
	[aDecoder decodeValueOfObjCType:@encode(int) at:&tag];
    else
	tag = 0;

    if (x & MISC_TC1_SELF_TEXT_COLOR)
	[self setTextColor:[aDecoder decodeNXColor]];
    if (x & MISC_TC1_SELF_BACKGROUND_COLOR)
	[self setBackgroundColor:[aDecoder decodeNXColor]];
    if (x & MISC_TC1_SELF_TEXT_COLOR_H)
	[self setSelectedTextColor:[aDecoder decodeNXColor]];
    if (x & MISC_TC1_SELF_BACKGROUND_COLOR_H)
	[self setSelectedBackgroundColor:[aDecoder decodeNXColor]];
    }


//-----------------------------------------------------------------------------
// initWithCoder_v1:
//-----------------------------------------------------------------------------
- (void)initWithCoder_v1:(NSCoder*)aDecoder
    {
    unsigned int x;

    owner = [[aDecoder decodeObject] retain];

    [aDecoder decodeValueOfObjCType:@encode(int) at:&tag];
    [aDecoder decodeValueOfObjCType:@encode(unsigned int) at:&x];

    if (x & MISC_TC1_SELF_TEXT_COLOR)
	[self setTextColor:[aDecoder decodeNXColor]];
    if (x & MISC_TC1_SELF_BACKGROUND_COLOR)
	[self setBackgroundColor:[aDecoder decodeNXColor]];
    if (x & MISC_TC1_SELF_TEXT_COLOR_H)
	[self setSelectedTextColor:[aDecoder decodeNXColor]];
    if (x & MISC_TC1_SELF_BACKGROUND_COLOR_H)
	[self setSelectedBackgroundColor:[aDecoder decodeNXColor]];
    }


//-----------------------------------------------------------------------------
// initWithCoder_v1000:
//-----------------------------------------------------------------------------
- (void)initWithCoder_v1000:(NSCoder*)aDecoder
    {
    unsigned int x;

    owner = [[aDecoder decodeObject] retain];

    [aDecoder decodeValueOfObjCType:@encode(int) at:&tag];
    [aDecoder decodeValueOfObjCType:@encode(unsigned int) at:&x];

    if (x & MISC_TC1_SELF_TEXT_COLOR)
	[self setTextColor:[aDecoder decodeObject]];
    if (x & MISC_TC1_SELF_BACKGROUND_COLOR)
	[self setBackgroundColor:[aDecoder decodeObject]];
    if (x & MISC_TC1_SELF_TEXT_COLOR_H)
	[self setSelectedTextColor:[aDecoder decodeObject]];
    if (x & MISC_TC1_SELF_BACKGROUND_COLOR_H)
	[self setSelectedBackgroundColor:[aDecoder decodeObject]];
    }


//-----------------------------------------------------------------------------
// initWithCoder:
//-----------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder*)aDecoder
    {
    [super initWithCoder:aDecoder];

    [self tc1DestroyData];
    [self tc1FreeData];

    unsigned int const ver =
	    [aDecoder versionForClassName:[[MiscTableCell class] description]];

    switch (ver)
	{
	case MISC_TC_VERSION_0:    [self initWithCoder_v0:   aDecoder]; break;
	case MISC_TC_VERSION_1:    [self initWithCoder_v1:   aDecoder]; break;
	case MISC_TC_VERSION_1000: [self initWithCoder_v1000:aDecoder]; break;
	default:
	    [NSException raise:NSGenericException
		    format:@"Cannot read: unknown version %d", ver];
	    break;
	}

    return self;
    }


//-----------------------------------------------------------------------------
// encodeWithCoder:
//-----------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder*)aCoder
    {
    [super encodeWithCoder:aCoder];
    [aCoder encodeConditionalObject:owner];
    [aCoder encodeValueOfObjCType:@encode(int) at:&tag];
    [aCoder encodeValueOfObjCType:@encode(unsigned int) at:&tc1_flags];
    if (![self useOwnerTextColor])
	[aCoder encodeObject:[self textColor]];
    if (![self useOwnerBackgroundColor])
	[aCoder encodeObject:[self backgroundColor]];
    if (![self useOwnerSelectedTextColor])
	[aCoder encodeObject:[self selectedTextColor]];
    if (![self useOwnerSelectedBackgroundColor])
	[aCoder encodeObject:[self selectedBackgroundColor]];
    }

@end
