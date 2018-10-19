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
// MiscTableBorderSel.cc
//
//	Selection management methods for the MiscTableBorder class.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableBorderSel.cc,v 1.2 97/11/24 03:03:48 sunshine Exp $
// $Log:	MiscTableBorderSel.cc,v $
// Revision 1.2  97/11/24  03:03:48  sunshine
// v132.1: MiscTableBorder_sel --> MiscTableBorderSel
// 
// Revision 1.1  97/11/23  07:36:07  sunshine
// v130.1: Selection management routines for MiscTableBorder.
//-----------------------------------------------------------------------------
#include "MiscTableBorder.h"
#import <Foundation/NSArray.h>

//-----------------------------------------------------------------------------
// visualToPhysical
//	Used to save the selection before sorting.
//-----------------------------------------------------------------------------
void MiscTableBorder::visualToPhysical( MiscSparseSet const& vset,
					MiscSparseSet& pset ) const
{
    pset.empty();
    unsigned int const lim = vset.numRanges();
    for (unsigned int i = 0; i < lim; i++)
    {
        int lo, hi;
        vset.getRangeAt( i, lo, hi );
        for ( ; lo <= hi; lo++)
            pset.add( visualToPhysical( lo ) );
    }
}


//-----------------------------------------------------------------------------
// physicalToVisual
//	Used to restore the selection after sorting.
//-----------------------------------------------------------------------------
void MiscTableBorder::physicalToVisual( MiscSparseSet const& pset,
					MiscSparseSet& vset ) const
{
    vset.empty();
    unsigned int const lim = pset.numRanges();
    for (unsigned int i = 0; i < lim; i++)
    {
        int lo, hi;
        pset.getRangeAt( i, lo, hi );
        for ( ; lo <= hi; lo++)
            vset.add( physicalToVisual( lo ) );
    }
}


//-----------------------------------------------------------------------------
// hasMultipleSelection
//-----------------------------------------------------------------------------
bool MiscTableBorder::hasMultipleSelection() const
{
    MiscCoord_V lo, hi;
    selection.getTotalRange( lo, hi );
    return hi > lo;
}


//-----------------------------------------------------------------------------
// selected_slots
//-----------------------------------------------------------------------------
NSArray* MiscTableBorder::selected_slots( bool do_tags ) const
{
    NSMutableArray* array = [NSMutableArray array];
    for (unsigned int i = 0, lim = selection.numRanges(); i < lim; i++)
    {
        MiscCoord_V lo, hi;
        selection.getRangeAt( i, lo, hi );
        for ( ; lo <= hi; lo++)
        {
            int n = (do_tags ? getTag(lo) : visualToPhysical(lo));
            [array addObject:[NSNumber numberWithInt:n]];
        }
    }
    return array;
}


//-----------------------------------------------------------------------------
// select_slots
//-----------------------------------------------------------------------------
void MiscTableBorder::select_slots( NSArray* list, bool clear, bool set )
{
    if (clear)
        selectNone();
    int const lim = [list count];
    if (lim > 0)
    {
        MiscCoord_V last_selected = -1;
        for (int i = lim; i-- > 0; )
        {
            MiscCoord_P const p_slot = [[list objectAtIndex:i] intValue];
            if (goodPos( p_slot ))
            {
                MiscCoord_V const v_slot = physicalToVisual( p_slot );
                if (v_slot > last_selected) last_selected = v_slot;
                if (set)
                    selection.add( v_slot );
                else
                    selection.remove( v_slot );
            }
        }
        if (set && last_selected != -1)
            setSelectedSlot( last_selected );
        else
            fixSelectedSlot();
    }
}


//-----------------------------------------------------------------------------
// select_tags
//-----------------------------------------------------------------------------
void MiscTableBorder::select_tags( NSArray* list, bool clear, bool set )
{
    if (clear)
        selectNone();
    unsigned int const M = [list count];
    if (M > 0)
    {
        MiscCoord_V last_selected = -1;
        unsigned int i;
        int* const v0 = (int*)malloc( M * sizeof(*v0) );
        int const* const vM = v0 + M;

        for (i = 0; i < M; i++)
            v0[i] = [[list objectAtIndex:i] intValue];

        unsigned int const N = count();
        for (i = 0; i < N; i++)
        {
            int const t = getTag(i);		// MiscCoord_V
            for (int const* v = v0; v < vM; v++)
                if (*v == t)
                {
                    if (int(i) > last_selected) last_selected = (MiscCoord_V)i;
                    if (set)
                        selection.add(i);
                    else
                        selection.remove(i);
                    break;
                }
        }
        free( v0 );
        if (set && last_selected != -1)
            setSelectedSlot( last_selected );
        else
            fixSelectedSlot();
    }
}
