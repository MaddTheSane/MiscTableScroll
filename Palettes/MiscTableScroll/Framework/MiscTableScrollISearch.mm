//=============================================================================
//
//    Copyright (C) 1996-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollIncSearch.M
//
//	Incremental searching methods for MiscTableScroll.
//
//	FIXME *1*: Need to handle Unichars.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollISearch.M,v 1.15 99/06/15 03:31:19 sunshine Exp $
// $Log:	MiscTableScrollISearch.M,v $
// Revision 1.15  99/06/15  03:31:19  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Method renamed: trackingBy --> selectsByRows
// Methods renamed: ...ISearchColumn: --> ...IncrementalSearchColumn:
// 
// Revision 1.14  1998/03/30 01:02:39  sunshine
// v138.1: Ported back to OPENSTEP 4.1.  Compiler was complaining about
// using enumeral and non-enumeral in conditional expression.
//
//  Revision 1.13  98/03/23  11:12:16  sunshine
//  v136.1: Applied v0.136 NEXTSTEP 3.3 diffs.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscBorderCell.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import "MiscTableView.h"
#import	<AppKit/NSApplication.h>
#import <AppKit/NSCursor.h>
#import <AppKit/NSWindow.h>

static float const ISEARCH_TIMEOUT = 2.5;	// seconds

enum MiscKeyAction
{
    MISC_KEY_IGNORE,	// Ignore this event, get next.
    MISC_KEY_SPACE,		// Space character, not valid as first char.
    MISC_KEY_APPEND,	// Append a character to the template.
    MISC_KEY_EXPAND,	// Expand common-prefix.
    MISC_KEY_DELETE,	// Delete the last character from template.
    MISC_KEY_CLEAR,		// Clear (empty) the template.
    MISC_KEY_SELECT,	// Stop, Select the first entry.
    MISC_KEY_EXECUTE,	// Stop, Select and perform double action.
    MISC_KEY_STOP,		// Stop, don't select, consume keystroke.
    MISC_KEY_ABORT,		// Stop, don't select, don't consume.
};


//-----------------------------------------------------------------------------
// Feedback
//-----------------------------------------------------------------------------
class MISC_IS_Feedback
{
private:
    MiscTableScroll* scroll;
    BOOL drawn;
    MiscBorderCell* cell;
    NSRect drawRect;
    void init_cell();

public:
    MISC_IS_Feedback( MiscTableScroll* s ) : scroll(s),drawn(NO),cell(0) {}
    ~MISC_IS_Feedback() { if (cell != 0) [cell release]; }
    void draw( NSString* str );
    void erase();
};

void MISC_IS_Feedback::init_cell()
{
    if (cell == 0)
    {
        cell = [[MiscBorderCell allocWithZone:[scroll zone]] initTextCell:@""];
		[cell setAlignment:NSTextAlignmentLeft];
    }
}

void MISC_IS_Feedback::erase()
{
    if (drawn)
    {
        drawn = NO;
        [scroll displayRect:drawRect];
    }
}


void MISC_IS_Feedback::draw( NSString* str )
{
    init_cell();
    [cell setStringValue:str];

    NSSize size = [cell cellSize];
    NSRect clipFrame = [scroll documentClipRect];
    NSRect r = NSMakeRect( NSMinX(clipFrame), NSMaxY(clipFrame) - size.height,
                          size.width, size.height );
    r = NSIntersectionRect( clipFrame, r );

    [scroll lockFocus];
    [cell drawWithFrame:r inView:scroll];
    [scroll unlockFocus];

    drawn = YES;
    drawRect = r;
}


//-----------------------------------------------------------------------------
// classify_event
//-----------------------------------------------------------------------------
static MiscKeyAction classify_event(NSEvent* p)
{
	NSEventModifierFlags const BAD_FLAGS = (NSEventModifierFlagCommand | NSEventModifierFlagHelp | NSEventModifierFlagControl);
    MiscKeyAction rc = MISC_KEY_ABORT;
    unichar const K_DEL = '\x7f';
    NSEventType type = [p type];

	if ([p type] == NSEventTypeKeyDown)
    {
        if (([p modifierFlags] & BAD_FLAGS) == 0)
        {
            unichar const ch =
            [[p charactersIgnoringModifiers] characterAtIndex:0];
            if (ch == K_DEL || ch == '\b')
                rc = MISC_KEY_DELETE;
            else if (ch == '\t')
                rc = MISC_KEY_EXPAND;
            else if (ch > ' ' && ch < K_DEL)			// FIXME *1*
                rc = MISC_KEY_APPEND;
            else if (ch == ' ')
                rc = MISC_KEY_SPACE;
        }
    }
	else if (type == NSEventTypeKeyUp || type == NSEventTypeFlagsChanged)
    {
        rc = MISC_KEY_IGNORE;
    }

    return rc;
}



//-----------------------------------------------------------------------------
// map
//	Conditionally apply a mapping vector to an index value.
//-----------------------------------------------------------------------------
inline static int map( int const* a, int x ) { return a ? a[x] : x; }


//-----------------------------------------------------------------------------
// DATA RETRIEVAL AND COMPARE SUPPORT
//-----------------------------------------------------------------------------

typedef NSString* (*Datafunc)( id obj, SEL cmd,
                              MiscCoord_P row, MiscCoord_P col );

struct MiscSortTypeInfo
{
    SEL const* data_sel;	// Selector to use to retrieve string.
    BOOL fold_case;		// Case insensitive compare?
};

#define SEL_STRV &@selector(stringValueAtRow:column:)
#define SEL_TITL &@selector(titleAtRow:column:)

static MiscSortTypeInfo SORT_TYPE_INFO[ MISC_SORT_TYPE_MAX + 1 ] =
{
    { SEL_STRV, YES },	// MISC_SORT_STRING_CASE_INSENSITIVE
    { SEL_STRV, NO },	// MISC_SORT_STRING_CASE_SENSITIVE
    { 0, NO },		// MISC_SORT_INT
    { 0, NO },		// MISC_SORT_UNSIGNED_INT
    { 0, NO },		// MISC_SORT_TAG
    { 0, NO },		// MISC_SORT_UNSIGNED_TAG
    { 0, NO },		// MISC_SORT_FLOAT
    { 0, NO },		// MISC_SORT_DOUBLE
    { 0, NO },		// MISC_SORT_SKIP
    { SEL_TITL, YES },	// MISC_SORT_TITLE_CASE_INSENSITIVE
    { SEL_TITL, NO },	// MISC_SORT_TITLE_CASE_SENSITIVE
    { 0, NO },		// MISC_SORT_STATE
    { 0, NO },		// MISC_SORT_UNSIGNED_STATE
};

#undef SEL_STRV
#undef SEL_TITL


//-----------------------------------------------------------------------------
// MISC_IS_bsearch
//-----------------------------------------------------------------------------
static int MISC_IS_bsearch(
                           MiscCoord_V lo, MiscCoord_V hi,
                           BOOL upper_bound, BOOL descending,
                           MiscTableScroll* scroll,
                           NSString* buff,
                           MiscCoord_P col, MiscCoord_P const* v2p,
                           Datafunc data_func, SEL data_sel, unsigned int cmp_mask )
{
    int const buff_len = [buff length];
    while (lo <= hi)
    {
        MiscCoord_V const mid = (lo + hi) >> 1;
        MiscCoord_P const row = map( v2p, mid );
        NSString* s = (*data_func)( scroll, data_sel, row, col );
        if (s == 0)
            s = @"";
        int const s_len = [s length];
        NSRange r = NSMakeRange( 0, s_len < buff_len ? s_len : buff_len );
        int cmp = [s compare:buff options:cmp_mask range:r];
        if (descending)
            cmp = -cmp;
        if (cmp < 0 || (upper_bound && cmp == 0))
            lo = mid + 1;
        else
            hi = mid - 1;
    }
    return (upper_bound ? hi : lo);
}


//-----------------------------------------------------------------------------
// peek_event
//-----------------------------------------------------------------------------
inline static NSEvent* peek_event( float timeout )
{
	return [NSApp nextEventMatchingMask:NSEventMaskAny
                              untilDate:[NSDate dateWithTimeIntervalSinceNow:timeout]
                                 inMode:NSDefaultRunLoopMode
                                dequeue:NO];
}


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableScroll(IncrementalSearch)

//-----------------------------------------------------------------------------
// -doIncrementalSearch:column:	FIXME *1*
//-----------------------------------------------------------------------------
- (BOOL)doIncrementalSearch:(NSEvent*)p column:(int)col
{
    BOOL handled = YES;		// Event was handled here.
    BOOL descending = NO;
    if (col < 0)
    {
        col = ~col;
        descending = YES;
    }
    if ([self border:MISC_COL_BORDER slotSortDirection:col] ==
        MISC_SORT_DESCENDING)
        descending = !descending;

    MiscSortType type = [self border:MISC_COL_BORDER slotSortType:col];
    MiscSortTypeInfo const& INFO = SORT_TYPE_INFO[type];
    unsigned int const cmp_mask =
    INFO.fold_case ? (unsigned int)NSCaseInsensitiveSearch : 0;

    if (INFO.data_sel == 0 ||
        [self border:MISC_COL_BORDER slotSortFunction:col] != 0)
        return NO;					// *** RETURN ***

    SEL const data_sel = *(INFO.data_sel);
    Datafunc const data_func = (Datafunc) [self methodForSelector:data_sel];
    MiscCoord_P const* const v2p = rowInfo.border->getV2PMap();

    MISC_IS_Feedback feedback( self );
    MiscKeyAction ka;
    int const MARGIN = 2;
    int const BUFF_MAX = 61;
    int buff_len = 0;
    char margin[ MARGIN + BUFF_MAX + 1 ];
    char* buff = margin + MARGIN;
    MiscCoord_V first_stk[ BUFF_MAX + 1 ], last_stk[ BUFF_MAX + 1 ];
    MiscCoord_V first = 0, last = [self numberOfRows] - 1;
    MiscCoord_V prev_first = -1;
    BOOL update_cursor = ([self selectsByRows]);
    BOOL changed = NO;

    for (int i = 0; i < MARGIN; i++)
        margin[i] = ' ';

    float delay = 0.25;

    first_stk[0] = first;
    last_stk [0] = last;

    ka = classify_event( p );
    while (1)
    {
        [NSCursor setHiddenUntilMouseMoves:YES];
        switch (ka)
        {
            case MISC_KEY_IGNORE:
                break;
            case MISC_KEY_SPACE:
            case MISC_KEY_APPEND:
                if (buff_len < BUFF_MAX && first <= last)
                {
                    unichar ch = [[p characters] characterAtIndex:0];
                    buff[ buff_len++ ] = char( ch );
                    buff[ buff_len ] = '\0';
                    NSString* s = @(buff);
                    
                    MiscCoord_V const new_first = MISC_IS_bsearch(
                                                                  first, last, NO, descending, self, s,
                                                                  col, v2p, data_func, data_sel, cmp_mask );
                    
                    MiscCoord_V const new_last = MISC_IS_bsearch(
                                                                 new_first, last, YES, descending, self, s,
                                                                 col, v2p, data_func, data_sel, cmp_mask );
                    
                    if (new_first <= new_last)
                    {
                        first = new_first;
                        last  = new_last;
                        first_stk[ buff_len ] = first;
                        last_stk [ buff_len ] = last;
                        changed = YES;
                    }
                    else		// Do not add "invalid" characters.
                    {
                        buff[ --buff_len ] = '\0';
                        if (ka == MISC_KEY_SPACE)
                        {
                            ka = MISC_KEY_SELECT;
                            goto finished;	// *** GOTO ***
                        }
                        else if (buff_len == 0)
                        {			// Couldn't even add 1st char,
                            handled = NO;	// so don't go modal.
                            goto finished;	// *** GOTO ***
                        }
                        else
                            NSBeep();
                    }
                }
                else
                    NSBeep();
                break;
            case MISC_KEY_EXPAND:
            {
                if (first <= last)
                {
                    NSString* s1 =
                    (*data_func)( self, data_sel, map( v2p, first ), col );
                    NSString* s2 =
                    (*data_func)( self, data_sel, map( v2p, last  ), col );
                    NSString* s =
                    [s1 commonPrefixWithString:s2 options:cmp_mask];
                    int i = [s length];;
                    if (i > buff_len)
                    {
                        for (int j = buff_len + 1; j <= i; j++)
                        {
                            first_stk[j] = first;
                            last_stk[j] = last;
                        }
                        buff_len = i;
                        strncpy( buff, [s UTF8String], buff_len );
                        buff[ buff_len ] = '\0';
                        changed = YES;
                    }
                }
            }
                break;
            case MISC_KEY_DELETE:
                if (buff_len > 0)
                {
                    buff[ --buff_len ] = '\0';
                    first = first_stk[ buff_len ];
                    last  = last_stk[ buff_len ];
                    changed = YES;
                }
                else
                    goto finished;	// *** GOTO ***
                break;
            case MISC_KEY_CLEAR:
            case MISC_KEY_SELECT:
            case MISC_KEY_EXECUTE:
            case MISC_KEY_STOP:
            case MISC_KEY_ABORT:
                goto finished;		// *** GOTO ***
        }

        if ((p = peek_event( delay )) == 0)
        {
            if (changed)
            {
                changed = NO;
                NSWindow* win = [self window];
                [win disableFlushWindow];
                feedback.erase();
                if (prev_first != first)
                {
                    prev_first = first;
                    MiscCoord_P const r = map( v2p, first );
                    [self border:MISC_ROW_BORDER setFirstVisibleSlot:r];
                    if (update_cursor)
                        [self border:MISC_ROW_BORDER setCursorSlot:r];
                    [self displayIfNeeded];
                }
                NSString* s = @(margin);
                feedback.draw( s );
                [win enableFlushWindow];
                [win flushWindow];

                if (buff_len == 0)
                    break;		// *** BREAK ***
            }

            if ((p = peek_event( ISEARCH_TIMEOUT )) == 0)
                break;			// *** BREAK *** inactivity timeout.
        }

        delay = 0.0;
        ka = classify_event( p );

        if (ka != MISC_KEY_ABORT)	// "Eat" the event.
			[NSApp nextEventMatchingMask:NSEventMaskAny
                               untilDate:[NSDate dateWithTimeIntervalSinceNow:ISEARCH_TIMEOUT]
                                  inMode:NSDefaultRunLoopMode
                                 dequeue:YES];
    }

finished:
    feedback.erase();

    if (ka==MISC_KEY_SELECT || ka==MISC_KEY_EXECUTE)
    {
        MiscCoord_P const phys_first = map( v2p, first );
        if (prev_first != first)
        {
            [self border:MISC_ROW_BORDER setFirstVisibleSlot:phys_first];
            if (update_cursor)
                [self border:MISC_ROW_BORDER setCursorSlot:phys_first];
        }
        if (update_cursor)
            [self keyboardSelect:p];
        if ([self isEnabled])
        {
            [self sendAction];
            if (ka == MISC_KEY_EXECUTE)
                [self sendDoubleAction];
        }
    }

    return handled;
}


//-----------------------------------------------------------------------------
// -doGetIncrementalSearchColumn:
//	Default implementation.  If auto-sort-rows is on, and the first
//	non-skip column is string-based, use that column, else fail.
//-----------------------------------------------------------------------------
- (BOOL)doGetIncrementalSearchColumn:(int*)col
{
    if ([self autoSortRows])
    {
        int const lim = colInfo.border->count();
        int const* v2p = colInfo.border->getV2PMap();
        for (int i = 0; i < lim; i++)
        {
            int const j = map( v2p, i );
            if ([self border:MISC_COL_BORDER slotSortFunction:j] != 0)
                return NO;
            MiscSortType const t = [self border:MISC_COL_BORDER slotSortType:j];
            if (t != MISC_SORT_SKIP)
            {
                *col = j;
                return (SORT_TYPE_INFO[t].data_sel != 0);
            }
        }
    }
    return NO;
}


//-----------------------------------------------------------------------------
// -getIncrementalSearchColumn:
//-----------------------------------------------------------------------------
- (BOOL)getIncrementalSearchColumn:(int*)col
{
    id del = [self responsibleDelegate:MiscDelegateFlags::DEL_GET_ISEARCH_COL];
    if (del != 0)
        return [del tableScroll:self getIncrementalSearchColumn:col];
    return [self doGetIncrementalSearchColumn:col];
}


//-----------------------------------------------------------------------------
// -incrementalSearch:
//-----------------------------------------------------------------------------
- (BOOL)incrementalSearch:(NSEvent*)p 
{
    if ([self numberOfRows] > 0 && [self numberOfColumns] > 0)
    {
        MiscKeyAction const ka = classify_event( p );
        if (ka == MISC_KEY_APPEND)
        {
            int col;
            if ([self getIncrementalSearchColumn:&col])
                return [self doIncrementalSearch:p column:col];
        }
    }
    return NO;	// Event was not handled here.
}

@end
