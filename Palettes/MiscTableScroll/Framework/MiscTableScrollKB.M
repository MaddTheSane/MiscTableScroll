//=============================================================================
//
//	Copyright (C) 1996-1999 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTableScrollKB.M
//
//	Keyboard event handling for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollKB.M,v 1.8 99/06/15 03:32:16 sunshine Exp $
// $Log:	MiscTableScrollKB.M,v $
// Revision 1.8  99/06/15  03:32:16  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Method renamed: trackingBy --> selectsByRows
// 
// Revision 1.7  1997/06/18 10:50:46  sunshine
// v125.9: Worked around Objective-C++ compiler crash in OPENSTEP 4.2 for NT
// when sending message to 'super' from within a category.
//
//  Revision 1.6  97/04/15  09:08:47  sunshine
//  v0.125.8: Added "MiscTableScroll/" prefix to #import to facilitate new
//  framework organization.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscTableScroll.h>
#import "MiscTableView.h"

enum KB_Action
    {
    ACT_IGNORE,
    ACT_SELECT,
    ACT_PERFORM,
    ACT_LEFT,
    ACT_RIGHT,
    ACT_UP,
    ACT_DOWN,
    ACT_PAGE_LEFT,
    ACT_PAGE_RIGHT,
    ACT_PAGE_UP,
    ACT_PAGE_DOWN,
    ACT_LEFT_EDGE,
    ACT_RIGHT_EDGE,
    ACT_TOP_EDGE,
    ACT_BOT_EDGE,

    ACT_NUM_ACTIONS
    };

enum
    {
    K_RETURN		= '\r',
    K_SPACE		= ' ' ,
    K_LEFT		= NSLeftArrowFunctionKey,
    K_UP		= NSUpArrowFunctionKey,
    K_RIGHT		= NSRightArrowFunctionKey,
    K_DOWN		= NSDownArrowFunctionKey,
    K_KP_LEFT		= '4',
    K_KP_UP		= '8',
    K_KP_RIGHT		= '6',
    K_KP_DOWN		= '2',
    K_KP_PAGE_UP	= '9',
    K_KP_PAGE_DOWN	= '3',
    K_KP_HOME		= '7',
    K_KP_END		= '1',
    K_KP_INSERT		= '0',
    K_KP_ENTER		= 0x03,
    K_PAGE_UP		= NSPageUpFunctionKey,
    K_PAGE_DOWN		= NSPageDownFunctionKey,
    K_HOME		= NSHomeFunctionKey,
    K_END		= NSEndFunctionKey,
    };


//=============================================================================
// IMPLEMENTATION
//=============================================================================
@implementation MiscTableScroll(Keyboard)

//-----------------------------------------------------------------------------
// - keyboardSelect:
//-----------------------------------------------------------------------------
- (void)keyboardSelect:(NSEvent*)p 
    {
    [tableView keyboardSelect:p];
    [self clearSlotSelection:		// Clear *other* border.
	[tableView selectsByRows] ? MISC_COL_BORDER : MISC_ROW_BORDER];
    [self selectionChanged];
    [self sendActionIfEnabled];
    }


//-----------------------------------------------------------------------------
// goFirstSlot:
//-----------------------------------------------------------------------------
- (void)goFirstSlot:(MiscBorderType)b
    {
    if ([self numberOfSlots:b] > 0)
	{
	int const s = [self border:b slotAtPosition:0];
	NSWindow* const w = [self window];
	[w disableFlushWindow];
	[self border:b setCursorSlot:s];
	[self border:b setFirstVisibleSlot:s];
	[w enableFlushWindow];
	[w flushWindow];
	}
    }


//-----------------------------------------------------------------------------
// goLastSlot
//-----------------------------------------------------------------------------
- (void)goLastSlot:(MiscBorderType)b
    {
    int const n = [self numberOfSlots:b];
    if (n > 0)
	{
	int s = [self border:b slotAtPosition:(n - 1)];
	NSWindow* const w = [self window];
	[w disableFlushWindow];
	[self border:b setCursorSlot:s];
	[self border:b setLastVisibleSlot:s];
	[w enableFlushWindow];
	[w flushWindow];
	}
    }


//-----------------------------------------------------------------------------
// goPrevPage:
//-----------------------------------------------------------------------------
- (void)goPrevPage:(MiscBorderType)b
    {
    if ([self numberOfSlots:b] > 0)
	{
	int sFirst = [self firstVisibleSlot:b];
	int const sLast  = [self lastVisibleSlot:b];
	int const v = [self border:b slotPosition:sFirst];
	if (sFirst == sLast && v > 0)
	    sFirst = [self border:b slotAtPosition:(v - 1)];
	NSWindow* const w = [self window];
	[w disableFlushWindow];
	[self border:b setLastVisibleSlot:sFirst];
	if (b == ([self selectsByRows] ? MISC_ROW_BORDER : MISC_COL_BORDER))
	    [self border:b setCursorSlot:[self firstVisibleSlot:b]];
	[w enableFlushWindow];
	[w flushWindow];
	}
    }


//-----------------------------------------------------------------------------
// goNextPage:
//-----------------------------------------------------------------------------
- (void)goNextPage:(MiscBorderType)b
    {
    int const lim = [self numberOfSlots:b];
    if (lim > 0)
	{
	int const sFirst = [self firstVisibleSlot:b];
	int sLast = [self lastVisibleSlot:b];
	int const v = [self border:b slotPosition:sLast];
	if (sFirst == sLast && v < lim - 1)
	    sLast = [self border:b slotAtPosition:(v + 1)];
	NSWindow* const w = [self window];
	[w disableFlushWindow];
	[self border:b setFirstVisibleSlot:sLast];
	if (b == ([self selectsByRows] ? MISC_ROW_BORDER : MISC_COL_BORDER))
	    [self border:b setCursorSlot:[self lastVisibleSlot:b]];
	[w enableFlushWindow];
	[w flushWindow];
	}
    }


//-----------------------------------------------------------------------------
// - classifyFunctionKey:
//-----------------------------------------------------------------------------
- (KB_Action)classifyFunctionKey:(NSEvent*)p
    {
    KB_Action deed = ACT_IGNORE;
    switch ([[p charactersIgnoringModifiers] characterAtIndex:0])
	{
	case K_LEFT:		deed = ACT_LEFT;	break;
	case K_RIGHT:		deed = ACT_RIGHT;	break;
	case K_UP:		deed = ACT_UP;		break;
	case K_DOWN:		deed = ACT_DOWN;	break;
	case K_PAGE_UP:		deed = ACT_PAGE_UP;	break;
	case K_PAGE_DOWN:	deed = ACT_PAGE_DOWN;	break;
	case K_HOME:		deed = ACT_TOP_EDGE;	break;
	case K_END:		deed = ACT_BOT_EDGE;	break;
	}
    return deed;
    }


//-----------------------------------------------------------------------------
// - classifyOtherKey:
//-----------------------------------------------------------------------------
- (KB_Action)classifyOtherKey:(NSEvent*)p
    {
    KB_Action deed = ACT_IGNORE;
    switch ([[p charactersIgnoringModifiers] characterAtIndex:0])
	{
	case K_SPACE:		deed = ACT_SELECT;	break;
	case K_RETURN:		deed = ACT_PERFORM;	break;
	}
    return deed;
    }


//-----------------------------------------------------------------------------
// - classifyNumericPadKey:
//-----------------------------------------------------------------------------
- (KB_Action)classifyNumericPadKey:(NSEvent*)p
    {
    KB_Action deed = ACT_IGNORE;
    unichar const charCode =
		[[p charactersIgnoringModifiers] characterAtIndex:0];

    if (charCode == K_KP_ENTER)
	deed = ACT_PERFORM;
    else if ('0' <= charCode && charCode <= '9')
	{
	static KB_Action const ACTS[] =
	    {
	    ACT_SELECT,		// KP 0 (insert)
	    ACT_BOT_EDGE,	// KP 1 (end)
	    ACT_DOWN,		// KP 2 (arrow down)
	    ACT_PAGE_DOWN,	// KP 3 (page down)
	    ACT_LEFT,		// KP 4 (arrow left)
	    ACT_IGNORE,		// KP 5
	    ACT_RIGHT,		// KP 6 (arrow right)
	    ACT_TOP_EDGE,	// KP 7 (home)
	    ACT_UP,		// KP 8 (arrow up)
	    ACT_PAGE_UP		// KP 9 (page up)
	    };
	deed = ACTS[ charCode - '0' ];
	}
    return deed;
    }


//-----------------------------------------------------------------------------
// - classifyFlags:forAction:
//-----------------------------------------------------------------------------
- (KB_Action)classifyFlags:(int)flags forAction:(KB_Action)deed
    {
    static KB_Action const MODIFIED_ACTIONS[ ACT_NUM_ACTIONS ] =
	{
//--	Becomes...		Was...		--//
	ACT_IGNORE,		// ACT_IGNORE
	ACT_SELECT,		// ACT_SELECT
	ACT_PERFORM,		// ACT_PERFORM
	ACT_PAGE_LEFT,		// ACT_LEFT
	ACT_PAGE_RIGHT,		// ACT_RIGHT
	ACT_PAGE_UP,		// ACT_UP
	ACT_PAGE_DOWN,		// ACT_DOWN
	ACT_PAGE_LEFT,		// ACT_PAGE_LEFT
	ACT_PAGE_RIGHT,		// ACT_PAGE_RIGHT
	ACT_PAGE_LEFT,		// ACT_PAGE_UP
	ACT_PAGE_RIGHT,		// ACT_PAGE_DOWN
	ACT_LEFT_EDGE,		// ACT_LEFT_EDGE
	ACT_RIGHT_EDGE,		// ACT_RIGHT_EDGE
	ACT_LEFT_EDGE,		// ACT_TOP_EDGE
	ACT_RIGHT_EDGE		// ACT_BOT_EDG
	};
    int const FLAGS = NSControlKeyMask | NSAlternateKeyMask | NSShiftKeyMask;
    if ((flags & FLAGS) != 0)
	return MODIFIED_ACTIONS[ deed ];
    return deed;
    }


//-----------------------------------------------------------------------------
// - classifyKeyDown:
//-----------------------------------------------------------------------------
- (KB_Action)classifyKeyDown:(NSEvent*)p
    {
    KB_Action deed = ACT_IGNORE;
    unsigned int const flags = [p modifierFlags];
    if ((flags & NSCommandKeyMask) == 0)
	{
	if ((flags & NSFunctionKeyMask) != 0)
	    deed = [self classifyFunctionKey:p];
	else if ((flags & NSNumericPadKeyMask) != 0)
	    deed = [self classifyNumericPadKey:p];
	else
	    deed = [self classifyOtherKey:p];

	if (deed != ACT_IGNORE)
	    deed = [self classifyFlags:flags forAction:deed];
	}
    return deed;
    }


//-----------------------------------------------------------------------------
// - keyDown:
//-----------------------------------------------------------------------------
- (void)keyDown:(NSEvent*)p 
    {
    KB_Action deed = [self classifyKeyDown:p];
    BOOL handled = (deed != ACT_IGNORE);
    if (handled)
	{
	switch (deed)
	    {
	    case ACT_SELECT:	[self keyboardSelect:p];		break;
	    case ACT_PERFORM:	[self sendDoubleActionIfEnabled];	break;
	    case ACT_UP:	[tableView moveCursorBy:-1];		break;
	    case ACT_DOWN:	[tableView moveCursorBy: 1];		break;
	    case ACT_LEFT:	[tableView moveCursorBy:-1];		break;
	    case ACT_RIGHT:	[tableView moveCursorBy: 1];		break;
	    case ACT_PAGE_LEFT:	[self goPrevPage: MISC_COL_BORDER];	break;
	    case ACT_PAGE_RIGHT:[self goNextPage: MISC_COL_BORDER];	break;
	    case ACT_PAGE_UP:	[self goPrevPage: MISC_ROW_BORDER];	break;
	    case ACT_PAGE_DOWN:	[self goNextPage: MISC_ROW_BORDER];	break;
	    case ACT_LEFT_EDGE:	[self goFirstSlot:MISC_COL_BORDER];	break;
	    case ACT_RIGHT_EDGE:[self goLastSlot: MISC_COL_BORDER];	break;
	    case ACT_TOP_EDGE:	[self goFirstSlot:MISC_ROW_BORDER];	break;
	    case ACT_BOT_EDGE:	[self goLastSlot: MISC_ROW_BORDER];	break;	
	    default:		handled = NO;				break;
	    }
	}

    if (!handled && ![self incrementalSearch:p])
	[self superKeyDown:p];
    }

@end
