section .data
vm db 'virtual machine', 10 // Строка для вывода в случае виртуальной машины
vmLen equ $-vm // Длина строки vm
rm db 'real machine', 10 // Строка для вывода в случае реальной машины
rmLen equ $-rm // Длина строки rm

section .text
global _start

_start:
    mov eax, 1
    cpuid // Выполнение инструкции CPUID
    test ecx, 800000h // Проверка наличия гипервизора
    jz .rm // Если гипервизор отсутствует, переход к метке .rm

.vm:
    mov eax, 4 // Номер системного вызова write
    mov ebx, 1 // Дескриптор файла stdout
    mov ecx, vm // Указатель на строку vm
    mov edx, vmLen // Длина строки vm
    int 0x80 // Вызов системного вызова write для вывода строки vm
    jmp .exit // Переход к метке .exit

.rm:
    mov eax, 4 // Номер системного вызова write
    mov ebx, 1 // Дескриптор файла stdout
    mov ecx, rm // Указатель на строку rm
    mov edx, rmLen // Длина строки rm
    int 0x80 // Вызов системного вызова write для вывода строки rm

.exit:
    mov eax, 1 // Номер системного вызова exit
    xor ebx, ebx // Код выхода 0
    int 0x80 // Вызов системного вызова exit для завершения программы

