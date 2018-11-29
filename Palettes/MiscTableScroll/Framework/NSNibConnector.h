#ifndef __MiscTableScroll_NSNibConnector_h
#define __MiscTableScroll_NSNibConnector_h
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
// NSNibConnector.h
//
//	The declarations of Interface Builder's private connection classes:
//	NSNibConnector, NSNibOutletConnector, and NSNibControlConnector.
//
// NOTE
//	Prior to MacOS/X Server DR2 the names of these classes were named 
//	NSIBConnector, NSIBOutletConnector, and NSIBControlConnector, 
//	respectively.  Furthermore, the definitions of these classes were 
//	private.  Consequently, for pre DR2 platforms, we also have to provide 
//	definitions for these classes in order to be able to access them.  We 
//	use a litle C-macro magic to iron out differences between OpenStep and 
//	MacOS/X Server.  
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: NSNibConnector.h,v 1.4 99/06/15 04:11:00 sunshine Exp $
// $Log:	NSNibConnector.h,v $
// Revision 1.4  99/06/15  04:11:00  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// As of MacOS/X Server DR2, connector classes are public so we no longer have
// to supply declarations ourselves.  Compilation is conditionalized as
// appropriate.  Also connector classes changed name in DR2 from
// NSIBConnector, NSIBOutletConnector, and NSIBControlConnector to
// NSNibConnector, NSNibOutletConnector, and NSNibControlConnector,
// respectively.
// 
// Revision 1.3  1997/06/18 09:53:53  sunshine
// v125.9: Renamed: IBConnector.h --> NSIBConnector.h.  Commented & updated.
//-----------------------------------------------------------------------------
extern "C" {
#import <InterfaceBuilder/InterfaceBuilder.h>
}

#if !defined(FOUNDATION_STATIC_INLINE) // Key off macro new to YellowBox.
#define MISC_OLD_IB_CONNECTORS
#else
#undef  MISC_OLD_IB_CONNECTORS
#endif

#if defined(MISC_OLD_IB_CONNECTORS)

#define NSNibConnector        NSIBConnector
#define NSNibOutletConnector  NSIBOutletConnector
#define NSNibControlConnector NSIBControlConnector

@interface NSNibConnector : NSObject<IBConnectors>
    {
    id source;
    id destination;
    NSString* label;
    }

- (id)initWithCoder:(NSCoder*)coder;
- (void)encodeWithCoder:(NSCoder*)coder;

- (id)source;
- (void)setSource:(id)src;
- (id)destination;
- (void)setDestination:(id)dest;
- (NSString*)label;
- (void)setLabel:(NSString*)label;
- (void)replaceObject:(id)oldObject withObject:(id)newObject;
- (id)nibInstantiate;
- (void)establishConnection;

- (NSString*)nibLabel;
- (void)displayConnection;

@end

@interface NSNibOutletConnector : NSNibConnector
- (void)establishConnection;
@end

@interface NSNibControlConnector : NSNibConnector
- (NSString*)nibLabel;
- (void)establishConnection;
@end

#endif // MISC_OLD_IB_CONNECTORS

#endif // __MiscTableScroll_NSNibConnector_h
