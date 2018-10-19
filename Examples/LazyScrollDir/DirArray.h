#ifndef __DirArray_h
#define __DirArray_h
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
// DirArray.h
//
//	An extensible array of directory entries.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: DirArray.h,v 1.4 98/03/30 09:12:24 sunshine Exp $
// $Log:	DirArray.h,v $
// Revision 1.4  98/03/30  09:12:24  sunshine
// v18.1: Now correctly types totalBytes as unsigned long long; not size_t.
// 
// Revision 1.3  97/06/24  07:57:50  sunshine
// v15.1: Removed unused dictionary keys.  Fixed bug: Wasn't taking sticky bit
// into account when computing canToggleLock.
// 
// Revision 1.2  97/04/25  19:53:04  sunshine
// v14.2: Ported to OPENSTEP 4.2 (prerelease) for Mach & NT.
// Completely rewrote to use NSFileManager rather than Unix directory-scanning
// functions so that it works on Windows NT.
//-----------------------------------------------------------------------------
#import <Foundation/NSDictionary.h>
@class DirArray, NSMutableArray;

extern NSString* const DA_SHORT_NAME;
extern NSString* const DA_LONG_NAME;
extern NSString* const DA_SOFT_LINK;
extern NSString* const DA_IS_DIRECTORY;
extern NSString* const DA_IS_LOCKED;
extern NSString* const DA_CAN_TOGGLE_LOCK;

@interface NSDictionary(DirArray)
- (id)scaledImage;
- (id)unscaledImage;
@end

@interface DirArray : NSObject
    {
    NSString* name;
    NSMutableArray* files;
    unsigned long long totalBytes;
    BOOL writable;
    BOOL sticky;
    NSString* username;
    };

- (id)init;
- (void)dealloc;
- (unsigned int)count;
- (id)objectAtIndex:(unsigned int)n;
- (BOOL)loadPath:(NSString*)path showHidden:(BOOL)flag;
- (unsigned long long)totalBytes;
- (BOOL)writable;
- (BOOL)sticky;
- (NSString*)username;

@end

#endif // __DirArray_h
