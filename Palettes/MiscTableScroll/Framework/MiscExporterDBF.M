//=============================================================================
//
//	Copyright (C) 1996-1997 by Paul S. McCarthy and Eric Sunshine.
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
// MiscExporterDBF.M
//
//	Routines to export MiscTableScrolls in dBASE III (.DBF) format.
//
// TODO:
//	Provide some public means to set the "AMERICAN_DATE" and the
//	locale-specific characters.
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// $Id: MiscExporterDBF.M,v 1.3 97/04/01 07:47:22 sunshine Exp $
// $Log:	MiscExporterDBF.M,v $
// Revision 1.3  97/04/01  07:47:22  sunshine
// v0.125.5: Removed unused argument.  No longer shadows variable in
// -dbfAnalyze:::.
// 
// Revision 1.2  97/02/07  13:53:18  sunshine
// v108: Ported to OPENSTEP 4.1 (gamma).
// 
// Revision 1.1  96/09/25  11:55:17  zarnuk
// Exports the contents of table scroll in dBASEIII .dbf format.
//-----------------------------------------------------------------------------
#import "MiscExporterPrivate.h"
#import	"bool.h"

extern "C" {
#import	<stdio.h>
#import	<time.h>		// time(), localtime(), strftime()
}

char const DECIMAL_CHAR = '.';		// American value.
char const DATE_CHAR = '/';		// American value.
char const TIME_CHAR = ':';		// American value.
bool const AMERICAN_DATE = true;	// mm/dd/yy vs. dd/mm/yy

int const DBF_NUM_FLDS_MAX	= 1022;		// Max # fields.
int const DBF_REC_LEN_MAX	= 0x7fff;	// Max record length.
int const DBF_FLD_NAME_MAX	= 10;
int const DBF_CHAR_LEN_MAX	= 254;
int const DBF_DATE_WIDTH	= 8;		// "YYYYMMDD"
int const DBF_TIME_WIDTH	= 5;		// "HH:MM"
int const DBF_NUMERIC_LEN_MAX	= 19;		// Max length for "N" fields.

static char const DBF_NULL_DATE_STR[] = "        ";
static char const DBF_NULL_TIME_STR[] = "     ";


struct DBFHeader
	{
	unsigned char	version;
	unsigned char	update_yr;
	unsigned char	update_mon;
	unsigned char	update_day;
	unsigned char	num_recs[4];	// little-endian long int
	unsigned char	hdr_len[2];	// little-endian short int
	unsigned char	rec_len[2];	// little-endian short int
	char		fill[20];
	};

struct DBFFieldDef
	{
	char		name[ DBF_FLD_NAME_MAX + 1 ];
	char		type;		// Char, Numeric, Logical, Date, Memo.
	char		fill[4];
	unsigned char	fld_len;
	unsigned char	num_decimals;
	char		fill2[14];
	};

enum DBFDataType
	{
	DBF_TYPE_CHAR,			// Non-structured type.
	DBF_TYPE_NUMERIC,		// Numeric values only.
	DBF_TYPE_DATE,			// Date values only.
	DBF_TYPE_DATETIME		// Date-time values only.
	};

#define	DBF_BIT_CHAR		(1 << DBF_TYPE_CHAR)
#define	DBF_BIT_NUMERIC		(1 << DBF_TYPE_NUMERIC)
#define	DBF_BIT_DATE		(1 << DBF_TYPE_DATE)
#define	DBF_BIT_DATETIME	(1 << DBF_TYPE_DATETIME)

static char const DBF_TYPE_CODE[] = "CNDD";


struct DBFInfo
	{
	DBFDataType	type;		// Final data type.
	unsigned int	mask;		// All candidate types.
	int		max_width;	// Max width for this column.
	int		max_left;	// Left of decimal for numeric.
	int		max_right;	// Right of decimal for numeric.
	};

struct DBFDateTime
	{
	int		year;
	int		month;
	int		day;
	int		hour;
	int		minute;
	int		second;
	};


//-----------------------------------------------------------------------------
// dbf_field_name
//	Make sure all field names conform to DBF field name rules.
//-----------------------------------------------------------------------------
static int dbf_field_name( char* buff, NSString* str )
    {
    int len = 0;
    char const* s = (str != 0 ? [str lossyCString] : 0);
    if (s != 0)
	{
	bool in_gap = true;
	for (; len < DBF_FLD_NAME_MAX && *s != 0; s++)
	    {
	    char const c = toupper(*s);
	    if ('A' <= c && c <= 'Z')
		{
		in_gap = false;
		buff[len++] = c;
		}
	    else if ('0' <= c && c <= '9')
		{
		in_gap = false;
		if (len == 0)		// Cannot start with digit.
		    buff[len++] = 'F';
		buff[len++] = c;
		}
	    else if (!in_gap)
		{
		in_gap = true;
		buff[len++] = '_';
		}
	    }
	if (in_gap && len > 0)		// Remove trailing underline.
	    len--;
	}

    if (len == 0)
	{
	char const DEFAULT_FIELD_NAME[] = "FIELD";
	strcpy( buff, DEFAULT_FIELD_NAME );
	len = sizeof( DEFAULT_FIELD_NAME ) - 1;
	}

    buff[ len ] = '\0';

    return len;
    }


//-----------------------------------------------------------------------------
// adjust_name
//	Adjust this field name to try to avoid a collision with other
//	field names.  Performs the adjustment by appending a counter to
//	the end of the name.  If the counter does not fit in the space
//	following the field name, the field name's "core" length is
//	trimmed back to allow more space for the counter.  Returns the
//	new "core" length for the field.
//-----------------------------------------------------------------------------
static int adjust_name( char* name, int core_len, int counter )
    {
    char buff[ 16 ];
    sprintf( buff, "%d", counter );

    int buff_len = strlen( buff );
    if (core_len + buff_len > DBF_FLD_NAME_MAX)
	core_len = DBF_FLD_NAME_MAX - buff_len;

    strcpy( name + core_len, buff );

    return core_len;
    }


//-----------------------------------------------------------------------------
// collision
//	Does this field name collide with any preceeding field name?
//-----------------------------------------------------------------------------
static BOOL collision(	DBFFieldDef const* flds,
			DBFFieldDef const* flds_lim )
    {
    char const* const name = flds_lim->name;
    for ( ; flds < flds_lim; flds++)
	if (strcmp( flds->name, name ) == 0)
	    return YES;
    return NO;
    }


//-----------------------------------------------------------------------------
// set_field_name
//-----------------------------------------------------------------------------
static void set_field_name( NSString* s, DBFFieldDef* fld,
			DBFFieldDef* flds )
    {
    int slen = dbf_field_name( fld->name, s );
    int num_tries = 0;
    while (collision( flds, fld ))
	slen = adjust_name( fld->name, slen, ++num_tries );
    }


//-----------------------------------------------------------------------------
// set_field
//-----------------------------------------------------------------------------
static void set_field( NSString* s, DBFFieldDef* fld,
			DBFFieldDef* flds, DBFInfo const* ip )
    {
    set_field_name( s, fld, flds );
    fld->type = DBF_TYPE_CODE[ ip->type ];
    fld->fld_len = (unsigned char) ip->max_width;
    if (ip->type == DBF_TYPE_NUMERIC)
	fld->num_decimals = ip->max_right;
    }



//-----------------------------------------------------------------------------
// set_time_field
//-----------------------------------------------------------------------------
static void set_time_field( NSString* s, DBFFieldDef* fld,
			DBFFieldDef* flds, DBFInfo const* )
    {
    set_field_name( s, fld, flds );
    fld->type = DBF_TYPE_CODE[ DBF_TYPE_CHAR ];
    fld->fld_len = DBF_TIME_WIDTH;
    }



//-----------------------------------------------------------------------------
// skip_whitespace
//-----------------------------------------------------------------------------
inline static char const* skip_whitespace( char const* s )
    {
    if (s != 0)
	for (; *s != 0 && isspace(*s); s++) /*empty*/;
    return s;
    }


//-----------------------------------------------------------------------------
// dbf_is_numeric
//-----------------------------------------------------------------------------
static bool dbf_is_numeric( NSString* str, DBFInfo* ip )
    {
    bool neg = false;
    int left_len = 0;
    int right_len = 0;
    char const* s = [str lossyCString];

    if (*s == '\0')			// Empty string, treat as null.
	return true;

    if (*s == '-')
	{ s++; neg = true; }
    else if (*s == '+')
	s++;

    s = skip_whitespace( s );

    while ('0' <= *s && *s <= '9')
	{
	s++;
	left_len++;
	}

    if (*s == DECIMAL_CHAR)
	{
	s++;
	while ('0' <= *s && *s <= '9')
	    {
	    s++;
	    right_len++;
	    }
	}

    s = skip_whitespace( s );

    if (*s == '\0' && (left_len > 0 || right_len > 0))
	{
	if (left_len == 0)
	    left_len++;
	if (neg)
	    left_len++;

	if (ip->max_left < left_len)
	    ip->max_left = left_len;

	if (ip->max_right < right_len)
	    ip->max_right = right_len;

	return true;
	}

    return false;
    }


//-----------------------------------------------------------------------------
// dbf_parse_time
//-----------------------------------------------------------------------------
static DBFDataType dbf_parse_time( NSString* str, DBFDateTime& dt )
    {
    char const* s = [str lossyCString];
    DBFDataType type = DBF_TYPE_CHAR;
    if ('0' <= *s && *s <= '9')
	{
	int hour = 0;
	do { hour = hour * 10 + *s - '0'; s++; }
	while ('0' <= *s && *s <= '9');
	if (*s == TIME_CHAR)
	    {
	    s++;
	    if ('0' <= *s && *s <= '9')
		{
		int minute = 0;
		int second = 0;
		do { minute = minute * 10 + *s - '0'; s++; }
		while ('0' <= *s && *s <= '9');
		if (*s == TIME_CHAR)	// seconds are optional.
		    {
		    s++;
		    second = -1;
		    if ('0' <= *s && *s <= '9')
			{
			second = 0;
			do { second = second * 10 + *s - '0'; s++; }
			while ('0' <= *s && *s <= '9');
			if (*s == TIME_CHAR || *s == DECIMAL_CHAR)
			    {
			    s++;	// fractions of seconds ignored.
			    while ('0' <= *s && *s <= '9')
				s++;
			    }
			}
		    }
		s = skip_whitespace(s);
		if (*s == '\0' &&
		    0 <= hour && hour <= 23 &&
		    0 <= minute && minute <= 59 &&
		    0 <= second && second <= 59)
		    {
		    dt.hour = hour;
		    dt.minute = minute;
		    dt.second = second;
		    type = DBF_TYPE_DATETIME;
		    }
		}
	    }
	}
    return type;
    }


//-----------------------------------------------------------------------------
// dbf_parse_date
//-----------------------------------------------------------------------------
static DBFDataType dbf_parse_date( NSString* str, DBFDateTime& dt )
    {
    char const* s = [str lossyCString];
    memset( &dt, 0, sizeof(dt) );
    DBFDataType type = DBF_TYPE_CHAR;
    if (*s == '\0')
	type = DBF_TYPE_DATE;
    else if ('0' <= *s && *s <= '9')
	{
	int month = 0;
	do { month = month * 10 + *s - '0'; s++; }
	while ('0' <= *s && *s <= '9');
	if (*s == DATE_CHAR)
	    {
	    s++;
	    if ('0' <= *s && *s <= '9')
		{
		int day = 0;
		do { day = day * 10 + *s - '0'; s++; }
		while ('0' <= *s && *s <= '9');
		if (*s == DATE_CHAR)
		    {
		    s++;
		    if ('0' <= *s && *s <= '9')
			{
			int year = 0;
			do { year = year * 10 + *s - '0'; s++; }
			while ('0' <= *s && *s <= '9');
			if (!AMERICAN_DATE)
			    {
			    int tmp = month;
			    month = day;
			    day = tmp;
			    }
			if (1 <= month && month <= 12 &&
			    1 <= day && day <= 31 &&
			    ((0 <= year && year < 100) ||
			    (1700 < year && year < 3000)))
			    {
			    if (year < 100)
				{
				time_t t;
				time(&t);
				struct tm const* tm = localtime(&t);
				int tm_year = tm->tm_year + 1900;
				year += 1900;
				while ((tm_year - year) > 90)
				    year += 100;
				}
			    dt.year = year;
			    dt.month = month;
			    dt.day = day;
			    s = skip_whitespace(s);
			    if (*s == '\0')
				type = DBF_TYPE_DATE;
			    else 
				{
				NSString* tm = [NSString stringWithCString:s];
				type = dbf_parse_time( tm, dt );
				}
			    }
			}
		    }
		}
	    }
	}
    return type;
    }



//=============================================================================
// MiscExporter
//=============================================================================
@implementation MiscExporter(DBF)

//-----------------------------------------------------------------------------
// dbfAnalyze:::
//-----------------------------------------------------------------------------
- (DBFInfo*)dbfAnalyze:(int)nrows :(int)ncols :(int const*)map
    {
    int c;
    DBFDateTime datetime;
    DBFInfo* const info = (DBFInfo*) calloc( ncols, sizeof(*info) );

    for (c = 0; c < ncols; c++)
	info[c].mask = (DBF_BIT_NUMERIC | DBF_BIT_DATE | DBF_BIT_DATETIME);

    for (int r = 0; r < nrows; r++)
	{
	DBFInfo* ip = info;
	for (c = 0; c < ncols; c++,ip++)
	    {
	    NSString* const s = str_at( r, map[c], tableScroll );
	    if (s != 0 && [s length] > 0)
		{
		int const len = [s length];
		if (ip->max_width < len)
		    ip->max_width = len;
		unsigned int mask = ip->mask;
		if (mask & DBF_BIT_NUMERIC)
		    {
		    if (!dbf_is_numeric( s, ip ))
			mask &= ~DBF_BIT_NUMERIC;
		    }
		if (mask & (DBF_BIT_DATE | DBF_BIT_DATETIME))
		    {
		    switch (dbf_parse_date( s, datetime ))
			{
			default:
			case DBF_TYPE_CHAR:
			case DBF_TYPE_NUMERIC:
				mask &= ~(DBF_BIT_DATE | DBF_BIT_DATETIME);
				break;
			case DBF_TYPE_DATETIME:
				mask &= ~DBF_BIT_DATE;
				break;
			case DBF_TYPE_DATE:
				break;
			}
		    }
		ip->mask = mask;
		}
	    }
	}

    DBFInfo* ip = info;
    for (c = 0; c < ncols; c++,ip++)
	{
	DBFDataType type = DBF_TYPE_CHAR;
	unsigned int const mask = ip->mask;
	if (mask & DBF_BIT_DATE)
	    {
	    type = DBF_TYPE_DATE;
	    ip->max_width = DBF_DATE_WIDTH;
	    }
	else if (mask & DBF_BIT_DATETIME)
	    {
	    type = DBF_TYPE_DATETIME;
	    ip->max_width = DBF_DATE_WIDTH;
	    }
	else if (mask & DBF_BIT_NUMERIC)
	    {
	    type = DBF_TYPE_NUMERIC;
	    int width = ip->max_left;
	    if (ip->max_right > 0)
		width += ip->max_right + 1;
	    if (width > DBF_NUMERIC_LEN_MAX)
		{
		type = DBF_TYPE_CHAR;
		if (width > DBF_CHAR_LEN_MAX)
		    width = DBF_CHAR_LEN_MAX;
		}
	    ip->max_width = width;
	    }
	else if (ip->max_width > DBF_CHAR_LEN_MAX)
	    ip->max_width = DBF_CHAR_LEN_MAX;
	ip->type = type;
	}

    return info;
    }


//-----------------------------------------------------------------------------
// dbfFields:::::
//	Set the names of the Field definitions.
//	Make sure all field names conform to DBF field name rules.
//	Make sure all field names are unique within the DBF length limits.
//-----------------------------------------------------------------------------
- (void)dbfFields:(int)row_title_width
	:(DBFFieldDef*)flds :(int)ncols :(int const*)map :(DBFInfo const*)info
    {
    DBFFieldDef* fld = flds;

    if (row_title_width > 0)
	{
	strcpy( fld->name, "ROW_TITLE" );
	fld->type = DBF_TYPE_CODE[ DBF_TYPE_CHAR ];
	fld->fld_len = (unsigned char) row_title_width;
	fld++;
	}

    DBFInfo const* ip = info;
    for (int c = 0; c < ncols; c++,fld++,ip++)
	{
	NSString* const s = col_title( map[c], tableScroll );
	set_field( s, fld, flds, ip );
	if (ip->type == DBF_TYPE_DATETIME)
	    set_time_field( s, ++fld, flds, ip );
	}
    }


//-----------------------------------------------------------------------------
// dbfHeader::::
//-----------------------------------------------------------------------------
- (int)dbfHeader:(int)row_title_width :(int)nrows :(int)ncols
	:(int const*)map :(DBFInfo const*)info :(FILE*)fp
    {
    BOOL const rowTitlesOn = (row_title_width > 0);
    int rec_len = 1;			// All records have a one-byte flag.
    int nflds = 0;
    int ntime = 0;			// Number of extra time fields.

    if (rowTitlesOn)
	{
	rec_len += row_title_width;
	nflds++;
	}

    DBFInfo const* ip = info;
    for (int i = 0; i < ncols; i++,ip++)
	{
	if (ip->type == DBF_TYPE_DATETIME)
	    {
	    if (nflds + 1 < DBF_NUM_FLDS_MAX &&
		rec_len <= DBF_REC_LEN_MAX - DBF_DATE_WIDTH - DBF_TIME_WIDTH)
		{
		rec_len += DBF_DATE_WIDTH + DBF_TIME_WIDTH;
		nflds += 2;
		ntime++;
		}
	    else
		break;			// Either get both in, or neither.
	    }
	else if (nflds < DBF_NUM_FLDS_MAX &&
	    rec_len + ip->max_width < DBF_REC_LEN_MAX)
	    {
	    rec_len += ip->max_width;
	    nflds++;
	    }
	}

    int const nbytes = sizeof(DBFHeader) + (nflds * sizeof(DBFFieldDef)) + 1;
    DBFHeader* hdr = (DBFHeader*) calloc( 1, nbytes );
    DBFFieldDef* flds = (DBFFieldDef*)(hdr + 1);

    time_t t;
    time( &t );
    struct tm const* tm = localtime( &t );

    hdr->version	= 0x03;
    hdr->update_yr	= (unsigned char) ((tm->tm_year) & 0x0ff);
    hdr->update_mon	= (unsigned char) ((tm->tm_mon + 1) & 0x0ff);
    hdr->update_day	= (unsigned char) ((tm->tm_mday) & 0x0ff);

    int n = nrows;
    hdr->num_recs[0]	= (unsigned char) (n & 0x0ff);	n = n >> 8;
    hdr->num_recs[1]	= (unsigned char) (n & 0x0ff);	n = n >> 8;
    hdr->num_recs[2]	= (unsigned char) (n & 0x0ff);	n = n >> 8;
    hdr->num_recs[3]	= (unsigned char) (n & 0x0ff);

    n = nbytes;
    hdr->hdr_len[0]	= (unsigned char) (n & 0x0ff); n = n >> 8;
    hdr->hdr_len[1]	= (unsigned char) (n & 0x0ff);

    n = rec_len;
    hdr->rec_len[0] = (unsigned char) (n & 0x0ff); n = n >> 8;
    hdr->rec_len[1] = (unsigned char) (n & 0x0ff);

    ncols = (rowTitlesOn ? nflds - 1 : nflds) - ntime;

    [self dbfFields:row_title_width:flds:ncols:map:info];

    flds[nflds].name[0] = '\r';

    fwrite( hdr, nbytes, 1, fp );

    free( hdr );

    return ncols;
    }


//-----------------------------------------------------------------------------
// dbf_put_char
//-----------------------------------------------------------------------------
static void dbf_put_char( NSString* str, int width, FILE* fp )
    {
    char const* s = [str lossyCString];
    if (s == 0)
	pad( width, fp );
    else
	{
	int const len = strlen( s );
	int const delta = width - len;
	if (delta > 0)
	    {
	    fwrite( s, len, 1, fp );
	    pad( delta, fp );
	    }
	else
	    fwrite( s, width, 1, fp );
	}
    }


//-----------------------------------------------------------------------------
// dbf_put_numeric
//-----------------------------------------------------------------------------
static void dbf_put_numeric( NSString* str, DBFInfo const* ip, FILE* fp )
    {
    if (str == 0)
	{
	if (ip->max_left > 1)
	    pad( ip->max_left - 1, fp );
	fputc( '0', fp );
	if (ip->max_right > 0)
	    {
	    fputc( '.', fp );
	    repchar( ip->max_right, '0', fp );
	    }
	}
    else
	{
	bool neg = false;
	int right_len = 0;

	char const* s = [str lossyCString];
	s = skip_whitespace(s);
	if (*s == '-')
	    { s++; neg = true; }
	else if (*s == '+')
	    s++;
	s = skip_whitespace(s);
	char const* const left_part = s;

	while ('0' <= *s && *s <= '9')
	    s++;

	int const left_len = (s - left_part);

	char const* right_part = s;
	if (*s == DECIMAL_CHAR)
	    {
	    s++;
	    right_part++;
	    while ('0' <= *s && *s <= '9')
		s++;
	    right_len = (s - right_part);
	    }

	int left_pad = ip->max_width - left_len;
	if (left_len == 0)
	    left_pad--;			// Room for required '0'.

	if (ip->max_right > 0)		// Room for decimal and fraction.
	    left_pad -= ip->max_right + 1;

	if (neg)
	    left_pad--;			// Room for '-'.

	pad( left_pad, fp );
	if (neg)
	    fputc( '-', fp );
	if (left_len <= 0)
	    fputc( '0', fp );
	else
	    fwrite( left_part, 1, left_len, fp );

	if (ip->max_right > 0)
	    {
	    fputc( '.', fp );
	    if (right_len > 0)
		fwrite( right_part, 1, right_len, fp );
	    if (right_len < ip->max_right)
		repchar( ip->max_right - right_len, '0', fp );
	    }
	}
    }


//-----------------------------------------------------------------------------
// dbf_put_date
//-----------------------------------------------------------------------------
static void dbf_put_date( NSString* str, DBFInfo const* ip, FILE* fp )
    {
    char const* s = (str != 0 ? [str lossyCString] : 0);
    s = skip_whitespace(s);
    if (s == 0 || *s == 0)
	{
	fputs( DBF_NULL_DATE_STR, fp );
	if (ip->type == DBF_TYPE_DATETIME)
	    fputs( DBF_NULL_TIME_STR, fp );
	}
    else
	{
	char buff[ 64 ];
	DBFDateTime dt;
	dbf_parse_date( str, dt );
	sprintf( buff, "%04d%02d%02d", dt.year, dt.month, dt.day );
	fputs( buff, fp );
	if (ip->type == DBF_TYPE_DATETIME)
	    {
	    sprintf( buff, "%02d:%02d", dt.hour, dt.minute );
	    fputs( buff, fp );
	    }
	}
    }


//-----------------------------------------------------------------------------
// exportDBF:
//-----------------------------------------------------------------------------
- (void)exportDBF:(FILE*)fp
    {
    int const nrows = [tableScroll numberOfRows];
    int const tcols = [tableScroll numberOfColumns];
    int* col_map = [self makeColMap:tcols];
    DBFInfo* info = [self dbfAnalyze:nrows:tcols:col_map];
    int row_title_width = [self rowTitleCharWidth:nrows];

    if (row_title_width > DBF_CHAR_LEN_MAX)
	row_title_width = DBF_CHAR_LEN_MAX;

    int const ncols =
	[self dbfHeader:row_title_width:nrows:tcols:col_map:info:fp];

    for (int r = 0; r < nrows; r++)
	{
	int const pr = row_at( r, tableScroll );
	fputc( ' ', fp );
	if (row_title_width > 0)
	    dbf_put_char( row_title( pr, tableScroll ), row_title_width, fp );
	DBFInfo const* ip = info;
	for (int c = 0; c < ncols; c++,ip++)
	    {
	    NSString* const s = str_at( pr, col_map[c], tableScroll );
	    switch (ip->type)
		{
		case DBF_TYPE_CHAR:
			dbf_put_char( s, ip->max_width, fp );
			break;
		case DBF_TYPE_NUMERIC:
			dbf_put_numeric( s, ip, fp );
			break;
		case DBF_TYPE_DATE:
		case DBF_TYPE_DATETIME:
			dbf_put_date( s, ip, fp );
			break;
		}
	    }
	}
    fputc( '\x1a', fp );	// Terminating Control-Z.

    free( info );
    free( col_map );
    }

@end
