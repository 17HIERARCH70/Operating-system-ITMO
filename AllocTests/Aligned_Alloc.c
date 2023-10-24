#include <time.h>
#include <stdio.h>
#include <stdlib.h>

#define PAGESIZE 4096
#define SIZE (1024 * 1024)  // (GB)
#define OPERATION_COUNT 10

int main(int argc, char *argv[])
{
    FILE *file = fopen("AlignedAllocFree.txt", "w");
    if (file == NULL)
    {
        printf("Error opening file!\n");
        return 1;
    }

    char *memory;
    double t_aligned_alloc, t_free, total_aligned_alloc = 0, total_free = 0;
    int i, j, k;

    for (i = PAGESIZE; i <= SIZE; i *= 2)
    {
        long count = SIZE / i;

        for (j = 0; j < OPERATION_COUNT; ++j)
        {
            clock_t start_aligned_alloc = clock();
            size_t size = ((count * sizeof(char) + i - 1) / i) * i;
            memory = (char *)aligned_alloc(i, size);

            if (memory == NULL)
            {
                perror("Error allocating memory");
                return 1;
            }
            for (k = 0; k < count; k += PAGESIZE)
                memory[k] = k;

            t_aligned_alloc = (double)(clock() - start_aligned_alloc) / CLOCKS_PER_SEC;
            total_aligned_alloc += t_aligned_alloc;

            clock_t start_free = clock();
            free(memory);
            t_free = (double)(clock() - start_free) / CLOCKS_PER_SEC;
            total_free += t_free;

            fprintf(file, "AlignedAlloc:%d/%d/%f Free:%d/%d/%f\n", OPERATION_COUNT, i, t_aligned_alloc, OPERATION_COUNT, i, t_free);
        }
    }

    fprintf(file, "total aligned_alloc time = %f\n", total_aligned_alloc);
    fprintf(file, "total free time = %f\n", total_free);

    fclose(file);

    return 0;
}
