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
// MiscTableBorder.cc
//
//	Structure describing border of an MiscTableView.
//
//	NOTE: many of the sub-arrays in an MiscTableBorder are conditional.
//	They are not guaranteed to be allocated for every instance.  They are
//	only allocated when the caller tries to store a value in them.
//
//	FIXME: Optimization: separate slot-offset calculations from
//	resizing calculations.	Many situations only require an offset-
//	update, not a full size recalc.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableBorder.cc,v 1.30 99/06/15 02:41:05 sunshine Exp $
// $Log:	MiscTableBorder.cc,v $
// Revision 1.30  99/06/15  02:41:05  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Added support for slot-wise "represented objects".
// Fixed bug: setPrototype_P() failed to retain the new prototype.
// 
// Revision 1.29  1998/03/29 23:47:03  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public headers.
// Now uses MISC_FRAME_HEIGHT rather than hard-coded "18".
//
//  Revision 1.28  98/03/23  21:39:45  sunshine
//  v137.1: Added clearSortDirection().
//-----------------------------------------------------------------------------
#ifdef __GNUC__
# pragma implementation
#endif
#include "MiscTableBorder.h"
#include "MiscTableScrollPrivate.h"
#include "MiscTableUtil.h"
#include <MiscTableScroll/MiscTableScroll.h>
#include <MiscTableScroll/MiscTableCell.h>
#import <AppKit/NSCell.h>
#import <AppKit/NSButtonCell.h>
#import <AppKit/NSImage.h>
#include <cmath>
#include <cstdlib>
#include <cstring>

#define MISC_SWAP(T,V,X,Y)\
	if ((V) != 0) { T const t = (V)[X]; (V)[X] = (V)[Y]; (V)[Y] = t; }

#define MISC_SIZE_CHECK(X)\
	do {\
	NSCParameterAssert( 0 <= X );\
	NSCParameterAssert( X <= MISC_MAX_PIXELS_SIZE );\
	} while(0)

#define MISC_RANGE_CHECK(X)\
	NSCParameterAssert( 0 <= X );  NSCParameterAssert( X < num_slots )
#define MISC_RANGE_CHECK_1(X)\
	NSCParameterAssert( 0 <= X );  NSCParameterAssert( X <= num_slots )

#define MISC_SLOT_MEMBER(X,M)	((slots != 0) ? slots[X].M : def_slot.M)
#define MISC_SET_SLOT_MEMBER(X,N,M)\
	do {\
	needs_recalc = true;\
	if (slots == 0) alloc_slots();\
	slots[X].M = N;\
	} while (0)

#define MISC_MAP(M,I)	(((M) != 0) ? (M)[I] : I)

#define	MISC_DEF_SORT_DIR	MISC_SORT_ASCENDING
#define	MISC_DEF_SORT_TYPE	MISC_SORT_STRING_CASE_INSENSITIVE
#define MISC_DEF_SORT_INFO	((MISC_DEF_SORT_TYPE << 1) | \
					(MISC_DEF_SORT_DIR & 1))

//-----------------------------------------------------------------------------
// global_grow
//-----------------------------------------------------------------------------
void MiscTableBorder::global_grow( MiscPixels total_size )
{
    MiscPixels offset = 0;
    MiscPixels deficit = min_total_size - total_size;
    MiscPixels const adj = deficit / num_springy;
    int nextra = (int) (deficit - adj * num_springy);
    for (int i = 0; i < num_slots; i++)
    {
        MiscTableSlot& r = slots[i];
        if (r.isSpringy())
        {
            MiscPixels delta = adj;
            if (nextra > 0)
            {
                nextra--;
                delta++;
            }
            r.adj_size = r.size + delta;
        }
        r.offset = offset;
        offset += r.adj_size;
    }
}


//-----------------------------------------------------------------------------
// perform_recalc
//-----------------------------------------------------------------------------
void MiscTableBorder::perform_recalc()
{
    MISC_SIZE_CHECK( min_total_size );

    int i;
    MiscPixels total_size = 0;

    if (slots == 0)
        alloc_slots();

    for (i = 0;	 i < num_slots;	 i++)
    {
        MiscTableSlot& r = slots[i];
        NSCParameterAssert( 0 <= r.min_size );
        NSCParameterAssert( r.min_size <= r.size );
        NSCParameterAssert( r.size <= r.max_size );
        NSCParameterAssert( r.max_size <= MISC_MAX_PIXELS_SIZE );
        r.offset = total_size;
        r.adj_size = r.size;
        total_size += r.adj_size;
    }

    if (total_size < min_total_size && num_springy > 0)
        global_grow( total_size );
}


//-----------------------------------------------------------------------------
// do_recalc
//-----------------------------------------------------------------------------
void MiscTableBorder::do_recalc()
{
    needs_recalc = false;
    if (uniform_size == 0 && num_slots > 0)
        perform_recalc();
}


//-----------------------------------------------------------------------------
// recalc_if_needed
//-----------------------------------------------------------------------------
inline void MiscTableBorder::recalc_if_needed()
{
    if (needs_recalc)
        do_recalc();
}


//-----------------------------------------------------------------------------
// recalcOffsets
//-----------------------------------------------------------------------------
void MiscTableBorder::recalcOffsets()
{
    needs_recalc = true;
    recalc_if_needed();
}


//-----------------------------------------------------------------------------
// alloc_size
//-----------------------------------------------------------------------------
inline int MiscTableBorder::alloc_size( int rec_size )
    { return rec_size * max_slots; }


//-----------------------------------------------------------------------------
// do_alloc
//-----------------------------------------------------------------------------
void* MiscTableBorder::do_alloc( int size )
{ return malloc( alloc_size(size) ); }


//-----------------------------------------------------------------------------
// do_alloc_init
//-----------------------------------------------------------------------------
void* MiscTableBorder::do_alloc_init( int size )
{
    int const nbytes = alloc_size( size );
    void* const p = malloc( nbytes );
    memset( p, 0, nbytes );
    return p;
}


//-----------------------------------------------------------------------------
// do_realloc
//-----------------------------------------------------------------------------
void* MiscTableBorder::do_realloc( void* p, int size )
{
    if (p != 0)
    {
        if (max_slots != 0)
        {
            p = realloc( p, max_slots * size );
        }
        else
        {
            free( p );
            p = 0;
        }
    }
    return p;
}


//-----------------------------------------------------------------------------
// do_realloc
//-----------------------------------------------------------------------------
void MiscTableBorder::do_realloc()
{
    slots  = (MiscTableSlot*) do_realloc( slots, sizeof(*slots) );
    v2p	   = (MiscCoord_P*) do_realloc( v2p, sizeof(*v2p) );
    p2v	   = (MiscCoord_V*) do_realloc( p2v, sizeof(*p2v) );
    tags   = (NSInteger*) do_realloc( tags, sizeof(*tags) );
    rep_objs = (id*) do_realloc( rep_objs, sizeof(*rep_objs) );
    titles = (NSString**) do_realloc( titles, sizeof(*titles) );
    styles = (MiscTableCellStyle*) do_realloc( styles, sizeof(*styles) );
    prototypes = (id*) do_realloc( prototypes, sizeof(*prototypes) );
    sort_funcs = (MiscCompareEntryFunc*)
    do_realloc( sort_funcs, sizeof(*sort_funcs) );
    sort_info = (int*) do_realloc(sort_info,sizeof(*sort_info));
}


//-----------------------------------------------------------------------------
// freeExtraCapacity
//-----------------------------------------------------------------------------
void MiscTableBorder::freeExtraCapacity()
{
    if (max_slots > num_slots)
    {
        max_slots = num_slots;
        do_realloc();
    }
}


//-----------------------------------------------------------------------------
// setCapacity
//-----------------------------------------------------------------------------
void MiscTableBorder::setCapacity( int x )
{
    if (max_slots < x)
    {
        max_slots = x;
        do_realloc();
    }
}


//-----------------------------------------------------------------------------
// empty
//-----------------------------------------------------------------------------
void MiscTableBorder::empty()
{
    setCount(0);
    selectNone();
    clearCursor();
    clearClickedSlot();
}


//-----------------------------------------------------------------------------
// DELETE
//-----------------------------------------------------------------------------
void MiscTableBorder::destroy_slot( MiscCoord_V x, MiscCoord_P p )
{
    if (isSpringy(x)) num_springy--;
    if (rep_objs != 0 && rep_objs[p] != 0)	[rep_objs[p] release];
    if (titles != 0 && titles[p] != 0)		[titles[p] release];
    if (prototypes != 0 && prototypes[p] != 0)	[prototypes[p] release];
}


void MiscTableBorder::do_delete( void* p, int n, int i )
{
    if (p != 0)
        memmove( (void*)((uintptr_t)p + i * n), (const void*)((uintptr_t)p + (i + 1) * n), (num_slots - i) * n );
}


void MiscTableBorder::do_delete( MiscCoord_V x, MiscCoord_P p )
{
    if (x < num_slots)
    {
        do_delete( slots, sizeof(*slots), x );
        do_delete( v2p, sizeof(*v2p), x );
    }
    if (p < num_slots)
    {
        do_delete( tags, sizeof(*tags), p );
        do_delete( rep_objs, sizeof(*rep_objs), p );
        do_delete( titles, sizeof(*titles), p );
        do_delete( styles, sizeof(*styles), p );
        do_delete( prototypes, sizeof(*prototypes), p );
        do_delete( sort_funcs, sizeof(*sort_funcs), p );
        do_delete( sort_info, sizeof(*sort_info), p );
        do_delete( p2v, sizeof(*p2v), p );
    }
}


void MiscTableBorder::deleteAt( MiscCoord_V x )
{
    MISC_RANGE_CHECK( x );
    
    selection.shiftDownAt( x );
    if (num_slots <= 1 || num_slots <= getCursor() + 1)
        clearCursor();
    if (num_slots <= 1 || num_slots <= clickedSlot() + 1)
        clearClickedSlot();
    
    needs_recalc = true;
    
    MiscCoord_P const p = visualToPhysical(x);
    
    destroy_slot( x, p );
    
    num_slots--;
    do_delete( x, p );
    
    if (v2p != 0)
    {
        for (int i = 0;	 i < num_slots;	 i++)
        {
            if (v2p[i] >= p)
                v2p[i]--;
            if (p2v[i] >= x)
                p2v[i]--;
        }
    }
    fixSelectedSlot();
}


//-----------------------------------------------------------------------------
// INSERT
//-----------------------------------------------------------------------------
void MiscTableBorder::init_slot( MiscCoord_V x, MiscCoord_P p )
{
    if (def_slot.isSpringy())
        num_springy++;
    
    if (slots != 0)		slots[x] = def_slot;
    if (tags != 0)		tags[p] = def_tag;
    if (rep_objs != 0)		rep_objs[p] = 0;
    if (titles != 0)		titles[p] = 0;
    if (styles != 0)		styles[p] = def_style;
    if (prototypes != 0)	prototypes[p] = 0;
    if (sort_funcs != 0)	sort_funcs[p] = 0;
    if (sort_info != 0)		sort_info[p] = MISC_DEF_SORT_INFO;
    
    if (v2p != 0)
    {
        v2p[x] = p;
        p2v[p] = x;
    }
}


void MiscTableBorder::do_insert( void* p, int n, int i )
{
    if (p != 0)
        memmove( (void*)((uintptr_t)p + (i + 1) * n), (const void*)((uintptr_t)p + i * n), (num_slots - i) * n );
}


void MiscTableBorder::do_insert( MiscCoord_V x, MiscCoord_P p )
{
    if (x < num_slots)
    {
        do_insert( slots, sizeof(*slots), x );
        do_insert( v2p, sizeof(*v2p), x );
    }
    if (p < num_slots)
    {
        do_insert( titles, sizeof(*titles), p );
        do_insert( tags, sizeof(*tags), p );
        do_insert( rep_objs, sizeof(*rep_objs), p );
        do_insert( styles, sizeof(*styles), p );
        do_insert( prototypes, sizeof(*prototypes), p );
        do_insert( sort_funcs, sizeof(*sort_funcs), p );
        do_insert( sort_info, sizeof(*sort_info), p );
        do_insert( p2v, sizeof(*p2v), p );
    }
}


void MiscTableBorder::insertAt( MiscCoord_V x, MiscCoord_P p )
{
    MISC_RANGE_CHECK_1( x );
    
    needs_recalc = true;
    
    if (num_slots >= max_slots)
        setCapacity( max_slots + 1 );
    
    do_insert( x, p );
    
    if (v2p != 0)
    {
        for (int i = 0;	 i < num_slots;	 i++)
        {
            if (p2v[i] >= x)
                p2v[i]++;
            if (v2p[i] >= p)
                v2p[i]++;
        }
    }
    
    init_slot( x, p );
    
    num_slots++;
    
    selection.shiftUpAt( x );
    if (selected_slot >= x)
        selected_slot++;
    if (hasValidCursor() && cursor >= x)
        cursor++;
    if (clicked_slot >= x)
        clicked_slot++;
}


//-----------------------------------------------------------------------------
// do_shift
//-----------------------------------------------------------------------------
void MiscTableBorder::do_shift( void* p, int n, int i, int j )
{
    if (p != 0) {
        if (i < j) {
            memmove( (void*)((uintptr_t)p + i * n), (const void*)((uintptr_t)p + (i + 1) * n), (j - i) * n );
        } else {
            memmove( (void*)((uintptr_t)p + (j  + 1) * n), (const void*)((uintptr_t)p + j * n), (i - j) * n );
        }
    }
}


//-----------------------------------------------------------------------------
// do_shift
//-----------------------------------------------------------------------------
void MiscTableBorder::do_shift( MiscCoord_V from, MiscCoord_V to )
{
    do_shift( slots, sizeof(*slots), from, to );
    do_shift( v2p, sizeof(*v2p), from, to );
}


//-----------------------------------------------------------------------------
// alloc_vmap
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_vmap()
{
    p2v = (MiscCoord_V*) do_alloc( sizeof(*p2v) );
    v2p = (MiscCoord_P*) do_alloc( sizeof(*v2p) );
    for (int i = 0;  i < num_slots;  i++)
    { p2v[i] = i; v2p[i] = i; }
}


//-----------------------------------------------------------------------------
// moveFromTo
//-----------------------------------------------------------------------------
void MiscTableBorder::moveFromTo( MiscCoord_V from, MiscCoord_V to )
{
    MISC_RANGE_CHECK( from ); MISC_RANGE_CHECK( to );
    
    bool const was_cursor	 = (cursor == from);
    bool const was_clicked_slot  = (clicked_slot == from);
    bool const was_selected_slot = (selected_slot == from);
    bool const was_selected	 = selection.contains( from );
    selection.shiftDownAt( from );

    needs_recalc = true;

    MiscCoord_P const p = visualToPhysical( from );
    MiscTableSlot const tmp_slot = slots ? slots[from] : def_slot;

    if (p2v == 0)
        alloc_vmap();

    do_shift( from, to );

    if (from < to)
    {
        for (int i = 0;	 i < num_slots;	 i++)
            if (from < p2v[i] && p2v[i] <= to)
                p2v[i]--;
        if (!was_cursor && from <= cursor && cursor >= to)
            cursor--;
    }
    else
    {
        for (int i = 0;	 i < num_slots;	 i++)
            if (to <= p2v[i] && p2v[i] < from)
                p2v[i]++;
        if (!was_cursor && from <= cursor && cursor >= to)
            cursor++;
    }
    p2v[p] = to;
    v2p[to] = p;

    if (slots != 0) slots[to]  = tmp_slot;

    selection.shiftUpAt( to );
    if (was_selected)		selection.add( to );
    if (was_selected_slot)	setSelectedSlot( to );
    if (was_clicked_slot)	setClickedSlot( to );
    if (was_cursor)		cursor = to;
}


//-----------------------------------------------------------------------------
// setCount
//-----------------------------------------------------------------------------
void MiscTableBorder::setCount( int x )
{
    setP2VMap(0);
    if (num_slots != x)
    {
        needs_recalc = true;
        int const old_slots = num_slots;
        num_slots = x;
        setCapacity( x );	// Only increases capacity, never decreases.
        
        if (old_slots < num_slots)
        {
            for (int i = old_slots;  i < num_slots;  i++)
                init_slot( i, i );
        }
        else
        {
            NSCParameterAssert( old_slots <= max_slots );
            num_slots = old_slots;
            for (int i = x;  i < old_slots;  i++)
                destroy_slot( i, visualToPhysical(i) );
            num_slots = x;
            
            selection.remove( num_slots, old_slots );
            if (selectedSlot() >= num_slots)	fixSelectedSlot();
            if (cursor >= num_slots)		clearCursor();
            if (clicked_slot >= num_slots)	clearClickedSlot();
        }
    }
}


//-----------------------------------------------------------------------------
// good_map
//	'map' is a good map if all the values are in-range, and no value
//	is repeated.  A null map represents a normal sequential series.
//	'onescomp' interprets negative values as the one's complement of a
//	slot number.
//-----------------------------------------------------------------------------
bool MiscTableBorder::good_map( int const* map, bool onescomp ) const
{
    bool answer = true;
    int const lim = count();
    if (lim > 0)
    {
        if (map != 0)
        {
            bool* seen = (bool*) calloc( sizeof(bool), lim );
            for (int i = 0;  i < lim;  i++)
            {
                int x = map[i];
                if (onescomp && x < 0)
                    x = ~x;
                if ((unsigned int) x < (unsigned int)lim && !seen[i])
                    seen[i] = true;
                else
                {
                    answer = false;
                    break;
                }
            }
            free( seen );
        }
    }
    return answer;
}


//-----------------------------------------------------------------------------
// do_remap
//-----------------------------------------------------------------------------
void* MiscTableBorder::do_remap( void* p, int n, MiscCoord_V const* new_p2v )
{
    if (p != 0)
    {
        void* t = do_alloc( n );
        for (int i = 0;	 i < num_slots;	 i++)
            memcpy( (void*)((uintptr_t)t + MISC_MAP(new_p2v,i) * n),
                   (const void*)((uintptr_t)p + MISC_MAP(p2v,i) * n), n );
        free( p );
        p = t;
    }
    return p;
}


//-----------------------------------------------------------------------------
// do_remap
//-----------------------------------------------------------------------------
void MiscTableBorder::do_remap( MiscCoord_V const* new_p2v )
{
    if (num_slots > 0)
        slots = (MiscTableSlot*) do_remap( slots, sizeof(*slots), new_p2v );
}


//-----------------------------------------------------------------------------
// setP2VMap
//-----------------------------------------------------------------------------
bool MiscTableBorder::setP2VMap( MiscCoord_V const* new_p2v )
{
    if (good_map( (int const*) new_p2v, false ))
    {
        if (new_p2v != 0 || p2v != 0)
        {
            MiscSparseSet p_sel;
            visualToPhysical( selection, p_sel );
            MiscCoord_P const p_selSlot =
            (selected_slot >= 0 ?
             visualToPhysical(selected_slot) : -1);

            needs_recalc = true;
            do_remap( new_p2v );
            if (p2v == 0)
            {
                p2v = (MiscCoord_V*) do_alloc( sizeof(*p2v) );
                v2p = (MiscCoord_P*) do_alloc( sizeof(*v2p) );
            }
            if (new_p2v != 0 && p2v != 0)
            {
                for (int i = 0;  i < num_slots;  i++)
                    v2p[new_p2v[i]] = i;
                memcpy( p2v, new_p2v, num_slots * sizeof(*p2v) );
            }
            else if (new_p2v == 0)
            {
                free( p2v );  p2v = 0;
                free( v2p );  v2p = 0;
            }

            physicalToVisual( p_sel, selection );
            selected_slot = (p_selSlot >= 0 ? physicalToVisual(p_selSlot) : -1);
        }
        return true;
    }
    return false;
}


//-----------------------------------------------------------------------------
// setV2PMap
//-----------------------------------------------------------------------------
bool MiscTableBorder::setV2PMap( MiscCoord_P const* new_v2p )
{
    if (good_map( (int const*) new_v2p, false ))
    {
        if (new_v2p != 0 || v2p != 0)
        {
            if (new_v2p != 0)
            {
                MiscCoord_V* new_p2v =
                (MiscCoord_V*) malloc( sizeof(*new_p2v) * num_slots );
                for (int i = 0;  i < num_slots;  i++)
                    new_p2v[new_v2p[i]] = i;
                setP2VMap( new_p2v );
                free( new_p2v );
            }
            else
                setP2VMap( 0 );
        }
        return true;
    }
    return false;
}


//-----------------------------------------------------------------------------
// swapSlots
//-----------------------------------------------------------------------------
void MiscTableBorder::swapSlots( MiscCoord_P x, MiscCoord_P y )
{
    MISC_SWAP( MiscTableSlot, slots, x, y )
    MISC_SWAP( NSInteger, tags, x, y )
    MISC_SWAP( id, rep_objs, x, y )
    MISC_SWAP( NSString*, titles, x, y )
    MISC_SWAP( MiscTableCellStyle, styles, x, y )
    MISC_SWAP( id, prototypes, x, y )
    MISC_SWAP( MiscCompareEntryFunc, sort_funcs, x, y )
    MISC_SWAP( int, sort_info, x, y )
    do_recalc();	// offsets only.
}


//-----------------------------------------------------------------------------
// setUniformSize
//-----------------------------------------------------------------------------
bool MiscTableBorder::setUniformSize( MiscPixels x )
{
    bool const changed = (uniform_size != x);
    if (changed)
    {
        needs_recalc = true;
        if (uniform_size == 0)	// New, non-zero uniform size.
        {
            if (slots != 0)
            { free( slots );  slots = 0; }
            num_springy = 0;
            min_total_size = 0;
        }
        uniform_size = x;
    }
    return changed;
}


//-----------------------------------------------------------------------------
// TOTAL SIZE
//-----------------------------------------------------------------------------
MiscPixels MiscTableBorder::totalSize()
{
    if (num_slots == 0)
        return 0;
    else if (uniform_size != 0)
        return (uniform_size * num_slots);
    else
    {
        recalc_if_needed();
        return getOffset( num_slots - 1 ) + effectiveSize( num_slots - 1 );
    }
}

void MiscTableBorder::setMinTotalSize( MiscPixels x )
{
    if (min_total_size != x)
    {
        min_total_size = x;
        MISC_SIZE_CHECK( min_total_size );
        needs_recalc = true;
    }
}

//-----------------------------------------------------------------------------
// EFFECTIVE SIZE
//-----------------------------------------------------------------------------
MiscPixels MiscTableBorder::effectiveSize( MiscCoord_V x )
{
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return uniform_size;
    recalc_if_needed();
    return MISC_SLOT_MEMBER( x, adj_size );
}


MiscPixels MiscTableBorder::effectiveMinSize( MiscCoord_V x )
{
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return min_uniform_size;

    recalc_if_needed();

    MiscTableSlot const& r = slots[x];
    MiscPixels slot_min = r.min_size;

    MiscPixels global_min = min_total_size;

    for (int i = 0;  i < num_slots;  i++)
    {
        if (i != x)
        {
            MiscTableSlot& t = slots[i];
            if (t.isSpringy())
                global_min -= t.max_size;
            else
                global_min -= t.size;
        }
    }

    if (slot_min < global_min)
        slot_min = global_min;

    if (slot_min > r.adj_size)
        slot_min = r.adj_size;

    return slot_min;
}


//-----------------------------------------------------------------------------
// alloc_slots
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_slots()
{
    NSCParameterAssert( slots == 0 );
    slots = (MiscTableSlot*) do_alloc( sizeof(*slots) );
    for (int i = 0;  i < num_slots;  i++)
        slots[i] = def_slot;
}


//-----------------------------------------------------------------------------
// OFFSETS
//-----------------------------------------------------------------------------
MiscCoord_V MiscTableBorder::find_slot_for_offset( MiscPixels x )
{
    NSCParameterAssert( num_slots > 0 );
    int lo = 0;
    int hi = num_slots - 1;
    while (lo <= hi)
    {
        int const mid = (lo + hi) >> 1;
        if (slots[mid].offset <= x)
            lo = mid + 1;
        else
            hi = mid - 1;
    }
    if (lo > 0 && (lo >= num_slots || slots[lo].offset > x))
        lo--;
    return lo;
}


MiscCoord_V MiscTableBorder::visualForOffset( MiscPixels x )
{
    MiscCoord_V i = -1;
    if (x >= 0 && num_slots > 0)
    {
        if (uniform_size != 0)
        {
            i = (MiscCoord_V) (x / uniform_size);
        }
        else
        {
            recalc_if_needed();
            i = find_slot_for_offset( x );
        }
    }
    if (i >= num_slots)
        i = num_slots - 1;
    return i;
}


MiscPixels MiscTableBorder::getOffset( MiscCoord_V x )
{
    if (num_slots == 0)
        return 0;
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return uniform_size * x;
    recalc_if_needed();
    return MISC_SLOT_MEMBER( x, offset );
}


//-----------------------------------------------------------------------------
// SIZE
//-----------------------------------------------------------------------------
MiscPixels MiscTableBorder::getSize( MiscCoord_V x ) const
{
    if (num_slots == 0)
        return 0;
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return uniform_size;
    return MISC_SLOT_MEMBER( x, size );
}

void MiscTableBorder::setSize( MiscCoord_V x, MiscPixels n )
{
    MISC_RANGE_CHECK( x );
    if (uniform_size == 0)
        MISC_SET_SLOT_MEMBER( x, n, size );
}


MiscPixels MiscTableBorder::getMinSize( MiscCoord_V x ) const
{
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return uniform_size;
    return MISC_SLOT_MEMBER( x, min_size );
}

void MiscTableBorder::setMinSize( MiscCoord_V x, MiscPixels n )
{
    MISC_RANGE_CHECK( x );
    if (uniform_size == 0)
        MISC_SET_SLOT_MEMBER( x, n, min_size );
}


MiscPixels MiscTableBorder::getMaxSize( MiscCoord_V x ) const
{
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return max_uniform_size;
    return MISC_SLOT_MEMBER( x, max_size );
}

void MiscTableBorder::setMaxSize( MiscCoord_V x, MiscPixels n )
{
    MISC_RANGE_CHECK( x );
    if (uniform_size == 0)
        MISC_SET_SLOT_MEMBER( x, n, max_size );
}


//-----------------------------------------------------------------------------
// SIZING
//-----------------------------------------------------------------------------
MiscTableSizing MiscTableBorder::getSizing( MiscCoord_V x ) const
{
    MISC_RANGE_CHECK( x );
    if (uniform_size != 0)
        return MISC_NUSER_NSPRINGY_SIZING;
    return MISC_SLOT_MEMBER( x, sizing );
}

void MiscTableBorder::setSizing( MiscCoord_V x, MiscTableSizing n )
{
    MISC_RANGE_CHECK( x );
    MISC_ENUM_CHECK( n, MISC_MAX_SIZING );
    if (uniform_size == 0)
    {
        bool was_springy = ::isSpringy(getSizing(x));
        bool is_springy = ::isSpringy(n);
        if (was_springy != is_springy)
        {
            if (was_springy)
                num_springy--;
            else
                num_springy++;
            needs_recalc = true;
        }
        MISC_SET_SLOT_MEMBER( x, n, sizing );
    }
}


//-----------------------------------------------------------------------------
// TITLES
//-----------------------------------------------------------------------------
void MiscTableBorder::dealloc_titles()
{
    if (titles != 0)
    {
        for (int i = 0;  i < num_slots;  i++)
            if (titles[i] != 0)
                [titles[i] release];
        free( titles );
        titles = 0;
    }
}

void MiscTableBorder::alloc_titles()
{ titles = (NSString**) do_alloc_init( sizeof(*titles) ); }

bool MiscTableBorder::setTitle_P( MiscCoord_P x, NSString* s )
{
    bool changed = false;
    if (getTitleMode() == MISC_CUSTOM_TITLE)
    {
        MISC_RANGE_CHECK( x );
        NSString* const t = (titles ? titles[x] : 0);
        if (t != 0 || s != 0)
        {
            if (t == 0 || s == 0 || ![t isEqualToString:s])
            {
                if (t != 0) [t autorelease];
                if (titles == 0) alloc_titles();
                titles[x] = [s copy];
                changed = true;
            }
        }
    }
    return changed;
}

static inline void prepend_char( NSMutableString* s, char const c )
{
    NSString* cs = [NSString stringWithFormat:@"%c", c];
    [s insertString:cs atIndex:0];
}

static NSString* alpha_title( int x )
{
    NSMutableString* s = [[[NSMutableString alloc] init] autorelease];
    if (x >= 26)
    {
        do  {
            prepend_char( s, (x % 26) + 'A' );
            x /= 26;
        }
        while (x >= 26);
        x--;
    }
    prepend_char( s, x + 'A' );
    return s;
}

NSString* MiscTableBorder::getTitle_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    NSString* s = @"";
    switch (title_mode)
    {
        case MISC_NO_TITLE:
            break;
        case MISC_NUMBER_TITLE:
            s = [[NSNumber numberWithInt:x + 1] description];
            break;
        case MISC_ALPHA_TITLE:
            s = alpha_title(x);
            break;
        case MISC_CUSTOM_TITLE:
            s = (titles != 0) ? (titles[x] != 0 ? titles[x] : @"") : @"";
            break;
        case MISC_DELEGATE_TITLE:
            s = [owner border:type getDelegateSlotTitle:x];
            break;
    }
    return s;
}

bool MiscTableBorder::setTitleMode( MiscTableTitleMode x )
{
    MISC_ENUM_CHECK( x, MISC_MAX_TITLE );
    bool const changed = (title_mode != x);
    if (changed)
    {
        dealloc_titles();
        title_mode = x;
    }
    return changed;
}


//-----------------------------------------------------------------------------
// TAGS
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_tags()
{
    tags = (NSInteger*) do_alloc_init( sizeof(*tags) );
    if (def_tag != 0)
        for (int i = 0;	 i < num_slots;	 i++)
            tags[i] = def_tag;
}

void MiscTableBorder::setTag_P( MiscCoord_P x, NSInteger n )
{
    MISC_RANGE_CHECK( x );
    if (tags == 0) alloc_tags();
    tags[x] = n;
}

NSInteger MiscTableBorder::getTag_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    return (tags != 0) ? tags[x] : def_tag;
}


//-----------------------------------------------------------------------------
// REPRESENTED OBJECTS
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_represented_objects()
{ rep_objs = (id*) do_alloc_init( sizeof(*rep_objs) ); }

void MiscTableBorder::setRepresentedObject_P( MiscCoord_P x, id n )
{
    MISC_RANGE_CHECK( x );
    if (rep_objs == 0) alloc_represented_objects();
    if (rep_objs[x] != 0)
        [rep_objs[x] autorelease];
    rep_objs[x] = [n retain];
}

id MiscTableBorder::getRepresentedObject_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    return (rep_objs != 0) ? rep_objs[x] : 0;
}


//-----------------------------------------------------------------------------
// STYLES
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_styles()
{
    styles = (MiscTableCellStyle*) do_alloc_init( sizeof(*styles) );
    if ((int) def_style != 0)
        for (int i = 0;	 i < num_slots;	 i++)
            styles[i] = def_style;
}

void MiscTableBorder::setStyle_P( MiscCoord_P x, MiscTableCellStyle n )
{
    MISC_RANGE_CHECK( x );
    MISC_ENUM_CHECK( n, MISC_TABLE_CELL_MAX );
    if (styles == 0) alloc_styles();
    styles[x] = n;
}

MiscTableCellStyle MiscTableBorder::getStyle_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    return (styles != 0) ? styles[x] : def_style;
}


//-----------------------------------------------------------------------------
// PROTOTYPES
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_prototypes()
    { prototypes = (id*) do_alloc_init( sizeof(*prototypes) ); }

id MiscTableBorder::new_prototype( MiscCoord_P x )
{
    NSZone* const zone = [owner zone];
    id p = 0;
    switch (getStyle_P(x))
    {
        case MISC_TABLE_CELL_TEXT:
            p = [[MiscTableCell allocWithZone:zone] initTextCell:@""];
            break;
        case MISC_TABLE_CELL_IMAGE:
            p = [[MiscTableCell allocWithZone:zone] initImageCell:
                 [[NSImage alloc] initWithSize:NSZeroSize]];
            break;
        case MISC_TABLE_CELL_BUTTON:
            p = [[NSButtonCell allocWithZone:zone] initTextCell:@""];
            break;
        case MISC_TABLE_CELL_CALLBACK:
            p = [[owner border:type getDelegateSlotPrototype:x] retain];
            break;
    }
    return [p autorelease];
}

id MiscTableBorder::getPrototype_P( MiscCoord_P x )
{
    MISC_RANGE_CHECK( x );
    if (prototypes == 0)
        alloc_prototypes();
    id p = prototypes[x];
    if (p == 0)
        p = prototypes[x] = [new_prototype(x) retain];
    return p;
}

void MiscTableBorder::setPrototype_P( MiscCoord_P x, id n )
{
    MISC_RANGE_CHECK( x );
    if (prototypes == 0) alloc_prototypes();
    if (prototypes[x] != 0)
        [prototypes[x] autorelease];
    prototypes[x] = [n retain];
}


//-----------------------------------------------------------------------------
// SORT FUNCTIONS
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_sort_funcs()
{
    sort_funcs = (MiscCompareEntryFunc*) do_alloc_init( sizeof(*sort_funcs) );
}

void MiscTableBorder::setSortFunc_P( MiscCoord_P x, MiscCompareEntryFunc n )
{
    MISC_RANGE_CHECK( x );
    if (sort_funcs == 0) alloc_sort_funcs();
    sort_funcs[x] = n;
}

MiscCompareEntryFunc MiscTableBorder::getSortFunc_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    return (sort_funcs != 0) ? sort_funcs[x] : 0;
}


//-----------------------------------------------------------------------------
// SORT INFO (TYPE + DIR)
//-----------------------------------------------------------------------------
void MiscTableBorder::alloc_sort_info()
{ sort_info = (int*) do_alloc_init( sizeof(*sort_info) ); }

void MiscTableBorder::setSortType_P( MiscCoord_P x, MiscSortType n )
{
    MISC_RANGE_CHECK( x );
    MISC_ENUM_CHECK( n, MISC_SORT_TYPE_MAX );
    if (sort_info == 0) alloc_sort_info();
    int const z = sort_info[x];			// Preserve direction.
    sort_info[x] = ((n << 1) | (z & 1));
}

MiscSortType MiscTableBorder::getSortType_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    return (sort_info != 0) ? MiscSortType( sort_info[x] >> 1 ) :
    MISC_SORT_STRING_CASE_INSENSITIVE;
}

void MiscTableBorder::setSortDirection_P( MiscCoord_P x, MiscSortDirection n )
{
    MISC_RANGE_CHECK( x );
    MISC_ENUM_CHECK( n, MISC_SORT_DIR_MAX );
    if (sort_info == 0) alloc_sort_info();
    int const z = sort_info[x];			// Preserve type.
    sort_info[x] = ((z & ~1) | (n & 1));
}

MiscSortDirection MiscTableBorder::getSortDirection_P( MiscCoord_P x ) const
{
    MISC_RANGE_CHECK( x );
    return (sort_info != 0) ? MiscSortDirection( sort_info[x] & 1 ) :
    MISC_SORT_ASCENDING;
}

void MiscTableBorder::clearSortDirection()	// Set all slots to ascending.
{
    if (sort_info != 0)
    {
        int const* const plim = sort_info + count();
        for (int* p = sort_info; p < plim; p++)
            *p &= ~1;
    }
}


//-----------------------------------------------------------------------------
// DESTRUCTOR / CONSTRUCTOR
//-----------------------------------------------------------------------------
MiscTableBorder::~MiscTableBorder()	{ emptyAndFree(); }
MiscTableBorder::MiscTableBorder( MiscBorderType x )
{
    MISC_ENUM_CHECK( x, MISC_MAX_BORDER );
    memset( this, 0, sizeof(*this) );
    type = x;
    clearSelectedSlot();
    clearCursor();
    clearClickedSlot();

    if (type == MISC_ROW_BORDER)
    {
        uniform_size	= MISC_FRAME_HEIGHT;
        def_slot.offset = 0;
        def_slot.size	= uniform_size;
        def_slot.min_size = 10;
        def_slot.max_size = MISC_MAX_PIXELS_SIZE;
        def_slot.sizing = MISC_NUSER_NSPRINGY_SIZING;
        title_mode	= MISC_NUMBER_TITLE;
        draggable	= false;
        modifier_drag	= true;
        sizeable	= false;
        selectable	= true;
    }
    else
    {
        def_slot.offset = 0;
        def_slot.size	= 80;
        def_slot.min_size = 10;
        def_slot.max_size = MISC_MAX_PIXELS_SIZE;
        def_slot.sizing = MISC_USER_NSPRINGY_SIZING;
        uniform_size	= 0;
        title_mode	= MISC_CUSTOM_TITLE;
        draggable	= true;
        modifier_drag	= false;
        sizeable	= true;
        selectable	= false;
    }
    min_uniform_size = MISC_MIN_PIXELS_SIZE;
    max_uniform_size = MISC_MAX_PIXELS_SIZE;
}
