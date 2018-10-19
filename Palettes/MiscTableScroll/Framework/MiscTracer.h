#ifndef __MiscTracer_h
#define __MiscTracer_h
#ifdef __GNUC__
#pragma interface
#endif
//=============================================================================
//
//	Copyright (C) 1997,1998 by Paul S. McCarthy and Eric Sunshine.
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
// MiscTracer.h
//
//	Simple C++ class that helps generate function enter/exit
//	trace messages.
//
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscTracer.h,v 1.2 98/03/23 07:48:27 sunshine Exp $
// $Log:	MiscTracer.h,v $
// Revision 1.2  98/03/23  07:48:27  sunshine
// v134.1: Ported from NEXTSTEP to OPENSTEP/Rhapsody.
// 
//  Revision 1.1  97/12/22  22:00:23  zarnuk
//  v134: Utility class to create function enter/exit messages.
//-----------------------------------------------------------------------------

class MiscTracer
	{
private:
static	int TRACE_DEPTH;
	char const* msg;
	void dump( char const* ) const;
public:
	MiscTracer( char const* s ): msg(s)
	    {
	    dump( "->" );
	    TRACE_DEPTH += 2;
	    }
	~MiscTracer()
	    {
	    TRACE_DEPTH -= 2;
	    dump( "<-" );
	    }
	void foo() const {}	// compiler muffler
static	int get_depth()		{ return TRACE_DEPTH; }
	};


#ifdef TRACE_ON
#define	TRACE(X)	MiscTracer mcgh_tracer(X); mcgh_tracer.foo();
#else
#define	TRACE(X)
#endif

#endif // __MiscTracer_h
