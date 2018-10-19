//=============================================================================
//
//	Copyright (C) 1996,1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscGeometry.cc
//
//	*NOTE* The methods in this file were moved here from the interface
//	file in order to work around a bug in the PPC compiler for Rhapsody
//	DR1.  The compiler would crash with an "internal compiler error" each
//	time it got to the code where these methods convert a float to an int.
//	Moving the methods to the implementation file (so that they are no
//	longer inline) keeps the compiler from crashing.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscGeometry.cc,v 1.2 98/03/30 09:44:03 sunshine Exp $
// $Log:	MiscGeometry.cc,v $
// Revision 1.2  98/03/30  09:44:03  sunshine
// v138.1: Worked around Rhapsody DR1, PPC "internal compiler error" bug.
// 
// Revision 1.1  96/05/05  10:53:55  sunshine
// Geometric type structures which know their border orientation.
//-----------------------------------------------------------------------------
#ifdef __GNUC__
# pragma implementation
#endif
#import "MiscGeometry.h"


//-----------------------------------------------------------------------------
// MiscPoint_O
//-----------------------------------------------------------------------------
MiscPoint_O::MiscPoint_O( bool is_horz, NSPoint p ) :
    MiscOrientation(is_horz),x(MiscPixels(p.x)),y(MiscPixels(p.y)) {}
MiscPoint_O::MiscPoint_O( MiscBorderType b, NSPoint p ) :
    MiscOrientation(b),x(MiscPixels(p.x)),y(MiscPixels(p.y)) {}
MiscPoint_O& MiscPoint_O::operator=( NSPoint p )
	{ x = MiscPixels( p.x ); y = MiscPixels( p.y ); return *this; }


//-----------------------------------------------------------------------------
// MiscSize_O
//-----------------------------------------------------------------------------
MiscSize_O::MiscSize_O( bool is_horz, NSSize p ) : MiscOrientation(is_horz),
    width(MiscPixels(p.width)),height(MiscPixels(p.height)) {}
MiscSize_O::MiscSize_O( MiscBorderType b, NSSize p ) : MiscOrientation(b),
    width(MiscPixels(p.width)),height(MiscPixels(p.height)) {}
MiscSize_O& MiscSize_O::operator=( NSSize s )
    { width = MiscPixels( s.width ); height = MiscPixels( s.height );
		return *this; }
