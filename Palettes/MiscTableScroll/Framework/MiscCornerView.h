#ifndef __MiscCornerView_h
#define __MiscCornerView_h
//=============================================================================
//
//	Copyright (C) 1995-1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscCornerView.h
//
//	View class that covers the gap in the upper left corner when a 
//	MiscTableScroll has both row and column titles turned on.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscCornerView.h,v 1.3 98/03/22 13:29:57 sunshine Exp $
// $Log:	MiscCornerView.h,v $
// Revision 1.3  98/03/22  13:29:57  sunshine
// v133.1: MiscNullView --> MiscCornerView.  Added -title, -setTitle:.
// 
//  Revision 1.2  96/04/30  05:38:38  sunshine
//  Ported to OpenStep 4.0 for Mach PR2.
//-----------------------------------------------------------------------------
extern "C" {
#import <AppKit/NSView.h>
}
@class MiscBorderCell;

@interface MiscCornerView : NSView
    {
    MiscBorderCell* theCell;
    }

- (NSString*)title;
- (void)setTitle:(NSString*)s;

@end

#endif // __MiscCornerView_h
