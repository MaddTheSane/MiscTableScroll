#ifndef __MiscTableBorder_h
#define __MiscTableBorder_h
#ifdef __GNUC__
# pragma interface
#endif
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
// MiscTableBorder.h
//
//	Structure describing border of an MiscTableView.
//
//	NOTE: Many of the sub-arrays in an MiscTableBorder are conditional.
//	They are not guaranteed to be allocated for every instance.  They are
//	only allocated when the caller tries to store a value in them.	Doing
//	a "set" creates the array, even if the value is the default value.
//
//	"Springy" grow when the total size exceeds the global min total size.
//
//	NOTE *1* These methods return true if the new value is different than
//	the old value, and the display needs updating.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTableBorder.h,v 1.20 99/06/15 02:39:50 sunshine Exp $
// $Log:	MiscTableBorder.h,v $
// Revision 1.20  99/06/15  02:39:50  sunshine
// v140.1: Ported to MacOS/X Server DR2 for Mach and Windows.
// Added support for slot-wise "represented objects".
// Fixed bug: Incorrect clearCursor() implementation did nothing at all.
// 
// Revision 1.19  1998/03/29 23:47:14  sunshine
// v138.1: #import was missing "MiscTableScroll/" for public header.
//
//  Revision 1.18  98/03/23  21:39:55  sunshine
//  v137.1: Added clearSortDirection().
//-----------------------------------------------------------------------------
#include <MiscTableScroll/MiscTableScroll.h>
#include "MiscSparseSet.h"
#include "MiscTableUtil.h"
@class NSArray, NSCell, NSCoder;

struct MiscTableSlot
	{
	MiscPixels	offset;		// Offset of this slot.
	MiscPixels	adj_size;	// Size adjusted for springy-ness.
	MiscPixels	size;		// Target size.
	MiscPixels	min_size;	// Minimum size.
	MiscPixels	max_size;	// Maximum size.
	MiscTableSizing	sizing;		// Sizing options.
	bool isSpringy() const	{ return ::isSpringy(sizing); }
	void initWithCoder( NSCoder*, int ver );
	void encodeWithCoder( NSCoder* );
	};


class MiscTableBorder
	{
private:
	MiscBorderType	type;		// Row / Col.
	MiscTableScroll* owner;
	MiscTableSlot	def_slot;	// Default slot configuration.
	int		max_slots;	// Capacity.  Allocation size of arrays.
	int		num_slots;	// Active number of rows/cols.
	MiscTableSlot*	slots;		// Indexed by visual coords.
	MiscCoord_P*	v2p;		// Visual -> Physical coord map.
	MiscCoord_V*	p2v;		// Physical -> Visual coord map.
	int		def_tag;	// Default tag value.
	int*		tags;		// Indexed by physical coords.
	id*		rep_objs;	// Indexed by physical coords.
	MiscPixels	min_uniform_size;// Limits for user resizing.
	MiscPixels	max_uniform_size;//
	MiscPixels	uniform_size;	// 0 = not uniform.
	MiscPixels	min_total_size; // Min size for the entire border.
	int		num_springy;	// Number of "springy" slots.
	MiscTableTitleMode title_mode;
	NSString**	titles;		// Indexed by physical coords.
	MiscTableCellStyle def_style;
	MiscTableCellStyle* styles;	// Indexed by physical coords.
	id*		prototypes;	// Indexed by physical coords.
	MiscCompareEntryFunc* sort_funcs;//Indexed by physical coords.
	int*		sort_info;	// ((sort_type << 1) | sort_dir)
	MiscSparseSet	selection;	// Selection (visual coordinates).
	MiscCoord_V	selected_slot;	// Selected slot.
	MiscCoord_V	cursor;		// Keyboard cursor.
	MiscCoord_V	clicked_slot;	// Clicked slot.
	bool		selectable;	// User can select slot-titles.
	bool		sizeable;	// User can resize slots.
	bool		draggable;	// User can rearrange slots.
	bool		modifier_drag;	// Use modifier key to drag slots.
	bool		needs_recalc;	// Offset values are "stale".

	void		global_grow( MiscPixels );
	void		init_slot( MiscCoord_V, MiscCoord_P );
	void	 	destroy_slot( MiscCoord_V, MiscCoord_P );
	void		do_shift( void*, int, int, int );
	void		do_shift( MiscCoord_V, MiscCoord_V );
	void*		do_remap( void*, int, MiscCoord_V const* );
	void		do_remap( MiscCoord_V const* );
	MiscCoord_V	find_slot_for_offset( MiscPixels );

	void		perform_recalc();
	void		do_recalc();
	void		recalc_if_needed();
	int		alloc_size( int rec_size );
	void*		do_alloc( int );
	void*		do_alloc_init( int );
	void*		do_realloc( void*, int );
	void		do_realloc();
	void		do_delete( void*, int, int );
	void		do_delete( MiscCoord_V, MiscCoord_P );
	void		do_insert( void*, int, int );
	void		do_insert( MiscCoord_V, MiscCoord_P );
	void		alloc_slots();
	void		alloc_vmap();
	void		alloc_titles();
	void		dealloc_titles();
	void		alloc_tags();
	void		alloc_represented_objects();
	void		alloc_styles();
	void		alloc_prototypes();
	id		new_prototype( MiscCoord_P );
	void		alloc_sort_funcs();
	void		alloc_sort_info();

	NSArray*	selected_slots( bool do_tags ) const;
	void		select_slots( NSArray*, bool clear, bool set );
	void		select_tags( NSArray*, bool clear, bool set );

public:
	MiscTableBorder( MiscBorderType );
	~MiscTableBorder();

	MiscTableScroll* getOwner() const	{ return owner; }
	void	setOwner( MiscTableScroll* x )	{ owner = x; }

	int	count() const		{ return num_slots; }
	int	capacity() const	{ return max_slots; }
	void	setCount( int );
	void	setCapacity( int );
	void	freeExtraCapacity();
	void	empty();
	void	emptyAndFree()		{ empty(); freeExtraCapacity(); }
	bool	goodPos( int x ) const	{ return 0 <= x && x < count(); }
	int	numSpringy() const	{ return num_springy; }

	MiscTableSlot const* getSlots() const	{ return slots; }
	MiscCoord_V const* getP2VMap() const	{ return p2v; }
	MiscCoord_P const* getV2PMap() const	{ return v2p; }
	void	setSlotSizes( MiscPixels const* );
	bool	setP2VMap( MiscCoord_P const* );
	bool	setV2PMap( MiscCoord_V const* );
	bool	good_map( int const* map, bool onescomp ) const;
	void	swapSlots( MiscCoord_P, MiscCoord_P );

	MiscBorderType getType() const	{ return type; }
	bool	isColBorder() const	{ return type == MISC_COL_BORDER; }
	bool	isRowBorder() const	{ return type == MISC_ROW_BORDER; }
	bool	isSelectable() const	{ return selectable; }
	bool	isSizeable() const	{ return sizeable; }
	bool	isDraggable() const	{ return draggable; }
	bool	isModifierDrag() const	{ return modifier_drag; }
	bool	isUniformSize() const	{ return uniform_size != 0; }
	MiscPixels getMinUniformSize() const	{ return min_uniform_size; }
	MiscPixels getMaxUniformSize() const	{ return max_uniform_size; }
	MiscPixels getUniformSize() const	{ return uniform_size; }
	MiscTableTitleMode getTitleMode() const { return title_mode; }

	void	setType( MiscBorderType );
	void	setDraggable( bool x )	{ draggable = x; }
	void	setModifierDrag( bool x ) { modifier_drag = x; }
	void	setSelectable( bool x ) { selectable = x; }
	void	setSizeable( bool x )	{ sizeable = x; }
	void	setMinUniformSize( MiscPixels x ) { min_uniform_size = x; }
	void	setMaxUniformSize( MiscPixels x ) { max_uniform_size = x; }
	bool	setUniformSize( MiscPixels );		// NOTE *1*
	bool	setTitleMode( MiscTableTitleMode );	// NOTE *1*

	MiscPixels totalSize();
	MiscPixels getMinTotalSize() const { return min_total_size; }
	void	setMinTotalSize( MiscPixels );

	MiscCoord_P visualToPhysical( MiscCoord_V x ) const
		{ return (x >= 0 && v2p != 0) ? v2p[x] : (MiscCoord_P)x; }
	MiscCoord_V physicalToVisual( MiscCoord_P x ) const
		{ return (x >= 0 && p2v != 0) ? p2v[x] : (MiscCoord_V)x; }
	void visualToPhysical( MiscSparseSet const&, MiscSparseSet& ) const;
	void physicalToVisual( MiscSparseSet const&, MiscSparseSet& ) const;

	MiscCoord_V visualForOffset( MiscPixels );
	bool	needsRecalc() const	{ return needs_recalc; }
	void	recalcOffsets();

	void moveFromTo( MiscCoord_V, MiscCoord_V );
	void insertAt( MiscCoord_V, MiscCoord_P );
	void add()			{ insertAt(count(),count()); }
	void deleteAt( MiscCoord_V );
	void deleteAt_P( MiscCoord_P x ){ deleteAt( physicalToVisual(x) ); }

	MiscPixels getOffset( MiscCoord_V );
	MiscPixels getOffset_P( MiscCoord_P x )
		{ return getOffset( physicalToVisual(x) ); }
	MiscPixels effectiveSize( MiscCoord_V );
	MiscPixels effectiveSize_P( MiscCoord_P x )
		{ return effectiveSize( physicalToVisual(x) ); }
	MiscPixels effectiveMinSize( MiscCoord_V );
	MiscPixels effectiveMinSize_P( MiscCoord_P x )
		{ return effectiveMinSize( physicalToVisual(x) ); }

	MiscPixels getSize( MiscCoord_V ) const;	// target size.
	MiscPixels getSize_P( MiscCoord_P x ) const
		{ return getSize( physicalToVisual(x) ); }
	void setSize( MiscCoord_V, MiscPixels );
	void setSize_P( MiscCoord_P x, MiscPixels y )
		{ setSize( physicalToVisual(x), y ); }

	MiscPixels getMinSize( MiscCoord_V ) const;
	MiscPixels getMinSize_P( MiscCoord_P x ) const
		{ return getMinSize( physicalToVisual(x) ); }
	void setMinSize( MiscCoord_V, MiscPixels );
	void setMinSize_P( MiscCoord_P x, MiscPixels y )
		{ setMinSize( physicalToVisual(x), y ); }

	MiscPixels getMaxSize( MiscCoord_V ) const;
	MiscPixels getMaxSize_P( MiscCoord_P x ) const
		{ return getMaxSize( physicalToVisual(x) ); }
	void setMaxSize( MiscCoord_V, MiscPixels );
	void setMaxSize_P( MiscCoord_P x, MiscPixels y )
		{ setMaxSize( physicalToVisual(x), y ); }

	MiscTableSizing getSizing( MiscCoord_V ) const;
	MiscTableSizing getSizing_P( MiscCoord_P x ) const
		{ return getSizing( physicalToVisual(x) ); }
	void setSizing( MiscCoord_V, MiscTableSizing );
	void setSizing_P( MiscCoord_P x, MiscTableSizing y )
		{ setSizing( physicalToVisual(x), y ); }

	bool isSortable( MiscCoord_V x ) const
		{ return getSortFunc(x) != 0 ||
			getSortType(x) != MISC_SORT_SKIP; }
	bool isSortable_P( MiscCoord_P x ) const
		{ return isSortable( physicalToVisual(x) ); }

	bool isFixed( MiscCoord_V x ) const
		{ return ::isFixed(getSizing(x)); }
	bool isFixed_P( MiscCoord_P x ) const
		{ return ::isFixed(getSizing_P(x)); }

	bool isSpringy( MiscCoord_V x ) const
		{ return ::isSpringy(getSizing(x)); }
	bool isSpringy_P( MiscCoord_P x ) const
		{ return ::isSpringy(getSizing_P(x)); }
	void setSpringy( MiscCoord_V x, bool b )
		{ setSizing( x, ::setSpringy(getSizing(x),b) ); }
	void setSpringy_P( MiscCoord_P x, bool y )
		{ setSpringy( physicalToVisual(x), y ); }

	bool isSizeable( MiscCoord_V x ) const
		{ return ::isSizeable(getSizing(x)); }
	bool isSizeable_P( MiscCoord_P x ) const
		{ return ::isSizeable(getSizing_P(x)); }
	void setSizeable( MiscCoord_V x, bool b )
		{ setSizing( x, ::setSizeable(getSizing(x),b) ); }
	void setSizeable_P( MiscCoord_P x, bool y )
		{ setSizeable( physicalToVisual(x), y ); }

	int getTag_P( MiscCoord_P ) const;
	int getTag( MiscCoord_V x ) const
		{ return getTag_P( visualToPhysical(x) ); }
	void setTag_P( MiscCoord_P, int );
	void setTag( MiscCoord_V x, int y )
		{ setTag_P( visualToPhysical(x), y ); }

	id getRepresentedObject_P( MiscCoord_P ) const;
	id getRepresentedObject( MiscCoord_V x ) const
		{ return getRepresentedObject_P( visualToPhysical(x) ); }
	void setRepresentedObject_P( MiscCoord_P, id );
	void setRepresentedObject( MiscCoord_V x, id y )
		{ setRepresentedObject_P( visualToPhysical(x), y ); }

	NSString* getTitle_P( MiscCoord_P ) const;
	NSString* getTitle( MiscCoord_V x ) const
		{ return getTitle_P( visualToPhysical(x) ); }
	bool setTitle_P( MiscCoord_P, NSString* ); 	// NOTE *1*
	bool setTitle( MiscCoord_V x, NSString* y )	// NOTE *1*
		{ return setTitle_P( visualToPhysical(x), y ); }

	MiscTableCellStyle getStyle_P( MiscCoord_P ) const;
	MiscTableCellStyle getStyle( MiscCoord_V x ) const
		{ return getStyle_P( visualToPhysical(x) ); }
	void setStyle_P( MiscCoord_P, MiscTableCellStyle );
	void setStyle( MiscCoord_V x, MiscTableCellStyle y )
		{ setStyle_P( visualToPhysical(x), y ); }

	id getPrototype_P( MiscCoord_V );
	id getPrototype( MiscCoord_V x )
		{ return getPrototype_P( visualToPhysical(x) ); }
	void setPrototype_P( MiscCoord_P, id );
	void setPrototype( MiscCoord_V x, id y )
		{ setPrototype_P( visualToPhysical(x), y ); }

	MiscCompareEntryFunc getSortFunc_P( MiscCoord_P ) const;
	MiscCompareEntryFunc getSortFunc( MiscCoord_V x ) const
		{ return getSortFunc_P( visualToPhysical(x) ); }
	void setSortFunc_P( MiscCoord_P, MiscCompareEntryFunc );
	void setSortFunc( MiscCoord_V x, MiscCompareEntryFunc y )
		{ setSortFunc_P( visualToPhysical(x), y ); }

	MiscSortDirection getSortDirection_P( MiscCoord_P ) const;
	MiscSortDirection getSortDirection( MiscCoord_V x ) const
		{ return getSortDirection_P( visualToPhysical(x) ); }
	void setSortDirection_P( MiscCoord_P, MiscSortDirection );
	void setSortDirection( MiscCoord_V x, MiscSortDirection y )
		{ setSortDirection_P( visualToPhysical(x), y ); }
	void clearSortDirection();	// Set all slots to ascending.

	MiscSortType getSortType_P( MiscCoord_P ) const;
	MiscSortType getSortType( MiscCoord_V x ) const
		{ return getSortType_P( visualToPhysical(x) ); }
	void setSortType_P( MiscCoord_P, MiscSortType );
	void setSortType( MiscCoord_V x, MiscSortType y )
		{ setSortType_P( visualToPhysical(x), y ); }

	// DEFAULT VALUES ARE USED TO INITIALIZE NEW SLOTS.
	MiscPixels	getDefaultSize() const	  { return def_slot.size; }
	MiscPixels	getDefaultMinSize() const { return def_slot.min_size; }
	MiscPixels	getDefaultMaxSize() const { return def_slot.min_size; }
	MiscTableSizing getDefaultSizing() const  { return def_slot.sizing; }
	int		getDefaultTag() const	  { return def_tag; }
	MiscTableCellStyle getDefaultStyle() const{ return def_style; }

	void setDefaultSize( MiscPixels x )
		{ needs_recalc = true; def_slot.size = x; }
	void setDefaultMinSize( MiscPixels x )
		{ needs_recalc = true; def_slot.min_size = x; }
	void setDefaultMaxSize( MiscPixels x )
		{ needs_recalc = true; def_slot.max_size = x; }
	void setDefaultSizing( MiscTableSizing x )
		{ needs_recalc = true; def_slot.sizing = x; }
	void setDefaultTag( int x )			{ def_tag = x; }
	void setDefaultStyle( MiscTableCellStyle x )	{ def_style = x; }

	// SELECTION
	MiscSparseSet const& selectionSet() const	{ return selection; }
	bool hasSelection() const	{ return !selection.isEmpty(); }
	bool hasMultipleSelection() const;
	unsigned int numSelected() const { return selection.count(); }
	MiscCoord_V selectedSlot() const { return selected_slot; }
	void clearSelectedSlot()	{ selected_slot = -1; }
	void setSelectedSlot( MiscCoord_V x )
					{ selected_slot = selection.coerce(x);}
	void fixSelectedSlot()		{ setSelectedSlot(selectedSlot()); }

	bool isSelected( MiscCoord_V x ) const { return selection.contains(x);}
	void toggle( MiscCoord_V x ) {selection.toggle(x); setSelectedSlot(x);}
	void select( MiscCoord_V x ) {selection.add(x); setSelectedSlot(x);}
	void select( MiscCoord_V lo, MiscCoord_V hi )
				{ selection.add(lo,hi); setSelectedSlot(hi); }
	void unselect( MiscCoord_V x )
				{ selection.remove(x); fixSelectedSlot(); }
	void unselect( MiscCoord_V lo, MiscCoord_V hi )
				{ selection.remove(lo,hi); fixSelectedSlot(); }

	void selectOne( MiscCoord_V x ) { selection.empty(); select(x); }
	void selectAll() { if (count() > 0) { selection.add( 0, count() - 1 );
				setSelectedSlot( count() - 1 ); } }
	void selectNone() { selection.empty(); clearSelectedSlot(); }
	void selectSlots( NSArray* l, bool extend )	// Physical coords.
				{ select_slots( l, !extend, true ); }
	NSArray* selectedSlots() const { return selected_slots( false ); }
	void selectTags( NSArray* l, bool extend )
				{ select_tags( l, !extend, true ); }
	NSArray* selectedTags() const { return selected_slots( true ); }

	void unselectSlots( NSArray* l )	// Physical coords.
				{ select_slots( l, false, false ); }
	void unselectTags( NSArray* l ) { select_tags( l, false, false ); }

	// KEYBOARD CURSOR
	MiscCoord_V getCursor() const { return cursor; }
	void setCursor( MiscCoord_V c )
		{ if (c >= 0 && c < count()) cursor = c; }
	void clearCursor() { cursor = -1; }
	bool hasValidCursor() const { return cursor >= 0 && cursor < count(); }


	// CLICKED SLOT
	MiscCoord_V clickedSlot() const { return clicked_slot; }
	void setClickedSlot( MiscCoord_V s ) { clicked_slot = s; }
	void clearClickedSlot() { setClickedSlot(-1); }


	// PHYSICAL-COORDINATE CONVENIENCE METHODS.

	MiscCoord_P selectedSlot_P() const
		{ return visualToPhysical(selected_slot); }
	void setSelectedSlot_P( MiscCoord_P x )
		{ setSelectedSlot( physicalToVisual(x) ); }
	void toggle_P( MiscCoord_P x )	{ toggle( physicalToVisual(x) ); }
	void select_P( MiscCoord_P x )	{ select( physicalToVisual(x) ); }
	void unselect_P( MiscCoord_P x ){ unselect( physicalToVisual(x) ); }
	bool isSelected_P( MiscCoord_P x ) const
		{ return isSelected( physicalToVisual(x) ); }
	void selectOne_P( MiscCoord_P x ) { selectOne(physicalToVisual(x)); }

	void setCursor_P( MiscCoord_P x ) { setCursor(physicalToVisual(x)); }
	MiscCoord_P getCursor_P() const
		{ return visualToPhysical(getCursor()); }

	MiscCoord_P clickedSlot_P() const
		{ return visualToPhysical( clickedSlot() ); }
	void setClickedSlot_P( MiscCoord_P x )
		{ setClickedSlot( physicalToVisual(x) ); }

	// ARCHIVING SUPPORT.
	void encodeWithCoder( NSCoder* );
	void initWithCoder( NSCoder*, int ver );
	void initWithCoder_v1( NSCoder*, int ver );
	void initWithCoder_v2( NSCoder*, int ver );
	};

#endif // __MiscTableBorder_h
