#ifndef __MiscBorderCell_h
#define __MiscBorderCell_h
//=============================================================================
//
//  Copyright (C) 1995,1996,1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscBorderCell.h
//
//	Cell class used by MiscBorderView to manage column headings and row 
//	labels for MiscTableScroll.  
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscBorderCell.h,v 1.5 98/03/29 23:38:20 sunshine Exp $
// $Log:	MiscBorderCell.h,v $
// Revision 1.5  98/03/29  23:38:20  sunshine
// v138.1: Now derived from NSTableHeaderCell rather than NSTextFieldCell
// so that it knows how to correctly draw and color itself on all platforms
// rather than only being able to draw itself in a NextStep-like fashion.
// 
//  Revision 1.4  97/03/23  05:45:42  sunshine
//  v125.4: Worked around OPENSTEP 4.1 bug where -setupFieldEditorAttributes:
//  never gets called, so text was not drawing white.  Worked around problem by
//  subclassing from NSTextFieldCell rather than NSCell.  This way color can
//  be set with -setTextColor:.
//-----------------------------------------------------------------------------
extern "Objective-C" {
#import <AppKit/NSTableHeaderCell.h>
}
class NSImage;

@interface MiscBorderCell : NSTableHeaderCell
    {
    NSImage* toggleImage;
    }

- (void)setToggleImage:(NSImage*)image;

@end

#endif // __MiscBorderCell_h
