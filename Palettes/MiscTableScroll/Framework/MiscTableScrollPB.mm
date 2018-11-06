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
// MiscTableScrollPB.M
//
//	Pasteboard and services support for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollPB.M,v 1.10 99/06/15 03:33:07 sunshine Exp $
// $Log:	MiscTableScrollPB.M,v $
// Revision 1.10  99/06/15  03:33:07  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Renamed: stringForNSTabularPBoardType --> stringForNSTabularPboardType
// 
// Revision 1.9  1997/06/18 10:06:23  sunshine
// v125.9: Worked around Objective-C++ compiler crash in OPENSTEP 4.2 for NT
// when sending message to 'super' from within a category.
// numSelected{Rows|Cols} --> numberOfSelected{Rows|Cols}
//
//  Revision 1.8  97/04/15  09:08:59  sunshine
//  v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
//  framework organization.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscTableScrollPrivate.h"
#import <AppKit/NSApplication.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSPasteboard.h>

#define	MISC_PB_FIELD_SEPARATOR		@"\t"
#define	MISC_PB_RECORD_TERMINATOR	@"\n"

@implementation MiscTableScroll(Pasteboard)

//-----------------------------------------------------------------------------
// - sortSel:border:
//-----------------------------------------------------------------------------
- (NSArray*)sortSel:(NSArray*)sel_list border:(MiscBorderType)b
{
    return [self border:b visualToPhysical:
            [[self border:b physicalToVisual:sel_list]
             sortedArrayUsingSelector:@selector(compare:)]];
}


- (NSString *)stringForNSStringPboardType
{
	return [self stringForPboardType:NSPasteboardTypeString];
}

- (NSString *)stringForNSTabularTextPboardType
{
	return [self stringForPboardType:NSPasteboardTypeTabularText];
}


//-----------------------------------------------------------------------------
// - builtinRegisterServicesTypes
//
// FIXME: Deal with these also:
//	returnTypes[*] = NSRTFPboardType
//	returnTypes[*] = NSFontPboardType
//	returnTypes[*] = NSColorPboardType
//-----------------------------------------------------------------------------
- (void)builtinRegisterServicesTypes
{
    NSArray* sendTypes = [NSArray arrayWithObjects:
                          NSPasteboardTypeTabularText, NSPasteboardTypeString, nil];
    NSArray* returnTypes = [NSArray array];
    [NSApp registerServicesMenuSendTypes:sendTypes returnTypes:returnTypes];
}



//-----------------------------------------------------------------------------
// - registerServicesTypes
//-----------------------------------------------------------------------------
- (void)registerServicesTypes
{
    id del = [self responsibleDelegate:
                     MiscDelegateFlags::DEL_REGISTER_SERVICE_TYPES];
    if (del != 0)
        [del tableScrollRegisterServicesTypes:self];
    else
        [self builtinRegisterServicesTypes];
}



//-----------------------------------------------------------------------------
// - builtinValidRequestorForSendType:returnType:
//-----------------------------------------------------------------------------
- (id)builtinValidRequestorForSendType:(NSString*)t_send
                            returnType:(NSString*)t_return
{
    if (t_return == 0 &&	// We only send stuff, we never take stuff.
        ([t_send isEqualToString:NSPasteboardTypeTabularText] ||
         [t_send isEqualToString:NSPasteboardTypeString]) &&
        ([self hasRowSelection] || [self hasColumnSelection]))
        return self;

    return [super validRequestorForSendType:t_send returnType:t_return];
}


//-----------------------------------------------------------------------------
// - validRequestorForSendType:returnType:
//-----------------------------------------------------------------------------
- (id)validRequestorForSendType:(NSString*)t_send
                     returnType:(NSString*)t_return
{
    id del = [self responsibleDelegate:MiscDelegateFlags::DEL_VALID_REQUESTOR];
    if (del != 0)
        return [del tableScroll:self
      validRequestorForSendType:t_send returnType:t_return];

    return [self builtinValidRequestorForSendType:t_send returnType:t_return];
}


//-----------------------------------------------------------------------------
// - builtinReadSelectionFromPasteboard:
//-----------------------------------------------------------------------------
- (BOOL)builtinReadSelectionFromPasteboard:(NSPasteboard*)pboard
{
    return NO;
}


//-----------------------------------------------------------------------------
// - readSelectionFromPasteboard:
//-----------------------------------------------------------------------------
- (BOOL)readSelectionFromPasteboard:(NSPasteboard*)pb
{
    id del = [self responsibleDelegate:
                     MiscDelegateFlags::DEL_READ_SEL_FROM_PB];
    if (del != 0)
        return [del tableScroll:self readSelectionFromPasteboard:pb];

    return [self builtinReadSelectionFromPasteboard:pb];
}


//-----------------------------------------------------------------------------
// - builtinCanWritePboardType:
//-----------------------------------------------------------------------------
- (BOOL)builtinCanWritePboardType:(NSString*)type
{
    return ([type isEqualToString:NSPasteboardTypeString] ||
            [type isEqualToString:NSPasteboardTypeTabularText]);
}


//-----------------------------------------------------------------------------
// - canWritePboardType:
//-----------------------------------------------------------------------------
- (BOOL)canWritePboardType:(NSString*)type
{
    id del = [self responsibleDelegate:
                     MiscDelegateFlags::DEL_CAN_WRITE_PB_TYPE];
    if (del != 0)
        return [del tableScroll:self canWritePboardType:type];

    return [self builtinCanWritePboardType:type];
}


//-----------------------------------------------------------------------------
// - stringForNSPasteboardTypeStringAtRow:column:
//-----------------------------------------------------------------------------
- (NSString*)stringForNSPasteboardTypeStringAtRow:(int)row column:(int)col
{
    NSString* s = 0;
    id cell = [self cellAtRow:row column:col];
    
    if (cell != 0)
    {
        if ([cell respondsToSelector:@selector(title)])
            s = [cell title];
        else if ([cell respondsToSelector:@selector(stringValue)])
            s = [cell stringValue];
    }

    if (s == 0)
        s = @"";
    else
    {
        NSRange r = { 0, 0 };
        NSMutableString* ms = [[s mutableCopy] autorelease];
        for (;;)
        {
            r = [ms rangeOfString:MISC_PB_FIELD_SEPARATOR options:0
                            range:(NSRange){ r.location, [s length] - r.location }];
            if (r.length == 0)
                break;
            else
                [ms replaceCharactersInRange:r withString:@" "];
        }
        s = ms;
    }

    return s;
}


//-----------------------------------------------------------------------------
// - stringForNSPasteboardTypeString
//-----------------------------------------------------------------------------
- (NSString*)stringForNSPasteboardTypeString
{
    NSMutableString* s =
    [[[NSMutableString allocWithZone:[self zone]] init] autorelease];
    NSInteger i, i_lim;
    MiscCoord_V j, j_lim;
    MiscCoord_P row, col;

    if ([self numberOfSelectedRows] > 0)
    {
        NSArray* sel_list =
        [self sortSel:[self selectedRows] border:MISC_ROW_BORDER];
        i_lim = [sel_list count];
        j_lim = (MiscCoord_V) [self numberOfColumns];
        for (i = 0;  i < i_lim;  i++)
        {
            row = (MiscCoord_P) [[sel_list objectAtIndex:i] intValue];
            for (j = 0;  j < j_lim;  j++)
            {
                if (j > 0) [s appendString:MISC_PB_FIELD_SEPARATOR];
                col = [self columnAtPosition:j];
                [s appendString:
                 [self stringForNSPasteboardTypeStringAtRow:row column:col]];
            }
            [s appendString:MISC_PB_RECORD_TERMINATOR];
        }
    }
    else if ([self numberOfSelectedColumns] > 0)
    {
        NSArray* sel_list =
        [self sortSel:[self selectedColumns] border:MISC_COL_BORDER];
        i_lim = [sel_list count];
        j_lim = (MiscCoord_V) [self numberOfRows];
        for (j = 0;  j < j_lim;  j++)
        {
            row = [self rowAtPosition:j];
            for (i = 0;  i < i_lim;  i++)
            {
                if (i > 0) [s appendString:MISC_PB_FIELD_SEPARATOR];
                col = (MiscCoord_P) [[sel_list objectAtIndex:i] intValue];
                [s appendString:
                 [self stringForNSPasteboardTypeStringAtRow:row column:col]];
            }
            [s appendString:MISC_PB_RECORD_TERMINATOR];
        }
    }
    return s;
}


//-----------------------------------------------------------------------------
// - stringForNSPasteboardTypeTabularText
//-----------------------------------------------------------------------------
- (NSString*)stringForNSPasteboardTypeTabularText
{
    return [self stringForNSPasteboardTypeString];
}


//-----------------------------------------------------------------------------
// - builtinStringForPboardType:
//-----------------------------------------------------------------------------
- (NSString*)builtinStringForPboardType:(NSString*)type
{
    NSString* s = @"";
    if ([type isEqualToString:NSPasteboardTypeString])
        s = [self stringForNSPasteboardTypeString];
    else if ([type isEqualToString:NSPasteboardTypeTabularText])
        s = [self stringForNSPasteboardTypeTabularText];
    return s;
}


//-----------------------------------------------------------------------------
// - stringForPboardType:
//-----------------------------------------------------------------------------
- (NSString*)stringForPboardType:(NSString*)t
{
    id del = [self responsibleDelegate:
                     MiscDelegateFlags::DEL_STRING_FOR_PB_TYPE];
    if (del != 0)
        return [del tableScroll:self stringForPboardType:t];
    else
        return [self builtinStringForPboardType:t];
}


//-----------------------------------------------------------------------------
// - builtinWriteSelectionToPasteboard:types:
//-----------------------------------------------------------------------------
- (BOOL)builtinWriteSelectionToPasteboard:(NSPasteboard*)pboard
                                    types:(NSArray*)original_types
{
    BOOL result = NO;
    NSMutableArray* types = [NSMutableArray array];

    if (original_types != nil)
    {
        for (NSInteger i = 0, lim = [original_types count]; i < lim; i++)
        {
            id t = [original_types objectAtIndex:i];
            if ([self canWritePboardType:t])
                [types addObject:t];
        }
    }

    NSInteger const nTypes = [types count];
    if (nTypes > 0 && ([self hasRowSelection] || [self hasColumnSelection]))
    {
        [pboard declareTypes:types owner:nil];
        
        for (NSInteger i = 0;  i < nTypes;  i++)
        {
            NSString* s = [types objectAtIndex:i];
            [pboard setString:[self stringForPboardType:s] forType:s];
        }
        
        result = YES;
    }

    return result;
}


//-----------------------------------------------------------------------------
// - writeSelectionToPasteboard:types:
//-----------------------------------------------------------------------------
- (BOOL)writeSelectionToPasteboard:(NSPasteboard*)pboard types:(NSArray*)types
{
    id del = [self responsibleDelegate:
                     MiscDelegateFlags::DEL_WRITE_SEL_TO_PB_TYPES];
    if (del != 0)
        return [del tableScroll:self
     writeSelectionToPasteboard:pboard types:types];

    return [self builtinWriteSelectionToPasteboard:pboard types:types];
}


//-----------------------------------------------------------------------------
// - copy:
//-----------------------------------------------------------------------------
- (void)copy:(id)sender
{
    NSArray* types = [NSArray arrayWithObjects:
                      NSPasteboardTypeTabularText, NSPasteboardTypeString, nil];
    [self writeSelectionToPasteboard:[NSPasteboard generalPasteboard]
                               types:types];
}



//-----------------------------------------------------------------------------
// - cut:
//-----------------------------------------------------------------------------
- (void)cut:(id)sender
{
    [self copy:sender];
}

@end
