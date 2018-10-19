#ifndef __MiscTableTypes_h
#define __MiscTableTypes_h
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
// <MiscTableTypes.h>
//
//	Common types used for the MiscTableScroll object.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableTypes.h,v 1.13 99/06/15 03:54:33 sunshine Exp $
// $Log:	MiscTableTypes.h,v $
// Revision 1.13  99/06/15  03:54:33  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Added macros for exporting variables from the framework's DLL:
// MISC_TABLE_SCROLL_EXTERN, MISC_TABLE_SCROLL_PRIVATE_EXTERN,
// MISC_TABLE_SCROLL_BUILDING, & MISC_TABLE_SCROLL_EXPORTING.
// These macros are used to export new MiscTableScroll notifications.
// Worked around Objective-C++ compiler bug on Windows where export of
// symbols resulted in linker failing to initialize other unrelated variables.
// Fixed bug: Was not using extern "C" to export MiscDefaultCompareFunc().
// Thus C and Objective-C clients were unable to access the function.
// No longer #imports unportable <objc/zone.h>.
// Now #imports <Foundation/NSGeometry.h> rather than <AppKit/NSGraphics.h>.
// 
// Revision 1.12  1998/03/22 13:14:10  sunshine
// v133.1: Eliminated data-sizing.
//
//  Revision 1.11  97/06/18  10:03:06  sunshine
//  v125.9: MISC_TABLE_CELL_ICON --> MISC_TABLE_CELL_IMAGE.
//-----------------------------------------------------------------------------
#ifdef __cplusplus
# define MISC_TS_EXTERN_BEGIN(X)	extern "C" {
# define MISC_TS_EXTERN_END		}
# define MISC_TS_CLASS_DEF(X)		class X
#else
# define MISC_TS_EXTERN_BEGIN(X)
# define MISC_TS_EXTERN_END
# define MISC_TS_CLASS_DEF(X)		typedef struct X X
#endif

MISC_TS_EXTERN_BEGIN( "Objective-C" )
#import <Foundation/NSGeometry.h>
MISC_TS_EXTERN_END

//-----------------------------------------------------------------------------
// Platform-specific definitions for exporting variables and functions.
//
// Use the two EXTERN macros for exporting symbols.  The macro should be used
// as part of the declaration of the symbol in the interface file in place of
// the standard "extern" declaration.  Nothing special is required for the
// definition of the symbol in the implementation file other than ensuring that
// it is not declared "static".
//
// MISC_TABLE_SCROLL_EXTERN
//	Export as public symbol to clients of framework.
// MISC_TABLE_SCROLL_PRIVATE_EXTERN
//	Export as private symbol for use within framework.
//
// Use the BUILDING and EXPORTING macros to correctly finalize export of
// public symbols.  There is an Objective-C++ compiler bug in YellowBox and
// OpenStep 4.2 for Windows which results in a failure to initialize some
// static, constant, file-global variables within the framework if a
// __declspec(dllexport) appears in the compilation (even from a header file).
// Specifically, the compiler incorrectly places the affected variables into a
// ".drectve" section within the object file, instead of an ".rdata" section
// where they belong.  Since the linker discards .drectve sections before
// producing the final output, these variables are never initialized and the
// program crashes.  The Objective-C compiler does not contain this bug, which
// explains why the problem does not affect the AppKit or Foundation
// frameworks.  See Notes/DLL-EXPORT.txt for a detailed discussion.
//
// To work around this problem, it is necessary to use __declspec(dllexport)
// only in files which do not otherwise contain variables needing
// initialization, since the initialization may not occur on account of this
// bug.  The simplest solution is to create a file which exists only for the
// purpose of exporting variables which are declared and defined elsewhere in
// the framework.
//
// These macros should be defined at the appropriate times as discussed below.
// The value of the macro is not relevant and may be the empty string.  It is
// safe to define these macros across all platforms, though they impact only
// Windows.  Clients of the framework should not define either of these
// macros.
//
// MISC_TABLE_SCROLL_BUILDING
//	Must be defined when building the framework itself.  Typically this is
//	done in the Makefile by passing the -D directive to the compiler.
// MISC_TABLE_SCROLL_EXPORTING
//	Generally should be defined in a single implementation file which does
//	not define or provide any variables of its own.  Typically this file
//	is empty except for two lines.  One line #defines this macro, and the
//	other #includes the header file or files which declare the exported
//	variables.  The actual definitions of the variables should be
//	elsewhere.
//
// To illustrate with a fictional framwork, MyFramework, which exports the
// symbol MyFrameworkNotification, its header file might look like this:
//
//	/* MyFramework.h */
//	MISC_TABLE_SCROLL_EXTERN NSString* const MyFrameworkNotification;
//
// The implementation of MyFramework should be compiled with the macro
// MISC_TABLE_SCROLL_BUILDING defined by the Makefile, using a -D directive.
// The implementation file which actually defines MyFrameworkNotification
// might look like this:
//
//	/* MyFramework.M */
//	NSString* const MyFrameworkNotification = @"MyFrameworkNotification";
//
// Finally, a file which exists only to tell Windows which variables should be
// exported from the DLL might look like this.  It contains only two lines, a
// #define and an #include.
//
//	/* MyFrameworkSymbols.M */
//	#define MISC_TABLE_SCROLL_EXPORTING
//	#include <MyFramework/MyFramework.h>
//
//-----------------------------------------------------------------------------
#if defined(__MACH__)

#if defined(__cplusplus)
#define MISC_TABLE_SCROLL_EXTERN extern "C"
#define MISC_TABLE_SCROLL_PRIVATE_EXTERN __private_extern__
#else
#define MISC_TABLE_SCROLL_EXTERN extern
#define MISC_TABLE_SCROLL_PRIVATE_EXTERN __private_extern__
#endif

#elif defined(SOLARIS)

#if defined(__cplusplus)
#define MISC_TABLE_SCROLL_EXTERN extern "C"
#define MISC_TABLE_SCROLL_PRIVATE_EXTERN extern "C"
#else
#define MISC_TABLE_SCROLL_EXTERN extern
#define MISC_TABLE_SCROLL_PRIVATE_EXTERN extern
#endif

#elif defined(WIN32)

#if defined(MISC_TABLE_SCROLL_EXPORTING)
#define MISC_TABLE_SCROLL_DECLSPEC __declspec(dllexport)
#elif defined(MISC_TABLE_SCROLL_BUILDING)
#define MISC_TABLE_SCROLL_DECLSPEC
#else
#define MISC_TABLE_SCROLL_DECLSPEC __declspec(dllimport)
#endif

#if defined(__cplusplus)
#define MISC_TABLE_SCROLL_EXTERN extern "C" MISC_TABLE_SCROLL_DECLSPEC
#define MISC_TABLE_SCROLL_PRIVATE_EXTERN extern
#else
#define MISC_TABLE_SCROLL_EXTERN MISC_TABLE_SCROLL_DECLSPEC extern
#define MISC_TABLE_SCROLL_PRIVATE_EXTERN extern
#endif

#endif


//-----------------------------------------------------------------------------
// Types & Constants
//-----------------------------------------------------------------------------

typedef int MiscPixels;
typedef int MiscCoord_V;	// Visual coordinate.
typedef int MiscCoord_P;	// Physical coordinate.

#define MISC_MIN_PIXELS_SIZE	((MiscPixels) 10)
#define MISC_MAX_PIXELS_SIZE	((MiscPixels) 0x7FFF0000)

typedef enum
{
    MISC_COL_BORDER,
    MISC_ROW_BORDER
} MiscBorderType;

#define	MISC_MAX_BORDER	MISC_ROW_BORDER
#define	MISC_OTHER_BORDER(B) \
	(B == MISC_ROW_BORDER ? MISC_COL_BORDER : MISC_ROW_BORDER)


typedef struct
{
    NSSize		page_size;	// [NSPrintInfo paperSize]
    NSRect		print_rect;	// MiscTableView rect.
    MiscCoord_V	first_print_row;// one's comp if started on prev page.
    MiscCoord_V	last_print_row;	// one's comp if ends on later page.
    MiscCoord_V	first_print_col;// one's comp if started on prev page.
    MiscCoord_V	last_print_col;	// one's comp if ends on later page.
    int		print_page;	// 1 <= print_page <= num_print_pages
    int		print_row;	// 1 <= print_row <= num_print_rows
    int		print_col;	// 1 <= print_col <= num_print_cols
    int		num_print_pages;
    int		num_print_rows;
    int		num_print_cols;
    double		scale_factor;
    BOOL		is_scaled;
} MiscTablePrintInfo;


typedef enum
{
    MISC_NO_TITLE,		// No titles on row/col cells.
    MISC_NUMBER_TITLE,		// Titles are sequential numbers.
    MISC_ALPHA_TITLE,		// Titles are sequential alphabetics...
    MISC_CUSTOM_TITLE,		// Titles are user-supplied strings...
    MISC_DELEGATE_TITLE		// Ask the delegate for titles.
} MiscTableTitleMode;

#define	MISC_MAX_TITLE	MISC_DELEGATE_TITLE


typedef enum
{
    MISC_LIST_MODE,
    MISC_RADIO_MODE,
    MISC_HIGHLIGHT_MODE
} MiscSelectionMode;

#define	MISC_MAX_MODE	MISC_HIGHLIGHT_MODE


typedef enum
{
    MISC_TABLE_CELL_TEXT,
    MISC_TABLE_CELL_IMAGE,
    MISC_TABLE_CELL_BUTTON,
    MISC_TABLE_CELL_CALLBACK
} MiscTableCellStyle;

#define MISC_TABLE_CELL_MAX	MISC_TABLE_CELL_CALLBACK


#define MISC_SIZING_SPRINGY_BIT (1 << 0) // Adjusts for global limits.
#define MISC_SIZING_USER_BIT	(1 << 1) // User can resize.


typedef enum
{
    MISC_NUSER_NSPRINGY_SIZING,
    MISC_NUSER_SPRINGY_SIZING,
    MISC_USER_NSPRINGY_SIZING,
    MISC_USER_SPRINGY_SIZING,
} MiscTableSizing;

#define	MISC_MAX_SIZING	MISC_USER_SPRINGY_SIZING


typedef enum
{
    MISC_SORT_ASCENDING,
    MISC_SORT_DESCENDING
} MiscSortDirection;

#define	MISC_SORT_DIR_MAX	MISC_SORT_DESCENDING

#define	MISC_OTHER_DIRECTION(D)\
((D) == MISC_SORT_DESCENDING ? \
MISC_SORT_ASCENDING : MISC_SORT_DESCENDING)


typedef enum				// Selector used to get data:
{
    MISC_SORT_STRING_CASE_INSENSITIVE,	//  0 -stringValue
    MISC_SORT_STRING_CASE_SENSITIVE,	//  1 -stringValue
    MISC_SORT_INT,			//  2 -intValue
    MISC_SORT_UNSIGNED_INT,		//  3 -intValue
    MISC_SORT_TAG,			//  4 -tag
    MISC_SORT_UNSIGNED_TAG,		//  5 -tag
    MISC_SORT_FLOAT,			//  6 -floatValue
    MISC_SORT_DOUBLE,			//  7 -doubleValue
    MISC_SORT_SKIP,			//  8 Don't compare cells in this slot.
    MISC_SORT_TITLE_CASE_INSENSITIVE,	//  9 -title
    MISC_SORT_TITLE_CASE_SENSITIVE,	// 10 -title
    MISC_SORT_STATE,			// 11 -state
    MISC_SORT_UNSIGNED_STATE,		// 12 -state
} MiscSortType;

#define	MISC_SORT_TYPE_MAX	MISC_SORT_UNSIGNED_STATE
#define	MISC_SORT_CUSTOM	((MiscSortType)(int(MISC_SORT_TYPE_MAX) + 1))

@class MiscTableScroll;

typedef struct MiscEntrySortInfo MiscEntrySortInfo;
typedef struct MiscSlotSortInfo MiscSlotSortInfo;

//-----------------------------------------------------------------------------
// MiscCompareEntryFunc
// 
//	Compare two cells, given the coordinates of the cells, and a pointer 
//	to the sorting information structure.  This is the prototype for 
//	custom sort functions that you write, and install with 
//	-border:setSlot:sortFunction:, -setColumn:sortFunction:,
//	or -setRow:sortFunction:.
//
// Returns:
//	< 0	if (table[r1][c1] < table[r2][c2])
//	= 0	if (table[r1][c1] = table[r2][c2])
//	> 0	if (table[r1][c1] > table[r2][c2])
//
//	When sorting rows:
//		info->border_type == MISC_COL_BORDER, col1 == col2
//
//	When sorting columns:
//		info->border_type == MISC_ROW_BORDER, row1 == row2
//
//	Always return the result of an "ascending" comparison.  The
//	caller is responsible for choosing the sort direction.
//
// WARNING:
//	If info->need_copy is YES, you must copy the information from
//	the first cell *BEFORE* accessing the second cell.  (This happens
//	with lazy tables that provide only a single buffer.)  Failure to
//	do so will result in catastrophic worst-case performance and will 
//	not sort the table.
//-----------------------------------------------------------------------------
typedef int (*MiscCompareEntryFunc)
	( int r1, int c1, int r2, int c2, 
	MiscEntrySortInfo const* entry_info,
	MiscSlotSortInfo* sort_info );


//-----------------------------------------------------------------------------
// MiscCompareSlotFunc
//
//	Compare two entire slots (usually rows) from the table.
//
// Returns:
//	< 0	if (table.b[slot1] < table.b[slot2])
//	= 0	if (table.b[slot1] = table.b[slot2])
//	> 0	if (table.b[slot1] > table.b[slot2])
//
//	The default version, MiscDefaultComareSlotFunc(), compares the
//	slots, one entry at a time, using the sorting information
//	structure.
//
//	You can install a customized replacement via -setCompareSlotFunction:
//
//	This routine is responsible for honoring the slot-sort-vector (order 
//	in which columns/rows are visited), applying the sort-direction 
//	(ascending/descending), and calling user-installed custom 
//	slot-sort-funcs.  
//-----------------------------------------------------------------------------
typedef int (*MiscCompareSlotFunc)
	( int slot1, int slot2, MiscSlotSortInfo* );

MISC_TABLE_SCROLL_EXTERN
int MiscDefaultCompareSlotFunc( int, int, MiscSlotSortInfo* );


//-----------------------------------------------------------------------------
// MiscSlotSortInfo
//
//	This structure provides the sorting information used by the 
//	MiscDefaultCompareSlotFunc() function.  This structure is properly 
//	intialized by the -sortInfoInit:border: method, and storage is 
//	reclaimed by the -sortInfoDone: method.  The initialization and 
//	cleanup is handled automatically by the sorting and comparison 
//	methods that do NOT accept an "info" argument.  You are responsible 
//	for calling -sortInfoInit:border: and -sortInfoDone: when you call 
//	any of the methods that DO accept an 'info' argument.  
//
//  Order in which entries are visited:
//	If you have installed a slot-sort-vector for the "other" border, that 
//	will determine the order in which entries are compared.  If you have 
//	not installed a slot-sort-vector, the current visual order is used.  
//	This information is stored in num_entries and entry_info[].slot
//
//  Sort direction:
//	Each entry (slot from the "other" border) has a sort direction which
//	is either ascending or descending.  This is the basis for determining
//	the sort direction of an entry.  In addition, if you have installed
//	a slot-sort-vector, and any of the elements of that slot-sort-vector 
//	are negative, they will reverse the sort direction of that entry.  
//	(If the sort-direction for the entry is ascending, a negative index 
//	will cause that entry to be sorted in descending order.  If the 
//	sort-direction for the entry is descending, a negative index will 
//	cause that entry to be sorted in ascending order.)  This information
//	is stored in entry_info[].ascending.
//
//  Comparison function:
//	If you have installed a custom comparison function for the entry 
//	(slot from the "other" border), your custom comparison function will 
//	be used.  Otherwise, an internal comparison function will be selected 
//	based on the "sort-type" for the entry.  The address of the function 
//	is stored in entry_info[].compare_func.  
//
// struct MiscSlotSortInfo
//
//	table_scroll		The MiscTableScroll being used.
//
//	zone			This is [table_scroll zone].  The zone that
//				is used for allocation of the entry_info[]
//				buff[] arrays.
//
//	border_type		The "other" border.  When rows are being
//				compared, this is MISC_COL_BORDER.  When 
//				comparing columns, this is MISC_ROW_BORDER.  
//
//	num_entries		The number of entries that will be compared.
//				Normally, this is the number of slots in
//				the "border_type" border (usually, the number
//				of columns).  This can be different if you
//				have installed a slot-sort-vector.
//
//	entry_info		An array of sorting information for each
//				entry in a slot.  This information is 
//				precomputed in -sortInfoInit:border: for 
//				use by MiscDefaultCompareSlotFunc().
//
//	need_copy		Flag indicating whether information from the
//				the first entry (cell) must be copied before
//				accessing the second entry (cell).  This is
//				YES when table_scroll is lazy and supplies
//				only a single buffer.
//
// struct MiscEntrySortInfo
//
//	slot			The original (physical) index of the slot that
//				this entry corresponds to.
//
//	ascending		Sort direction: 1=ascending, 0=descending.
//
//	value_func		The address of the function that will be
//	value_target		called to get the values for the comparison.  
//	value_sel		The function must match the argument pattern 
//				of the -tableScroll:intValueAtRow:column: 
//				method, but the data-type of the return value 
//				depends on the sort-type of the slot.  The 
//				-sortInfoInit:border: method determines which 
//				object will supply the values for the slot 
//				(value_target), and which message should be 
//				used to retrieve the value (value_sel).  Then 
//				it calls [value_target methodFor:value_sel] to
//				get the address of the function (value_func).  
//				The value_func is called directly during 
//				sorting, rather than going through the normal 
//				Objective-C dispatch.  
//
//	value_obj		The object that will be passed as the
//				'tableScroll:' argument to the 'value_func'
//				function.  This is usually the table scroll
//				itself.
//
//	cell_at_func		Address of the tableScroll:cellAtRow:column:
//				function.
//	cell_class		Last cell class seen in this slot.
//	cell_sel		Selector to extract value (intValue,etc.)
//	cell_func		Address of the cell's cell_sel function.
//
//	sort_type		The sort-type for this slot.
//
//	compare_func		Comparison function to use for this slot.
//
//-----------------------------------------------------------------------------

//-----------------------------------------------------------------------------
// MISC_TS_TYPE_AT
//	This macro generates a function prototype typedef that describes the 
//	methods used to retrieve the values for comparison during sorting.  
//	The macro is used to generate function prototypes for each data-type 
//	that can be compared.  These prototypes describe the arguments passed
//	to a function that has the same format as the following standard
//	delegate message:
//		- (int) tableScroll:(MiscTableScroll*)tableScroll
//			intValueAtRow:(int)row column:(int)col
//	The data-type for the return value is different for each of the
//	data-types.
//-----------------------------------------------------------------------------
#define MISC_TS_TYPE_AT( TYPE, NAME ) \
typedef TYPE (*MISC_TS_##NAME##_AT)(id,SEL,id,int r,int c, ...);

MISC_TS_TYPE_AT( int, INT )			// MISC_TS_INT_AT
MISC_TS_TYPE_AT( float, FLOAT )			// MISC_TS_FLOAT_AT
MISC_TS_TYPE_AT( double, DOUBLE )		// MISC_TS_DOUBLE_AT
MISC_TS_TYPE_AT( NSString*, STRING )		// MISC_TS_STRING_AT

typedef union
{
    MISC_TS_INT_AT		i;
    MISC_TS_FLOAT_AT	f;
    MISC_TS_DOUBLE_AT	d;
    MISC_TS_STRING_AT	s;
} MISC_TS_VAL_AT_FUNC;


//-----------------------------------------------------------------------------
// MISC_TS_TYPE_VAL
//	This macro generates a function prototype typedef that describes
//	the value-access methods for a cell.  They match the following 
//	pattern:
//		- (int) intValue
//	The data-type for the return value is different for each.
//-----------------------------------------------------------------------------
#define MISC_TS_TYPE_VAL( TYPE, NAME ) \
typedef TYPE (*MISC_TS_##NAME##_VAL)(id,SEL);

MISC_TS_TYPE_VAL( int, INT )			// MISC_TS_INT_VAL
MISC_TS_TYPE_VAL( float, FLOAT )		// MISC_TS_FLOAT_VAL
MISC_TS_TYPE_VAL( double, DOUBLE )		// MISC_TS_DOUBLE_VAL
MISC_TS_TYPE_VAL( NSString*, STRING )		// MISC_TS_STRING_VAL

typedef union
{
    MISC_TS_INT_VAL		i;
    MISC_TS_FLOAT_VAL	f;
    MISC_TS_DOUBLE_VAL	d;
    MISC_TS_STRING_VAL	s;
} MISC_TS_VAL_FUNC;



// *** WARNING ***
// The sizes of these structures are likely to change between versions.
// *** WARNING ***

struct MiscEntrySortInfo
{
    int slot;
    int ascending;
    MISC_TS_VAL_AT_FUNC value_func;
    id  value_target;
    SEL value_sel;
    id  value_obj;
    IMP cell_at_func;
    id  cell_class;
    SEL cell_sel;
    MISC_TS_VAL_FUNC cell_func;
    MiscSortType sort_type;
    MiscCompareEntryFunc compare_func;
};


struct MiscSlotSortInfo
{
    MiscTableScroll* table_scroll;
    NSZone* zone;
    MiscBorderType border_type;
    int num_entries;
    MiscEntrySortInfo const* entry_info;
    BOOL need_copy;
};

#endif // __MiscTableTypes_h
