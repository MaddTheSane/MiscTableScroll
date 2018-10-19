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
// DirController.m
//
//	Manages application which demonstrates use of TableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirController.m,v 1.3 99/06/14 16:07:03 sunshine Exp $
// $Log:	DirController.m,v $
// Revision 1.3  99/06/14  16:07:03  sunshine
// v35.1: For clarity renamed -new: to -openDirectory:.
// 
// Revision 1.2  1997/03/23 01:41:00  sunshine
// v29.2: Brought into syncrhonization with LazyScrollDir v13.1 for OPENSTSEP.
//-----------------------------------------------------------------------------
#import "DirController.h"
#import "Defaults.h"
#import "DirWindow.h"
#import "SD_PageLayout.h"
#import <AppKit/NSNibLoading.h>
#import <AppKit/NSOpenPanel.h>
#import <AppKit/NSTextField.h>

@implementation DirController

//-----------------------------------------------------------------------------
// - init
//-----------------------------------------------------------------------------
- (id)init
    {
    [super init];
    infoPanel = 0;
    return self;
    }


//-----------------------------------------------------------------------------
// - dealloc
//-----------------------------------------------------------------------------
- (void)dealloc
    {
    if (infoPanel)
	[infoPanel release];
    [super dealloc];
    }


//-----------------------------------------------------------------------------
// - applicationDidFinishLaunching:
//-----------------------------------------------------------------------------
- (void)applicationDidFinishLaunching:(NSNotification*)n
    {
    [DirWindow launchDir:0];
    }


//-----------------------------------------------------------------------------
// - applicationWillTerminate:
//-----------------------------------------------------------------------------
- (void)applicationWillTerminate:(NSNotification*)n
    {
    [Defaults commit];
    }


//-----------------------------------------------------------------------------
// - runPageLayout:
//-----------------------------------------------------------------------------
- (void)runPageLayout:(id)sender
    {
    [[SD_PageLayout pageLayout] runModal];
    }


//-----------------------------------------------------------------------------
// - openDirectory:
//-----------------------------------------------------------------------------
- (void)openDirectory:(id)sender
    {
    static NSOpenPanel* panel = 0;
    if (panel == 0)
	{
	panel = [[NSOpenPanel openPanel] retain];
	[panel setTitle:@"Open Directory"];
	[panel setPrompt:@"Directory:"];
	[panel setCanChooseDirectories:YES];
	[panel setCanChooseFiles:NO];
	[panel setAllowsMultipleSelection:YES];
	[panel setTreatsFilePackagesAsDirectories:YES];
	}

    if ([panel runModal] == NSOKButton)
    	{
	unsigned int i;
	NSArray* filenames = [panel filenames];
	for (i = [filenames count]; i-- > 0; )
	    [DirWindow launchDir:[filenames objectAtIndex:i]];
	} 
    }


//-----------------------------------------------------------------------------
// - info:
//-----------------------------------------------------------------------------
- (void)info:(id)sender
    {
    if (infoPanel == 0)
	{
	NSString* s;
	[NSBundle loadNibNamed:@"Info" owner:self];
	s = [[NSBundle bundleForClass:[self class]]
			pathForResource:@"README" ofType:@"rtf"];
	if (s == 0)
	    s = [[NSBundle bundleForClass:[self class]]
			pathForResource:@"README" ofType:@"rtfd"];
	if (s != 0)
	    [infoText readRTFDFromFile:s];
	}
    [infoPanel makeKeyAndOrderFront:self]; 
    }

@end
