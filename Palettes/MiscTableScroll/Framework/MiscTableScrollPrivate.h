#ifndef __MiscTableScrollPrivate_h
#define __MiscTableScrollPrivate_h
//=============================================================================
//
//	Copyright (C) 1995-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollPrivate.h
//
//	Methods used within the Table Scroll palette but which are not
//	exported with the *public* interface.
//
// NOTE *1*
//	The OPENSTEP 4.1 (gamma) Objective-C++ compiler neglects to define the
//	macro __PRETTY_FUNCTION__ which is used by the macro NSCAssert() and
//	its cousins, so we have to fake it up.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollPrivate.h,v 1.12 99/06/15 03:35:59 sunshine Exp $
// $Log:	MiscTableScrollPrivate.h,v $
// Revision 1.12  99/06/15  03:35:59  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Represented object support was added, so incremented class version number.
// Renamed method: setTracking: --> setIsTrackingMouse:
// 
// Revision 1.11  1998/03/29 23:57:26  sunshine
// v138.1: Moved MISC_FRAME_HEIGHT & MISC_FRAME_WIDTH here from MiscBorderView
// since MiscTableBorder needs to access them as well.
//
// Revision 1.10  98/03/22  13:14:50  sunshine
// v133.1: Broke off IO category of TableScroll.  Migrated some version
// related declarations here.  Added access to the cornerView.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscDelegateFlags.h"

#if defined(NX_CURRENT_COMPILER_RELEASE) && NX_CURRENT_COMPILER_RELEASE <= 400
# define __PRETTY_FUNCTION__ "<unknown>"		/* NOTE 1 */
#endif

#define MISC_TS_VERSION_0	0	// Initial version
#define MISC_TS_VERSION_1	1	// MiscSortType was 0..8, now 0..12
#define MISC_TS_VERSION_2	2	// Overhauled border archive format.
#define MISC_TS_VERSION_1000	1000	// First OpenStep version (4.0 PR2)
#define MISC_TS_VERSION_1001	1001	// Sort vector: (int*) ->> (NSArray)
#define MISC_TS_VERSION_1002	1002	// Overhauled border archive format.
#define MISC_TS_VERSION_1003	1003	// Added representedObject.
#define MISC_TS_VERSION		MISC_TS_VERSION_1003

#define MISC_FRAME_HEIGHT	20
#define MISC_FRAME_WIDTH	46

@interface MiscTableScroll (PrivateInternal)

- (id)responsibleDelegate:(MiscDelegateFlags::Selector)cmd;

// Private: border -> scroll
- (NSString*) border:(MiscBorderType)b getDelegateSlotTitle:(int)slot;
- (id) border:(MiscBorderType)b getDelegateSlotPrototype:(int)s;

// TableScroll(IncrementalSearch) -> TableScroll(Keyboard)
- (void) keyboardSelect:(NSEvent*)p;

- (MiscBorderView*)rowTitles;
- (MiscBorderView*)colTitles;
- (MiscCornerView*)cornerView;

- (void)setIsTrackingMouse:(BOOL)flag;
- (void)setClickedRow:(MiscCoord_P)r column:(MiscCoord_P)c;
- (void)clearClicked;

// Reset stale-old-selection in Table & Border views.
- (void)resetSelection;

// TableScroll(IO) -> TableScroll
- (void)doInit:(int)ver cornerTitle:(NSString*)s;

@end

#endif // __MiscTableScrollPrivate_h
