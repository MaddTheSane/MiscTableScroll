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
// MiscColorList.cc
//
//	An extensible array of colors that can act as a color palette to
//	reduce the storage overhead of storing a lot of colors.  Also
//	useful for speeding color comparisons in some cases.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscColorList.cc,v 1.2 96/12/30 03:09:47 sunshine Exp $
// $Log:	MiscColorList.cc,v $
// Revision 1.2  96/12/30  03:09:47  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:51:54  sunshine
// Extensible array of colors acting as a color palette.
//-----------------------------------------------------------------------------
#ifdef __GNUC__
#pragma implementation
#endif
#include "MiscColorList.h"

extern "C" {
#include <stdlib.h>	// free(), malloc(), realloc()
}


//-----------------------------------------------------------------------------
// Destructor
//-----------------------------------------------------------------------------
MiscColorList::~MiscColorList()
{
    [colors release];
}


//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
MiscColorList::MiscColorList()
{
    colors = [[NSMutableArray alloc] init];
}


//-----------------------------------------------------------------------------
// store
//-----------------------------------------------------------------------------
int MiscColorList::store( NSColor* c )
{
    for (int i = count(); i-- > 0; )
        if ([c isEqual:nth(i)])
            return i;
    [colors addObject:c];
    return (count() - 1);
}
