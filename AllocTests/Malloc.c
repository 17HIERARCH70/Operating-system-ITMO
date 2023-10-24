#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#define  PAGESIZE 4096
#define SIZE 1024*1024 //(MB)
#define OPERATION_COUNT 10

int main (int argc, char *argv[])
{
  FILE *file = fopen("MallocFree.txt", "w");
  if (file == NULL)
  {
    printf("Error opening file!\n");
    return 1;
  }

  char *memory;
  double t_malloc, t_free, total_malloc = 0, total_free = 0;
  int i, j, k;

  for (i = 0; i < 2048; i += 64)
  {
    long count = SIZE * i;

    for (j = 0; j < OPERATION_COUNT; ++j)
    {
      clock_t start_malloc = clock();
      memory = (char*)malloc(count);

      for (k = 0; k < count; k += PAGESIZE )
        memory[k] = k;

      t_malloc = (double)(clock() - start_malloc) / CLOCKS_PER_SEC;
      total_malloc += t_malloc;

      clock_t start_free = clock();
      free(memory);
      t_free = (double)(clock() - start_free) / CLOCKS_PER_SEC;
      total_free += t_free;

      fprintf(file, "Malloc:%d/%d/%f Free:%d/%d/%f\n", OPERATION_COUNT, i, t_malloc, OPERATION_COUNT, i, t_free);
    }
  }

  fprintf (file, "total malloc time = %f\n", total_malloc);
  fprintf (file, "total free time = %f\n", total_free);
  fclose(file);

  return 0;
}