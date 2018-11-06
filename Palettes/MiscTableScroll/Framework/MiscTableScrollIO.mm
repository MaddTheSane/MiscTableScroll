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
// MiscTableScrollIO.M
//
//	Input and Output (IO) methods for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollIO.M,v 1.4 99/08/20 06:05:58 sunshine Exp $
// $Log:	MiscTableScrollIO.M,v $
// Revision 1.4  99/08/20  06:05:58  sunshine
// 140.1: Now archives the represented-object only if it conforms to the
// NSCoding protocol.
// 
// Revision 1.3  99/06/15  03:29:33  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Instance variable renamed: drawClippedText --> drawsClippedText
// Now archives new "represented object".  Incremented class version number.
// 
// Revision 1.2  1998/03/29 23:56:48  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// Worked around OPENSTEP 4.2 for NT bug where compiler crashes when
// sending a message to 'super' from within a category.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import <MiscTableScroll/MiscTableCell.h>
#import "MiscCornerView.h"
#import "MiscDelegateFlags.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import "MiscTableView.h"
#import <AppKit/NSClipView.h>
#import <AppKit/NSColor.h>

@implementation MiscTableScroll(IO)

//-----------------------------------------------------------------------------
// - awakeFromNib
//-----------------------------------------------------------------------------
- (void)awakeFromNib
{
    delegateFlags->setDelegate( [self delegate] );
    dataDelegateFlags->setDelegate( [self dataDelegate] );
}


//-----------------------------------------------------------------------------
// - readString:isCString:
//-----------------------------------------------------------------------------
- (NSString*)readString:(NSCoder*)decoder isCString:(BOOL)isCString
{
    NSString* s = @"";
    if (!isCString)
        s = [decoder decodeObject];
    else
    {
        char* cstr = 0;
        [decoder decodeValueOfObjCType:@encode(char*) at:&cstr];
        if (cstr != 0)
        {
            s = @(cstr);
            NSZoneFree( [decoder objectZone], cstr );
        }
    }
    return s;
}


//-----------------------------------------------------------------------------
// - read:selector:
//-----------------------------------------------------------------------------
- (SEL)read:(int)ver selector:(NSCoder*)decoder
{
    SEL cmd = 0;
    BOOL const isCString = (ver < MISC_TS_VERSION_1000);
    NSString* s = [self readString:decoder isCString:isCString];
    if (![s isEqualToString:@""])
        cmd = NSSelectorFromString(s);
    return cmd;
}


//-----------------------------------------------------------------------------
// - read:cornerTitle:globalInfo:
//	NOTE: Cannot unarchive sort_entry_func and sort_slot_func because they 
//	are function addresses.  
//-----------------------------------------------------------------------------
- (NSString*)read:(int)ver cornerTitleAndGlobalInfo:(NSCoder*)decoder
{
    [decoder decodeValueOfObjCType:@encode(int) at:&tag];
    [decoder decodeValueOfObjCType:@encode(BOOL) at:&enabled];
    [decoder decodeValueOfObjCType:@encode(BOOL) at:&lazy];
    if (ver < MISC_TS_VERSION_2 || (ver >= MISC_TS_VERSION_1000 &&
                                    ver < MISC_TS_VERSION_1002))
        drawsClippedText = NO;
    else
        [decoder decodeValueOfObjCType:@encode(BOOL) at:&drawsClippedText];
    [decoder decodeValueOfObjCType:@encode(MiscSelectionMode) at:&mode];
    font = [[decoder decodeObject] retain];

    if (ver < MISC_TS_VERSION_1000)
    {
        textColor		= [[decoder decodeNXColor] retain];
        backgroundColor		= [[decoder decodeNXColor] retain];
        selectedTextColor	= [[decoder decodeNXColor] retain];
        selectedBackgroundColor	= [[decoder decodeNXColor] retain];
        id nextText		= [decoder decodeObject];
        id previousText		= [decoder decodeObject];
        [self setNextKeyView:nextText];
        [previousText setNextKeyView:self];
    }
    else
    {
        textColor		= [[decoder decodeObject] retain];
        backgroundColor		= [[decoder decodeObject] retain];
        selectedTextColor	= [[decoder decodeObject] retain];
        selectedBackgroundColor	= [[decoder decodeObject] retain];
    }

    delegate	= [decoder decodeObject];
    dataDelegate= [decoder decodeObject];
    target	= [decoder decodeObject];
    doubleTarget= [decoder decodeObject];
    action	= [self read:ver selector:decoder];
    doubleAction= [self read:ver selector:decoder];

    representedObject = (ver < MISC_TS_VERSION_1003) ? 0 :
    [[decoder decodeObject] retain];

    NSString* s = @"";
    if ((ver >= MISC_TS_VERSION_2 && ver < MISC_TS_VERSION_1000) ||
        ver >= MISC_TS_VERSION_1002)
        s = [self readString:decoder isCString:(ver < MISC_TS_VERSION_1000)];
    return s;
}


//-----------------------------------------------------------------------------
// - read:border:decoder:
//-----------------------------------------------------------------------------
- (void)read:(int)ver border:(MiscBorderInfo*)p decoder:(NSCoder*)decoder
{
    if (p->sort_vector != 0)
    {
        [p->sort_vector release];
        p->sort_vector = 0;
    }

    if (ver >= MISC_TS_VERSION_1001)
    {
        p->sort_vector = [[decoder decodeObject] retain];
    }
    else
    {
        int n;
        [decoder decodeValueOfObjCType:@encode(int) at:&n];
        if (n > 0)
        {
            NSMutableArray* a =
            [[NSMutableArray allocWithZone:[self zone]] init];
            for (int i = 0; i < n; i++)
            {
                int j;
                [decoder decodeValueOfObjCType:@encode(int) at:&j];
                [a addObject:[NSNumber numberWithInt:j]];
            }
            p->sort_vector = a;
        }
    }
    [decoder decodeValueOfObjCType:@encode(BOOL) at:&(p->isOn)];
    [decoder decodeValueOfObjCType:@encode(BOOL) at:&(p->autoSort)];
    if (ver < MISC_TS_VERSION_2 || (ver >= MISC_TS_VERSION_1000 &&
                                    ver < MISC_TS_VERSION_1002))
    {
        BOOL b;
        [decoder decodeValueOfObjCType:@encode(BOOL) at:&b];	// obsolete.
        [decoder decodeValueOfObjCType:@encode(BOOL) at:&b];
    }
    
    if (p->border == 0)
        p->border = new
        MiscTableBorder( MISC_ROW_BORDER );
    p->border->initWithCoder( decoder, ver );
}


//-----------------------------------------------------------------------------
// - read:cells:
// FIXME: What happens when a non-empty non-lazy TableScroll reads the data
// from a lazy, empty one.  Does the memory get freed?
//-----------------------------------------------------------------------------
- (void)read:(int)ver cells:(NSCoder*)decoder
{
    [decoder decodeValueOfObjCType:@encode(int) at:&num_cols];
    [decoder decodeValueOfObjCType:@encode(int) at:&num_rows];
    if (lazy)
    {
        max_rows = 0;		// No rows have been allocated.
        max_cells = 0;
        cells = 0;
    }
    else // (!lazy)
    {
        max_rows = num_rows;
        max_cells = max_rows * num_cols;
        if (max_cells == 0)
            cells = 0;
        else
        {
            int const nbytes = max_cells * sizeof(*cells);
            cells = (id*) NSZoneMalloc( [self zone], nbytes );
            id* p = cells;
            for (int r = 0; r < num_rows; r++)
                for (int c = 0; c < num_cols; c++)
                    *p++ = [[decoder decodeObject] retain];
        }
    }
}


//-----------------------------------------------------------------------------
// - initWithCoder:
//-----------------------------------------------------------------------------
- (id)initWithCoder:(NSCoder*)decoder
{
    self = [super initWithCoder:decoder];
    NSString* class_name = [[MiscTableScroll class] description];
    int const ver = [decoder versionForClassName:class_name];
    if (((unsigned int)ver) > ((unsigned int)MISC_TS_VERSION))
        [NSException raise:NSGenericException format:
         @"%@: old library (version %d), can't -read: new object (version %d)",
         class_name, MISC_TS_VERSION, ver ];
    NSString* s = [self read:ver cornerTitleAndGlobalInfo:decoder];
    [self read:ver border:&colInfo decoder:decoder];
    [self read:ver border:&rowInfo decoder:decoder];
    [self read:ver cells:decoder];
    [self doInit:ver cornerTitle:s];
    return self;
}


//-----------------------------------------------------------------------------
// - writeSelector:encoder:
//-----------------------------------------------------------------------------
- (void)writeSelector:(SEL)cmd encoder:(NSCoder*)encoder
{
    NSString* str = @"";
    if (cmd != 0)
        str = NSStringFromSelector( cmd );
    [encoder encodeObject:str];
}


//-----------------------------------------------------------------------------
// - writeGlobalInfo:
//	NOTE: Cannot archive sort_entry_func and sort_slot_func because they 
//	are function addresses.  
//-----------------------------------------------------------------------------
- (void)writeGlobalInfo:(NSCoder*)encoder
{
    [encoder encodeValueOfObjCType:@encode(int) at:&tag];
    [encoder encodeValueOfObjCType:@encode(BOOL) at:&enabled];
    [encoder encodeValueOfObjCType:@encode(BOOL) at:&lazy];
    [encoder encodeValueOfObjCType:@encode(BOOL) at:&drawsClippedText];
    [encoder encodeValueOfObjCType:@encode(MiscSelectionMode) at:&mode];
    [encoder encodeObject:font];
    [encoder encodeObject:textColor];
    [encoder encodeObject:backgroundColor];
    [encoder encodeObject:selectedTextColor];
    [encoder encodeObject:selectedBackgroundColor];
    [encoder encodeConditionalObject:delegate];
    [encoder encodeConditionalObject:dataDelegate];
    [encoder encodeConditionalObject:target];
    [encoder encodeConditionalObject:doubleTarget];
    [self writeSelector:action encoder:encoder];
    [self writeSelector:doubleAction encoder:encoder];
    [encoder encodeObject:(representedObject != 0 && [representedObject
                                                      conformsToProtocol:@protocol(NSCoding)] ? representedObject : 0)];
    [encoder encodeObject:[self cornerTitle]];
}


//-----------------------------------------------------------------------------
// - writeBorder:encoder:
//-----------------------------------------------------------------------------
- (void)writeBorder:(MiscBorderInfo*)p encoder:(NSCoder*)encoder
{
    [encoder encodeObject:p->sort_vector];
    [encoder encodeValueOfObjCType:@encode(BOOL) at:&(p->isOn)];
    [encoder encodeValueOfObjCType:@encode(BOOL) at:&(p->autoSort)];
    p->border->encodeWithCoder( encoder );
}


//-----------------------------------------------------------------------------
// - writeCells:
//-----------------------------------------------------------------------------
- (void)writeCells:(NSCoder*)encoder
{
    [encoder encodeValueOfObjCType:@encode(int) at:&num_cols];
    [encoder encodeValueOfObjCType:@encode(int) at:&num_rows];
    if (!lazy)
        for (int r = 0;	 r < num_rows;	r++)
            for (int c = 0;  c < num_cols;  c++)
                [encoder encodeObject:[self cellAtRow:r column:c]];
}


//-----------------------------------------------------------------------------
// - encodeWithCoder:
//-----------------------------------------------------------------------------
- (void)encodeWithCoder:(NSCoder*)encoder
{
    // Ensure that subviews are NOT archived.
    if (colInfo.isOn)	[colInfo.clip removeFromSuperview];
    if (rowInfo.isOn)	[rowInfo.clip removeFromSuperview];
    if (rowInfo.isOn && colInfo.isOn) [cornerView removeFromSuperview];
    [tableView removeFromSuperview];

    [super encodeWithCoder:encoder];
    [self writeGlobalInfo:encoder];
    [self writeBorder:&colInfo encoder:encoder];
    [self writeBorder:&rowInfo encoder:encoder];
    [self writeCells:encoder];

    // Restore state.
    [self setDocumentView:tableView];
    if (colInfo.isOn)	[self addSubview:colInfo.clip];
    if (rowInfo.isOn)	[self addSubview:rowInfo.clip];
    if (rowInfo.isOn && colInfo.isOn) [self addSubview:cornerView];
}

@end
