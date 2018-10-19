#ifndef __MiscSparseSet_h
#define __MiscSparseSet_h
#ifdef __GNUC__
# pragma interface
#endif
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
// MiscSparseSet.h
//
//	This object implements a sparse set.  The set is represented by an
//	array of ranges kept in sorted ascending order.  Each range is
//	separated from neighboring ranges by a gap of at least one value.
//	In other words, ranges do not overlap, and they do not "touch" each
//	other.  The upper and lower bounds in each range are inclusive.  A
//	range might contain a single value.  In that case, both the upper and
//	lower bounds will have the same value.  There are no empty ranges.
//
// NOTE *1*
//	coerce(x) will return x if x is a member of the set.  Otherwise, it
//	will return the closest previous member of the set, if any.  Otherwise
//	it will return the closest following member of the set.  Otherwise
//	it will return -1 if the set is empty.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscSparseSet.h,v 1.5 96/12/30 09:13:42 sunshine Exp $
// $Log:	MiscSparseSet.h,v $
// Revision 1.5  96/12/30  09:13:42  sunshine
// v107.1: Added coerce().
// 
//  Revision 1.4  96/12/30  03:12:49  sunshine
//  v104.1: Removed "cursor" wart.  Now this is a simple generic class.
//  
//  Revision 1.3  96/04/30  05:38:43  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#include "bool.h"

class MiscSparseSet
	{
private:
	struct Range
	    {
	    int lo;
	    int hi;
	    };

	unsigned int num_ranges;
	unsigned int max_ranges;
	Range* ranges;

	void expand( unsigned int new_capacity );
	void expand();
	int bsearch( int x ) const;
	void insertAt( unsigned int i, int lo, int hi );
	void deleteAt( unsigned int i, unsigned int n );

public:
	MiscSparseSet():num_ranges(0),max_ranges(0),ranges(0){}
	MiscSparseSet( MiscSparseSet const& );
	~MiscSparseSet();

	MiscSparseSet& operator=( MiscSparseSet const& );
	bool operator==( MiscSparseSet const& ) const;
	bool operator!=( MiscSparseSet const& s ) const
					{ return !operator==(s); }

	bool contains( int x ) const	{ return (bsearch( x ) >= 0); }
	bool isEmpty() const		{ return (num_ranges == 0); }
	void empty()			{ num_ranges = 0; }
	unsigned int count() const;	// # elments in set

	void add( int lo, int hi );	// add a range
	void add( int x );
	void remove( int lo, int hi );	// remove a range
	void remove( int x );
	void toggle( int x );
	void shiftUpAt( int x );
	void shiftDownAt( int x );

	int coerce( int x ) const;	// NOTE *1*

	unsigned int numRanges() const	{ return num_ranges; }
	void getRangeAt( unsigned int i, int& lo, int& hi ) const;
	void getTotalRange( int& lo, int& hi ) const;

	void dump( char const* msg ) const;
	};

#endif // __MiscSparseSet_h
