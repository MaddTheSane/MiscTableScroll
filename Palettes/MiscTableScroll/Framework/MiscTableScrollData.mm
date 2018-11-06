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
// MiscTableScrollData.M
//
//	The (DATA) category of MiscTableScroll.	 Implements the management
//	of the cells of the table.
//
// FIXME *SEL*
//	The current selection architecture is imposing undesirable overhead
//	on a *highly* used function, -cellAt::.  We need to come up with a
//	better way to handle this.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollData.M,v 1.24 99/06/15 03:23:10 sunshine Exp $
// $Log:	MiscTableScrollData.M,v $
// Revision 1.24  99/06/15  03:23:10  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Method renamed: tracking --> isTrackingMouse
// 
// Revision 1.23  1997/06/18 10:08:53  sunshine
// v125.9: Renamed methods containing: "buff" --> "buffer"
// Color-related methods "highlight" --> "selected".
//
//  Revision 1.22  97/04/15  09:07:40  sunshine
//  v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
//  framework organization.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import <MiscTableScroll/MiscTableCell.h>
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import <AppKit/NSCell.h>
#import <AppKit/NSImage.h>
extern "C" {
#import <limits.h>
}
#include <cstdlib>
#include <cstring>

#define	EAGER_CELL_AT(R,C)	(cells[ (R) * num_cols + (C) ])

@implementation MiscTableScroll(DATA)

//-----------------------------------------------------------------------------
// - lazyCellAtRow:column:
//-----------------------------------------------------------------------------
- (id)lazyCellAtRow:(int)row column:(int)col
{
    id del = [self responsibleDelegate:MiscDelegateFlags::DEL_CELL_AT];
    if (del != 0)
    {
        id c = [del tableScroll:self cellAtRow:row column:col];
        if (c != 0 && [c respondsToSelector:@selector(setCellAttribute:to:)])
            [c setCellAttribute:NSCellHighlighted to:([self isTrackingMouse] &&
                                                      row == [self clickedRow] && col == [self clickedColumn])];
        return c;
    }
    return 0;
}


//-----------------------------------------------------------------------------
// - eagerCellAtRow:column:
//-----------------------------------------------------------------------------
- (id)eagerCellAtRow:(int)row column:(int)col
{
    return EAGER_CELL_AT( row, col );
}


//-----------------------------------------------------------------------------
// - cellAtRow:column:
//-----------------------------------------------------------------------------
- (id)cellAtRow:(int)row column:(int)col
{
    id cell = 0;
    if ((unsigned int) row < (unsigned int) num_rows &&
        (unsigned int) col < (unsigned int) num_cols)
    {
        if (!lazy)
            cell = EAGER_CELL_AT( row, col );
        else
            cell = [self lazyCellAtRow:row column:col];
        
        if ([cell respondsToSelector:@selector(setSelected:)]) // FIXME: *SEL*
        {
            MiscCoord_V vr = rowInfo.border->physicalToVisual(row);
            MiscCoord_V vc = colInfo.border->physicalToVisual(col);
            [cell setSelected:colInfo.border->selectionSet().contains(vc) ||
             rowInfo.border->selectionSet().contains(vr)];
        }
    }
    return cell;
}


//-----------------------------------------------------------------------------
// tagAtRow:column:, intValueAtRow:column:, floatValueAtRow:column:,
// doubleValueAtRow:column:, stringValueAtRow:column:, titleAtRow:column:,
// stateAtRow:column:
//-----------------------------------------------------------------------------
#define MISC_CELL_VAL( DATA_TYPE, NAME, CMD )\
- (DATA_TYPE)NAME##AtRow:(int)r column:(int)c\
{\
id del = [self responsibleDelegate:MiscDelegateFlags::DEL_##CMD##_AT];\
if (del != 0)\
return [del tableScroll:self NAME##AtRow:r column:c];\
id cell = (!lazy ?	EAGER_CELL_AT(r,c) : [self lazyCellAtRow:r column:c]);\
if (cell != 0 && [cell respondsToSelector:@selector(NAME)])\
return [cell NAME];\
return 0;\
}

MISC_CELL_VAL( NSInteger, tag, TAG )				// tagAtRow:column:
MISC_CELL_VAL( int, intValue, INT_VALUE )		// intValueAtRow:col...
MISC_CELL_VAL( float, floatValue, FLOAT_VALUE )		// floatValueAtRow:c...
MISC_CELL_VAL( double, doubleValue, DOUBLE_VALUE )	// doubleValueAtRow:...
MISC_CELL_VAL( NSString*, stringValue, STRING_VALUE )	// stringValueAtRow:...
MISC_CELL_VAL( int, state, STATE )			// stateAtRow:column:
MISC_CELL_VAL( NSString*, title, TITLE )		// titleAtRow:column:
#undef MISC_CELL_VAL


//-----------------------------------------------------------------------------
// - bufferCount
//	For lazy-mode tables that perform multiple-buffering.  This can
//	avoid copying when accessing more than one cell at a time (such
//	as during sorting.)
//-----------------------------------------------------------------------------
- (int)bufferCount
{
    id del = [self responsibleDelegate:MiscDelegateFlags::DEL_BUFFER_COUNT];
    if (del != 0)
        return [del tableScrollBufferCount:self];
    return 1;
}


//-----------------------------------------------------------------------------
// - expandIfNeeded
//-----------------------------------------------------------------------------
- (void)expandIfNeeded
{
    int const num_cells = max_rows * num_cols;
    if (num_cells > max_cells)
    {
        NSZone* const z = [self zone];
        int const nbytes = num_cells * sizeof(*cells);
        if (max_cells == 0)
            cells = (id*) NSZoneMalloc( z, nbytes );
        else
            cells = (id*) NSZoneRealloc( z, cells, nbytes );
        max_cells = num_cells;
    }
}


//-----------------------------------------------------------------------------
// - extendMaxRows:
//-----------------------------------------------------------------------------
- (void)extendMaxRows:(int)new_max
{
    int const old_max = max_rows;
    max_rows = new_max;
    
    [self expandIfNeeded];
    NSZone* const z = [self zone];
    MiscTableBorder* const bp = colInfo.border;
    id* p = cells + old_max * num_cols;
    for (int r = old_max; r < new_max; r++)
        for (int c = 0; c < num_cols; c++)
            *p++ = [bp->getPrototype_P(c) copyWithZone:z];
}


//-----------------------------------------------------------------------------
// - lazyInsertColumn:
//-----------------------------------------------------------------------------
- (void)lazyInsertColumn:(int)n
{
    colInfo.border->insertAt(n,n);	// FIXME: Check this.
    num_cols++;
}


//-----------------------------------------------------------------------------
// - eagerInsertColumn:
//-----------------------------------------------------------------------------
- (void)eagerInsertColumn:(int)n
{
    NSParameterAssert( 0 <= n );  NSParameterAssert( n <= num_cols );
    NSParameterAssert( 0 < num_cols );	// lazyInsert must increment num_cols.
    
    if (max_rows > 0 || num_rows > 0)
    {
        if (max_rows == 0)
            max_rows = num_rows;
        [self expandIfNeeded];
        int const num_new = num_cols;
        int const num_old = num_cols - 1;
        if (num_old > 0)		// Shift old, existing cells.
        {
            int const frag = num_old - n; // #cols right of insert col.
            id* src = cells + (max_rows * num_old) - frag;
            id* dst = cells + (max_rows * num_new) - frag;
            if (frag > 0)		// Last partial row.
                memmove( dst, src, frag * sizeof(*dst) );
            
            int const nbytes = num_old * sizeof(*dst);
            src -= num_old;
            dst -= num_new;
            while (src > cells)		// All full rows.
            {
                memmove( dst, src, nbytes );
                src -= num_old;
                dst -= num_new;
            }
        }
        int row = 0;
        NSZone* const z = [self zone];
        id const proto = colInfo.border->getPrototype_P(n);
        id* const plim = cells + (max_rows * num_new);
        id* p = cells + n;
        while (p < plim)		// Initialize cells in new column.
        {
            *p = [self reviveCell:[proto copyWithZone:z] atRow:row++ column:n];
            p += num_new;
        }
    }
}


//-----------------------------------------------------------------------------
// - insertColumn:
//-----------------------------------------------------------------------------
- (void)insertColumn:(int)n
{
    if (0 <= n && n <= num_cols)
    {
        [self lazyInsertColumn:n];
        if (!lazy)
            [self eagerInsertColumn:n];
        [self constrainSize];
        [self resetSelection];
        [self setNeedsDisplay:YES];
    }
}


//-----------------------------------------------------------------------------
// - addColumn
//-----------------------------------------------------------------------------
- (void)addColumn
{
    [self insertColumn:num_cols];
}


//-----------------------------------------------------------------------------
// - lazyRemoveColumn:
//-----------------------------------------------------------------------------
- (void)lazyRemoveColumn:(int)n
{
    colInfo.border->deleteAt_P(n);
    num_cols--;
}


//-----------------------------------------------------------------------------
// - eagerRemoveColumn:
//-----------------------------------------------------------------------------
- (void)eagerRemoveColumn:(int)n
{
    NSParameterAssert( 0 < num_cols );
    NSParameterAssert( 0 <= n );  NSParameterAssert( n < num_cols );
    if (max_rows > 0)
    {
        int const num_old = num_cols;
        int const num_new = num_cols - 1;
        id* dst = cells + n;
        id* src = dst + 1;
        id* const dst_lim = cells + (num_old * max_rows);
        int row = 0;
        while (dst < dst_lim)		// Destroy deleted cells.
        {
            if (row < num_rows)
                [[self retireCell:*dst atRow:row++ column:n] release];
            else
                [*dst release];
            dst += num_old;
        }
        if (num_new > 0)		// Shift remaining columns.
        {
            dst = cells + n;
            int const nbytes = num_new * sizeof(*dst);
            id* const src_lim = cells + (max_rows - 1) * num_old + n;
            while (src < src_lim)
            {
                memmove( dst, src, nbytes );
                dst += num_new;
                src += num_old;
            }
            if (n < num_new)		// Shift last partial row.
                memmove( dst, src, (num_new - n) * sizeof(*dst) );
        }
        else // (num_new <= 0)
        {
            max_rows = 0;
        }
    }
}


//-----------------------------------------------------------------------------
// - removeColumn:
//-----------------------------------------------------------------------------
- (void)removeColumn:(int)n
{
    if (0 <= n && n < num_cols)
    {
        if (!lazy)
            [self eagerRemoveColumn:n];
        [self lazyRemoveColumn:n];
        [self constrainSize];
        [self resetSelection];
        [self setNeedsDisplay:YES];
    }
}


//-----------------------------------------------------------------------------
// - numberOfColumns
//-----------------------------------------------------------------------------
- (int)numberOfColumns
{
    return num_cols;
}


//-----------------------------------------------------------------------------
// - lazyInsertRow:
//-----------------------------------------------------------------------------
- (void)lazyInsertRow:(int)n
{
    rowInfo.border->insertAt(n,n);	// FIXME.  Check this.
    num_rows++;
}


//-----------------------------------------------------------------------------
// - eagerInsertRow:
//-----------------------------------------------------------------------------
- (void)eagerInsertRow:(int)n
{
    NSParameterAssert( 0 < num_rows );	// lazy-insert must increment num_rows
    NSParameterAssert( 0 <= n );  NSParameterAssert( n < num_rows );
    
    if (num_cols > 0)
    {
        max_rows++;				// Incremental growth.
        NSParameterAssert( num_rows <= max_rows );
        [self expandIfNeeded];
        
        int const old_max = max_rows - 1;
        id* p = cells + n * num_cols;
        if (n < old_max)			// Shift other rows.
        {
            id* src = p;
            id* dst = src + num_cols;
            memmove( dst, src, (old_max - n) * num_cols * sizeof(*dst) );
        }
        NSZone* const z = [self zone];
        MiscTableBorder* const bp = colInfo.border;
        for (int c = 0;	 c < num_cols;	c++)	// Initialize new cells.
            *p++ = [self reviveCell:[bp->getPrototype_P(c) copyWithZone:z]
                              atRow:n column:c];
    }
}


//-----------------------------------------------------------------------------
// - insertRow:
//-----------------------------------------------------------------------------
- (void)insertRow:(int)n
{
    if (0 <= n && n <= num_rows)
    {
        [self lazyInsertRow:n];
        if (!lazy)
            [self eagerInsertRow:n];
        [self constrainSize];
        [self resetSelection];
        [self setNeedsDisplay:YES];
    }
}


//-----------------------------------------------------------------------------
// - eagerAddRow
//-----------------------------------------------------------------------------
- (void)eagerAddRow
{
    // Lazy insertRow: must increment num_rows.
    NSParameterAssert( 0 < num_rows );
    if (num_cols > 0)
    {
        if (num_rows >= max_rows)
        {
            NSParameterAssert( num_rows < (INT_MAX >> 1) );
            int n = (max_rows != 0 ? max_rows : 16);
            while (n < num_rows)
                n <<= 1;
            [self extendMaxRows:n];
        }
        int const r = num_rows - 1;
        id* p = cells + (num_cols * r);
        for (int c = 0; c < num_cols; c++)
            *p++ = [self reviveCell:*p atRow:r column:c];
    }
}


//-----------------------------------------------------------------------------
// - addRow
//
// NOTE: We explicitly do NOT -constrainSize here, because we expect that the
// user will call this routine many times successively.  
//-----------------------------------------------------------------------------
- (void)addRow
{
    [self lazyInsertRow:num_rows];
    if (!lazy)
        [self eagerAddRow];
}


//-----------------------------------------------------------------------------
// - lazyRemoveRow:
//-----------------------------------------------------------------------------
- (void)lazyRemoveRow:(int)n
{
    rowInfo.border->deleteAt_P(n);
    num_rows--;
}


//-----------------------------------------------------------------------------
// - eagerRemoveRow:
//-----------------------------------------------------------------------------
- (void)eagerRemoveRow:(int)n
{
    NSParameterAssert( 0 < num_rows );
    NSParameterAssert( 0 <= n );  NSParameterAssert( n < num_rows );
    if (num_cols > 0)
    {
        NSParameterAssert( num_rows <= max_rows );
        max_rows--;
        id* const dst = cells + (n * num_cols );
        id* p = dst;
        id* const plim = p + num_cols;
        int col = 0;
        while (p < plim)	// Destroy the cells.
        {
            [[self retireCell:*p atRow:n column:col++] release];
            p++;
        }
        if (n < max_rows)
            memmove( dst, plim, (max_rows - n) * num_cols * sizeof(*dst) );
    }
}


//-----------------------------------------------------------------------------
// - removeRow:
//-----------------------------------------------------------------------------
- (void)removeRow:(int)n
{
    if (0 <= n && n < num_rows)
    {
        if (!lazy)
            [self eagerRemoveRow:n];
        [self lazyRemoveRow:n];
        [self constrainSize];
        [self resetSelection];
        [self setNeedsDisplay:YES];
    }
}


//-----------------------------------------------------------------------------
// - numberOfRows
//-----------------------------------------------------------------------------
- (int)numberOfRows
{
    return num_rows;
}


//-----------------------------------------------------------------------------
// - lazyRenewRows:
//-----------------------------------------------------------------------------
- (void)lazyRenewRows:(int)n
{
    rowInfo.border->setCount(n);
    num_rows = n;
}


//-----------------------------------------------------------------------------
// - eagerRenewRows:
//-----------------------------------------------------------------------------
- (void)eagerRenewRows:(int)n
{
    NSParameterAssert( 0 <= n );
    if (num_cols > 0)
    {
        int const old_num_rows = num_rows;
        int const new_num_rows = n;
        if (n > max_rows)
            [self extendMaxRows:n];
        if (old_num_rows < new_num_rows)		// Growing
        {
            id* p = cells + old_num_rows * num_cols;
            for (int r = old_num_rows; r < new_num_rows; r++)
                for (int c = 0; c < num_cols; c++)
                    *p++ = [self reviveCell:*p atRow:r column:c];
        }
        else if (old_num_rows > new_num_rows)		// Shrinking
        {
            id* p = cells + new_num_rows * num_cols;
            for (int r = new_num_rows; r < old_num_rows; r++)
                for (int c = 0; c < num_cols; c++)
                    *p++ = [self retireCell:*p atRow:r column:c];
        }
    }
}


//-----------------------------------------------------------------------------
// - renewRows:
//-----------------------------------------------------------------------------
- (void)renewRows:(int)n
{
    [self clearSelection];
    if (0 <= n && n != num_rows)
    {
        if (!lazy)
            [self eagerRenewRows:n];
        [self lazyRenewRows:n];
    }
    [self constrainSize];
    [self setNeedsDisplay:YES];
}


//-----------------------------------------------------------------------------
// - empty
//-----------------------------------------------------------------------------
- (void)empty
{
    [self renewRows:0];
}


//-----------------------------------------------------------------------------
// - releaseCells
//-----------------------------------------------------------------------------
- (void)releaseCells
{
    if (max_rows > 0 && num_cols > 0)
    {
        id* p = cells;
        id* const plim = p + (max_rows * num_cols);
        while (p < plim)
            [*p++ release];
    }
    if (cells != 0)
        NSZoneFree( [self zone], cells );
    cells = 0;
    max_cells = 0;
    max_rows = 0;
}


//-----------------------------------------------------------------------------
// - emptyAndReleaseCells
//-----------------------------------------------------------------------------
- (void)emptyAndReleaseCells
{
    [self empty];
    [self releaseCells];
}


//-----------------------------------------------------------------------------
// - setLazy:
//-----------------------------------------------------------------------------
- (void)setLazy:(BOOL)flag
{
    if (lazy != flag)
    {
        lazy = flag;
        if (lazy)
            [self emptyAndReleaseCells];
        else
            [self eagerRenewRows:num_rows];
    }
}


//-----------------------------------------------------------------------------
// - isLazy
//-----------------------------------------------------------------------------
- (BOOL)isLazy
{
    return lazy;
}


//-----------------------------------------------------------------------------
// Generic Slot methods
//-----------------------------------------------------------------------------
- (void)addSlot:(MiscBorderType)b
{ if (b == MISC_COL_BORDER) [self addColumn]; else [self addRow]; }

- (void)border:(MiscBorderType)b insertSlot:(int)n
{ if (b == MISC_COL_BORDER)
    [self insertColumn:n]; else [self insertRow:n]; }

- (void)border:(MiscBorderType)b removeSlot:(int)n
{ if (b == MISC_COL_BORDER)
    [self removeColumn:n]; else [self removeRow:n]; }

- (int)numberOfSlots:(MiscBorderType)b
{ return (b == MISC_COL_BORDER) ?
    [self numberOfColumns] : [self numberOfRows]; }


//-----------------------------------------------------------------------------
// REVIVE
//-----------------------------------------------------------------------------
- (id)doReviveCell:(id)cell atRow:(int)row column:(int)col
{
    if (cell != 0)
    {
        if ([cell respondsToSelector:@selector(setOwner:)])
            [cell setOwner:self];

        if ([cell respondsToSelector:@selector(setUseOwnerFont:)])
            [cell setUseOwnerFont:YES];
        if ([cell respondsToSelector:@selector(setUseOwnerTextColor:)])
            [cell setUseOwnerTextColor:YES];
        if ([cell respondsToSelector:@selector(setUseOwnerBackgroundColor:)])
            [cell setUseOwnerBackgroundColor:YES];
        if ([cell respondsToSelector:
             @selector(setUseOwnerSelectedTextColor:)])
            [cell setUseOwnerSelectedTextColor:YES];
        if ([cell respondsToSelector:
             @selector(setUseOwnerSelectedBackgroundColor:)])
            [cell setUseOwnerSelectedBackgroundColor:YES];

        if ([cell respondsToSelector:@selector(setOwnerFont:)])
            [cell setOwnerFont:[self font]];
        else if ([cell respondsToSelector:@selector(setFont:)])
            [cell setFont:[self font]];

        if ([cell respondsToSelector:@selector(setOwnerTextColor:)])
            [cell setOwnerTextColor:[self textColor]];
        else if ([cell respondsToSelector:@selector(setTextColor:)])
            [cell setTextColor:[self textColor]];

        if ([cell respondsToSelector:@selector(setOwnerBackgroundColor:)])
            [cell setOwnerBackgroundColor:[self backgroundColor]];
        else if ([cell respondsToSelector:@selector(setBackgroundColor:)])
            [cell setBackgroundColor:[self backgroundColor]];

        if ([cell respondsToSelector:@selector(setOwnerSelectedTextColor:)])
            [cell setOwnerSelectedTextColor:[self selectedTextColor]];
        else if ([cell respondsToSelector:@selector(setSelectedTextColor:)])
            [cell setSelectedTextColor:[self selectedTextColor]];

        if ([cell respondsToSelector:
             @selector(setOwnerSelectedBackgroundColor:)])
            [cell setOwnerSelectedBackgroundColor:
             [self selectedBackgroundColor]];
        else if ([cell respondsToSelector:
                  @selector(setSelectedBackgroundColor:)])
            [cell setSelectedBackgroundColor:[self selectedBackgroundColor]];
    }
    return cell;
}


- (id)reviveCell:(id)cell atRow:(int)row column:(int)col
{
    id del = [self responsibleDelegate:MiscDelegateFlags::DEL_REVIVE_CELL];
    if (del != 0)
        return [del tableScroll:self reviveCell:cell atRow:row column:col];

    if (cell != 0 && [cell respondsToSelector:
                      @selector(tableScroll:reviveAtRow:column:)])
        return [cell tableScroll:self reviveAtRow:row column:col];

    return [self doReviveCell:cell atRow:row column:col];
}


//-----------------------------------------------------------------------------
// RETIRE
//-----------------------------------------------------------------------------
- (id)doRetireCell:(id)cell atRow:(int)row column:(int)col
{
    if ([cell respondsToSelector:@selector(setTitle:)])
        [cell setTitle:@""];
    else if ([cell respondsToSelector:@selector(setStringValue:)])
        [cell setStringValue:@""];
    return cell;
}


- (id)retireCell:(id)cell atRow:(int)row column:(int)col
{
    id del = [self responsibleDelegate:MiscDelegateFlags::DEL_RETIRE_CELL];
    if (del != 0)
        return [del tableScroll:self retireCell:cell atRow:row column:col];

    if (cell != 0 && [cell respondsToSelector:
                      @selector(tableScroll:retireAtRow:column:)])
        return [cell tableScroll:self retireAtRow:row column:col];

    return [self doRetireCell:cell atRow:row column:col];
}

@end
