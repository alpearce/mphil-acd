#include <stdio.h>
#include <stdint.h>

extern void *__heap, *__heap_top__;

void main(void)
{
  char *str="foo57";
  uint64_t l64=0xFEDCBA9876543210LL;
  char *p, *q;
  
  printf("Hello world!\n");
  printf("Example string=%s\n",str);
  printf("zero pointer=%s\n",0);
  printf("two=%d, sizeof(void *)=%d\n",2,sizeof(void *));
  printf("char *=%p\n",str);
  printf("Printing 0xFEDCBA9876543210LL:\n");
  printf("32bit hex=%x\n",l64);
  printf("32bit dec=%d\n",l64);
  printf("64bit hex=%llx\n",l64);
  printf("64bit dec=%lld\n\n",l64);
  printf("seventy three padded=%08d\n",73);
  printf("__heap=%p\n",&__heap);
  printf("__heap_top=%p\n",&__heap_top__);
  p=malloc(35);
  printf("malloc(35)=%p\n",p);
  strcpy(p,"Malloc 1 string\n");
  q=malloc(35);
  printf("malloc(35)=%p\n",q);
  strcpy(q,"Malloc 2 string\n");
  printf("%s%s",p,q);
  fprintf(stdout,"You weren't expecting free() were you?\n");
  printf("Done.\n");
}
