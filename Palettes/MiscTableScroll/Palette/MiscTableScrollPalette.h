#ifndef __MiscTableScrollPalette_h
#define __MiscTableScrollPalette_h
//=============================================================================
//
//	Copyright (C) 1996 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollPalette.h
//
//	Subclass of IBPalette for the MiscTableScroll palette.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollPalette.h,v 1.4 96/04/30 05:39:58 sunshine Exp $
// $Log:	MiscTableScrollPalette.h,v $
// Revision 1.4  96/04/30  05:39:58  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
// 
//-----------------------------------------------------------------------------
extern "Objective-C" {
#import <InterfaceBuilder/InterfaceBuilder.h>
}

@class MiscTableScroll;

@interface MiscTableScrollPalette : IBPalette
    {
    MiscTableScroll* tableScroll;
    }

- (void) finishInstantiate;

@end

#endif // __MiscTableScrollPalette_h
