#ifndef __MiscTableScrollJava_h
#define __MiscTableScrollJava_h
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
// MiscTableScrollJava.h
//
//	Private Java interface which exposes MiscTableScroll to Java.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableScrollJava.h,v 1.2 99/06/30 09:28:05 sunshine Exp $
// $Log:	MiscTableScrollJava.h,v $
// Revision 1.2  99/06/30  09:28:05  sunshine
// v140.1: Ported to final release of MacOS/X Server.
// Prototypes for objc_msgSendSuper_stret() & objc_msgSend_Stret() are now
// properly declared for ppc in the system headers.  Now we only declare them
// manually for DR2.
// 
// Revision 1.1  1999/06/14 18:50:35  sunshine
// v140.1: Extensions to MiscTableScroll to support Java exposure.
//-----------------------------------------------------------------------------
#import <MiscTableScroll/MiscExporter.h>
#import <MiscTableScroll/MiscTableCell.h>
#import <MiscTableScroll/MiscTableScroll.h>

MISC_TS_EXTERN_BEGIN( "Objective-C" )
#import <AppKitJava.h>
MISC_TS_EXTERN_END

//-----------------------------------------------------------------------------
// Redefine MiscTableScroll's parent class from bridget's stand-point.  There
// is certain initialization which must be performed before bridget-generated
// code loads MiscTableScrollJava.dylib.  In particular the Java TableScroll
// provides the client with the option of automatically installing the null
// security manager, which is required by the Java run-time in order to
// actually make calls across the bridge to the Objective-C MiscTableScroll
// class.  It further provides the client with the option of adding the
// framework directory to the standard Java dynamic-library search path.  This
// directory must appear in the search path in order for the dynamic library
// to be loaded at all.  Unfortunately bridget does not provide any mechanism
// for performing this initialization prior to the loading of the dynamic
// library.  Normally we would like to be able to perform our own
// initialization in a static initializer, however bridget always inserts its
// own static initializer into the generated Java code prior to all other
// static initilizers.  Since static initializers are executed in order of
// appearance in the source file, and since bridget's static initializer,
// which attempts to load the dynamic-library, appears before all others, we
// have no opportunity to adjust the search path prior to the attempt to load
// the library.  To work around this problem, and ensure that our
// initialization is performed prior to bridget's own initialization, we fake
// bridget out by convincing it that MiscTableScroll is subclassed from
// TableScrollPrivate rather than NSScrollView.  TableScrollPrivate is a small
// Java-only class which is implemented in MiscTableScrollJava.jobs.  Its
// static initializer performs the desired initialization steps as described
// above.  TableScrollPrivate's initialization code is always executed prior
// to that of TableScroll since TableScrollPrivate is TableScroll's
// superclass.  MISC_BRIDGET_COMPILE, as used below, is only defined by
// Makefile.preamble when bridget itself is running, so this superclass
// redefinition hack has no adverse effects on "real" code.
//-----------------------------------------------------------------------------
#if defined(MISC_BRIDGET_COMPILE)
@interface MiscTableScroll : TableScrollPrivate
- (id)init;
@end
#endif


//-----------------------------------------------------------------------------
// In MacOS/X Server DR2 for Mach on PowerPC, there is a bug in the header
// file /System/Developer/Java/Headers/java-vm.h.  It neglects to declare
// objc_msgSendSuper_stret() and objc_msgSend_stret() even though bridget
// generates code which uses these functions.  The final release of of MacOS/X
// Server, however, does not exhibit this problem.  In order to work around
// the problem in DR2 and pacify the compiler, we must manually declare these
// prototypes.  In order to detect DR2 we key off the existence of the
// __NeXT__ macro which is defined in the DR2 build environment, but not in
// MacOS/X Server.
//-----------------------------------------------------------------------------
#if defined(__NeXT__) && defined(__ppc__)
#if defined(__cplusplus)
#define JEXPORT JOBJC_EXPORT "Objective-C"
#else
#define JEXPORT JOBJC_EXPORT
#endif

JEXPORT id objc_msgSendSuper_stret();
JEXPORT id objc_msgSend_stret();

#undef JEXPORT
#endif


//-----------------------------------------------------------------------------
// Replacements for methods which return row & column by reference in a single
// message.  Only a single value can be returned from a method in Java.  These
// stand-in methods provide just such behavior.  See the implementation file
// for full details.
//-----------------------------------------------------------------------------
@interface MiscTableScroll(JavaExtensions)
- (NSRange)javaNextEditLocationInDirection:(BOOL)forward;
- (NSRange)javaNextEditLocation;
- (NSRange)javaPreviousEditLocation;
- (NSRange)javaLocationForPoint:(NSPoint)point;
- (NSRange)javaLocationOfCell:(NSCell*)cell;
- (NSRange)javaLocationOfCellWithTag:(int)tag;
- (NSRange)javaLocationOfCellWithRepresentedObject:(id)object;
@end


//-----------------------------------------------------------------------------
// Signature fixing for Java.  This category is unimplemented.  It exists only
// to expose the correct type (i.e. NSCell* instead of id).
//-----------------------------------------------------------------------------
@interface MiscTableScroll(JavaSignatures)
- (NSCell*)selectedCell;
- (NSCell*)clickedCell;
- (NSCell*)cellWithTag:(int)tag;
- (NSCell*)cellWithRepresentedObject:(id)object;
- (NSCell*)cellAtRow:(int)row column:(int)col;
- (NSCell*)tableScroll:(MiscTableScroll*)scroll cellAtRow:(int)r column:(int)c;

- (NSCell*)border:(MiscBorderType)b slotCellPrototype:(int)slot;
- (void)border:(MiscBorderType)b setSlot:(int)n cellPrototype:(NSCell*)cell;
- (NSCell*)columnCellPrototype:(int)col;
- (void)setColumn:(int)col cellPrototype:(NSCell*)cell;
- (NSCell*)rowCellPrototype:(int)row;
- (void)setRow:(int)row cellPrototype:(NSCell*)cell;
- (NSCell*)tableScroll:(MiscTableScroll*)scroll
	border:(MiscBorderType)b slotPrototype:(int)slot;

- (NSCell*)reviveCell:(NSCell*)cell atRow:(int)row column:(int)col;
- (NSCell*)retireCell:(NSCell*)cell atRow:(int)row column:(int)col;
- (NSCell*)doReviveCell:(NSCell*)cell atRow:(int)row column:(int)col;
- (NSCell*)doRetireCell:(NSCell*)cell atRow:(int)row column:(int)col;
- (NSCell*)tableScroll:(MiscTableScroll*)scroll reviveCell:(NSCell*)cell
	atRow:(int)row column:(int)col;
- (NSCell*)tableScroll:(MiscTableScroll*)scroll retireCell:(NSCell*)cell
	atRow:(int)row column:(int)col;
- (NSCell*)tableScroll:(MiscTableScroll*)scroll
	reviveAtRow:(int)row column:(int)col;
- (NSCell*)tableScroll:(MiscTableScroll*)scroll
	retireAtRow:(int)row column:(int)col;
@end

#endif __MiscTableScrollJava_h
