#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <time.h>
#include "bstrlib.h"
#include "darray.h"
#include "dynamic.h"

%%{
    machine DynArgScanner;
    write data;
}%%

void DynArgScanner_init(DynArgScanner *s, char *input) {
    srand(time(NULL));
    memset(s, '\0', sizeof(DynArgScanner));
    s->curline = 1;
    s->input = input;
    s->p = s->input;
    s->pe = s->p + strlen(s->input) + 1;
    s->eof = s->pe;
    s->ts = s->p;
    s->te = s->ts;

    s->pieces = DArray_create(sizeof(Piece), 2);
    Piece *piece = calloc(1, sizeof(Piece));
    piece->str = bfromcstr("");
    piece->func = NULL;
    piece->p1 = 0;
    piece->p2 = 0;
    DArray_push(s->pieces, piece);

    s->new_piece = 0;

    %% write init;
}

bstring random_func(int length, int notused) {
    static const char alphanum[] =
        "0123456789"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "abcdefghijklmnopqrstuvwxyz";
    bstring toret = bfromcstralloc(length, "");
    int i = 0; 
    for (i = 0; i < length; i++) {
        bconchar(toret, alphanum[rand() % (sizeof(alphanum) - 1)]);
    }
    return toret;
}

bstring long_increasing_func(int start, int step) {
    char *toret = calloc(64, sizeof(char));
    sprintf(toret, "%ld", random());
    bstring out = bfromcstr(toret);
    free(toret);
    return out;
}

void DynArgScanner_scan(DynArgScanner *s) {
    %%{
        machine DynArgScanner;
        access s->;
        variable p s->p;
        variable pe s->pe;
        variable eof s->eof;

        marker_random_string = '{RANDOM|' . digit+ . '}';
        marker_increasing_long = '{LONGINC|' . digit+ . '|' . digit+ . '}';
        EOF = 0;

        main := |*
            marker_random_string => {
                int len = s->te - s->ts;
                int chars_to_copy = len;
                char *tmpbuf = calloc(chars_to_copy + 1, sizeof(char));
                strncpy(tmpbuf, s->ts, chars_to_copy);
                int length = 0;
                sscanf(tmpbuf, "{RANDOM|%d}", &length);
                free(tmpbuf);

                Piece *piece = calloc(1, sizeof(Piece));
                piece->str = NULL;
                piece->func = random_func;
                piece->p1 = length;
                piece->p2 = 0;

                DArray_push(s->pieces, piece);
                s->new_piece = 1;
            };
            marker_increasing_long =>  {
                int len = s->te - s->ts;
                int chars_to_copy = len;
                char *tmpbuf = calloc(chars_to_copy + 1, sizeof(char));
                strncpy(tmpbuf, s->ts, chars_to_copy);
                int start = 0; int step = 0;
                sscanf(tmpbuf, "{LONGINC|%d|%d}", &start, &step);
                free(tmpbuf);

                Piece *piece = calloc(1, sizeof(Piece));
                piece->str = NULL;
                piece->func = long_increasing_func;
                piece->p1 = start;
                piece->p2 = step;

                DArray_push(s->pieces, piece);
                s->new_piece = 1;
            };
            any => {
                if (s->new_piece == 1) {
                    Piece *piece = calloc(1, sizeof(Piece));
                    piece->str = bfromcstr("");
                    piece->func = NULL;
                    piece->p1 = 0;
                    piece->p2 = 0;

                    DArray_push(s->pieces, piece);
                    s->new_piece = 0;
                    bconchar(piece->str, s->ts[0]);
                } else {
                    Piece *piece = DArray_get(s->pieces, DArray_count(s->pieces) - 1);
                    bconchar(piece->str, s->ts[0]);
                }
            };
        *|;
        write exec;
    }%%
}

bstring DynArgScanner_get_url(DynArgScanner *scanner) {
    bstring out = bfromcstr("");
    for(int i = 0; i < DArray_count(scanner->pieces); i++) {
        Piece * piece = DArray_get(scanner->pieces, i);
        if (piece->str != NULL) {
            bconcat(out, piece->str);
        } else {
            bstring in = piece->func(piece->p1, piece->p2);
            bconcat(out, in);
            bdestroy(in);
        }

    }
    return out;
}

/* int main() { */
/*     DynArgScanner scanner; */
/*     char *url = "GET /s:core:device={RANDOM|34}&l:tmp:unu=19&s:ts:ts={LONGINC|144444444|99}&kk=1 HTTP/1.1\r\nHost: localhost:8081\r\n\r\n"; //\r\nHost: localhost:8081\r\n\r\n */
/*     DynArgScanner_init(&scanner, url); */
/*     DynArgScanner_scan(&scanner); */
/*     printf("out: %s", bdata(DynArgScanner_get_url(&scanner))); */
/*     return 0; */
/* } */
