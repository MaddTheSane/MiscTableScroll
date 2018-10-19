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
//	"License.rtf" in the MiscKit disibution.  Please refer to that file
//	for a list of all applicable permissions and resictions.
//
//=============================================================================
//-----------------------------------------------------------------------------
// Defaults.java
//
//	Simplified interface to Yellow Box defaults system.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: Defaults.java,v 1.1 99/06/14 15:41:52 sunshine Exp $
// $Log:	Defaults.java,v $
// Revision 1.1  99/06/14  15:41:52  sunshine
// v1.1: Defaults manager.
// 
//-----------------------------------------------------------------------------
import com.apple.yellow.foundation.*;
import com.apple.yellow.application.*;

class Defaults {
    private static final String FONT_NAME_KEY = "Name";
    private static final String FONT_SIZE_KEY = "Size";


//-----------------------------------------------------------------------------
// commit()
//-----------------------------------------------------------------------------
static void commit() {
    NSUserDefaults.standardUserDefaults().synchronize();
}


//-----------------------------------------------------------------------------
// set(String)
//-----------------------------------------------------------------------------
static void set( String key, String s ) {
    NSUserDefaults.standardUserDefaults().setObjectForKey( s, key );
}


//-----------------------------------------------------------------------------
// getString()
//-----------------------------------------------------------------------------
static String getString( String key, String fallback ) {
    String s = NSUserDefaults.standardUserDefaults().stringForKey( key );
    if (s == null)
	s = fallback;
    return s;
}


//-----------------------------------------------------------------------------
// set(int)
//-----------------------------------------------------------------------------
static void set( String key, int i ) {
    NSUserDefaults.standardUserDefaults().setIntegerForKey( i, key );
}


//-----------------------------------------------------------------------------
// getInteger()
//-----------------------------------------------------------------------------
static int getInteger( String key, int fallback ) {
    NSUserDefaults defs = NSUserDefaults.standardUserDefaults();
    if (defs.objectForKey(key) != null)
	return defs.integerForKey( key );
    else
	return fallback;
}


//-----------------------------------------------------------------------------
// getInteger(min,max)
//-----------------------------------------------------------------------------
static int getInteger( String key, int fallback, int min, int max ) {
    int n = getInteger( key, fallback );
    if (n < min)
	n = min;
    else if (n > max)
	n = max;
    return n;
}


//-----------------------------------------------------------------------------
// getInteger(min)
//-----------------------------------------------------------------------------
static int getInteger( String key, int fallback, int min ) {
    return getInteger( key, fallback, min, Integer.MAX_VALUE );
}


//-----------------------------------------------------------------------------
// set(float)
//-----------------------------------------------------------------------------
static void set( String key, float f ) {
    NSUserDefaults.standardUserDefaults().setFloatForKey( f, key );
}


//-----------------------------------------------------------------------------
// getFloat()
//-----------------------------------------------------------------------------
static float getFloat( String key, float fallback ) {
    NSUserDefaults defs = NSUserDefaults.standardUserDefaults();
    if (defs.objectForKey(key) != null)
	return defs.floatForKey( key );
    else
	return fallback;
}


//-----------------------------------------------------------------------------
// set(NSColor)
//-----------------------------------------------------------------------------
static void set( String key, NSColor c ) {
    NSData d = NSArchiver.archivedDataWithRootObject(c);
    NSUserDefaults.standardUserDefaults().setObjectForKey( d, key );
}


//-----------------------------------------------------------------------------
// getColor()
//-----------------------------------------------------------------------------
static NSColor getColor( String key, NSColor fallback ) {
    NSData d = NSUserDefaults.standardUserDefaults().dataForKey( key );
    if (d != null)
	return (NSColor)NSUnarchiver.unarchiveObjectWithData(d);
    else
	return fallback;
}


//-----------------------------------------------------------------------------
// set(boolean)
//-----------------------------------------------------------------------------
static void set( String key, boolean b ) {
    NSUserDefaults.standardUserDefaults().setBooleanForKey( b, key );
}


//-----------------------------------------------------------------------------
// getBoolean()
//-----------------------------------------------------------------------------
static boolean getBoolean( String key, boolean fallback ) {
    NSUserDefaults defs = NSUserDefaults.standardUserDefaults();
    if (defs.objectForKey(key) != null)
	return defs.booleanForKey( key );
    else
	return fallback;
}


//-----------------------------------------------------------------------------
// set(NSFont)
//-----------------------------------------------------------------------------
static void set( String key, NSFont f ) {
    NSMutableDictionary d = new NSMutableDictionary();
    d.setObjectForKey( f.fontName(), FONT_NAME_KEY );
    d.setObjectForKey( Float.toString(f.pointSize()), FONT_SIZE_KEY );
    NSUserDefaults.standardUserDefaults().setObjectForKey( d, key );
}


//-----------------------------------------------------------------------------
// getFont()
//-----------------------------------------------------------------------------
static NSFont getFont( String key, NSFont fallback ) {
    NSFont font = fallback;
    NSDictionary d =
	NSUserDefaults.standardUserDefaults().dictionaryForKey( key );
    if (d != null) {
	String name = (String)d.objectForKey( FONT_NAME_KEY );
	String size = (String)d.objectForKey( FONT_SIZE_KEY );
	if (name != null && name.length() > 0 && size != null) {
	    try {
		Float f = Float.valueOf( size );
		NSFont p = NSFont.fontWithNameAndSize( name, f.floatValue() );
		if (p != null)
		    font = p;
	    }
	    catch (NumberFormatException e) {}
	}
    }
    return font;
}


//-----------------------------------------------------------------------------
// set(NSSize)
//-----------------------------------------------------------------------------
static void set( String key, NSSize s ) {
    NSUserDefaults.standardUserDefaults().setObjectForKey( s.toString(), key );
}


//-----------------------------------------------------------------------------
// getSize()
//-----------------------------------------------------------------------------
static NSSize getSize( String key, NSSize fallback ) {
    String s = NSUserDefaults.standardUserDefaults().stringForKey( key );
    if (s != null)
	return NSSize.fromString(s);
    else
	return fallback;
}


//-----------------------------------------------------------------------------
// set(NSPoint)
//-----------------------------------------------------------------------------
static void set( String key, NSPoint p ) {
    NSUserDefaults.standardUserDefaults().setObjectForKey( p.toString(), key );
}


//-----------------------------------------------------------------------------
// getPoint()
//-----------------------------------------------------------------------------
static NSPoint getPoint( String key, NSPoint fallback ) {
    String s = NSUserDefaults.standardUserDefaults().stringForKey( key );
    if (s != null)
	return NSPoint.fromString(s);
    else
	return fallback;
}


//-----------------------------------------------------------------------------
// set(NSRect)
//-----------------------------------------------------------------------------
static void set( String key, NSRect r ) {
    NSUserDefaults.standardUserDefaults().setObjectForKey( r.toString(), key );
}


//-----------------------------------------------------------------------------
// getRect()
//-----------------------------------------------------------------------------
static NSRect getRect( String key, NSRect fallback ) {
    String s = NSUserDefaults.standardUserDefaults().stringForKey( key );
    if (s != null)
	return NSRect.fromString(s);
    else
	return fallback;
}

} // class Defaults
