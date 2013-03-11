#ifndef dynamic_h
#define dynamic_h

#include "bstrlib.h"
#include "darray.h"

typedef struct Piece {
    bstring str;
    bstring (*func)(int, int);
    int p1;
    int p2;
} Piece;

typedef struct DynArgScanner {
    int cs;
    int act;
    int have;
    int curline;
    char *ts;
    char *te;
    char *p;
    char *pe;
    char *eof;
    char *input;
    
    int new_piece;
    DArray *pieces;
    size_t pieces_index;
    int count;
} DynArgScanner;

bstring random_func(int length, int notused);
bstring long_increasing_func(int start, int step);
void DynArgScanner_scan(DynArgScanner *s);
void DynArgScanner_init(DynArgScanner *s, char *input);
bstring DynArgScanner_get_url(DynArgScanner *scanner);

#endif
