#ifndef __MiscGeometry_h
#define __MiscGeometry_h
#ifdef __GNUC__
# pragma interface
#endif
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
// MiscGeometry.h
//
//	Geometric types (point, size, rectangle) which understand and can
//	adjust for orientation (horizontal or vertical).  Orientation is
//	specified upon creation and can not be changed thereafter.
//
//	Method names with the "_O" suffix take orientation into consideration,
//	whereas methods lacking this suffix do not.
//
//	Methods dealing with NeXT geometric structures do not apply orientation
//	adjustments.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscGeometry.h,v 1.4 98/03/30 09:43:59 sunshine Exp $
// $Log:	MiscGeometry.h,v $
// Revision 1.4  98/03/30  09:43:59  sunshine
// v138.1: Worked around Rhapsody DR1, PPC "internal compiler error" bug.
// 
// Revision 1.3  98/03/29  23:45:48  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
// 
// Revision 1.2  96/05/07  02:06:10  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
#include <MiscTableScroll/MiscTableTypes.h>
#include "bool.h"
extern "C" {
#import <Foundation/NSGeometry.h>
}

class MiscOrientation
    {
private:
    bool horizontal;
public:
    bool isHorz() const { return horizontal; }
    bool isVert() const { return !isHorz(); }
    MiscBorderType border() const
	{ return isHorz() ? MISC_COL_BORDER : MISC_ROW_BORDER; }
    MiscOrientation( bool is_horz ) : horizontal(is_horz) {}
    MiscOrientation( MiscBorderType b ) : horizontal( b == MISC_COL_BORDER ) {}
    };

class MiscPoint_O : public virtual MiscOrientation
    {
private:
    MiscPixels x;
    MiscPixels y;
public:
    MiscPixels getX() const { return x; }
    MiscPixels getY() const { return y; }
    MiscPixels getX_O() const { return isHorz() ? x : y; }
    MiscPixels getY_O() const { return isHorz() ? y : x; }
    void setX( MiscPixels n ) { x = n; }
    void setY( MiscPixels n ) { y = n; }
    void setX_O( MiscPixels n ) { (isHorz() ? x : y) = n; }
    void setY_O( MiscPixels n ) { (isHorz() ? y : x) = n; }
    MiscPoint_O& operator=( MiscPoint_O const& p )
	{ setX_O( p.getX_O() ); setY_O( p.getY_O() ); return *this; }
    bool operator==( MiscPoint_O const& p ) const
	{ return isHorz() == p.isHorz() &&
		getX_O() == p.getX_O() && getY_O() == p.getY_O(); }
    bool operator!=( MiscPoint_O const& p ) const { return !operator==(p); }

    NSPoint nsPoint() const { return NSMakePoint( x, y ); }
    operator NSPoint() const { return nsPoint(); }
    MiscPoint_O& operator=( NSPoint );

    MiscPoint_O( bool is_horz, MiscPixels _x = 0, MiscPixels _y = 0 ) :
	MiscOrientation(is_horz),x(_x),y(_y) {}
    MiscPoint_O( MiscBorderType b, MiscPixels _x = 0, MiscPixels _y = 0 ) :
	MiscOrientation(b),x(_x),y(_y) {}
    MiscPoint_O( MiscPoint_O const& p ) :
	MiscOrientation(p.isHorz()),x(p.getX_O()),y(p.getY_O()) {}
    MiscPoint_O( bool is_horz, NSPoint );
    MiscPoint_O( MiscBorderType b, NSPoint );
    };


class MiscSize_O : public virtual MiscOrientation
    {
private:
    MiscPixels width;
    MiscPixels height;
public:
    MiscPixels getWidth() const { return width; }
    MiscPixels getHeight() const { return height; }
    MiscPixels getWidth_O() const { return isHorz() ? width : height; }
    MiscPixels getHeight_O() const { return isHorz() ? height : width; }
    void setWidth( MiscPixels w ) { width = w; }
    void setHeight( MiscPixels h ) { height = h; }
    void setWidth_O( MiscPixels w ) { (isHorz() ? width : height) = w; }
    void setHeight_O( MiscPixels h ) { (isHorz() ? height : width) = h; }
    MiscSize_O& operator=( MiscSize_O const& p )
	{ setWidth_O( p.getWidth_O() ); setHeight_O( p.getHeight_O() );
		return *this; }
    bool operator==( MiscSize_O const& p ) const
	{ return isHorz() == p.isHorz() && getWidth_O() == p.getWidth_O() &&
		getHeight_O() == p.getHeight_O(); }
    bool operator!=( MiscSize_O const& p ) const { return !operator==(p); }

    NSSize nsSize() const { return NSMakeSize( width, height ); }
    operator NSSize() const { return nsSize(); }
    MiscSize_O& operator=( NSSize );

    MiscSize_O( bool is_horz, MiscPixels w = 0, MiscPixels h = 0 ) :
	MiscOrientation(is_horz),width(w),height(h) {}
    MiscSize_O( MiscBorderType b, MiscPixels w = 0, MiscPixels h = 0 ) :
	MiscOrientation(b),width(w),height(h) {}
    MiscSize_O( MiscSize_O const& p ) : MiscOrientation(p.isHorz()),
	width(p.getWidth_O()),height(p.getHeight_O()) {}
    MiscSize_O( bool is_horz, NSSize );
    MiscSize_O( MiscBorderType b, NSSize );
    };


class MiscRect_O : public MiscPoint_O, public MiscSize_O
    {
public:
    MiscPixels getMaxX() const { return getX() + getWidth(); }
    MiscPixels getMaxY() const { return getY() + getHeight(); }
    MiscPixels getMaxX_O() const { return getX_O() + getWidth_O(); }
    MiscPixels getMaxY_O() const { return getY_O() + getHeight_O(); }
    MiscRect_O& operator=( MiscPoint_O const& p )
	{ MiscPoint_O::operator=( p ); return *this; }
    MiscRect_O& operator=( MiscSize_O const& p )
	{ MiscSize_O::operator=( p ); return *this; }
    MiscRect_O& operator=( MiscRect_O const& r )
	{ MiscPoint_O::operator=(r); MiscSize_O::operator=(r); return *this; }
    bool operator==( MiscRect_O const& r ) const
	{ return MiscPoint_O::operator==(r) && MiscSize_O::operator==(r); }
    bool operator!=( MiscRect_O const& r ) const { return !operator==(r); }

    NSRect nsRect() const { NSRect r = { nsPoint(), nsSize() }; return r; }
    operator NSRect() const { return nsRect(); }
    MiscRect_O& operator=( NSPoint p )
	{ MiscPoint_O::operator=(p); return *this; }
    MiscRect_O& operator=( NSSize s )
	{ MiscSize_O::operator=(s); return *this; }
    MiscRect_O& operator=( NSRect r )
	{ MiscPoint_O::operator=( r.origin ); MiscSize_O::operator=( r.size );
		return *this; }

    MiscRect_O( bool is_horz, MiscPixels x = 0, MiscPixels y = 0,
	MiscPixels w = 0, MiscPixels h = 0 ) : MiscOrientation(is_horz),
	MiscPoint_O(is_horz,x,y),MiscSize_O(is_horz,w,h) {}
    MiscRect_O( MiscBorderType b, MiscPixels x = 0, MiscPixels y = 0,
	MiscPixels w = 0, MiscPixels h = 0 ) :
	MiscOrientation(b),MiscPoint_O(b,x,y),MiscSize_O(b,w,h) {}
    MiscRect_O( MiscRect_O const& r ) :
	MiscOrientation(r.isHorz()),MiscPoint_O(r),MiscSize_O(r) {}
    MiscRect_O( bool is_horz, NSRect r ) : MiscOrientation(is_horz),
	MiscPoint_O(is_horz,r.origin),MiscSize_O(is_horz,r.size) {}
    MiscRect_O( MiscBorderType b, NSRect r ) : MiscOrientation(b),
	MiscPoint_O(b,r.origin),MiscSize_O(b,r.size) {}
    };

#endif // __MiscGeometry_h
