    #include <unistd.h>
    #include <stdio.h>
    #include <stdlib.h>
    #include <sys/types.h>
    #include <ctype.h>
    #include <dirent.h>
    #include <sys/time.h>

    #define PROC_DIR "/proc"
    struct timeval start, end;

    // Функция проверки, является ли имя папки с процессом числом (PID)
    int is_pid_folder(const struct dirent *entry)
    {
        const char *p;
        for (p = entry->d_name; *p; p++) 
        {
            if (!isdigit(*p))
            {
                return 0;
            }
        }
        return 1;
    }

    // Функция записи информации о количестве процессов
    int StartInfoWriter()
    {
        FILE *fp;
        char fname[] = "result.txt";
        fp = fopen(fname, "a+");

        int CountOfProc = 0;
        DIR *procdir;
        struct dirent *entry;

        procdir = opendir("/proc");
        if (!procdir)
        {
            perror("opendir failed");
            return 1;
        }

        while ((entry = readdir(procdir)))
        {
            if (!is_pid_folder(entry))
            {
                continue;
            }
            CountOfProc = CountOfProc + 1;
        }

        fprintf(fp, "%d;%d.%d\n", CountOfProc, 0, 0);
        fclose(fp);
        return 0;
    }

    // Функция для вычисления времени в микросекундах
    float time_diff(struct timeval *start, struct timeval *end)
    {
        return (end->tv_sec - start->tv_sec) + 1e-6 * (end->tv_usec - start->tv_usec);
    }

    // Функция записи информации о процессах и времени выполнения
    int FileWriter()
    {
        FILE *fp;
        char fname[] = "result.txt";
        fp = fopen(fname, "a+");

        int CountOfProc = 0;
        DIR *procdir;
        struct dirent *entry;

        procdir = opendir("/proc");
        if (!procdir)
        {
            perror("opendir failed");
            return 1;
        }

        while ((entry = readdir(procdir)))
        {
            if (!is_pid_folder(entry))
            {
                continue;
            }
            CountOfProc = CountOfProc + 1;
        }

        fprintf(fp, "%d;%0.8f\n", CountOfProc, time_diff(&start, &end));
        fclose(fp);
        return 0;
    }

    int main()
    {
        StartInfoWriter();

        gettimeofday(&start, NULL);
        while (1)
        {
            fork();
            gettimeofday(&end, NULL);
            FileWriter();
        }
        return 0;
    }

