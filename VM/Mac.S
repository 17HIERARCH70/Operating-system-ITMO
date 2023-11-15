.data
vm:      .asciz  "virtual machine\n" 
rm:      .asciz  "real machine\n" 

.global _start
.section __TEXT,__text

_start:
    // Сначала проверяем, поддерживается ли инструкция MIDR_EL1
    mrs x0, id_aa64pfr0_el1
    ubfx x0, x0, #20, #4
    cbz x0, not_supported

    // Если поддерживается, считываем значение MIDR_EL1
    mrs x0, midr_el1

    // Проверяем, является ли процессор ARM
    ubfx x0, x0, #24, #8
    cmp x0, #0x41
    bne not_arm

    // Проверяем, является ли процессор Cortex-A72
    mov x1, #0xd08
    cmp x0, x1
    beq is_virtual_machine

not_arm:
    b .exit
not_supported:
    b .exit
is_virtual_machine:
    mov x0, 1
    ldr x1, =vm
    mov x2, 16
    mov x8, 4 // Системный вызов write
    svc 0 // Вывод строки vm
    b .exit

not_virtual_machine:
    mov x0, 1
    ldr x1, =rm
    mov x2, 13
    mov x8, 4 // Системный вызов write
    svc 0 // Вывод строки rm

.exit:
    mov x8, 1 // Системный вызов exit
    mov x0, 0 // Код выхода 0
    svc 0 // Завершение программы
