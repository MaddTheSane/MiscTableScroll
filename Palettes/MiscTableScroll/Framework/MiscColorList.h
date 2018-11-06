#ifndef __MiscColorList_h
#define __MiscColorList_h
#ifdef __GNUC__
#pragma interface
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
// MiscColorList.h
//
//	An extensible array of colors that can act as a color palette to
//	reduce the storage overhead of storing a lot of colors.  Also
//	useful for speeding color comparisons in some cases.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscColorList.h,v 1.2 96/12/30 03:09:44 sunshine Exp $
// $Log:	MiscColorList.h,v $
// Revision 1.2  96/12/30  03:09:44  sunshine
// v104.1: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/08/30  14:51:51  sunshine
// Extensible array of colors acting as a color palette.
//-----------------------------------------------------------------------------
#import <AppKit/NSColor.h>
@class NSMutableArray;

struct MiscColorList
{
private:
	NSMutableArray* colors;
	MiscColorList( MiscColorList const& ) {}	// No copy constructor.
	void operator=( MiscColorList const& ) {}	// No assign operator.
public:
	MiscColorList();
	~MiscColorList();
	NSInteger count() const	{ return [colors count]; }
	void empty()			{ [colors removeAllObjects]; }
	NSColor* nth( NSInteger n ) const	{ return [colors objectAtIndex:n]; }
	NSColor* operator[]( NSInteger n ) const { return nth(n); }
	NSInteger store( NSColor* );
};

#endif // __MiscColorList_h
