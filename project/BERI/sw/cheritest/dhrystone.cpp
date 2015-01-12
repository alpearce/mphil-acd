/*
*************************************************************************
*
*                   "DHRYSTONE" Benchmark Program
*                   -----------------------------
*
*  Version:    C, Version 2.1
*
*  File:       dhry.h (part 1 of 3)
*
*  Date:       May 25, 1988
*
*  Author:     Reinhold P. Weicker
*              Siemens Nixdorf Inf. Syst.
*              STM OS 32
*              Otto-Hahn-Ring 6
*              W-8000 Muenchen 83
*              Germany
*                      Phone:    [+49]-89-636-42436
*                                (8-17 Central European Time)
*                      UUCP:     weicker@ztivax.uucp@unido.uucp
*                      Internet: weicker@ztivax.siemens.com
*
*              Original Version (in Ada) published in
*              "Communications of the ACM" vol. 27., no. 10 (Oct. 1984),
*              pp. 1013 - 1030, together with the statistics
*              on which the distribution of statements etc. is based.
*
*              In this C version, the following C library functions are
*              used:
*              - strcpy, strcmp (inside the measurement loop)
*              - printf, scanf (outside the measurement loop)
*
*/


//#include "config.h"
//#include <cstdlib>
//#include <cstdio>
//#include <cstring>

//#include "util.h"
//#include "cpu_benchmark.h"
//#include "dhrystone.h"

#define structassign(d, s)      d = s

#define bool            int

#define REG register

typedef enum    {Ident_1, Ident_2, Ident_3, Ident_4, Ident_5} Enumeration;

typedef int     One_Thirty;
typedef int     One_Fifty;
typedef char    Capital_Letter;
typedef char    Str_30[31];
typedef int     Arr_1_Dim[50];
typedef int     Arr_2_Dim[50][50];

#define DRAM_BASE (0x9000000000001000ULL)
char * heap = (char *)DRAM_BASE;

typedef struct  Record {
        struct Record           *Ptr_Comp;
        Enumeration             Discr;
    union {
          struct {
                  Enumeration Enum_Comp;
                  int         Int_Comp;
                  char        Str_Comp [31];
                  } var_1;
          struct {
                  Enumeration E_Comp_2;
                  char        Str_2_Comp [31];
                  } var_2;
          struct {
                  char        Ch_1_Comp;
                  char        Ch_2_Comp;
                  } var_3;
          } variant;
} Rec_Type, *Rec_Pointer;

struct DS_DATA {
    Rec_Pointer       _Ptr_Glob;
    Rec_Pointer       _Next_Ptr_Glob;
    int             _Int_Glob;
    bool            _Bool_Glob;
    char            _Ch_1_Glob;
    char            _Ch_2_Glob;
    Arr_1_Dim       _Arr_1_Glob;
    Arr_2_Dim       _Arr_2_Glob;
};


#define Int_Glob  dd->_Int_Glob
#define Bool_Glob dd->_Bool_Glob
#define Ch_1_Glob dd->_Ch_1_Glob
#define Ch_2_Glob dd->_Ch_2_Glob
#define Arr_1_Glob dd->_Arr_1_Glob
#define Arr_2_Glob dd->_Arr_2_Glob
#define Ptr_Glob dd->_Ptr_Glob
#define Next_Ptr_Glob dd->_Next_Ptr_Glob



#define TRUE            1
#define FALSE           0


/*
 * Package 1
 */


void Proc_0();
void Proc_1(struct DS_DATA *, Rec_Pointer PtrParIn);
void Proc_2(struct DS_DATA *, One_Fifty *IntParIO);
void Proc_3(struct DS_DATA *, Rec_Pointer *PtrParOut);
void Proc_4(struct DS_DATA *);
void Proc_5(struct DS_DATA *);
void Proc_6(struct DS_DATA *, Enumeration EnumParIn, Enumeration *EnumParOut);
void Proc_7(One_Fifty IntParI1, One_Fifty IntParI2, One_Fifty *IntParOut);
void Proc_8(struct DS_DATA *, Arr_1_Dim Array1Par, Arr_2_Dim Array2Par, One_Fifty IntParI1, One_Fifty IntParI2);
Enumeration  Func_1(struct DS_DATA *, Capital_Letter , Capital_Letter );
bool      Func_2(struct DS_DATA *, Str_30 , Str_30 );
bool Func_3(Enumeration EnumParIn);
void * malloc(unsigned long size);
void free(void * ptr);
int strcmp(const char * s1, const char * s2);

int dhrystone(
   long long * Vax_Mips, long long * int_loops, long long * int_time, long long min_cpu_time
){
        One_Fifty       Int_1_Loc;
  REG   One_Fifty       Int_2_Loc;
        One_Fifty       Int_3_Loc;
  REG   char            Ch_Index;
        Enumeration     Enum_Loc;
        Str_30          Str_1_Loc;
        Str_30          Str_2_Loc;

    unsigned long         Loops;
    struct DS_DATA dd;

    long long                  startclock, endclock;
    long long                  benchtime;
    long long Dhrystones_Per_Second;

    register unsigned long  Run_Index;


  dd._Next_Ptr_Glob = (Rec_Pointer) malloc (sizeof (Rec_Type));
  dd._Ptr_Glob = (Rec_Pointer) malloc (sizeof (Rec_Type));

  dd._Ptr_Glob->Ptr_Comp                    = dd._Next_Ptr_Glob;
  dd._Ptr_Glob->Discr                       = Ident_1;
  dd._Ptr_Glob->variant.var_1.Enum_Comp     = Ident_3;
  dd._Ptr_Glob->variant.var_1.Int_Comp      = 40;
  strcpy (dd._Ptr_Glob->variant.var_1.Str_Comp,
          "DHRYSTONE PROGRAM, SOME STRING");
  strcpy (Str_1_Loc, "DHRYSTONE PROGRAM, 1'ST STRING");

  dd._Arr_2_Glob [8][7] = 10;

    Loops = 10;       // determines runtime
        // This must be small enough that, on the slowest CPU,
        // one loop completes within 10 seconds.
    int bigloops = 0;

    //do
    //{
        for (Run_Index = 0; Run_Index < Loops; ++Run_Index)
        {
            Proc_5(&dd);
            Proc_4(&dd);
            Int_1_Loc = 2;
            Int_2_Loc = 3;
            __writeString("a loop\n");
            strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 2'ND STRING");
            Enum_Loc = Ident_2;
            dd._Bool_Glob = ! Func_2 (&dd, Str_1_Loc, Str_2_Loc);
            while (Int_1_Loc < Int_2_Loc)  /* loop body executed once */
            {
              Int_3_Loc = 5 * Int_1_Loc - Int_2_Loc;
              Proc_7 (Int_1_Loc, Int_2_Loc, &Int_3_Loc);
              Int_1_Loc += 1;
            } /* while */
            Proc_8 (&dd, dd._Arr_1_Glob, dd._Arr_2_Glob, Int_1_Loc, Int_3_Loc);
            Proc_1 (&dd, dd._Ptr_Glob);
            for (Ch_Index = 'A'; Ch_Index <= dd._Ch_2_Glob; ++Ch_Index)
            {
              if (Enum_Loc == Func_1 (&dd, Ch_Index, 'C'))
                {
                Proc_6 (&dd, Ident_1, &Enum_Loc);
                strcpy (Str_2_Loc, "DHRYSTONE PROGRAM, 3'RD STRING");
                Int_2_Loc = Run_Index;
                dd._Int_Glob = Run_Index;
                }
            }
            Int_2_Loc = Int_2_Loc * Int_1_Loc;
            Int_1_Loc = Int_2_Loc / Int_3_Loc;
            Int_2_Loc = 7 * (Int_2_Loc - Int_3_Loc) - Int_1_Loc;
            Proc_2 (&dd, &Int_1_Loc);
        }
    //}
    //while (!benchmark_time_to_stop(BM_TYPE_INT));

    Loops *= bigloops;

    //boinc_calling_thread_cpu_time(endclock);
    benchtime = endclock - startclock;
    *int_time = benchtime;
    if (benchtime < min_cpu_time) return -1;

    //printf ("%12.0f runs %6.2f seconds \n",(long long) Loops, benchtime);

    Dhrystones_Per_Second = (long long) Loops / benchtime;
    *Vax_Mips = Dhrystones_Per_Second / 1757.0;
    *int_loops = Loops;
#if 0
    printf ("Dhrystones per Second:                      ");
    printf ("%10.0lf \n", Dhrystones_Per_Second);
    printf ("VAX  MIPS rating =                          ");
    printf ("%12.2lf \n",Vax_Mips);
#endif
    free(dd._Next_Ptr_Glob);
    free(dd._Ptr_Glob);
    return 0;
}

void Proc_1(struct DS_DATA * dd, REG Rec_Pointer Ptr_Val_Par)
{
  __writeHex(Ptr_Val_Par);
  REG Rec_Pointer Next_Record = Ptr_Val_Par->Ptr_Comp;
  __writeHex(Ptr_Val_Par->Ptr_Comp);
                                        /* == Ptr_Glob_Next */
  /* Local variable, initialized with Ptr_Val_Par->Ptr_Comp,    */
  /* corresponds to "rename" in Ada, "with" in Pascal           */

  //structassign (*(Ptr_Val_Par->Ptr_Comp), *Ptr_Glob);
  *(Ptr_Val_Par->Ptr_Comp) = *Ptr_Glob;
  __writeHex(Ptr_Val_Par);
  Ptr_Val_Par->variant.var_1.Int_Comp = 5;
  Next_Record->variant.var_1.Int_Comp
        = Ptr_Val_Par->variant.var_1.Int_Comp;
  Next_Record->Ptr_Comp = Ptr_Val_Par->Ptr_Comp;
  Proc_3 (dd, &Next_Record->Ptr_Comp);
    /* Ptr_Val_Par->Ptr_Comp->Ptr_Comp
                        == Ptr_Glob->Ptr_Comp */
  if (Next_Record->Discr == Ident_1)
    /* then, executed */
  {
    Next_Record->variant.var_1.Int_Comp = 6;
    Proc_6 (dd, Ptr_Val_Par->variant.var_1.Enum_Comp,
           &Next_Record->variant.var_1.Enum_Comp);
    Next_Record->Ptr_Comp = Ptr_Glob->Ptr_Comp;
    Proc_7 (Next_Record->variant.var_1.Int_Comp, 10,
           &Next_Record->variant.var_1.Int_Comp);
  }
  else /* not executed */
    structassign (*Ptr_Val_Par, *Ptr_Val_Par->Ptr_Comp);
}

void Proc_2(struct DS_DATA * dd, One_Fifty *Int_Par_Ref)
{
  One_Fifty  Int_Loc;
  Enumeration   Enum_Loc=Ident_1;

  Int_Loc = *Int_Par_Ref + 10;
  do /* executed once */
    if (Ch_1_Glob == 'A')
      /* then, executed */
    {
      Int_Loc -= 1;
      *Int_Par_Ref = Int_Loc - Int_Glob;
      Enum_Loc = Ident_1;
    } /* if */
  while (Enum_Loc != Ident_1); /* TRUE */
}

void Proc_3(struct DS_DATA * dd, Rec_Pointer *Ptr_Ref_Par)
{
  if (Ptr_Glob != 0)
    /* then, executed */
    *Ptr_Ref_Par = Ptr_Glob->Ptr_Comp;
  Proc_7 (10, Int_Glob, &Ptr_Glob->variant.var_1.Int_Comp);
}

void Proc_4(struct DS_DATA * dd)
{
  bool Bool_Loc;

  Bool_Loc = Ch_1_Glob == 'A';
  Bool_Glob = Bool_Loc | Bool_Glob;
  Ch_2_Glob = 'B';
}

void Proc_5(struct DS_DATA * dd)
{
        Ch_1_Glob = 'A';
        Bool_Glob = FALSE;
}

extern bool Func_3(Enumeration EnumParIn);

void Proc_6(struct DS_DATA * dd, Enumeration Enum_Val_Par, Enumeration *Enum_Ref_Par)
{
  *Enum_Ref_Par = Enum_Val_Par;
  if (! Func_3 (Enum_Val_Par))
    /* then, not executed */
    *Enum_Ref_Par = Ident_4;
  switch (Enum_Val_Par)
  {
    case Ident_1:
      *Enum_Ref_Par = Ident_1;
      break;
    case Ident_2:
      if (Int_Glob > 100)
        /* then */
      *Enum_Ref_Par = Ident_1;
      else *Enum_Ref_Par = Ident_4;
      break;
    case Ident_3: /* executed */
      *Enum_Ref_Par = Ident_2;
      break;
    case Ident_4: break;
    case Ident_5:
      *Enum_Ref_Par = Ident_3;
      break;
  } /* switch */
}

void Proc_7(One_Fifty Int_1_Par_Val, One_Fifty Int_2_Par_Val, One_Fifty *Int_Par_Ref)
{
  One_Fifty Int_Loc;

  Int_Loc = Int_1_Par_Val + 2;
  *Int_Par_Ref = Int_2_Par_Val + Int_Loc;
}

void Proc_8(struct DS_DATA * dd,
        Arr_1_Dim       Arr_1_Par_Ref,
        Arr_2_Dim       Arr_2_Par_Ref,
        int             Int_1_Par_Val,
        int             Int_2_Par_Val
) {
  REG One_Fifty Int_Index;
  REG One_Fifty Int_Loc;

  Int_Loc = Int_1_Par_Val + 5;
  Arr_1_Par_Ref [Int_Loc] = Int_2_Par_Val;
  Arr_1_Par_Ref [Int_Loc+1] = Arr_1_Par_Ref [Int_Loc];
  Arr_1_Par_Ref [Int_Loc+30] = Int_Loc;
  for (Int_Index = Int_Loc; Int_Index <= Int_Loc+1; ++Int_Index)
    Arr_2_Par_Ref [Int_Loc] [Int_Index] = Int_Loc;
  Arr_2_Par_Ref [Int_Loc] [Int_Loc-1] += 1;
  Arr_2_Par_Ref [Int_Loc+20] [Int_Loc] = Arr_1_Par_Ref [Int_Loc];
  Int_Glob = 5;
}

Enumeration Func_1(
        struct DS_DATA * dd,
        Capital_Letter   Ch_1_Par_Val,
        Capital_Letter   Ch_2_Par_Val
) {
  Capital_Letter        Ch_1_Loc;
  Capital_Letter        Ch_2_Loc;

  Ch_1_Loc = Ch_1_Par_Val;
  Ch_2_Loc = Ch_1_Loc;
  if (Ch_2_Loc != Ch_2_Par_Val)
    /* then, executed */
    return (Ident_1);
  else  /* not executed */
  {
    Ch_1_Glob = Ch_1_Loc;
    return (Ident_2);
   }
}

bool Func_2(struct DS_DATA * dd, Str_30  Str_1_Par_Ref, Str_30  Str_2_Par_Ref) {
  REG One_Thirty        Int_Loc;
      Capital_Letter    Ch_Loc=0;

  Int_Loc = 2;
  while (Int_Loc <= 2) /* loop body executed once */
    if (Func_1 (dd, Str_1_Par_Ref[Int_Loc],
                Str_2_Par_Ref[Int_Loc+1]) == Ident_1)
      /* then, executed */
    {
      Ch_Loc = 'A';
      Int_Loc += 1;
    } /* if, while */
  if (Ch_Loc >= 'W' && Ch_Loc < 'Z')
    /* then, not executed */
    Int_Loc = 7;
  if (Ch_Loc == 'R')
    /* then, not executed */
    return (TRUE);
  else /* executed */
  {
    if (strcmp (Str_1_Par_Ref, Str_2_Par_Ref) > 0)
      /* then, not executed */
    {
      Int_Loc += 7;
      Int_Glob = Int_Loc;
      return (TRUE);
    }
    else /* executed */
      return (FALSE);
  } /* if Ch_Loc */
}

bool Func_3(Enumeration Enum_Par_Val)
{
  Enumeration Enum_Loc;

  Enum_Loc = Enum_Par_Val;
  if (Enum_Loc == Ident_3)
    /* then, executed */
    return (TRUE);
  else /* not executed */
    return (FALSE);
}

void * malloc(unsigned long size) {
  void * rtnPtr = heap;
  if (heap < (char *)0x9800000010000000) heap += size;
  else heap = (char *)DRAM_BASE;
  rtnPtr = (char *) ((long long)rtnPtr & 0xFFFFFFFFFFFFFFF0);
  return rtnPtr;  
}

void free(void * ptr) {
  
}

int strcmp(const char* s1, const char* s2)
{
    while(*s1 && (*s1==*s2))
        s1++,s2++;
    return *(const unsigned char*)s1-*(const unsigned char*)s2;
}

