#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#define  PAGESIZE 4096
#define SIZE 1024*1024 //(MB)
#define OPERATION_COUNT 10

int main (int argc, char *argv[])
{
  FILE *file = fopen("CallocFree.txt", "w");
  if (file == NULL)
  {
    printf("Error opening file!\n");
    return 1;
  }

  char *memory;
  double t_calloc, t_free, total_calloc = 0, total_free = 0;
  int i, j, k;

  for (i = 0; i < 2048; i += 64)
  {
    long count = SIZE * i;

    for (j = 0; j < OPERATION_COUNT; ++j)
    {
      clock_t start_calloc = clock();
      memory = (char*)calloc(count, sizeof(char));

      for (k = 0; k < count; k += PAGESIZE )
        memory[k] = k;

      t_calloc = (double)(clock() - start_calloc) / CLOCKS_PER_SEC;
      total_calloc += t_calloc;

      clock_t start_free = clock();
      free(memory);
      t_free = (double)(clock() - start_free) / CLOCKS_PER_SEC;
      total_free += t_free;

      fprintf(file, "Calloc:%d/%d/%f Free:%d/%d/%f\n", OPERATION_COUNT, i, t_calloc, OPERATION_COUNT, i, t_free);
    }
  }

  fprintf (file, "total calloc time = %f\n", total_calloc);
  fprintf (file, "total free time = %f\n", total_free);
  
  fclose(file);

  return 0;
}
