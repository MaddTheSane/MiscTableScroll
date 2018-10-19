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
// MiscTableScrollEdit.M
//
//	Text cell editing support for MiscTableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollEdit.M,v 1.9 99/06/15 03:28:11 sunshine Exp $
// $Log:	MiscTableScrollEdit.M,v $
// Revision 1.9  99/06/15  03:28:11  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Now posts new text will-edit & did-edit notifications instead of sending
// messages to the delegates directly.
// Fixed bug: Was only sending NSControlTextDidEndNotification if one of the
// delegates implemented the corresponding delegate method.  This was
// incorrect since it is possible that some other object may be listening for
// the notification as well.  It is now sent in all cases.
// Method renamed: trackingBy --> selectsByRows
// No longer unnecessarily imports <stdlib.h>.
// 
// Revision 1.8  1998/03/29 23:56:01  sunshine
// v138.1: Now uses NSColor's "system" colors for editing.
// Fixed bug: Was sending NSControlTextDidChangeNotification in
// -textDidBeginEditing: rather than NSControlTextDidBeginEditingNotification.
//
// Revision 1.7  98/03/23  07:48:00  sunshine
// v134.1: Added -suspendEditing / -resumeEditing.  Eliminated delegate
// -tableScroll:edit:atRow:column: methods.
//-----------------------------------------------------------------------------
#import "MiscTableScrollPrivate.h"
#import "MiscTableBorder.h"
#import "MiscTableView.h"
#import	<AppKit/NSCell.h>
#import <AppKit/NSControl.h>
#import	<AppKit/NSText.h>

typedef MiscDelegateFlags DF;

@implementation MiscTableScroll(Edit)

- (BOOL)isEditing { return editInfo.editing; }

//-----------------------------------------------------------------------------
// cellFrameAtRow:column:
//-----------------------------------------------------------------------------
- (NSRect)cellFrameAtRow:(int)row column:(int)col
{
    return [self convertRect:[tableView cellFrameAtRow:row column:col]
                    fromView:tableView];
}


//-----------------------------------------------------------------------------
// getRow:andCol:forPoint:
//-----------------------------------------------------------------------------
- (BOOL)getRow:(int*)row column:(int*)col forPoint:(NSPoint)point
{
    return [tableView getRow:row column:col
                    forPoint:[tableView convertPoint:point fromView:self]];
}


//-----------------------------------------------------------------------------
// - resendTextNotification:as:
//-----------------------------------------------------------------------------
- (void)resendTextNotification:(NSNotification*)n as:(NSString*)name
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:name object:self
     userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
               [n object], @"NSFieldEditor", 0]];
}


//-----------------------------------------------------------------------------
// postDidEditNotificationAtRow:column:changed:
//-----------------------------------------------------------------------------
- (void)postDidEditNotificationAtRow:(int)r column:(int)c changed:(BOOL)changed
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:MiscTableScrollDidEditNotification
     object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:changed], @"Changed",
                           [NSNumber numberWithInt:r], @"Row",
                           [NSNumber numberWithInt:c], @"Column", 0]];
}


//-----------------------------------------------------------------------------
// forceEditorDirty:
//	Unlike the NEXTSTEP 3.x Text system which *always* sends 
//	-textWillEnd:, OPENSTEP 4.x only sends -textShouldEndEditing: if the 
//	text was indeed edited.  However, -suspendEditing & -resumeEditing 
//	work by ending the old edit session and beginning a new one (without 
//	the informing the delegate or the cell).  The problem is that by 
//	ending the old edit session, the text system loses the knowledge that 
//	the user had changed the text, and consequently -textShouldEndEditing: 
//	may not be called.  This "hack" works around the problem by forcing 
//	the text system to flag itself as dirty.  (FIXME: The text is always 
//	forced dirty even if the old session was not dirty.  This errs on the 
//	side of safety, though.) 
//-----------------------------------------------------------------------------
- (void)forceEditorDirty:(NSText*)editor
{
    [editor replaceCharactersInRange:NSMakeRange(0,0) withString:@"x"];
    [editor setSelectedRange:NSMakeRange(0,1)];
    [editor delete:0];
}


//-----------------------------------------------------------------------------
// setupFieldEditor:
//-----------------------------------------------------------------------------
- (void)setupFieldEditor:(NSText*)editor
{
    [editor setDrawsBackground:YES];
    [editor setBackgroundColor:[NSColor textBackgroundColor]];
    [editor setTextColor:[NSColor textColor]];
    [editor setNeedsDisplay:YES];
}


//-----------------------------------------------------------------------------
// resumeEditing
//-----------------------------------------------------------------------------
- (void)resumeEditing
{
    if (editInfo.editing && --editInfo.suspended == 0)
    {
        int const row = editInfo.row;
        int const col = editInfo.col;
        
        NSText* const editor = [[self window] fieldEditor:YES forObject:self];
        editInfo.editor = [editor retain];
        id const cell = editInfo.cell;
        
        NSRect rect = [tableView cellInsideAtRow:row column:col];
        [tableView scrollRectToVisible:rect];
        
        [cell selectWithFrame:rect inView:tableView editor:editor
                     delegate:self start:0 length:0];
        [self setupFieldEditor:editor];
        [self forceEditorDirty:editor];
        [editor selectAll:0];
        
        [self setClickedRow:row column:col];
    }
}


//-----------------------------------------------------------------------------
// suspendEditing
//-----------------------------------------------------------------------------
- (void)suspendEditing
{
    if (editInfo.editing && editInfo.suspended++ == 0)
    {
        id const cell = editInfo.cell;
        NSText* const editor = editInfo.editor;
        NSString* const s = [[[editor string] copy] autorelease];
        [editor setDelegate:0]; // Prevent -textDidEndEditing: invocation.
        [cell endEditing:editor];
        [cell setStringValue:s];
        [editor release];
        editInfo.editor = 0;
    }
}


//-----------------------------------------------------------------------------
// cleanupEditing
//-----------------------------------------------------------------------------
- (void)cleanupEditing
{
    [editInfo.cell release];
    editInfo.cell = 0;
    [editInfo.editor release];
    editInfo.editor = 0;
    editInfo.editing = NO;
    editInfo.suspended = 0;
}


//-----------------------------------------------------------------------------
// finishEditing
//-----------------------------------------------------------------------------
- (BOOL)finishEditing
{
    NSWindow* win = [self window];
    if ([self isEditing] && [win makeFirstResponder:win])
        [win endEditingFor:editInfo.editor];
    return ![self isEditing];
}


//-----------------------------------------------------------------------------
// abortEditing
//-----------------------------------------------------------------------------
- (BOOL)abortEditing
{
    BOOL const rc = editInfo.editing;
    if (rc)
    {
        editInfo.editing = NO;
        int const r = editInfo.row;
        int const c = editInfo.col;
        
        if (editInfo.editor != 0)
            [editInfo.cell endEditing:editInfo.editor];
        [self cleanupEditing];
        
        id d;
        if ((d = [self responsibleDelegate:DF::DEL_ABORT_EDIT_AT]) != 0)
            [d tableScroll:self abortEditAtRow:r column:c];
        
        [self postDidEditNotificationAtRow:r column:c changed:NO];
        [self drawCellAtRow:r column:c];
    }
    return rc;
}


//-----------------------------------------------------------------------------
// getNext:editRow:column:
//-----------------------------------------------------------------------------
- (BOOL)getNext:(BOOL)foreward
        editRow:(MiscCoord_P*)p_row
         column:(MiscCoord_P*)p_col
{
    MiscCoord_P pr = *p_row;
    MiscCoord_P pc = *p_col;

    MiscTableBorder const* const br = rowInfo.border;
    MiscTableBorder const* const bc = colInfo.border;

    MiscCoord_V const v_row = br->physicalToVisual( pr );	// Start pos.
    MiscCoord_V const v_col = bc->physicalToVisual( pc );

    MiscCoord_V vr = v_row;
    MiscCoord_V vc = v_col;

    do  {
        if (foreward)
        {
            if (++vc >= num_cols)
            {
                vc = 0;
                if (++vr >= num_rows)
                    vr = 0;
                pr = br->visualToPhysical( vr );
            }
        }
        else
        {
            if (--vc < 0)
            {
                vc = num_cols - 1;
                if (--vr < 0)
                    vr = num_rows - 1;
                pr = br->visualToPhysical( vr );
            }
        }
        if (vc == v_col && vr == v_row)		// Wrapped to start pos.
            return NO;
        pc = bc->visualToPhysical( vc );
    }
    while (![self canEdit:0 atRow:pr column:pc]);

    *p_row = pr;
    *p_col = pc;
    return YES;
}


//-----------------------------------------------------------------------------
// getPreviousEditRow:column:
//-----------------------------------------------------------------------------
- (BOOL)getPreviousEditRow:(MiscCoord_P*)p_row column:(MiscCoord_P*)p_col
{
    return [self getNext:NO editRow:p_row column:p_col];
}


//-----------------------------------------------------------------------------
// getNextEditRow:column:
//-----------------------------------------------------------------------------
- (BOOL)getNextEditRow:(MiscCoord_P*)p_row column:(MiscCoord_P*)p_col
{
    return [self getNext:YES editRow:p_row column:p_col];
}


//-----------------------------------------------------------------------------
// textDidEndEditing:
//-----------------------------------------------------------------------------
- (void)textDidEndEditing:(NSNotification*)n
{
    id d;
    NSText* theText = [n object];
    int const why = [[[n userInfo] objectForKey:@"NSTextMovement"] intValue];

    editInfo.editing = NO;
    NSString* s = [[[theText string] copy] autorelease];
    [editInfo.cell endEditing:editInfo.editor];
    int const r = editInfo.row;
    int const c = editInfo.col;
    NSString* t = [self stringValueAtRow:r column:c];
    BOOL changed = ![s isEqualToString:t];
    if (changed)
    {
        if ((d = [self responsibleDelegate:DF::DEL_SET_STRINGVALUE_AT]) != 0)
            changed = [d tableScroll:self setStringValue:s atRow:r column:c];
        else
            [[self cellAtRow:r column:c] setStringValue:s];
    }
    [self cleanupEditing];

    [self postDidEditNotificationAtRow:r column:c changed:changed];
    [self drawCellAtRow:r column:c];

    if (changed)
    {
        if ([self autoSortRows])
            [self sortRow:r];
        if ([self autoSortColumns])
            [self sortColumn:c];
    }

    [self resendTextNotification:n as:NSControlTextDidEndEditingNotification];
    if ([self responsibleDelegate:DF::DEL_TEXT_DID_END] == 0)
    {
        MiscCoord_P row = (MiscCoord_P)r;
        MiscCoord_P col = (MiscCoord_P)c;

        switch (why)
        {
            case NSReturnTextMovement:
                [[self window] makeFirstResponder:tableView];
                [self sendAction];
                break;
                
            case NSTabTextMovement:
                if ([self getNext:YES editRow:&row column:&col])
                    [self editCellAtRow:row column:col];
                else
                    [[self window] selectNextKeyView:self];
                break;
                
            case NSBacktabTextMovement:
                if ([self getNext:NO editRow:&row column:&col])
                    [self editCellAtRow:row column:col];
                else
                    [[self window] selectPreviousKeyView:self];
                break;

                // FIXME: CTRL-TAB => nextText, CTRL-SHIFT-TAB => previousText
            default:
                break;
        }
    }
}


//-----------------------------------------------------------------------------
// textDidBeginEditing:
//-----------------------------------------------------------------------------
- (void)textDidBeginEditing:(NSNotification*)n
{
    [self resendTextNotification:n as:NSControlTextDidBeginEditingNotification];
}


//-----------------------------------------------------------------------------
// textDidChange:
//-----------------------------------------------------------------------------
- (void)textDidChange:(NSNotification*)n
{
    [self resendTextNotification:n as:NSControlTextDidChangeNotification];
}


//-----------------------------------------------------------------------------
// textShouldBeginEditing:
//-----------------------------------------------------------------------------
- (BOOL)textShouldBeginEditing:(NSText*)text
{
    id d = [self responsibleDelegate:DF::DEL_TEXT_WILL_CHANGE];
    if (d != 0)
        return [d control:(NSControl*)self textShouldBeginEditing:text];
    return YES;
}


//-----------------------------------------------------------------------------
// textShouldEndEditing:
//-----------------------------------------------------------------------------
- (BOOL)textShouldEndEditing:(NSText*)text
{
    id d = [self responsibleDelegate:DF::DEL_TEXT_WILL_END];
    if (d != 0)
        return [d control:(NSControl*)self textShouldEndEditing:text];
    return YES;
}


//-----------------------------------------------------------------------------
// edit:atRow:column:
//	NOTE *1*: Must set color *after* cell initiates editing, else cell will
//	install its own colors making text selection invisible.
//-----------------------------------------------------------------------------
- (void)edit:(NSEvent*)ev atRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    [[NSNotificationCenter defaultCenter]
     postNotificationName:MiscTableScrollWillEditNotification
     object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInt:row], @"Row",
                           [NSNumber numberWithInt:col], @"Column", 0]];
    
    id const cell = [[self cellAtRow:row column:col] copyWithZone:[self zone]];
    id const editor = [[self window] fieldEditor:YES forObject:self];

    editInfo.editing = YES;
    editInfo.row = row;
    editInfo.col = col;
    editInfo.editor = [editor retain];
    editInfo.cell = [cell retain];

    NSRect const rect = [tableView cellInsideAtRow:row column:col];
    [tableView scrollRectToVisible:rect];
    if (ev != 0)
        [cell editWithFrame:rect inView:tableView editor:editor
                   delegate:self event:ev];
    else
        [cell selectWithFrame:rect inView:tableView editor:editor
                     delegate:self start:0 length:[[cell stringValue] length]];

    [self setupFieldEditor:editor];		// NOTE *1*
}


//-----------------------------------------------------------------------------
// canEdit:atRow:column:
//-----------------------------------------------------------------------------
- (BOOL)canEdit:(NSEvent*)ev atRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    id d = [self responsibleDelegate:DF::DEL_CAN_EDIT_AT];
    if (d != 0)
        return [d tableScroll:self canEdit:ev atRow:row column:col];

    id const cell = [self cellAtRow:row column:col];
    if ([cell respondsToSelector:@selector(tableScroll:canEdit:atRow:column:)])
        return [cell tableScroll:self canEdit:ev atRow:row column:col];

    return (ev == 0 || [ev clickCount] == 2) &&
    [cell respondsToSelector:@selector(isEditable)] &&
    [cell respondsToSelector:@selector(isEnabled)] &&
    [cell isEditable] && [cell isEnabled];
}


//-----------------------------------------------------------------------------
// editIfAble:atRow:column:
//-----------------------------------------------------------------------------
- (BOOL)editIfAble:(NSEvent*)ev atRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    if ([self canEdit:ev atRow:row column:col])
    {
        [self edit:ev atRow:row column:col];
        return YES;
    }
    return NO;
}


//-----------------------------------------------------------------------------
// editCellAtRow:column:
//-----------------------------------------------------------------------------
- (void)editCellAtRow:(MiscCoord_P)row column:(MiscCoord_P)col
{
    [self clearSelection];
    if ([self selectsByRows])
    {
        [self selectRow:row];
        [self setCursorRow:row];
    }
    else
    {
        [self selectColumn:col];
        [self setCursorColumn:col];
    }
    [self setClickedRow:row column:col];
    [self edit:0 atRow:row column:col];
}

@end
