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
// MiscSparseSet.cc
//
//	This object implements a sparse set.  The set is represented by an
//	array of ranges kept in sorted ascending order.  Each range is
//	separated from neighboring ranges by a gap of at least one value.
//	In other words, ranges do not overlap, and they do not "touch" each
//	other.  The upper and lower bounds in each range are inclusive.  A
//	range might contain a single value.  In that case, both the upper and
//	lower bounds will have the same value.  There are no empty ranges.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscSparseSet.cc,v 1.11 97/04/04 04:57:49 sunshine Exp $
// $Log:	MiscSparseSet.cc,v $
// Revision 1.11  97/04/04  04:57:49  sunshine
// 0.125.6: Removed unused <assert.h> header.
// 
//  Revision 1.10  97/04/01  07:47:58  sunshine
//  v0.125.5: Fixed comparisons between signed and unsigned integers.
//  
//  Revision 1.9  97/03/20  16:31:18  sunshine
//  v119.1: Removed unnecessary loop from shiftDownAt()
//-----------------------------------------------------------------------------
#ifdef __GNUC__
# pragma implementation
#endif
#import "MiscSparseSet.h"

extern "C" {
#import <stdio.h>
#import <stdlib.h>
#import <string.h>
}

unsigned int const INITIAL_CAPACITY = 16;


//-----------------------------------------------------------------------------
// sort
//-----------------------------------------------------------------------------
static inline void sort( int& low, int& high )
    {
    if (high < low) { int t = low; low = high; high = t; }
    }


//=============================================================================
// IMPLEMENTATION
//=============================================================================
//-----------------------------------------------------------------------------
// dump
//-----------------------------------------------------------------------------
void MiscSparseSet::dump( char const* msg ) const
    {
    fprintf( stderr, "(SPARSE-SET %s (", msg );
    int last_hi = -1;
    bool corrupt = false;
    for (unsigned int i = 0; i < num_ranges; i++)
	{
	Range const& r = ranges[i];
	if (r.lo <= last_hi)
	    corrupt = true;
	last_hi = r.hi;
	fprintf( stderr, "%s%d", (i != 0 ? " " : ""), r.lo );
	if (r.lo != r.hi)
	    fprintf( stderr, "-%d", r.hi );
	}
    fprintf( stderr, "))%s\n", corrupt ? " *** CORRUPT ***" : "" );
    }


//-----------------------------------------------------------------------------
// expand(uint)
//-----------------------------------------------------------------------------
void MiscSparseSet::expand( unsigned int new_capacity )
    {
    if (max_ranges < new_capacity)
	{
	max_ranges = new_capacity;
	int const BYTES = max_ranges * sizeof(*ranges);
	if (ranges == 0)
	    ranges = (Range*) malloc( BYTES );
	else
	    ranges = (Range*) realloc( ranges, BYTES );
	}
    }


//-----------------------------------------------------------------------------
// expand
//-----------------------------------------------------------------------------
inline void MiscSparseSet::expand()
    {
    if (num_ranges >= max_ranges)
	expand( max_ranges == 0 ? INITIAL_CAPACITY : max_ranges << 1 );
    }


//-----------------------------------------------------------------------------
// coerce
//-----------------------------------------------------------------------------
int MiscSparseSet::coerce( int x ) const
    {
    if (isEmpty())
	x = -1;
    else
	{
	int i = bsearch( x );
	if (i < 0)
	    {
	    i = ~i;
	    x = (i > 0 ? ranges[i-1].hi : ranges[i].lo);
	    }
	}
    return x;
    }


//-----------------------------------------------------------------------------
// bsearch
//-----------------------------------------------------------------------------
int MiscSparseSet::bsearch( int x ) const
    {
    int lo = 0;
    int hi = numRanges() - 1;
    while (lo <= hi)
	{
	int const mid = (lo + hi) >> 1;
	Range const& r = ranges[mid];
	if (x > r.hi)
	    lo = mid + 1;
	else if (x < r.lo)
	    hi = mid - 1;
	else
	    return mid;
	}
    return ~lo;
    }


//-----------------------------------------------------------------------------
// insertAt
//-----------------------------------------------------------------------------
void MiscSparseSet::insertAt( unsigned int i, int lo, int hi )
    {
    expand();
    Range* const p = ranges + i;
    if (i < num_ranges)
	memmove( p + 1, p, (num_ranges - i) * sizeof(*ranges) );
    num_ranges++;
    p->lo = lo;
    p->hi = hi;
    }


//-----------------------------------------------------------------------------
// deleteAt
//-----------------------------------------------------------------------------
void MiscSparseSet::deleteAt( unsigned int i, unsigned int n )
    {
    num_ranges -= n;
    if (i < num_ranges)
	{
	Range* const p = ranges + i;
	memmove( p, p + n, (num_ranges - i) * sizeof(*ranges));
	}
    }


//-----------------------------------------------------------------------------
// add -- singleton
//-----------------------------------------------------------------------------
void MiscSparseSet::add( int x )
    {
    int i = bsearch( x );
    if (i < 0)	// else, (i >= 0) already in an existing range.
	{
	int action = 0;
	i = ~i;
	if (i > 0 && ranges[i-1].hi == x - 1)			action |= 1;
	if (i < int(num_ranges) && ranges[i].lo == x + 1)	action |= 2;
	switch (action)
	    {
	case 0:	insertAt( i, x, x );				break;
	case 1:	ranges[i-1].hi = x;				break;
	case 2:	ranges[i].lo = x;				break;
	case 3:	ranges[i-1].hi = ranges[i].hi; deleteAt(i,1);	break;
	    }
	}
    }


//-----------------------------------------------------------------------------
// add -- range
//-----------------------------------------------------------------------------
void MiscSparseSet::add( int lo, int hi )
    {
    if (lo == hi)
	add( lo );
    else
	{
	sort( lo, hi );
	int ilo = bsearch( lo - 1 );
	int ihi = bsearch( hi + 1 );

	if (ilo == ihi)
	    {
	    if (ilo < 0)	// else both are in same existing range.
		insertAt( ~ilo, lo, hi );
	    }
	else
	    {			// Convert to good node coords.
	    int nlo = ilo; if (nlo < 0) nlo = ~nlo;	// round up
	    int nhi = ihi; if (nhi < 0) nhi = ~nhi - 1;	// round down

	    if (nlo != nhi)
		{
		Range const& t = ranges[nhi];
		if (hi < t.hi) hi = t.hi;
		deleteAt( nlo + 1, nhi - nlo );
		}

	    Range& r = ranges[nlo];
	    if (r.lo > lo) r.lo = lo;
	    if (r.hi < hi) r.hi = hi;
	    }
	}
    }


//-----------------------------------------------------------------------------
// remove -- singleton
// NOTE *1*: Can't use 'r.hi' here since insertAt() may have called realloc().
//-----------------------------------------------------------------------------
void MiscSparseSet::remove( int x )
    {
    int const i = bsearch( x );
    if (i >= 0)	// else, (i < 0) already in a "gap".
	{
	int action = 0;
	Range& r = ranges[i];
	if (r.lo == x) action |= 1;		// Trim below.
	if (r.hi == x) action |= 2;		// Trim above.
	switch (action)
	    {
	case 0:	insertAt( i + 1, x + 1, r.hi );
		ranges[i].hi = x - 1;	break;	// NOTE *1*
	case 1:	r.lo = x + 1;		break;
	case 2:	r.hi = x - 1;		break;
	case 3:	deleteAt( i, 1 );	break;
	    }
	}
    }


//-----------------------------------------------------------------------------
// remove -- range
//-----------------------------------------------------------------------------
void MiscSparseSet::remove( int lo, int hi )
    {
    if (lo == hi)
	remove( lo );
    else
	{
	sort( lo, hi );
	lo--;
	hi++;
	int ilo = bsearch( lo );
	int ihi = bsearch( hi );

	if (ilo == ihi)
	    {
	    if (ilo >= 0)	// else both in the same "gap".
		{
		Range& r = ranges[ilo];
		int const t = r.hi;
		r.hi = lo;
		insertAt( ilo + 1, hi, t );
		}
	    }
	else
	    {
	    if (ilo >= 0)
		{
		ranges[ilo].hi = lo;
		ilo++;
		}
	    else
		ilo = ~ilo;
	    
	    if (ihi >= 0)
		ranges[ihi].lo = hi;
	    else
		ihi = ~ihi;
	    
	    if (ihi > ilo)
		deleteAt( ilo, ihi - ilo );
	    }
	}
    }


//-----------------------------------------------------------------------------
// Constructor [Copy]
//-----------------------------------------------------------------------------
MiscSparseSet::MiscSparseSet( MiscSparseSet const& s ) :
    num_ranges(s.num_ranges), max_ranges(s.num_ranges), ranges(0)
    {
    if (max_ranges > 0)
	{
	int const BYTES = max_ranges * sizeof(*ranges);
	ranges = (Range*) malloc( BYTES );
	memcpy( ranges, s.ranges, BYTES );
	}
    }


//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
MiscSparseSet::~MiscSparseSet()
    {
    if (ranges != 0)
	free( ranges );
    }


//-----------------------------------------------------------------------------
// operator=
//-----------------------------------------------------------------------------
MiscSparseSet& MiscSparseSet::operator=( MiscSparseSet const& s )
    {
    if (&s != this)
	{
	if (s.isEmpty())
	    empty();
	else
	    {
	    expand( s.num_ranges );
	    num_ranges = s.num_ranges;
	    memcpy( ranges, s.ranges, num_ranges * sizeof(*ranges) );
	    }
	}
    return *this;
    }


//-----------------------------------------------------------------------------
// operator==
//-----------------------------------------------------------------------------
bool MiscSparseSet::operator==( MiscSparseSet const& s ) const
    {
    return (&s == this || (num_ranges == s.num_ranges && (num_ranges == 0 ||
	    memcmp( ranges, s.ranges, num_ranges * sizeof(*ranges) ) == 0)));
    }


//-----------------------------------------------------------------------------
// toggle
//-----------------------------------------------------------------------------
void MiscSparseSet::toggle( int x )
    {
    if (contains( x ))
	remove( x );
    else
	add( x );
    }


//-----------------------------------------------------------------------------
// shiftUpAt
//-----------------------------------------------------------------------------
void MiscSparseSet::shiftUpAt( int x )
    {
    for (unsigned int i = num_ranges;  i-- > 0;  )
	{
	Range& r = ranges[i];
	if (r.hi >= x)
	    {
	    r.hi++;
	    if (r.lo >= x)
		r.lo++;
	    }
	else
	    break;
	}

    if (contains(x))
	remove(x);		// Newly inserted slots are not selected.
    }


//-----------------------------------------------------------------------------
// shiftDownAt
//-----------------------------------------------------------------------------
void MiscSparseSet::shiftDownAt( int x )
    {
    if (contains(x))
	remove(x);

    int i;
    for (i = num_ranges; i-- > 0; )
	{
	Range& r = ranges[i];
	if (r.hi > x)
	    {
	    r.hi--;
	    if (r.lo > x)
		r.lo--;
	    }
	else
	    break;
	}

    if (i >= 0 && i + 1 < int(num_ranges) &&
	ranges[i].hi + 1 == ranges[i + 1].lo)
	{
	ranges[i].hi = ranges[i+1].hi;		// Collapse adjacent range.
	deleteAt( i + 1, 1 );
	}
    }


//-----------------------------------------------------------------------------
// count
//-----------------------------------------------------------------------------
unsigned int MiscSparseSet::count() const
    {
    unsigned int total = 0;
    Range const* p = ranges;
    Range const* const plim = p + num_ranges;
    for ( ; p < plim; p++)
	total += p->hi - p->lo + 1;
    return total;
    }


//-----------------------------------------------------------------------------
// getRangeAt
//-----------------------------------------------------------------------------
void MiscSparseSet::getRangeAt( unsigned int i, int& lo, int& hi ) const
    {
    lo = hi = -1;
    if (i < num_ranges)
	{
	lo = ranges[i].lo;
	hi = ranges[i].hi;
	}
    }


//-----------------------------------------------------------------------------
// getTotalRange
//-----------------------------------------------------------------------------
void MiscSparseSet::getTotalRange( int& lo, int& hi ) const
    {
    lo = hi = -1;
    if (num_ranges > 0)
	{
	lo = ranges[ 0 ].lo;
	hi = ranges[ num_ranges - 1 ].hi;
	}
    }
