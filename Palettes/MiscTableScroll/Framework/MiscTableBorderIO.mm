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
// MiscTableBorderIO.cc
//
//	Read/write routines for the MiscTableBorder class.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableBorderIO.cc,v 1.6 99/08/20 06:06:09 sunshine Exp $
// $Log:	MiscTableBorderIO.cc,v $
// Revision 1.6  99/08/20  06:06:09  sunshine
// 140.1: Now archives the represented-object only if it conforms to the
// NSCoding protocol.
// 
// Revision 1.5  99/06/15  02:43:14  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Added archiving support for new slot-wise "represented objects".
// 
// Revision 1.4  1998/03/22 13:18:47  sunshine
// v133.1: Combined sort-dir and sort-type.  Eliminated data-sizing entirely.
// Eliminated constrain-max functionality.  Added min/max uniform size.
// Now passes the version to read().  New storage layout.
//-----------------------------------------------------------------------------
#include "MiscTableBorder.h"
#include "MiscTableScrollPrivate.h"
#include "MiscTableUtil.h"


//-----------------------------------------------------------------------------
// decode_bool
//-----------------------------------------------------------------------------
static inline bool decode_bool( NSCoder* coder )
    {
    char c;
    [coder decodeValueOfObjCType:@encode(char) at:&c];
    return bool(c);
    }


//-----------------------------------------------------------------------------
// encode_bool
//-----------------------------------------------------------------------------
static inline void encode_bool( NSCoder* coder, bool b )
    {
    char const c = b;
    [coder encodeValueOfObjCType:@encode(char) at:&c];
    }


//-----------------------------------------------------------------------------
// decode_string
//-----------------------------------------------------------------------------
static NSString* decode_string( NSCoder* coder, bool isCString )
    {
    NSString* s = @"";
    if (!isCString)
	s = [coder decodeObject];
    else
	{
	char* cstr = 0;
	[coder decodeValueOfObjCType:@encode(char*) at:&cstr];
	if (cstr != 0)
	    {
	    s = [NSString stringWithCString:cstr];
	    NSZoneFree( [coder objectZone], cstr );
	    }
	}
    return s;
    }


//-----------------------------------------------------------------------------
// decode_strings
//-----------------------------------------------------------------------------
static void decode_strings( NSCoder* coder, NSString** strings, int n )
    {
    for (int i = 0; i < n; i++)
	strings[i] = [[coder decodeObject] retain];
    }


//-----------------------------------------------------------------------------
// decode_c_string_array
//-----------------------------------------------------------------------------
static void decode_c_string_array( NSCoder* coder, NSString** strings, int n )
    {
    NSZone* const z = [coder objectZone];
    char** cstrings = (char**)malloc( sizeof(char*) * n );
    [coder decodeArrayOfObjCType:@encode(char*) count:n at:cstrings];
    for (int i = 0; i < n; i++)
	{
	strings[i] = [[NSString allocWithZone:z] initWithCString:cstrings[i]];
	NSZoneFree( z, cstrings[i] );
	}
    free( cstrings );
    }


//-----------------------------------------------------------------------------
// MiscTableSlot::encodeWithCoder
//-----------------------------------------------------------------------------
void MiscTableSlot::encodeWithCoder( NSCoder* coder )
    {
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&size];
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&min_size];
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&max_size];
    [coder encodeValueOfObjCType:@encode(MiscTableSizing) at:&sizing];
    }


//-----------------------------------------------------------------------------
// encodeWithCoder
//-----------------------------------------------------------------------------
void MiscTableBorder::encodeWithCoder( NSCoder* coder )
    {
    int i;
    register unsigned int m = 0;
    m = (m << 1) | (rep_objs != 0);
    m = (m << 1) | (prototypes != 0);
    m = (m << 1) | (titles != 0);
    m = (m << 1) | (styles != 0);
    m = (m << 1) | (tags != 0);
    m = (m << 1) | (sort_info != 0);
    m = (m << 1) | (p2v != 0);
    m = (m << 1) | (slots != 0);
    m = (m << 1) | (modifier_drag != 0);
    m = (m << 1) | (draggable != 0);
    m = (m << 1) | (sizeable != 0);
    m = (m << 1) | (selectable != 0);
    m = (m << 1) | (type != 0);

    unsigned int const mbuff = m;
    [coder encodeValueOfObjCType:@encode(unsigned int) at:&mbuff];
    [coder encodeConditionalObject:owner];
    def_slot.encodeWithCoder( coder );
    [coder encodeValueOfObjCType:@encode(MiscTableCellStyle) at:&def_style];
    [coder encodeValueOfObjCType:@encode(int) at:&def_tag];
    [coder encodeValueOfObjCType:@encode(MiscTableTitleMode) at:&title_mode];
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&min_uniform_size];
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&max_uniform_size];
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&uniform_size];
    [coder encodeValueOfObjCType:@encode(MiscPixels) at:&min_total_size];
    [coder encodeValueOfObjCType:@encode(int) at:&num_springy];
    [coder encodeValueOfObjCType:@encode(int) at:&num_slots];

    if (slots != 0)
	for (i = 0; i < num_slots; i++)
	    slots[i].encodeWithCoder(coder);

    if (p2v != 0)
	[coder encodeArrayOfObjCType:@encode(MiscCoord_V)
		count:num_slots at:p2v];

    if (sort_info != 0)
	[coder encodeArrayOfObjCType:@encode(int)
		count:num_slots at:sort_info];

    if (tags != 0)
	[coder encodeArrayOfObjCType:@encode(int) count:num_slots at:tags];

    if (styles != 0)
	[coder encodeArrayOfObjCType:@encode(MiscTableCellStyle)
		count:num_slots at:styles];

    if (titles != 0)
	for (i = 0; i < num_slots; i++)
	    [coder encodeObject:titles[i]];

    if (prototypes != 0)
	for (i = 0; i < num_slots; i++)
	    [coder encodeObject:prototypes[i]];

    if (rep_objs != 0)
	for (i = 0; i < num_slots; i++)
	    {
	    id const r = rep_objs[i];
	    [coder encodeObject:
		r != 0 && [r conformsToProtocol:@protocol(NSCoding)] ? r : 0];
	    }
    }


//-----------------------------------------------------------------------------
// initWithCoder
//-----------------------------------------------------------------------------
void MiscTableBorder::initWithCoder( NSCoder* coder, int ver )
    {
    if (ver < MISC_TS_VERSION_2 || (ver >= MISC_TS_VERSION_1000 &&
	ver < MISC_TS_VERSION_1002))
	initWithCoder_v1( coder, ver );
    else
	initWithCoder_v2( coder, ver );
    }


//-----------------------------------------------------------------------------
// MiscTableSlot::initWithCoder
//-----------------------------------------------------------------------------
void MiscTableSlot::initWithCoder( NSCoder* coder, int ver )
    {
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&size];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&min_size];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&max_size];
    if (ver < MISC_TS_VERSION_2 || (ver >= MISC_TS_VERSION_1000 &&
	ver < MISC_TS_VERSION_1002))
	{
	MiscPixels data_size;
	unsigned int x;
	[coder decodeValueOfObjCType:@encode(MiscPixels) at:&data_size];
	[coder decodeValueOfObjCType:@encode(MiscTableSizing) at:&x];
	sizing = MiscTableSizing( (x & 1) | ((x & 4) >> 1) );
	}
    else
	[coder decodeValueOfObjCType:@encode(MiscTableSizing) at:&sizing];
    MISC_ENUM_CHECK( sizing, MISC_MAX_SIZING );
    offset = 0;
    adj_size = size;
    }


//-----------------------------------------------------------------------------
// initWithCoder_v2
//-----------------------------------------------------------------------------
void MiscTableBorder::initWithCoder_v2( NSCoder* coder, int ver )
    {
    emptyAndFree();

    sort_funcs = 0;	// Can't archive function addresses.

    unsigned int mbuff;
    [coder decodeValueOfObjCType:@encode(unsigned int) at:&mbuff];
    register unsigned int m = mbuff;

    type	= MiscBorderType( m & 1 );
    selectable	= bool((m >>= 1) & 1);
    sizeable	= bool((m >>= 1) & 1);
    draggable	= bool((m >>= 1) & 1);
    modifier_drag = bool((m >>= 1) & 1);

    owner = [coder decodeObject];
    def_slot.initWithCoder( coder, ver );
    [coder decodeValueOfObjCType:@encode(MiscTableCellStyle) at:&def_style];
    [coder decodeValueOfObjCType:@encode(int) at:&def_tag];
    [coder decodeValueOfObjCType:@encode(MiscTableTitleMode) at:&title_mode];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&min_uniform_size];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&max_uniform_size];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&uniform_size];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&min_total_size];
    [coder decodeValueOfObjCType:@encode(int) at:&num_springy];
    [coder decodeValueOfObjCType:@encode(int) at:&num_slots];
    max_slots = num_slots;

    if ((m >>= 1) & 1)
	{
	alloc_slots();
	for (int i = 0; i < num_slots; i++)
	    slots[i].initWithCoder( coder, ver );
	}

    if ((m >>= 1) & 1)
	{
	alloc_vmap();
	[coder decodeArrayOfObjCType:@encode(MiscCoord_V)
		count:num_slots at:p2v];
	for (int i = 0; i < num_slots; i++)
	    v2p[ p2v[i] ] = i;
	}

    if ((m >>= 1) & 1)
	{
	alloc_sort_info();
	[coder decodeArrayOfObjCType:@encode(int)
		count:num_slots at:sort_info];
	}

    if ((m >>= 1) & 1)
	{
	alloc_tags();
	[coder decodeArrayOfObjCType:@encode(int) count:num_slots at:tags];
	}

    if ((m >>= 1) & 1)
	{
	alloc_styles();
	[coder decodeArrayOfObjCType:@encode(MiscTableCellStyle)
		count:num_slots at:styles];
	}

    if ((m >>= 1) & 1)
	{
	alloc_titles();
	if (ver < MISC_TS_VERSION_1000)
	    decode_c_string_array( coder, titles, num_slots );
	else
	    decode_strings( coder, titles, num_slots );
	}

    if ((m >>= 1) & 1)
	{
	alloc_prototypes();
	for (int i = 0;	 i < num_slots;	 i++)
	    prototypes[i] = [[coder decodeObject] retain];
	}

    if ((m >>= 1) & 1)
	{
	alloc_represented_objects();
	for (int i = 0;	 i < num_slots;	 i++)
	    rep_objs[i] = [[coder decodeObject] retain];
	}

    needs_recalc = true;
    }


//-----------------------------------------------------------------------------
// initWithCoder_v1
//-----------------------------------------------------------------------------
void MiscTableBorder::initWithCoder_v1( NSCoder* coder, int ver )
    {
    int n;
    emptyAndFree();

    [coder decodeValueOfObjCType:@encode(MiscBorderType) at:&type];
    MISC_ENUM_CHECK( type, MISC_MAX_BORDER );
    owner = [coder decodeObject];
    def_slot.initWithCoder( coder, ver );
    [coder decodeValueOfObjCType:@encode(int) at:&num_slots];
    max_slots = num_slots;

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	alloc_slots();
	for (int i = 0;	 i < num_slots;	 i++)
	    slots[i].initWithCoder( coder, ver );
	}

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	alloc_vmap();
	for (int i = 0;	 i < num_slots;	 i++)
	    [coder decodeValueOfObjCType:@encode(MiscCoord_P) at:&(v2p[i])];
	for (int j = 0;	 j < num_slots;	 j++)
	    [coder decodeValueOfObjCType:@encode(MiscCoord_V) at:&(p2v[j])];
	}

    [coder decodeValueOfObjCType:@encode(int) at:&def_tag];
    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	alloc_tags();
	for (int i = 0;	 i < num_slots;	 i++)
	    {
	    int const j = visualToPhysical(i);
	    [coder decodeValueOfObjCType:@encode(int) at:&(tags[j])];
	    }
	}

    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&uniform_size];
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&min_total_size];
    MiscPixels max_total_size;	// obsolete.
    [coder decodeValueOfObjCType:@encode(MiscPixels) at:&max_total_size];
    [coder decodeValueOfObjCType:@encode(int) at:&num_springy];
    [coder decodeValueOfObjCType:@encode(MiscTableTitleMode) at:&title_mode];
    MISC_ENUM_CHECK( title_mode, MISC_MAX_TITLE );

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	bool const isCString = (ver < MISC_TS_VERSION_1000);
	alloc_titles();
	for (int i = 0;	 i < num_slots;	 i++)
	    {
	    int const j = visualToPhysical(i);
	    titles[j] = [decode_string( coder, isCString ) retain];
	    }
	}

    [coder decodeValueOfObjCType:@encode(MiscTableCellStyle) at:&def_style];
    MISC_ENUM_CHECK( def_style, MISC_TABLE_CELL_MAX );

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	alloc_styles();
	for (int i = 0;	 i < num_slots;	 i++)
	    {
	    int const j = visualToPhysical(i);
	    [coder decodeValueOfObjCType:@encode(MiscTableCellStyle)
		at:&(styles[j])];
	    MISC_ENUM_CHECK( styles[i], MISC_TABLE_CELL_MAX );
	    }
	}

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	alloc_prototypes();
	for (int i = 0;	 i < num_slots;	 i++)
	    {
	    int const j = visualToPhysical(i);
	    prototypes[j] = [[coder decodeObject] retain];
	    }
	}

    sort_funcs = 0;	// Can't archive function addresses.

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	alloc_sort_info();
	for (int i = 0;	 i < num_slots;	 i++)
	    {
	    int const j = visualToPhysical(i);
	    MiscSortDirection x;
	    [coder decodeValueOfObjCType:@encode(MiscSortDirection) at:&x];
	    MISC_ENUM_CHECK( x, MISC_SORT_DIR_MAX );
	    int const z = sort_info[j];
	    sort_info[j] = ((z & ~1) | (x & 1));
	    }
	}

    [coder decodeValueOfObjCType:@encode(int) at:&n];
    if (n != 0)
	{
	if (sort_info == 0)
	    alloc_sort_info();
	for (int i = 0;	 i < num_slots;	 i++)
	    {
	    int const j = visualToPhysical(i);
	    MiscSortType x;
	    [coder decodeValueOfObjCType:@encode(MiscSortType) at:&x];
	    MISC_ENUM_CHECK( x, MISC_SORT_TYPE_MAX );
	    int const z = sort_info[j];
	    sort_info[j] = ((x << 1) | (z & 1));
	    }
	}

    selectable	  = decode_bool( coder );
    sizeable	  = decode_bool( coder );
    draggable	  = decode_bool( coder );
    modifier_drag = decode_bool( coder );

    min_uniform_size = MISC_MIN_PIXELS_SIZE;
    max_uniform_size = MISC_MAX_PIXELS_SIZE;
    needs_recalc = true;
    }
