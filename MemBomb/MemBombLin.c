#define _GNU_SOURCE

#include <stdio.h>
#include <signal.h>
#include <sys/resource.h>
#include <unistd.h>
#include <stdlib.h>


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

    while(1) {
        char* tmp = (char*) malloc(page_size);
        if (tmp)
            tmp[0] = 0;
    }

    return 0;
}