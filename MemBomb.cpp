#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#ifdef _WIN64
#include <windows.h>
#endif

#define DEBUG 1
#define LOG_FILE "log.txt"
#define PAGE_SIZE 4096
#define MAX_MEMORY 256 * 1024 * 1024
#define START_DIR "/proc"

#ifdef _WIN64
LARGE_INTEGER frequency;
LARGE_INTEGER startCounter;
FILE* logFile;
#endif

#ifdef _WIN64
int isLinux = 0;
#endif

// Function to start a performance counter
#ifdef _WIN64
void StartCounter() {
    QueryPerformanceFrequency(&frequency);
    QueryPerformanceCounter(&startCounter);
}
#endif

// Function to get the elapsed time from the performance counter
#ifdef _WIN64
double GetCounter() {
    LARGE_INTEGER endCounter;
    QueryPerformanceCounter(&endCounter);
    return (double)(endCounter.QuadPart - startCounter.QuadPart) / frequency.QuadPart;
}
#endif

#ifdef _WIN64
// Function to initialize the log file
int InitializeLogFile() {
    logFile = fopen(LOG_FILE, "a+");
    if (logFile == NULL) {
        printf("Can't open log file!");
        return 1;
    }
    fprintf(logFile, "Time;UsedMemory\n");
    fclose(logFile);
    return 0;
}
#endif

#ifdef _WIN64
// Function to write memory usage and time to the log file on Windows
int WriteLogFile(int availableMemory) {
    logFile = fopen(LOG_FILE, "a+");
    if (logFile == NULL) {
        printf("Can't open log file!");
    } else {
        fprintf(logFile, "%d;%f\n", availableMemory, GetCounter());
        fclose(logFile);
    }
    return 0;
}
#endif

#ifdef _WIN64
int main(int argc, char* argv[]) {
    StartCounter();
    InitializeLogFile();
    unsigned int size = MAX_MEMORY;
    int total = 0;
    while (1) {
        char* VA = (char*)VirtualAlloc(0, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE);

        if (VA == 0) {
            if (size > 16) {
                size = size / 2;
            } else {
                size = MAX_MEMORY;
            }
        } else {
            total += size / 1024 / 1024;
            WriteLogFile(total);
            for (int i = 0; i < size; i += PAGE_SIZE) {
                memset(VA, '$', sizeof(char));
            }
        }
    }
    return 0;
}
#endif
