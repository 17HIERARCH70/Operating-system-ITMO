#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#define NUM_ALLOCATIONS 1000
#define MAX_MEMORY_SIZE 1000000

void log_to_file(const char* filename, double memory_size_kb, long long elapsed_time_ns) {
    FILE *file = fopen(filename, "a");
    if (file == NULL) {
        perror("Error opening log file");
        return;
    }
    fprintf(file, "%lf\t%lld\n", memory_size_kb, elapsed_time_ns);
    fclose(file);
}

void test_malloc_time() {
    struct timespec start_time, end_time;
    long long elapsed_time_ns;
    double memory_size_kb;

    printf("Memory Size (KB)\tTime (ns)\n");

    for (int i = 1; i <= NUM_ALLOCATIONS; i++) {
        memory_size_kb = i * (double)(MAX_MEMORY_SIZE) / NUM_ALLOCATIONS;

        clock_gettime(CLOCK_MONOTONIC_RAW, &start_time);
        void* memory = malloc(memory_size_kb * 1024);
        clock_gettime(CLOCK_MONOTONIC_RAW, &end_time);

        if (memory == NULL) {
            fprintf(stderr, "Memory allocation failed for size %lf KB\n", memory_size_kb);
            break;
        }

        elapsed_time_ns = (end_time.tv_sec - start_time.tv_sec) * 1000000000LL + (end_time.tv_nsec - start_time.tv_nsec);

        printf("%lf\t%lld\n", memory_size_kb, elapsed_time_ns);
        log_to_file("memory_allocation_log.txt", memory_size_kb, elapsed_time_ns);

        free(memory);
    }
}

int main() {
    FILE *log_file = fopen("memory_allocation_log.txt", "w");
    if (log_file == NULL) {
        perror("Error creating log file");
        return 1;
    }
    fprintf(log_file, "Memory Size (KB)\tTime (ns)\n");
    fclose(log_file);

    test_malloc_time();
    return 0;
}
