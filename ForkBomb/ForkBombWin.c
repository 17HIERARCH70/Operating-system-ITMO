#include <windows.h>
#include <psapi.h>
#include <time.h>
#include <process.h>
#include <stdio.h>

#pragma warning(disable : 4996)


double PCFreq;
__int64 CounterStart;

// Функция для инициализации счетчика производительности
void StartCounter()
{
    LARGE_INTEGER li;
    if (!QueryPerformanceFrequency(&li))
        printf("QueryPerformanceFrequency failed!\n");

    PCFreq = li.QuadPart;

    QueryPerformanceCounter(&li);
    CounterStart = li.QuadPart;
}

// Функция для получения текущего значения счетчика производительности
double GetCounter()
{
    LARGE_INTEGER li;
    QueryPerformanceCounter(&li);
    return (double)((li.QuadPart - CounterStart) / PCFreq);
}

// Функция записи информации о количестве процессов
int StartUpInfoFileWriter()
{
    FILE *f = fopen("result.txt", "a+");
    if (f == NULL)
    {
        printf("Can't open file!");
    }
    else
    {
        int Count = 0;

        DWORD aProcesses[8096], cbNeeded, cProcesses;

        if (!EnumProcesses(aProcesses, sizeof(aProcesses), &cbNeeded))
        {
            printf("EnumProcesses() Error \t%d", GetLastError());
        }
        else
        {
            printf("EnumProcesses() is OK!\n");
        }

        cProcesses = cbNeeded / sizeof(DWORD);

        fprintf(f, "Process;Time\n");
        fprintf(f, "%d;0\n", cProcesses);
        fclose(f);
    }
    return 0;
}

// Функция записи информации о процессах и времени выполнения
int FileWriter()
{
    FILE *f = fopen("result.txt", "a+");
    if (f == NULL)
    {
        printf("Can't open file!");
    }
    else
    {
        int Count = 0;
        DWORD aProcesses[8096], cbNeeded, cProcesses;

        if (!EnumProcesses(aProcesses, sizeof(aProcesses), &cbNeeded))
        {
            printf("EnumProcesses() Error \t%d", GetLastError());
        }
        else
        {
            printf("EnumProcesses() is OK!\n");
        }

        cProcesses = cbNeeded / sizeof(DWORD);

        fprintf(f, "%d;%f\n", cProcesses, GetCounter());
        fclose(f);
    }
    return 0;
}

void OpenProcessFunc()
{
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    // Эта функция будет создавать процессы в бесконечном цикле
    while (1)
    {
        CreateProcess(NULL, NULL, NULL, NULL, FALSE, 0, NULL, NULL, &si, &pi);
    }
}

int main()
{
    StartCounter();
    StartUpInfoFileWriter();

    // Создание нового потока для выполнения функции OpenProcessFunc
    _beginthread((void(*)(void*))OpenProcessFunc, 0, NULL);

    while (1)
    {
        Sleep(3);
        FileWriter();
    }
}
