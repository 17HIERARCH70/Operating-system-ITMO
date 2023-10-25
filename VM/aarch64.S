.section .data
vm:      .asciz  "virtual machine\n" 
rm:      .asciz  "real machine\n" 

.section .text
.global _start

_start:
    mov x0, 1
    ldr x8, =0xC0000082 // Загрузка системного регистра ID_AA64ISAR1_EL1
    svc 0 // Выполнение инструкции CPUID
    tbz x0, 31, .rm // Проверка наличия гипервизора

.vm:
    mov x0, 1
    ldr x1, =vm
    mov x2, 16
    mov x8, 64 // Системный вызов write
    svc 0 // Вывод строки vm
    b .exit

.rm:
    mov x0, 1
    ldr x1, =rm
    mov x2, 13
    mov x8, 64 // Системный вызов write
    svc 0 // Вывод строки rm

.exit:
    mov x8, 93 // Системный вызов exit
    mov x0, 0 // Код выхода 0
    svc 0 // Завершение программы


