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
// DirWindow.java
//
//	Manages window which displays directory listing.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirWindow.java,v 1.2 99/06/30 09:30:25 sunshine Exp $
// $Log:	DirWindow.java,v $
// Revision 1.2  99/06/30  09:30:25  sunshine
// v1.1: Ported to final release of MacOS/X Server.
// Behavior of Objective-to-Java bridge changed with regards to weakly
// referenced objects.  Had to accomodate new behavior by creating strong
// references to avoid "message sent to freed object" error.
// 
//-----------------------------------------------------------------------------
import java.io.File;
import java.text.DateFormat;
import java.util.Enumeration;
import com.apple.yellow.foundation.*;
import com.apple.yellow.application.*;
import org.misckit.yellow.application.TableScroll;

class DirWindow implements java.io.FilenameFilter {
    private static final int ICON_SLOT = 0;
    private static final int NAME_SLOT = 1;
    private static final int LOCK_SLOT = 2;
    private static final int SIZE_SLOT = 3;
    private static final int DATE_SLOT = 4;
    private static final int PERM_SLOT = 5;
    private static final int MAX_SLOT = PERM_SLOT + 1;

    private static final int CASCADE_MAX = 10;
    private static final float CASCADE_DELTA_X = 20;
    private static final float CASCADE_DELTA_Y = 20;
    private static int CASCADE_COUNTER = 0;
    private static float CASCADE_ORIGIN_X;
    private static float CASCADE_ORIGIN_Y;

    private static boolean DEFAULT_AUTO_SORT = true;
    private static boolean DEFAULT_ROW_NUMBERS = false;
    private static boolean DEFAULT_SHOW_HIDDEN = false;
    private static boolean DEFAULT_HIGHLIGHT_DIRS = false;
    private static boolean DEFAULT_DRAG_UNSCALED = true;
    private static NSColor DEFAULT_COLOR;
    private static NSSize DEFAULT_WIN_SIZE;
    private static NSFont DEFAULT_FONT = null;
    private static NSMutableArray OPEN_DIRS = null;
    private static NSImage LOCKED_IMAGE = null;
    private static NSImage UNLOCKED_IMAGE = null;
    private static DateFormat DATE_FORMAT = DateFormat.getInstance();

    private static final String COLOR_DEF = "DirColor";
    private static final String SIZE_DEF = "DirSize";
    private static final String FONT_DEF = "DirFont";
    private static final String SORT_DEF = "AutoSort";
    private static final String HIDDEN_DEF = "ShowHidden";
    private static final String HLIGHT_DEF = "HighlightDirs";
    private static final String UNSCALED_DEF = "DragUnscaled";
    private static final String COL_SIZES_DEF = "ColSizes";
    private static final String COL_ORDER_DEF = "ColOrder";
    private static final String ROW_NUMBERS_DEF = "RowNumbers";

    private static final String LOCKED_IMAGE_S = "Lock.secure";
    private static final String UNLOCKED_IMAGE_S = "Lock.insecure";

    private static final String DA_SHORT_NAME = "ShortName";
    private static final String DA_SOFT_LINK = "SoftLink";
    private static final String DA_IS_DIRECTORY = "IsDirectory";
    private static final String DA_IS_LOCKED = "IsLocked";
    private static final String DA_CAN_TOGGLE_LOCK = "CanToggleLock";
    private static final String DA_SCALED_ICON = "ScaledIcon";
    private static final String DA_UNSCALED_ICON = "UnscaledIcon";

    TableScroll scroll;
    NSWindow window;
    NSButton autoSortSwitch;
    NSButton cdButton;
    NSButton dragUnscaledSwitch;
    NSButton hiddenFilesSwitch;
    NSButton highlightSwitch;
    NSButton refreshButton;
    NSButton rowNumbersSwitch;
    NSTextField countField;
    String path;
    boolean writable;
    boolean autoSort;
    boolean dragUnscaled;
    boolean highlightDirs;
    boolean showHidden;


//-----------------------------------------------------------------------------
// initClass
//
// *NOTE*
//	This functionality can not be in a static initializer since it would
//	execute before NSScreen is available for query.
//
// *NOTE* OPEN_DIRS
//	An NSArray is used instead of a java.util.Vector to hold the list of
//	DirWindow objects in order to keep the Objective-C to Java bridge from
//	freeing the DirWindow's Objective-C proxy out from underneath us.
//	This is necessary in cases where a pure Java object, such as
//	DirWindow, is only referenced "weakly" on the Objective-C side.  Even
//	though DirWindow is the delegate of both the NSWindow and the
//	TableScroll, we say that it is referenced weakly since neither object
//	"retains" it.  Such weakly referenced objects are automatically freed
//	by the bridge since it has no way of knowing that they are needed.  In
//	order to work around this problem, such objects must be "strongly"
//	referenced on the Objective-C side.  In our case this is accomplished
//	by maintaining the list of active DirWindow objects in an NSArray
//	which retains each of its members.
//-----------------------------------------------------------------------------
private static void initClass() {
    if (OPEN_DIRS == null) {
	NSSize s = NSScreen.mainScreen().frame().size();
	CASCADE_ORIGIN_X = s.width() / 4;
	CASCADE_ORIGIN_Y = s.height() - 60;
	OPEN_DIRS = new NSMutableArray();		// *NOTE* OPEN_DIRS
	LOCKED_IMAGE   = NSImage.imageNamed( LOCKED_IMAGE_S );
	UNLOCKED_IMAGE = NSImage.imageNamed( UNLOCKED_IMAGE_S );
	DEFAULT_COLOR = Defaults.getColor( COLOR_DEF, NSColor.controlColor() );
	DEFAULT_AUTO_SORT = Defaults.getBoolean( SORT_DEF, true );
	DEFAULT_SHOW_HIDDEN = Defaults.getBoolean( HIDDEN_DEF, false );
	DEFAULT_ROW_NUMBERS = Defaults.getBoolean( ROW_NUMBERS_DEF, false );
	DEFAULT_HIGHLIGHT_DIRS = Defaults.getBoolean( HLIGHT_DEF, false );
	DEFAULT_DRAG_UNSCALED = Defaults.getBoolean( UNSCALED_DEF, true );
    }
}


//-----------------------------------------------------------------------------
// normalizePath
//-----------------------------------------------------------------------------
private static String normalizePath( String s ) {
    File f = new File(s);
    try { s = f.getCanonicalPath(); } catch (java.io.IOException e) {}
    return s;
}


//-----------------------------------------------------------------------------
// fmtIcon
//-----------------------------------------------------------------------------
private void fmtIcon( String name, File file, NSCell cell ) {
    NSImage i = NSWorkspace.sharedWorkspace().iconForFile( file.getPath() );
    cell.setRepresentedObject(i);

    float w = scroll.columnSize( ICON_SLOT );	if (w == 0) w = 18;
    float h = scroll.uniformSizeRows();		if (h == 0) h = 18;
    float s = (w < h ? w : h) - 1;

    try { i = (NSImage)i.clone(); } catch (CloneNotSupportedException e) {}
    i.setScalesWhenResized( true );
    i.setSize( new NSSize(s,s) );
    cell.setImage(i);
}


//-----------------------------------------------------------------------------
// fmtLock
//-----------------------------------------------------------------------------
private void fmtLock( String name, File file, NSCell cell ) {
    final boolean unlocked = writable && !name.equals("..");
    cell.setState( unlocked ? 1 : 0 );
    cell.setEnabled( unlocked );
}


//-----------------------------------------------------------------------------
// fmtName
//-----------------------------------------------------------------------------
private void fmtName( String name, File file, NSCell cell ) {
    cell.setStringValue( name );
}


//-----------------------------------------------------------------------------
// fmtSize
//-----------------------------------------------------------------------------
private void fmtSize( String name, File file, NSCell cell ) {
    cell.setIntValue( (int)file.length() );
}


//-----------------------------------------------------------------------------
// fmtDate
//-----------------------------------------------------------------------------
private void fmtDate( String name, File file, NSCell cell ) {
    java.util.Date d = new java.util.Date( file.lastModified() );
    cell.setStringValue( DATE_FORMAT.format(d) );
    cell.setTag( (int)file.lastModified() );
}


//-----------------------------------------------------------------------------
// fmtPerm
//-----------------------------------------------------------------------------
private void fmtPerm( String name, File file, NSCell cell ) {
    final boolean r = file.canRead();
    final boolean w = file.canWrite();
    String s;
    if (r && w) s = "read/write";
    else if (r) s = "read";
    else if (w) s = "write";
    else s = "none";
    cell.setStringValue(s);
    cell.setTag( file.isDirectory() ? 1 : 0);
}


//-----------------------------------------------------------------------------
// formatCell
//-----------------------------------------------------------------------------
private void formatCell( String name, File f, NSCell cell, int c ) {
    switch (c) {
	case ICON_SLOT: fmtIcon( name, f, cell ); break;
	case NAME_SLOT: fmtName( name, f, cell ); break;
	case LOCK_SLOT: fmtLock( name, f, cell ); break;
	case SIZE_SLOT: fmtSize( name, f, cell ); break;
	case DATE_SLOT: fmtDate( name, f, cell ); break;
	case PERM_SLOT: fmtPerm( name, f, cell ); break;
    }
}


//-----------------------------------------------------------------------------
// cascade
//-----------------------------------------------------------------------------
private void cascade() {
    float left = CASCADE_ORIGIN_X + (CASCADE_DELTA_X * CASCADE_COUNTER);
    float top  = CASCADE_ORIGIN_Y - (CASCADE_DELTA_Y * CASCADE_COUNTER);
    window.setFrameTopLeftPoint( new NSPoint(left, top) );
    if (++CASCADE_COUNTER >= CASCADE_MAX)
	CASCADE_COUNTER = 0;
}


//-----------------------------------------------------------------------------
// isDirAtRow
//-----------------------------------------------------------------------------
private boolean isDirAtRow( int r ) {
    return (scroll.tagAtLocation( r, PERM_SLOT ) != 0);
}


//-----------------------------------------------------------------------------
// updateButtons
//-----------------------------------------------------------------------------
private void updateButtons() {
    final boolean enable = scroll.numberOfSelectedRows() == 1 &&
	isDirAtRow( scroll.selectedRow() );
    if (enable != cdButton.isEnabled())
	cdButton.setEnabled( enable );
}


//-----------------------------------------------------------------------------
// trySendingMessage
//-----------------------------------------------------------------------------
private void trySendingMessage( String message, Object target,
				Object arg, Class argClass ) {
    try {
	java.lang.reflect.Method method =
		target.getClass().getMethod(message, new Class[] { argClass });
	method.invoke( target, new Object[] { arg } );
    } catch (Exception e) {}
}


//-----------------------------------------------------------------------------
// trySendingMessage
//-----------------------------------------------------------------------------
private void trySendingMessage( String message, Object target, Object arg ) {
    trySendingMessage( message, target, arg, arg.getClass() );
}


//-----------------------------------------------------------------------------
// setRowColorAndUseOwner
//-----------------------------------------------------------------------------
private void setRowColorAndUseOwner(int row, NSColor color, boolean useOwner) {
    for (int i = MAX_SLOT; i-- >= 0; ) {
	NSCell cell = scroll.cellAtLocation( row, i );
	if (!useOwner)
	    trySendingMessage( "setBackgroundColor", cell, color );
	else {
	    trySendingMessage( "setOwnerBackgroundColor", cell, color );
	    trySendingMessage( "setUseOwnerBackgroundColor", cell,
		new Boolean(true), boolean.class );
	}
    }
}


//-----------------------------------------------------------------------------
// scrollColor
//-----------------------------------------------------------------------------
private NSColor scrollColor() {
    if (DEFAULT_COLOR.equals( NSColor.controlColor() ))
        return TableScroll.defaultBackgroundColor();
    else
        return DEFAULT_COLOR;
}


//-----------------------------------------------------------------------------
// highlightRow
//-----------------------------------------------------------------------------
private void highlightRow( int r, boolean flag ) {
    if (flag)
	setRowColorAndUseOwner( r, NSColor.cyanColor(), false );
    else
	setRowColorAndUseOwner( r, scrollColor(), true );
}


//-----------------------------------------------------------------------------
// refreshHighlighting
//-----------------------------------------------------------------------------
private void refreshHighlighting( boolean flag ) {
    for (int i = scroll.numberOfRows(); i-- > 0; )
	if (isDirAtRow(i))
	    highlightRow( i, flag );
}


//-----------------------------------------------------------------------------
// releaseImages
//-----------------------------------------------------------------------------
private void releaseImages() {
    for (int i = scroll.numberOfRows(); i-- > 0; ) {
	NSCell cell = scroll.cellAtLocation( i, ICON_SLOT );
	cell.setImage( null );			// Scaled image.
	cell.setRepresentedObject( null );	// Unscaled image.
    }
}


//-----------------------------------------------------------------------------
// fullPathAtRow
//-----------------------------------------------------------------------------
private String fullPathAtRow( int r ) {
    return path + File.separator + scroll.stringValueAtLocation(r, NAME_SLOT);
}


//-----------------------------------------------------------------------------
// tableScrollChangeFont
//-----------------------------------------------------------------------------
public void tableScrollChangeFont( NSNotification n ) {
    DEFAULT_FONT = (NSFont)n.userInfo().objectForKey( "NewFont" );
    Defaults.set( FONT_DEF, DEFAULT_FONT );
}


//-----------------------------------------------------------------------------
// tableScrollSlotResized
//-----------------------------------------------------------------------------
public void tableScrollSlotResized( NSNotification n ) {
    Defaults.set( COL_SIZES_DEF, scroll.columnSizesAsString() );
}


//-----------------------------------------------------------------------------
// saveSlotOrderForBorder
//-----------------------------------------------------------------------------
private void saveSlotOrderForBorder( NSNotification n ) {
    int border = ((Integer)n.userInfo().objectForKey( "Border" )).intValue();
    if (border == TableScroll.BORDER_COLUMN)
	Defaults.set( COL_ORDER_DEF, scroll.columnOrderAsString() );
}


//-----------------------------------------------------------------------------
// tableScrollSlotDragged
//-----------------------------------------------------------------------------
public void tableScrollSlotDragged( NSNotification n ) {
    saveSlotOrderForBorder(n);
}


//-----------------------------------------------------------------------------
// tableScrollSlotSortReversed
//-----------------------------------------------------------------------------
public void tableScrollSlotSortReversed( NSNotification n ) {
    saveSlotOrderForBorder(n);
}


//-----------------------------------------------------------------------------
// tableScrollCanEditAtLocation
//-----------------------------------------------------------------------------
public boolean tableScrollCanEditAtLocation( TableScroll ts, NSEvent event,
	int row, int col ) {
    return ((event == null || event.clickCount() == 2) && col == NAME_SLOT &&
	ts.cellAtLocation( row, LOCK_SLOT ).state() != 0);
}


//-----------------------------------------------------------------------------
// tableScrollDraggingSourceOperationMask
//-----------------------------------------------------------------------------
public int tableScrollDraggingSourceOperationMask(
	TableScroll s, boolean isLocal ) {
    return NSDraggingInfo.DragOperationAll;
}


//-----------------------------------------------------------------------------
// tableScrollIgnoreModifierKeysWhileDragging
//-----------------------------------------------------------------------------
public boolean tableScrollIgnoreModifierKeysWhileDragging( TableScroll s ) {
    return false;
}


//-----------------------------------------------------------------------------
// tableScrollPreparePasteboardForDragOperationAtLocation
//-----------------------------------------------------------------------------
public void tableScrollPreparePasteboardForDragOperationAtLocation(
	TableScroll s, NSPasteboard pb, int row, int col ) {
    String file = fullPathAtRow( row );
    pb.declareTypes( new NSArray(NSPasteboard.FilenamesPboardType), null );
    pb.setPropertyListForType( new NSArray(file),
	NSPasteboard.FilenamesPboardType );
}


//-----------------------------------------------------------------------------
// tableScrollAllowDragOperationAtLocation
//-----------------------------------------------------------------------------
public boolean tableScrollAllowDragOperationAtLocation(
	TableScroll s, int row, int col ) {
    return (col == ICON_SLOT);
}


//-----------------------------------------------------------------------------
// tableScrollImageForDragOperationAtLocation
//-----------------------------------------------------------------------------
public NSImage tableScrollImageForDragOperationAtLocation(
	TableScroll s, int row, int col ) {
    return dragUnscaled ?
	(NSImage)s.cellAtLocation(row,col).representedObject() : null;
}


//-----------------------------------------------------------------------------
// addFile
//-----------------------------------------------------------------------------
private void addFile( String name, File file ) {
    scroll.addRow();
    int r = scroll.numberOfRows() - 1;
    for (int c = 0; c < MAX_SLOT; c++)
	formatCell( name, file, scroll.cellAtLocation(r, c), c );

    if (highlightDirs && file.isDirectory())
	highlightRow( r, true );
}


//-----------------------------------------------------------------------------
// accept -- java.io.FilenameFilter interface conformance.
//-----------------------------------------------------------------------------
public boolean accept( File dir, String name ) {
    return (showHidden || !name.startsWith("."));
}


//-----------------------------------------------------------------------------
// fillScroll
//-----------------------------------------------------------------------------
private void fillScroll() {
    File directory = new File( path );
    writable = directory.canWrite();
    long totalBytes = 0;

    releaseImages();
    scroll.empty();
    addFile( "..", new File(normalizePath(path + File.separator + "..")) );

    String[] files = directory.list( this );
    for (int i = 0; i < files.length; i++) {
	String name = files[i];
	File file = new File( directory, name );
	totalBytes += file.length();
	addFile( name, file );
    }

    if (scroll.autoSortRows())
	scroll.sortRows();
    scroll.sizeToCells();

    countField.setStringValue(
	scroll.numberOfRows() + " files   " + totalBytes + " bytes" );

    updateButtons();
}


//-----------------------------------------------------------------------------
// setPath
//-----------------------------------------------------------------------------
private void setPath( String dirname ) {
    if (dirname == null) dirname = NSSystem.currentHomeDirectory();
    if (dirname == null || dirname.length() == 0) dirname = "/";
    path = dirname;
    window.setTitleWithRepresentedFilename( path );
}


//-----------------------------------------------------------------------------
// loadDirectory
//-----------------------------------------------------------------------------
private void loadDirectory( String dirname ) {
    setPath( dirname );
    fillScroll();
    }


//-----------------------------------------------------------------------------
// export
//-----------------------------------------------------------------------------
public void export( Object sender ) {
    TableScroll.Exporter.commonInstance().exportTableScroll( scroll );
}


//-----------------------------------------------------------------------------
// printDirectory
//-----------------------------------------------------------------------------
public void printDirectory( Object sender ) {
    scroll.print( null );
}


//-----------------------------------------------------------------------------
// openSelected
//-----------------------------------------------------------------------------
public void openSelected( Object sender ) {
    if (scroll.hasRowSelection()) {
	NSArray list = scroll.selectedRows();
	for (int i = list.count(); i-- > 0; ) {
	    final int r = ((Integer)list.objectAtIndex(i)).intValue();
	    String s = fullPathAtRow(r);
	    if (isDirAtRow(r))
		launchDir(s);
	    else
		NSWorkspace.sharedWorkspace().openFile(s);
	}
    }
}


//-----------------------------------------------------------------------------
// destroy
//-----------------------------------------------------------------------------
public void destroy( Object sender ) {
    if (writable && scroll.hasRowSelection()) {
	if (NSAlertPanel.runAlert( "Delete Files", "Delete selected files?",
		"Yes", "No", null ) == NSAlertPanel.DefaultReturn) {
	    NSArray list = scroll.selectedRows();
	    for (int i = list.count(); i-- > 0; ) {
		final int r = ((Integer)list.objectAtIndex(i)).intValue();
		File file = new File( fullPathAtRow(r) );
		file.delete();
	    }
	    fillScroll();
	}
    }
}


//-----------------------------------------------------------------------------
// rename
//-----------------------------------------------------------------------------
private boolean rename( String oldName, String newName ) {
    File oldFile = new File( path, oldName );
    File newFile = new File( path, newName );
    final boolean ok = oldFile.renameTo( newFile );
    if (!ok)
	NSAlertPanel.runCriticalAlert( "Renamed Failed", "Unable to rename \""
		+ oldName + "\" to \"" + newName + "\".", "OK", null, null );
    return ok;
}


//-----------------------------------------------------------------------------
// controlTextShouldEndEditing
//-----------------------------------------------------------------------------
public boolean controlTextShouldEndEditing( NSControl control, NSText text ) {
    boolean accept = true;

    final int r = scroll.clickedRow();
    final int c = scroll.clickedColumn();

    String oldName = scroll.cellAtLocation(r, c).stringValue();
    String newName = text.string();

    if (!newName.equals( oldName ))
	accept = rename( oldName, newName );

    if (!accept)
	text.setString( oldName );

    return accept;
}


//-----------------------------------------------------------------------------
// refreshPressed
//-----------------------------------------------------------------------------
public void refreshPressed( Object sender ) {
    scroll.abortEditing();
    fillScroll();
}


//-----------------------------------------------------------------------------
// cdPressed
//-----------------------------------------------------------------------------
public void cdPressed( Object sender ) {
    scroll.abortEditing();
    if (scroll.numberOfSelectedRows() == 1) {
	int row = scroll.selectedRow();
	if (isDirAtRow( row ))
	    loadDirectory( normalizePath(fullPathAtRow(row)) );
    }
}


//-----------------------------------------------------------------------------
// rowNumbersClick
//-----------------------------------------------------------------------------
public void rowNumbersClick( Object sender ) {
    final boolean newVal = (rowNumbersSwitch.state() != 0);
    final boolean oldVal = scroll.rowTitlesOn();
    if (newVal != oldVal) {
	DEFAULT_ROW_NUMBERS = newVal;
	scroll.setRowTitlesOn( DEFAULT_ROW_NUMBERS );
	Defaults.set( ROW_NUMBERS_DEF, DEFAULT_ROW_NUMBERS );
    }
}


//-----------------------------------------------------------------------------
// autoSortClick
//-----------------------------------------------------------------------------
public void autoSortClick( Object sender ) {
    final boolean switchState = (autoSortSwitch.state() != 0);
    scroll.abortEditing();
    if (autoSort != switchState) {
	DEFAULT_AUTO_SORT = autoSort = switchState;
	Defaults.set( SORT_DEF, DEFAULT_AUTO_SORT );
	scroll.setAutoSortRows( switchState );
	if (switchState)
	    scroll.sortRows();
    }
}


//-----------------------------------------------------------------------------
// hiddenFilesClick
//-----------------------------------------------------------------------------
public void hiddenFilesClick( Object sender ) {
    final boolean switchState = (hiddenFilesSwitch.state() != 0);
    scroll.abortEditing();
    if (showHidden != switchState) {
	DEFAULT_SHOW_HIDDEN = showHidden = switchState;
	Defaults.set( HIDDEN_DEF, DEFAULT_SHOW_HIDDEN );
	fillScroll();
    }
}


//-----------------------------------------------------------------------------
// highlightClick
//-----------------------------------------------------------------------------
public void highlightClick( Object sender ) {
    final boolean switchState = (highlightSwitch.state() != 0);
    scroll.abortEditing();
    if (highlightDirs != switchState) {
	DEFAULT_HIGHLIGHT_DIRS = highlightDirs = switchState;
	Defaults.set( HLIGHT_DEF, DEFAULT_HIGHLIGHT_DIRS );

	refreshHighlighting( highlightDirs );
	scroll.setNeedsDisplay( true );
    }
}


//-----------------------------------------------------------------------------
// dragUnscaledClick
//-----------------------------------------------------------------------------
public void dragUnscaledClick( Object sender ) {
    final boolean switchState = (dragUnscaledSwitch.state() != 0);
    if (dragUnscaled != switchState) {
	DEFAULT_DRAG_UNSCALED = dragUnscaled = switchState;
	Defaults.set( UNSCALED_DEF, DEFAULT_DRAG_UNSCALED );
    }
}


//-----------------------------------------------------------------------------
// lockClick
//-----------------------------------------------------------------------------
public void lockClick( Object sender ) {
    TableScroll s = (TableScroll)sender;
    if (s.autoSortRows())
	s.sortRow( s.clickedRow() );
}


//-----------------------------------------------------------------------------
// scrollClick
//-----------------------------------------------------------------------------
public void scrollClick( Object sender ) {
    updateButtons();
}


//-----------------------------------------------------------------------------
// scrollDoubleClick
//-----------------------------------------------------------------------------
public void scrollDoubleClick( Object sender ) {
    openSelected( sender );
}


//-----------------------------------------------------------------------------
// activateWindow
//-----------------------------------------------------------------------------
private void activateWindow() {
    window.makeKeyAndOrderFront( null );
}


//-----------------------------------------------------------------------------
// windowShouldClose
//-----------------------------------------------------------------------------
public boolean windowShouldClose( Object sender ) {
    scroll.abortEditing();
    window.setDelegate( null );
    releaseImages();
    OPEN_DIRS.removeIdenticalObject( this );
    return true;
}


//-----------------------------------------------------------------------------
// windowDidResize
//-----------------------------------------------------------------------------
public void windowDidResize( NSNotification n ) {
    NSRect r = ((NSWindow)n.object()).frame();
    if (r.width () != DEFAULT_WIN_SIZE.width () ||
	r.height() != DEFAULT_WIN_SIZE.height()) {
	DEFAULT_WIN_SIZE = r.size();
	Defaults.set( SIZE_DEF, DEFAULT_WIN_SIZE );
    }
}


//-----------------------------------------------------------------------------
// setDefaultColor
//-----------------------------------------------------------------------------
private void setDefaultColor( NSColor c ) {
    DEFAULT_COLOR = c;
    Defaults.set( COLOR_DEF, c );
}


//-----------------------------------------------------------------------------
// setColors
//-----------------------------------------------------------------------------
private void setColors( NSColor c ) {
    window.setBackgroundColor(c);
    scroll.setBackgroundColor( scrollColor() );
    window.display();
}


//-----------------------------------------------------------------------------
// draggingEntered
//-----------------------------------------------------------------------------
public int draggingEntered( NSDraggingInfo info ) {
    return (info.draggingSourceOperationMask() &
	    NSDraggingInfo.DragOperationGeneric);
}


//-----------------------------------------------------------------------------
// performDragOperation
//-----------------------------------------------------------------------------
public boolean performDragOperation( NSDraggingInfo info ) {
    setDefaultColor( NSColor.colorFromPasteboard(info.draggingPasteboard()) );
    setColors( DEFAULT_COLOR );
    return true;
}


//-----------------------------------------------------------------------------
// initDefaults
//-----------------------------------------------------------------------------
private void initDefaults() {
    if (DEFAULT_FONT == null) {
	DEFAULT_WIN_SIZE = window.frame().size();
	DEFAULT_FONT = Defaults.getFont( FONT_DEF, scroll.font() );
    }
}


//-----------------------------------------------------------------------------
// loadDefaults
//-----------------------------------------------------------------------------
private void loadDefaults() {
    NSRect r = window.frame();
    NSSize z = Defaults.getSize( SIZE_DEF, DEFAULT_WIN_SIZE );
    window.setFrame( new NSRect(r.x(), r.y(), z.width(), z.height()), false );

    autoSort = DEFAULT_AUTO_SORT;
    showHidden = DEFAULT_SHOW_HIDDEN;
    highlightDirs = DEFAULT_HIGHLIGHT_DIRS;
    dragUnscaled = DEFAULT_DRAG_UNSCALED;

    autoSortSwitch.setState( autoSort ? 1 : 0 );
    hiddenFilesSwitch.setState( showHidden ? 1 : 0 );
    highlightSwitch.setState( highlightDirs ? 1 : 0 );
    dragUnscaledSwitch.setState( dragUnscaled ? 1 : 0 );
    rowNumbersSwitch.setState( DEFAULT_ROW_NUMBERS ? 1 : 0 );

    scroll.setRowTitlesOn( DEFAULT_ROW_NUMBERS );
    scroll.setAutoSortRows( autoSort );
    scroll.setFont( DEFAULT_FONT );
    setColors( DEFAULT_COLOR );

    String s;
    s = Defaults.getString( COL_SIZES_DEF, null );
    if (s != null)
	scroll.setColumnSizes(s);

    s = Defaults.getString( COL_ORDER_DEF, null );
    if (s != null)
	scroll.setColumnOrder(s);
}


//-----------------------------------------------------------------------------
// initLockSlot
//-----------------------------------------------------------------------------
private void initLockSlot() {
    NSButtonCell proto = (NSButtonCell)scroll.columnCellPrototype( LOCK_SLOT );
    proto.setButtonType( NSButtonCell.SwitchButton );
    proto.setImagePosition( NSCell.ImageOnly );
    proto.setTarget( this );
    proto.setAction( new NSSelector("lockClick", new Class[] {Object.class}) );
    proto.setImage( LOCKED_IMAGE );
    proto.setAlternateImage( UNLOCKED_IMAGE );
}


//-----------------------------------------------------------------------------
// initNameSlot
//-----------------------------------------------------------------------------
private void initNameSlot() {
    NSCell proto = scroll.columnCellPrototype( NAME_SLOT );
    proto.setEditable( true );
    proto.setScrollable( true );
}


//-----------------------------------------------------------------------------
// initSlots
//-----------------------------------------------------------------------------
private void initSlots() {
    initLockSlot();
    initNameSlot();
    scroll.columnCellPrototype(SIZE_SLOT).
	setAlignment(NSText.RightTextAlignment);
}


//-----------------------------------------------------------------------------
// Constructor
//-----------------------------------------------------------------------------
private DirWindow( String dirname ) {
    NSApplication.loadNibNamed( "DirWindow", this );
    window.registerForDraggedTypes(new NSArray(NSPasteboard.ColorPboardType));
    initSlots();
    initDefaults();
    loadDefaults();
    loadDirectory( dirname );
    cascade();
}


//-----------------------------------------------------------------------------
// findDir
//-----------------------------------------------------------------------------
private static DirWindow findDir( String normalizedPath ) {
    if (normalizedPath != null) {
	Enumeration e = OPEN_DIRS.objectEnumerator();
	while (e.hasMoreElements()) {
	    DirWindow p = (DirWindow)e.nextElement();
	    if (p.path != null && p.path.equals( normalizedPath ))
		return p;
	    }
	}
    return null;
}


//-----------------------------------------------------------------------------
// launchDir
//-----------------------------------------------------------------------------
public static void launchDir( String dirname ) {
    initClass();
    DirWindow p = null;
    if (dirname == null) dirname = NSSystem.currentHomeDirectory();
    if (dirname == null) dirname = "/";
    dirname = normalizePath( dirname );
    if ((p = findDir( dirname )) == null) {
	p = new DirWindow( dirname );
	OPEN_DIRS.addObject(p);
    }
    p.activateWindow();
}

} // class DirWindow
