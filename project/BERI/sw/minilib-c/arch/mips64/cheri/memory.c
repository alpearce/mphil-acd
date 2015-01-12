#include <stdlib.h>
#include <stdint.h>

extern uint64_t __heap;
extern uint64_t __heap_top__;

#define ALIGN64(x) ((void *)((((x+7)/8)*8)))

void * __heap_pointer = 0;

void *_malloc(size_t size)
{
  uint64_t heap_pointer, heap_top;
  void *p;
  heap_top = (uint64_t) &__heap_top__;
  if (__heap_pointer == 0)
    __heap_pointer = &__heap;
    
  heap_pointer = (uint64_t) __heap_pointer;

  if ((heap_top - heap_pointer)<size)
    return (void *) 0;
    
  p = (void *) heap_pointer;
  heap_pointer += size;
  __heap_pointer = ALIGN64(heap_pointer);
  return p;
}

void _free(void *ptr)
{
  // Ha ha, fooled you
  return;
}
