#==============================================================================
#
#	Copyright (C) 1999 by Paul S. McCarthy and Eric Sunshine.
#		Written by Paul S. McCarthy and Eric Sunshine.
#			    All Rights Reserved.
#
#	This notice may not be removed from this source code.
#
#	This object is included in the MiscKit by permission from the authors
#	and its use is governed by the MiscKit license, found in the file
#	"License.rtf" in the MiscKit distribution.  Please refer to that file
#	for a list of all applicable permissions and restrictions.
#
#==============================================================================
#------------------------------------------------------------------------------
# MiscTableScrollJava.sed
#
#	Under Windows, the stub file generated by bridget for MiscTableScroll
#	exports so many symbols that the compiler generates a single line of
#	assembly which is so long that it overflows the assembler's input
#	buffer, resulting in a crash.  The offending assembler directive looks
#	like this:
#
#	.ascii " -export:symbol1 -export:symbol2 ... -export:symbolN\0"
#
#	This "sed" script, which is inserted into the build process, breaks up
#	the problematic line in this fashion:
#
#	.ascii " -export:symbol1"
#	.ascii " -export:symbol2"
#	...
#	.ascii " -export:symbolN\0"
#
#------------------------------------------------------------------------------
#------------------------------------------------------------------------------
# $Id: MiscTableScrollJava.sed,v 1.1 99/06/14 18:53:47 sunshine Exp $
# $Log:	MiscTableScrollJava.sed,v $
# Revision 1.1  99/06/14  18:53:47  sunshine
# v140.1: A compilation patch to work around a bug in the compiler for
# Windows.  MiscTableScrollJava exports so many symbols from the DLL that
# the compiler generates a single assembly directive which is too long for
# the assemblers input buffer.  Consequently the build process aborts.  This
# script is inserted into the compilation process by the makefile and works
# around the problem by breaking the offending line into smaller pieces.
# 
#------------------------------------------------------------------------------

s/[ 	]*\.ascii " -export:/-export:/
s/-export:\([^ "]*\)[ "]/	.ascii " -export:\1"\
/g
