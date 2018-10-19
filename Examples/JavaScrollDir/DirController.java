//=============================================================================
//
//	Copyright (C) 1999 by Paul S. McCarthy and Eric Sunshine.
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
// DirController.java
//
//	Manages application which demonstrates use of TableScroll.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirController.java,v 1.1 99/06/14 15:40:39 sunshine Exp $
// $Log:	DirController.java,v $
// Revision 1.1  99/06/14  15:40:39  sunshine
// v1.1: Application controller.
// 
//-----------------------------------------------------------------------------
import java.util.Enumeration;
import com.apple.yellow.foundation.*;
import com.apple.yellow.application.*;

public class DirController {
    NSPanel infoPanel;
    NSText infoText;

//-----------------------------------------------------------------------------
// applicationDidFinishLaunching
//-----------------------------------------------------------------------------
public void applicationDidFinishLaunching( NSNotification n ) {
    DirWindow.launchDir( null );
}


//-----------------------------------------------------------------------------
// applicationWillTerminate
//-----------------------------------------------------------------------------
public void applicationWillTerminate( NSNotification n ) {
    Defaults.commit();
}


//-----------------------------------------------------------------------------
// runPageLayout
//-----------------------------------------------------------------------------
public void runPageLayout( Object sender ) {
    SD_PageLayout.sharedInstance().runModal();
}


//-----------------------------------------------------------------------------
// openDirectory
//-----------------------------------------------------------------------------
public void openDirectory( Object sender ) {
    NSOpenPanel panel = new NSOpenPanel();
    panel.setTitle( "Open Directory" );
    panel.setPrompt( "Directory:" );
    panel.setCanChooseDirectories( true );
    panel.setCanChooseFiles( false );
    panel.setAllowsMultipleSelection( true );
    panel.setTreatsFilePackagesAsDirectories( true );

    if (panel.runModal() == NSPanel.OKButton) {
	Enumeration filenames = panel.filenames().objectEnumerator();
	while (filenames.hasMoreElements())
	    DirWindow.launchDir( (String)filenames.nextElement() );
    }
}


//-----------------------------------------------------------------------------
// info
//-----------------------------------------------------------------------------
public void info( Object sender ) {
    if (infoPanel == null) {
	NSApplication.loadNibNamed( "Info", this );
	NSBundle b = NSBundle.bundleForClass( this.getClass() );
	String s = b.pathForResource( "README", "rtf" );
	if (s == null)
	    s = b.pathForResource( "README", "rtfd" );
	if (s != null)
	    infoText.readRTFDFromFile(s);
    }
    infoPanel.makeKeyAndOrderFront(null);
}

} // class DirController
