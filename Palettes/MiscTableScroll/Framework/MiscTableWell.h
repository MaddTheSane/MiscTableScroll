#ifndef __MiscTableWell_h
#define __MiscTableWell_h
//=============================================================================
//
//	Copyright (C) 1995, 1996 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableWell.h
//
//	View class that draws a well where a column/row laid before dragging
//	was started.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableWell.h,v 1.2 96/04/30 05:40:10 sunshine Exp $
// $Log:	MiscTableWell.h,v $
// Revision 1.2  96/04/30  05:40:10  sunshine
// Ported to OpenStep 4.0 for Mach PR2.
// 
//-----------------------------------------------------------------------------
extern "Objective-C" {
#import <AppKit/NSView.h>
}

@interface MiscTableWell : NSView
    {
    }

- initWithFrame:(NSRect)frameRect;
- (BOOL) isOpaque;
- (void) drawRect:(NSRect)rect;

@end

#endif // __MiscTableWell_h
