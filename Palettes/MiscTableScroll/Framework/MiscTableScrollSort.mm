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
// MiscTableScrollSort.M
//
//	Sorting support for MiscTableScroll.
//
// FIXME: OPTIMIZATION -- Explore other sorting algorithms:
//	MergeSort, Radix-Exchange, Distribution-Counting.
//	HeapSort: explored -- usually makes twice as many comparisons.
//	Binary Insertion Sort (bsort): explored -- *way* fewer comparisons,
//		but memmove() overhead slaughters performance.
//
// FIXME: OPTIMIZATION -- Explore calling -isSorted before actually sorting
//	the table.  This might save a lot of work when there are unique
//	columns near the left, and the user is dragging columns near the
//	right. ** Exploring ** Seems to improve overall performance for
//	quicksort(), not necessary with bsort().
//
// FIXME: OPTIMIZATION -- Explore giving the programmer some means to mark
//	columns as "unique".  Whenever the from- and to- positions of a
//	column-drag operation are to the right of a "unique" column, resorting
//	can be suppressed.  Extra sort-information does not need to be
//	pre-computed for columns to the right of the "unique" column.
//
// FIXME: OPTIMIZATION -- When sorting a column of integers, allocate an
//	array and fill it with the values so that we don't have to retrieve
//	the values several times while the sort is in progress.  Same thing
//	for string pointers if we can give the user some way to indicate
//	that the strings are stable for the duration of the sort.
//
// FIXME: OPTIMIZATION -- Most of the sorting and comparing uses one record
//	repeatedly while comparing it to others.  Find some way to cache
//	the values from that record so they don't have to be fetched
//	repeatedly.
//
// FIXME: OPTIMIZATION -- Consider re-using the sort info objects at least to
//	avoid allocating and freeing entry_info[] and buff[] all the time.
//	Consider embedding one of them right in the table-scroll itself.
//
// LOSER: OPTIMIZATION -- Don't make a function call to do the comparisons
//	unless the user has installed a custom sort function.  Use a big
//	switch statement.  (This eliminates one function call per comparison.)
//	*** I tried this.  It was actually a little bit slower than the ***
//	*** current design. ***
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollSort.M,v 1.20 99/06/15 03:44:38 sunshine Exp $
// $Log:	MiscTableScrollSort.M,v $
// Revision 1.20  99/06/15  03:44:38  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Method renamed: border:moveSlotFrom:to: --> border:moveSlot:toSlot:
// 
// Revision 1.19  1998/03/23 11:12:33  sunshine
// v136.1: Applied v0.136 NEXTSTEP 3.3 diffs.
//
// Revision 1.18  97/06/18  10:03:38  sunshine
// v125.9: buffCount --> bufferCount
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import <MiscTableScroll/MiscTableCell.h>
#import "MiscBorderView.h"
#import "MiscTableBorder.h"
#import "MiscTableScrollPrivate.h"
#import "MiscTableView.h"

extern "C" {
#import	<stdlib.h>
}

#ifndef USE_BSORT			// Use binary insertion sort.
#define USE_BSORT 0
#endif

#ifndef SORTING_STATS			// Gather and print some statistics.
#define SORTING_STATS 0
#endif

//=============================================================================
// CELL-VALUE ACCESS
//=============================================================================

//-----------------------------------------------------------------------------
// cell_str
//-----------------------------------------------------------------------------
static inline NSString* cell_str( int r, int c,
                                 MiscEntrySortInfo const* p, MiscSlotSortInfo* q,
                                 BOOL make_copy )
{
    NSString* t = (*(p->value_func.s))(
                                       p->value_target, p->value_sel, p->value_obj, r, c, p, q );
    if (make_copy)
        t = [t copy];
    else
        [t retain];
    return t;
}


//-----------------------------------------------------------------------------
// cell_int
//-----------------------------------------------------------------------------
static inline int cell_int( int r, int c,
                           MiscEntrySortInfo const* p, MiscSlotSortInfo const* q )
{
    return (*(p->value_func.i))(
                                p->value_target, p->value_sel, p->value_obj, r, c, p, q );
}


//-----------------------------------------------------------------------------
// cell_float
//-----------------------------------------------------------------------------
static inline float cell_float( int r, int c,
                               MiscEntrySortInfo const* p, MiscSlotSortInfo const* q )
{
    return (*(p->value_func.f))(
                                p->value_target, p->value_sel, p->value_obj, r, c, p, q );
}


//-----------------------------------------------------------------------------
// cell_double
//-----------------------------------------------------------------------------
static inline double cell_double( int r, int c,
                                 MiscEntrySortInfo const* p, MiscSlotSortInfo const* q )
{
    return (*(p->value_func.d))(
                                p->value_target, p->value_sel, p->value_obj, r, c, p, q );
}


//=============================================================================
// CELL COMPARISON FUNCTIONS
//=============================================================================

//-----------------------------------------------------------------------------
// cmp_istr
//-----------------------------------------------------------------------------
static int cmp_istr( int r1, int c1, int r2, int c2,
                    MiscEntrySortInfo const* p, MiscSlotSortInfo* q )
{
    NSString* const s1 = [cell_str( r1,c1,p,q,q->need_copy ) autorelease];
    NSString* const s2 = [cell_str( r2,c2,p,q,NO ) autorelease];
    return [s1 caseInsensitiveCompare:s2];
}


//-----------------------------------------------------------------------------
// cmp_str
//-----------------------------------------------------------------------------
static int cmp_str( int r1, int c1, int r2, int c2,
                   MiscEntrySortInfo const* p, MiscSlotSortInfo* q )
{
    NSString* const s1 = [cell_str( r1,c1,p,q,q->need_copy ) autorelease];
    NSString* const s2 = [cell_str( r2,c2,p,q,NO ) autorelease];
    return [s1 compare:s2];
}


//-----------------------------------------------------------------------------
// cmp_int
//-----------------------------------------------------------------------------
static int cmp_int( int r1, int c1, int r2, int c2,
                   MiscEntrySortInfo const* p, MiscSlotSortInfo* q )
{
    int const x1 = cell_int(r1,c1,p,q);
    int const x2 = cell_int(r2,c2,p,q);
    if (x1 < x2)
        return -1;
    if (x1 > x2)
        return 1;
    return 0;
}


//-----------------------------------------------------------------------------
// cmp_uint
//-----------------------------------------------------------------------------
static int cmp_uint( int r1, int c1, int r2, int c2,
                    MiscEntrySortInfo const* p, MiscSlotSortInfo * q )
{
    unsigned int const x1 = (unsigned int) cell_int(r1,c1,p,q);
    unsigned int const x2 = (unsigned int) cell_int(r2,c2,p,q);
    if (x1 < x2)
        return -1;
    if (x1 > x2)
        return 1;
    return 0;
}


//-----------------------------------------------------------------------------
// cmp_float
//-----------------------------------------------------------------------------
static int cmp_float( int r1, int c1, int r2, int c2,
                     MiscEntrySortInfo const* p, MiscSlotSortInfo * q )
{
    float const x1 = cell_float(r1,c1,p,q);
    float const x2 = cell_float(r2,c2,p,q);
    if (x1 < x2)
        return -1;
    if (x1 > x2)
        return 1;
    return 0;
}


//-----------------------------------------------------------------------------
// cmp_double
//-----------------------------------------------------------------------------
static int cmp_double( int r1, int c1, int r2, int c2,
                      MiscEntrySortInfo const* p, MiscSlotSortInfo * q )
{
    double const x1 = cell_double(r1,c1,p,q);
    double const x2 = cell_double(r2,c2,p,q);
    if (x1 < x2)
        return -1;
    if (x1 > x2)
        return 1;
    return 0;
}


//-----------------------------------------------------------------------------
// cmp_skip
//-----------------------------------------------------------------------------
static int cmp_skip( int,int,int,int,
                    MiscEntrySortInfo const*, MiscSlotSortInfo *)
{
    return 0;
}


//-----------------------------------------------------------------------------
// COMPARE_FUNC[]
//-----------------------------------------------------------------------------
static MiscCompareEntryFunc const COMPARE_FUNC[ MISC_SORT_TYPE_MAX + 1 ] =
{
    cmp_istr,	// MISC_SORT_STRING_CASE_INSENSITIVE
    cmp_str,	// MISC_SORT_STRING_CASE_SENSITIVE
    cmp_int,	// MISC_SORT_INT
    cmp_uint,	// MISC_SORT_UNSIGNED_INT
    cmp_int,	// MISC_SORT_TAG
    cmp_uint,	// MISC_SORT_UNSIGNED_TAG
    cmp_float,	// MISC_SORT_FLOAT
    cmp_double,	// MISC_SORT_DOUBLE
    cmp_skip,	// MISC_SORT_SKIP
    cmp_istr,	// MISC_SORT_TITLE_CASE_INSENSITIVE
    cmp_str,	// MISC_SORT_TITLE_CASE_SENSITIVE
    cmp_int,	// MISC_SORT_STATE
    cmp_uint,	// MISC_SORT_UNSIGNED_STATE
};


//=============================================================================
// SLOT-COMPARE
//=============================================================================

#if(SORTING_STATS)
static unsigned long int NUM_COMPARES = 0;
#endif

//-----------------------------------------------------------------------------
// MiscDefaultCompareSlotFunc
//-----------------------------------------------------------------------------
int MiscDefaultCompareSlotFunc(
                               int slot1,
                               int slot2,
                               MiscSlotSortInfo* info )
{
    int rc = 0;
    MiscEntrySortInfo const* p = info->entry_info;
    MiscEntrySortInfo const* const plim = p + info->num_entries;

    if (info->border_type == MISC_COL_BORDER)		// Row-wise compare
    {
        for ( ; p < plim; p++)
        {
#if(SORTING_STATS)
            NUM_COMPARES++;
#endif
            int const col = p->slot;
            if ((rc = (*(p->compare_func))(slot1,col,slot2,col,p,info)) != 0)
                return (p->ascending ? rc : -rc);
        }
    }
    else						// Col-wise compare
    {
        for ( ; p < plim; p++)
        {
#if(SORTING_STATS)
            NUM_COMPARES++;
#endif
            int const row = p->slot;
            if ((rc = (*(p->compare_func))(row,slot1,row,slot2,p,info)) != 0)
                return (p->ascending ? rc : -rc);
        }
    }

    return 0;
}



//=============================================================================
// QSORT
//=============================================================================
#if(USE_BSORT)
static void bsort(
                  int a[],
                  int N,
                  MiscCompareSlotFunc f,
                  MiscSlotSortInfo* info )
{
#if(SORTING_STATS)
    time_t const t0 = time(0);
    clock_t const c0 = clock();
    NUM_COMPARES = 0;
#endif

    int lo, mid, hi;

    for (int i = 1; i < N; i++)
    {
        NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
        int v = a[i];
        hi = i - 1;
        if ((*f)(a[hi],v,info) > 0)
        {
            lo = 0;
            while (lo <= hi)
            {
                mid = (lo + hi) >> 1;
                if ((*f)(a[mid],v,info) <= 0)
                    lo = mid + 1;
                else
                    hi = mid - 1;
            }

            int* lim = a + lo;
            int* src = a + i;
            int* dst = src + 1;
            do { *(--dst) = *(--src); } while (src != lim);
            *src = v;
            // 	    memmove( a + lo + 1, a + lo, (i - lo) * sizeof(*a) );
            // 	    a[lo] = v;
        }
        [pool release];
    }

#if(SORTING_STATS)
    clock_t const c1 = clock();
    time_t const t1 = time(0);
    NSLog( @"bsort: %d ticks %d seconds %lu compares",
          (c1 - c0), (t1 - t0), NUM_COMPARES );
#endif
}
#else
//-----------------------------------------------------------------------------
// swap
//-----------------------------------------------------------------------------
inline static void swap( int x, int y, int a[] )
{
    int t = a[x];
    a[x] = a[y];
    a[y] = t;
}


//-----------------------------------------------------------------------------
// do_qsort
//-----------------------------------------------------------------------------
static void do_qsort(
                     int a[],
                     int N,
                     MiscCompareSlotFunc f,
                     MiscSlotSortInfo* info )
{
#if(SORTING_STATS)
    time_t const t0 = time(0);
    clock_t const c0 = clock();
    NUM_COMPARES = 0;
#endif

    int const STACK_MAX = 64;		// log_base_2(ULNG_MAX) * 2
    int stk[ STACK_MAX ];
    int top = 0;
    int left = 0;
    int right = N - 1;
    int i,j,n;

    for (;;)
    {
        while (right > left)
        {
            NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
            n = (right - left) + 1;	// right,left bounds are inclusive.
            if (n >= 8)
            {
                int mid = (left + right) >> 1;
                if ((*f)(a[left],a[right],info) > 0) swap(left,right,a);
                if ((*f)(a[mid], a[right],info) > 0) swap(mid,right,a);
                if ((*f)(a[left],a[mid],  info) > 0) swap(left,mid,a);
                // 		if (n == 3) break;
                right--;
                swap(mid,right,a);
                int v = a[right];
                i = left;
                j = right;
                for (;;)
                {
                    while ((*f)(a[++i],v,info) < 0) /* empty */;
                    while ((*f)(a[--j],v,info) > 0) /* empty */;
                    if (i >= j) break;
                    swap( i, j, a );
                }
                swap( i, right, a );
                right++;
                if (i - left > right - i)
                { stk[top++] = left;  stk[top++] = i-1; left = i+1; }
                else
                { stk[top++] = i+1; stk[top++] = right; right = i-1; }
            }
            else // (n < 3)
            {
                if (n > 1)
                {
                    for (i = left + 1; i <= right; i++)
                    {
                        int const v = a[i];
                        j = i;
                        while (--j >= left && (*f)(a[j],v,info) > 0)
                            a[j+1] = a[j];
                        a[++j] = v;
                    }
                }
                break;
            }
            [pool release];
        }
        if (top == 0) break;
        right = stk[--top];
        left = stk[--top];
    }
    
#if(SORTING_STATS)
    clock_t const c1 = clock();
    time_t const t1 = time(0);
    NSLog( @"qsort: %d ticks %d seconds %lu compares",
          (c1 - c0), (t1 - t0), NUM_COMPARES );
#endif
}
#endif

@implementation MiscTableScroll(Sort)

//-----------------------------------------------------------------------------
// MISC_INDIRECT
//	Indirect value-access methods.  For lazy-mode tables where the 
//	delegate and dataDelegate do not provide the corresponding 
//	tableScroll:valueAtRow:column: method.  We retrieve the cell from the 
//	delegate or dataDelegate via the tableScroll:cellAtRow:column: method,
//	then we ask the cell for the value.  
//-----------------------------------------------------------------------------

#define MISC_INDIRECT( DATA_TYPE, NAME, SUFFIX, FUNC_TYPE ) \
- (DATA_TYPE)indirect:obj NAME##AtRow:(int)row column:(int)col \
:(MiscEntrySortInfo*)p :(MiscSlotSortInfo*)q \
{ \
id cell = (*(p->cell_at_func))( obj, \
@selector(tableScroll:cellAtRow:column:), \
self, row, col ); \
if (cell != 0) \
{ \
if (p->cell_class == (id)cell->isa) \
{ \
if (p->cell_func.SUFFIX != 0) \
return (*(p->cell_func.SUFFIX))( cell, p->cell_sel ); \
} \
else \
{ \
p->cell_class = (id)cell->isa; \
if ([cell respondsToSelector:p->cell_sel]) \
{ \
p->cell_func.SUFFIX = (MISC_TS_##FUNC_TYPE##_VAL) \
[cell methodForSelector:p->cell_sel]; \
if (p->cell_func.SUFFIX != 0) \
return (*(p->cell_func.SUFFIX))( cell, p->cell_sel ); \
} \
else \
p->cell_func.SUFFIX = 0; \
} \
} \
return 0; \
}

MISC_INDIRECT( int, tag, i, INT )		// tagAtRow:column:
MISC_INDIRECT( int, intValue, i, INT )		// intValueAtRow:column:
MISC_INDIRECT( float, floatValue, f, FLOAT )	// floatValueAtRow:column:
MISC_INDIRECT( double, doubleValue, d, DOUBLE )	// doubleValueAtRow:column:
MISC_INDIRECT( NSString*, stringValue,s,STRING)	// stringValueAtRow:column:
MISC_INDIRECT( int, state, i, INT )		// stateAtRow:column:
MISC_INDIRECT( NSString*, title, s, STRING )	// titleAtRow:column:



//-----------------------------------------------------------------------------
// MISC_DIRECT
//	Direct value-access methods for eager-mode tables.  These cover
//	routines match the correct prototype for sorting, and skip some
//	of the intervening overhead.
//-----------------------------------------------------------------------------

#define MISC_DIRECT( DATA_TYPE, NAME, SUFFIX, FUNC_TYPE ) \
- (DATA_TYPE)direct:dummyObj NAME##AtRow:(int)row column:(int)col \
:(MiscEntrySortInfo*)p :(MiscSlotSortInfo*)q \
{ \
id cell = cells[ row * num_cols + col ]; \
if (p->cell_class == (id)cell->isa) \
{ \
if (p->cell_func.SUFFIX != 0) \
return (*(p->cell_func.SUFFIX))( cell, p->cell_sel ); \
} \
else \
{ \
p->cell_class = (id)cell->isa; \
if ([cell respondsToSelector:p->cell_sel]) \
{ \
p->cell_func.SUFFIX = (MISC_TS_##FUNC_TYPE##_VAL) \
[cell methodForSelector:p->cell_sel]; \
if (p->cell_func.SUFFIX != 0) \
return (*(p->cell_func.SUFFIX))( cell, p->cell_sel ); \
} \
else \
p->cell_func.SUFFIX = 0; \
} \
return 0; \
}

MISC_DIRECT( int, tag, i, INT )			// tagAtRow:column:
MISC_DIRECT( int, intValue, i, INT )		// intValueAtRow:column:
MISC_DIRECT( float, floatValue, f, FLOAT )	// floatValueAtRow:column:
MISC_DIRECT( double, doubleValue, d, DOUBLE )	// doubleValueAtRow:column:
MISC_DIRECT( NSString*, stringValue, s, STRING)	// stringValueAtRow:column:
MISC_DIRECT( int, state, i, INT )		// stateAtRow:column:
MISC_DIRECT( NSString*, title, s, STRING )	// titleAtRow:column:



//-----------------------------------------------------------------------------
// copy_info
//-----------------------------------------------------------------------------
static void copy_info( MiscEntrySortInfo& info, MiscEntrySortInfo const& x )
{
    info.value_target = x.value_target;
    info.value_sel = x.value_sel;
    info.value_obj = x.value_obj;
    info.value_func.i = x.value_func.i;
    info.cell_at_func = x.cell_at_func;
    info.cell_class = x.cell_class;
    info.cell_sel = x.cell_sel;
    info.cell_func.i = x.cell_func.i;
}


//-----------------------------------------------------------------------------
// set_info
//-----------------------------------------------------------------------------
static void set_info( MiscEntrySortInfo* info, id targ,
                     SEL aSel, id obj, SEL cell_sel )
{
    info->value_target = targ;
    info->value_sel = aSel;
    info->value_obj = obj;
    info->value_func.i = (MISC_TS_INT_AT)[targ methodForSelector:aSel];
    info->cell_at_func =
    [obj methodForSelector:@selector(tableScroll:cellAtRow:column:)];
    info->cell_class = 0;
    info->cell_sel = cell_sel;
    info->cell_func.i = 0;
}


//-----------------------------------------------------------------------------
// MISC_INFO_INIT
//	Precompute which objects and messages to use to retrieve the values
//	for a particular type of data.
//-----------------------------------------------------------------------------
#define MISC_INFO_INIT( NAME, CMD ) \
- (BOOL)sortInfoInit_##NAME:(MiscEntrySortInfo*)p \
{ \
id del; \
BOOL ok = YES; \
del = [self responsibleDelegate:MiscDelegateFlags::DEL_##CMD##_AT]; \
if (del != 0) \
set_info( p,del,@selector(tableScroll:NAME##AtRow:column:),self,0 ); \
else if (!lazy) \
set_info( p, self, @selector(direct:NAME##AtRow:column: : :), 0, \
@selector(NAME) ); \
else \
{ \
del = [self responsibleDelegate:MiscDelegateFlags::DEL_CELL_AT]; \
if (del != 0) \
set_info(p,self,@selector(indirect:NAME##AtRow:column: : :),del, \
@selector(NAME)); \
else \
ok = NO; \
} \
return ok; \
}

MISC_INFO_INIT( tag, TAG )			// sortInfoInit_tag:
MISC_INFO_INIT( intValue, INT_VALUE )		// sortInfoInit_intValue:
MISC_INFO_INIT( floatValue, FLOAT_VALUE )	// sortInfoInit_floatValue:
MISC_INFO_INIT( doubleValue, DOUBLE_VALUE )	// sortInfoInit_doubleValue:
MISC_INFO_INIT( stringValue, STRING_VALUE )	// sortInfoInit_stringValue:
MISC_INFO_INIT( state, STATE )			// sortInfoInit_state:
MISC_INFO_INIT( title, TITLE )			// sortInfoInit_title:



//-----------------------------------------------------------------------------
// - sortValueInfoInit:type:
//-----------------------------------------------------------------------------
- (BOOL)sortValueInfoInit:(MiscEntrySortInfo*)p type:(MiscSortType)type
{
    BOOL ok = NO;
    switch (type)
    {
        case MISC_SORT_STRING_CASE_INSENSITIVE:
        case MISC_SORT_STRING_CASE_SENSITIVE:
            ok = [self sortInfoInit_stringValue:p];
            break;
        case MISC_SORT_INT:
        case MISC_SORT_UNSIGNED_INT:
            ok = [self sortInfoInit_intValue:p];
            break;
        case MISC_SORT_TAG:
        case MISC_SORT_UNSIGNED_TAG:
            ok = [self sortInfoInit_tag:p];
            break;
        case MISC_SORT_FLOAT:
            ok = [self sortInfoInit_floatValue:p];
            break;
        case MISC_SORT_DOUBLE:
            ok = [self sortInfoInit_doubleValue:p];
            break;
        case MISC_SORT_TITLE_CASE_INSENSITIVE:
        case MISC_SORT_TITLE_CASE_SENSITIVE:
            ok = [self sortInfoInit_title:p];
            break;
        case MISC_SORT_STATE:
        case MISC_SORT_UNSIGNED_STATE:
            ok = [self sortInfoInit_state:p];
            break;
        default:
        case MISC_SORT_SKIP:
            break;
    }
    return ok;
}


//-----------------------------------------------------------------------------
// - compareSlotFunction
//-----------------------------------------------------------------------------
- (MiscCompareSlotFunc)compareSlotFunction
{
    return sort_slot_func ? sort_slot_func : MiscDefaultCompareSlotFunc;
}


//-----------------------------------------------------------------------------
// - setCompareSlotFunction:
//-----------------------------------------------------------------------------
- (void)setCompareSlotFunction:(MiscCompareSlotFunc)f
{
    sort_slot_func =  (f ? f : MiscDefaultCompareSlotFunc);
}


//-----------------------------------------------------------------------------
// - sortInfoInit:border:
//
// NOTE *VAL-INFO*
//	The val_info[] array holds the index of the first entry for each
//	sort-type.  This is used so that the value-access information only
//	needs to be computed once.  Later entries can use the value-access
//	information already computed for previous entries of the same
//	sort-type.  If there is no method to retrieve the data for a given
//	sort-type, then the entry is marked with VAL_INFO_ERROR, and all
//	entries with that sort-type will be excluded from the final
//	entry_info[] array.
//-----------------------------------------------------------------------------
- (void)sortInfoInit:(MiscSlotSortInfo*)ip border:(MiscBorderType)b
{
    MiscBorderType const ob = MISC_OTHER_BORDER(b);
    MiscTableBorder* const obp = info[ob]->border;
    NSZone* const z = [self zone];

    ip->table_scroll	= self;
    ip->zone		= z;
    ip->border_type	= ob;
    ip->num_entries	= 0;
    ip->entry_info	= 0;
    ip->need_copy	= lazy && ([self bufferCount] < 2);

    int M;					// Number of "cols".
    NSArray* v = [self slotSortVector:ob];
    if (v != 0)
        M = [v count];
    else
    {
        M = obp->count();
        if (M > 0)
        {
            int const* pMap = obp->getV2PMap();
            NSMutableArray* a = [NSMutableArray array];
            for (int i = 0; i < M; i++)
            {
                int n = (pMap != 0 ? pMap[i] : i);
                [a addObject:[NSNumber numberWithInt:n]];
            }
            v = a;
        }
    }

    if (M > 0)
    {
        unsigned int const sz = M * sizeof( MiscEntrySortInfo );
        MiscEntrySortInfo* ep = (MiscEntrySortInfo*) NSZoneMalloc( z, sz );

        if (ep != 0)
        {
            ip->num_entries	= M;
            ip->entry_info	= ep;

            int const VAL_INFO_BLANK = -1;
            int const VAL_INFO_ERROR = -2;
            int val_info[ MISC_SORT_TYPE_MAX + 1 ];	// NOTE *VAL-INFO*
            for (int k = 0; k <= (int) MISC_SORT_TYPE_MAX; k++)
                val_info[k] = VAL_INFO_BLANK;

            int j = 0;
            for (int i = 0; i < M; i++)
            {
                MiscEntrySortInfo& r = ep[j];
                int n = (v ? [[v objectAtIndex:i] intValue] : i);
                BOOL was_neg = (n < 0);
                if (was_neg)
                    n = ~n;
                r.slot = n;
                if ([self border:ob slotSortDirection:n]==MISC_SORT_DESCENDING)
                    was_neg = !was_neg;
                r.ascending = !was_neg;
                if ((r.compare_func = [self border:ob slotSortFunction:n])==0)
                {
                    MiscSortType t = [self border:ob slotSortType:n];
                    if ((unsigned int)t <= (unsigned int)MISC_SORT_TYPE_MAX &&
                        t != MISC_SORT_SKIP)
                    {
                        r.sort_type = t;
                        r.compare_func = COMPARE_FUNC[t];

                        int* vi = val_info + (int)t;
                        if (*vi == VAL_INFO_BLANK)
                        {
                            if ([self sortValueInfoInit:&r type:t])
                                *vi = j;
                            else
                                *vi = VAL_INFO_ERROR;
                        }
                        else if (*vi != VAL_INFO_ERROR)
                            copy_info( r, ep[ *vi ] );

                        if (*vi != VAL_INFO_ERROR)
                            j++;	// Keep this slot.
                    }
                }
                else
                {
                    r.sort_type = MISC_SORT_CUSTOM;
                    j++;		// Keep this slot.
                }
            }
            ip->num_entries = j;	// Number of non-skip slots.
        }
        else
        {
            [NSException raise:NSMallocException
                        format:@"%d bytes requested", sz];
        }
    }
}


//-----------------------------------------------------------------------------
// - sortInfoDone:
//-----------------------------------------------------------------------------
- (void)sortInfoDone:(MiscSlotSortInfo*)ip
{
    if (ip->entry_info != 0)
    {			// Cast off const-ness.
        NSZoneFree( ip->zone, (MiscEntrySortInfo*) ip->entry_info );
        ip->entry_info = 0;
    }
}


//-----------------------------------------------------------------------------
// - slots:areSorted:func:info:
//-----------------------------------------------------------------------------
- (BOOL)slots:(int const*)v2p
    areSorted:(int)N
         func:(MiscCompareSlotFunc)func
         info:(MiscSlotSortInfo*)ip
{
    if (v2p == 0)
    {
        for (int i = 1; i < N; i++)
            if ((*func)( i-1, i, ip ) > 0)
                return NO;
    }
    else
    {
        for (int i = 1; i < N; i++)
            if ((*func)( v2p[i-1], v2p[i], ip ) > 0)
                return NO;
    }

    return YES;
}


#if(USE_BSORT)
//-----------------------------------------------------------------------------
// - sortSlots:
//-----------------------------------------------------------------------------
- (void)sortSlots:(MiscBorderType)b
{
    MiscTableBorder* const bp = info[b]->border;
    int const N = bp->count();

    if (N > 1)
    {
        MiscCompareSlotFunc func = [self compareSlotFunction];
        MiscSlotSortInfo data;
        [self sortInfoInit:&data border:b];
        if (data.num_entries > 0)
        {
            NSZone* const z = [self zone];
            int* const new_v2p = (int*) NSZoneMalloc(z,N*sizeof(int));
            if (new_v2p != 0)
            {
                for (int j = 0; j < N; j++)
                    new_v2p[j] = j;
                
                bsort( new_v2p, N, func, &data );
                bp->setV2PMap( new_v2p );
                NSZoneFree( z, new_v2p );
                [self resetSelection];
                [self setNeedsDisplay:YES];
            }
            else
            {
                [self error:"Memory allocation failure.\n" ];
            }
        }
        [self sortInfoDone:&data];
    }
}
#else
//-----------------------------------------------------------------------------
// - sortSlots:
//-----------------------------------------------------------------------------
- (void)sortSlots:(MiscBorderType)b
{
    MiscTableBorder* const bp = info[b]->border;
    int const N = bp->count();

    if (N > 1)
    {
        MiscCompareSlotFunc func = [self compareSlotFunction];
        MiscSlotSortInfo data;
        [self sortInfoInit:&data border:b];
        if (data.num_entries > 0)
        {
            int const* const old_v2p = bp->getV2PMap();
            if (![self slots:old_v2p areSorted:N func:func info:&data])
            {
                NSZone* const z = [self zone];
                unsigned int const sz = N * sizeof(int);
                int* const new_v2p = (int*) NSZoneMalloc( z, sz );
                if (new_v2p != 0)
                {
                    for (int j = 0; j < N; j++)
                        new_v2p[j] = j;
                    
                    do_qsort( new_v2p, N, func, &data );
                    bp->setV2PMap( new_v2p );
                    NSZoneFree( z, new_v2p );
                    [self resetSelection];
                    [self setNeedsDisplay:YES];
                }
                else
                {
                    [NSException raise:NSMallocException
                                format:@"%d bytes requested", sz];
                }
            }
        }
        [self sortInfoDone:&data];
    }
}
#endif

- (void)sortColumns { [self sortSlots:MISC_COL_BORDER]; }
- (void)sortRows { [self sortSlots:MISC_ROW_BORDER]; }


//-----------------------------------------------------------------------------
// - slotsAreSorted:
//-----------------------------------------------------------------------------
- (BOOL)slotsAreSorted:(MiscBorderType)b
{
    BOOL sorted = YES;
    MiscTableBorder* const border = info[b]->border;
    int const N = border->count();		// Number of "rows".
    
    if (N > 1)
    {
        MiscSlotSortInfo data;
        [self sortInfoInit:&data border:b];
        if (data.num_entries > 0)
        {
            sorted = [self slots:border->getV2PMap()
                       areSorted:N
                            func:[self compareSlotFunction]
                            info:&data];
        }
        [self sortInfoDone:&data];
    }
    
    return sorted;
}

- (BOOL)columnsAreSorted { return [self slotsAreSorted:MISC_COL_BORDER]; }
- (BOOL)rowsAreSorted    { return [self slotsAreSorted:MISC_ROW_BORDER]; }


//-----------------------------------------------------------------------------
// - border:compareSlots::info:
//-----------------------------------------------------------------------------
- (int)border:(MiscBorderType)b compareSlots:(int)slot1 :(int)slot2
         info:(MiscSlotSortInfo*)ip
{
    return (*[self compareSlotFunction])( slot1, slot2, ip );
}

- (int)compareColumns:(int)c1 :(int)c2 info:(MiscSlotSortInfo*)ip
{ return [self border:MISC_COL_BORDER compareSlots:c1:c2 info:ip]; }
- (int)compareRows:(int)r1 :(int)r2 info:(MiscSlotSortInfo*)ip
{ return [self border:MISC_ROW_BORDER compareSlots:r1:r2 info:ip]; }


//-----------------------------------------------------------------------------
// - border:compareSlots::
//-----------------------------------------------------------------------------
- (int)border:(MiscBorderType)b compareSlots:(int)slot1 :(int)slot2
{
    int rc = 0;
    MiscSlotSortInfo sort_info;
    [self sortInfoInit:&sort_info border:b];
    if (sort_info.num_entries > 0)
        rc = [self border:b compareSlots:slot1:slot2 info:&sort_info];
    [self sortInfoDone:&sort_info];
    return rc;
}

- (int)compareColumns:(int)c1 :(int)c2
{ return [self border:MISC_COL_BORDER compareSlots:c1:c2]; }
- (int)compareRows:(int)r1 :(int)r2
{ return [self border:MISC_ROW_BORDER compareSlots:r1:r2]; }


//-----------------------------------------------------------------------------
// - border:sortSlot:
//	NOTE *1* If the destination is at a higher index than the source,
//	then the destination index needs to be decremented by one to
//	reflect the fact that the contents of the "from" slot will be
//	removed, (and all following slots will be shifted down by one
//	position) before the insertion will take place.
//-----------------------------------------------------------------------------
- (BOOL)border:(MiscBorderType)b sortSlot:(int)pslot
{
    BOOL moved = NO;

    int const N = [self numberOfSlots:b];		// Number of "rows"

    if (N > 1)
    {
        MiscSlotSortInfo sort_info;
        [self sortInfoInit:&sort_info border:b];
        if (sort_info.num_entries > 0)
        {
            MiscCompareSlotFunc func = [self compareSlotFunction];
            
            int const vslot = [self border:b slotPosition:pslot];
            int const prev = (vslot > 0 ?
                              [self border:b slotAtPosition:vslot - 1] : -1);
            int const next = (vslot < N - 1 ?
                              [self border:b slotAtPosition:vslot + 1] : N);
            
            int adjust = 0;		// NOTE *1*
            int lo = vslot;
            int hi = vslot - 1;

            if (prev >= 0 && (*func)( pslot, prev, &sort_info ) < 0)
            {
                lo = 0;
                hi = vslot - 2;
            }
            else if (next < N && (*func)( pslot, next, &sort_info) > 0)
            {
                adjust = -1;		// NOTE *1*
                lo = vslot + 1;
                hi = N - 1;
            }

            while (lo <= hi)	// Binary search.
            {
                int const mid = (lo + hi) >> 1;
                int const n = [self border:b slotAtPosition:mid];
                int const cmp = (*func)( pslot, n, &sort_info );
                if (cmp < 0)
                    hi = mid - 1;
                else
                    lo = mid + 1;
            }

            if (lo != vslot)
            {
                [self border:b moveSlot:vslot toSlot:lo + adjust];	// *1*
                [self setNeedsDisplay:YES];
                moved = YES;
            }
        }
        [self sortInfoDone:&sort_info];
    }

    return moved;
}

- (BOOL)sortColumn:(int)n { return [self border:MISC_COL_BORDER sortSlot:n]; }
- (BOOL)sortRow:(int)n    { return [self border:MISC_ROW_BORDER sortSlot:n]; }


//-----------------------------------------------------------------------------
// - border:slotIsSorted:
//-----------------------------------------------------------------------------
- (BOOL)border:(MiscBorderType)b slotIsSorted:(int)pslot
{
    BOOL sorted = YES;
    int const N = [self numberOfSlots:b];		// Number of "rows".

    if (N > 1)
    {
        MiscSlotSortInfo data;
        [self sortInfoInit:&data border:b];
        if (data.num_entries > 0)
        {
            MiscCompareSlotFunc func = [self compareSlotFunction];
            
            int const vslot = [self border:b slotPosition:pslot];
            int const prev = (vslot > 0 ?
                              [self border:b slotAtPosition:vslot - 1] : -1);
            int const next = (vslot < N - 1 ?
                              [self border:b slotAtPosition:vslot + 1] : N);

            if (prev >= 0 && (*func)( prev, pslot, &data ) > 0)
                sorted = NO;

            else if (next < N && (*func)( pslot, next, &data ) > 0)
                sorted = NO;
        }
        [self sortInfoDone:&data];
    }

    return sorted;
}

- (BOOL)columnIsSorted:(int)n
{ return [self border:MISC_COL_BORDER slotIsSorted:n]; }
- (BOOL)rowIsSorted:(int)n
{ return [self border:MISC_ROW_BORDER slotIsSorted:n]; }


//-----------------------------------------------------------------------------
// autoSort
//-----------------------------------------------------------------------------
- (BOOL)autoSortSlots:(MiscBorderType)b
{ return info[b]->autoSort; }
- (void)border:(MiscBorderType)b setAutoSortSlots:(BOOL)flag
{
    if (info[b]->autoSort != flag)
    {
        info[b]->autoSort = flag;
        MiscBorderInfo const* const ip = info[ MISC_OTHER_BORDER(b) ];
        if (ip->isOn)
        {
            [[self window] invalidateCursorRectsForView:ip->view];
            [ip->view setNeedsDisplay:YES];
        }
    }
}

- (BOOL)autoSortColumns
{ return [self autoSortSlots:MISC_COL_BORDER]; }
- (void)setAutoSortColumns:(BOOL)flag
{ [self border:MISC_COL_BORDER setAutoSortSlots:flag]; }

- (BOOL)autoSortRows
{ return [self autoSortSlots:MISC_ROW_BORDER]; }
- (void)setAutoSortRows:(BOOL)flag
{ [self border:MISC_ROW_BORDER setAutoSortSlots:flag]; }


//-----------------------------------------------------------------------------
// Sort Vector
//-----------------------------------------------------------------------------
- (NSArray*)slotSortVector:(MiscBorderType)b
{
    return info[b]->sort_vector;
}

- (void)border:(MiscBorderType)b setSlotSortVector:(NSArray*)v
{
    MiscBorderInfo* const ip = info[b];
    if (ip->sort_vector != 0)
        [ip->sort_vector autorelease];
    if (v == 0 || [v count] == 0)
        ip->sort_vector = 0;
    else
    {
        ip->sort_vector = [v retain];
        [self border:MISC_OTHER_BORDER(b) setAutoSortSlots:NO];
    }
}

- (NSArray*)columnSortVector
{ return [self slotSortVector:MISC_COL_BORDER]; }
- (void)setColumnSortVector:(NSArray*)v
{ [self border:MISC_COL_BORDER setSlotSortVector:v]; }

- (NSArray*)rowSortVector
{ return [self slotSortVector:MISC_ROW_BORDER]; }
- (void)setRowSortVector:(NSArray*)v
{ [self border:MISC_ROW_BORDER setSlotSortVector:v]; }



//-----------------------------------------------------------------------------
// Sort Function
//-----------------------------------------------------------------------------
- (MiscCompareEntryFunc)border:(MiscBorderType)b slotSortFunction:(int)n
{ return info[b]->border->getSortFunc_P(n); }
- (void)border:(MiscBorderType)b setSlot:(int)n
  sortFunction:(MiscCompareEntryFunc)x
{ info[b]->border->setSortFunc_P(n,x); }

- (MiscCompareEntryFunc)columnSortFunction:(int)n
{ return [self border:MISC_COL_BORDER slotSortFunction:n]; }
- (void)setColumn:(int)n sortFunction:(MiscCompareEntryFunc)x
{ [self border:MISC_COL_BORDER setSlot:n sortFunction:x]; }

- (MiscCompareEntryFunc)rowSortFunction:(int)n
{ return [self border:MISC_ROW_BORDER slotSortFunction:n]; }
- (void)setRow:(int)n sortFunction:(MiscCompareEntryFunc)x
{ [self border:MISC_ROW_BORDER setSlot:n sortFunction:x]; }



//-----------------------------------------------------------------------------
// Sort Direction
//-----------------------------------------------------------------------------
- (MiscSortDirection)border:(MiscBorderType)b slotSortDirection:(int)n
{ return info[b]->border->getSortDirection_P(n); }
- (void)border:(MiscBorderType)b setSlot:(int)n
 sortDirection:(MiscSortDirection)x
{
    if ((unsigned int)x <= (unsigned int)MISC_SORT_DIR_MAX &&
        x != info[b]->border->getSortDirection_P(n))
    {
        info[b]->border->setSortDirection_P(n,x);
        MiscBorderInfo const* const ip = info[MISC_OTHER_BORDER(b)];
        if (ip->isOn && ip->autoSort)
        {		// FIXME: Just draw the part needed.
            [ip->view setNeedsDisplay:YES];
        }
    }
}

- (MiscSortDirection)columnSortDirection:(int)n
{ return [self border:MISC_COL_BORDER slotSortDirection:n]; }
- (void)setColumn:(int)n sortDirection:(MiscSortDirection)x
{ [self border:MISC_COL_BORDER setSlot:n sortDirection:x]; }

- (MiscSortDirection)rowSortDirection:(int)n
{ return [self border:MISC_ROW_BORDER slotSortDirection:n]; }
- (void)setRow:(int)n sortDirection:(MiscSortDirection)x
{ [self border:MISC_ROW_BORDER setSlot:n sortDirection:x]; }



//-----------------------------------------------------------------------------
// Sort Type
//-----------------------------------------------------------------------------
- (MiscSortType)border:(MiscBorderType)b slotSortType:(int)n;
{ return info[b]->border->getSortType_P(n); }
- (void)border:(MiscBorderType)b setSlot:(int)n
      sortType:(MiscSortType)x
{
    if ((unsigned int)x <= (unsigned int)MISC_SORT_TYPE_MAX)
        info[b]->border->setSortType_P(n,x);
}

- (MiscSortType)columnSortType:(int)n
{ return [self border:MISC_COL_BORDER slotSortType:n]; }
- (void)setColumn:(int)n sortType:(MiscSortType)x
{ [self border:MISC_COL_BORDER setSlot:n sortType:x]; }

- (MiscSortType)rowSortType:(int)n
{ return [self border:MISC_ROW_BORDER slotSortType:n]; }
- (void)setRow:(int)n sortType:(MiscSortType)x
{ [self border:MISC_ROW_BORDER setSlot:n sortType:x]; }

@end
