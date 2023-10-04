#define _GNU_SOURCE

#include <stdio.h>
#include <signal.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdlib.h>
#include <pthread.h>

#define LOG_FILE "log.txt"

void *logMemoryUsage(void *unused) {
    (void) unused;

    FILE *logFile;
    struct rusage r_usage;

    while (1) {
        sleep(0.1);  // Логируем каждые 5 секунд
        getrusage(RUSAGE_SELF, &r_usage);
        logFile = fopen(LOG_FILE, "a+");
        if (logFile) {
            fprintf(logFile, "Memory usage: %ld KB\n", r_usage.ru_maxrss);
            fclose(logFile);
        }
    }

    return NULL;
}

int main(int argc, char* argv[]) {
    if (setresuid(0, 0, 0) == -1) {
        printf("Root?!\n");
        return 1;
    }

    sigset_t mask;
    sigfillset(&mask);
    sigprocmask(SIG_SETMASK, &mask, NULL);

    struct rlimit memory = { RLIM_INFINITY, RLIM_INFINITY },
                  signal = { RLIM_INFINITY, RLIM_INFINITY};
    setrlimit(RLIMIT_AS, &memory);
    setrlimit(RLIMIT_SIGPENDING, &signal);

    char file_name[20];
    sprintf(file_name, "/proc/%u/oom_adj", getpid());

    FILE* oom_killer_file = fopen(file_name, "w");
    if (oom_killer_file) {
        fprintf(oom_killer_file, "-17\n");
        fclose(oom_killer_file);
    }

    long page_size = sysconf(_SC_PAGESIZE);

    pthread_t logThread;
    pthread_create(&logThread, NULL, logMemoryUsage, NULL);

    while(1) {
        char* tmp = (char*) malloc(page_size);
        if (tmp)
            tmp[0] = 0;
    }

    return 0;
}
