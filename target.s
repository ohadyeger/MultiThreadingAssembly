section	.rodata			; we define (global) read-only variables in .rodata section
    FMT2: db "target, co %lx, called by %lx, pass %ld", 10, 0 

section .bss			; we define (global) uninitialized variables in .bss section
section	.data			; we define (global) read-only variables in .rodata section

    reg0:          dd 0
    reg1:          dd 0
    d_reg0:        dq 0
    d_reg1:        dq 0

section .text

    global Func_target

    extern game_target
    global target_run
    extern target_run2
    extern random_gen
    extern CORS
    extern resume
    extern printf
    extern CURR
    extern malloc
    extern board_size
    extern printGameTarget
    extern exit
   
Func_target:
    call target_run
    mov ebx, [CORS+4*2] ; resume a drone
    call resume
    jmp Func_target

target_run:
        push    ebp
        mov     ebp, esp

        fld     tword [board_size]
        fstp    QWORD [d_reg0]
        fldz
        fstp    QWORD [d_reg1]

        push    dword [d_reg0+4]
        push    dword [d_reg0]
        push    dword [d_reg1+4]
        push    dword [d_reg1]
    

        call    random_gen
        add     esp, 16

        mov     eax, DWORD [game_target]
        mov     esi, DWORD [eax]

        fstp    QWORD [esi]
;;;;    get second number
        fld     tword [board_size]
        fstp    QWORD [d_reg0]
        fldz
        fstp    QWORD [d_reg1]

        push    dword [d_reg0+4]
        push    dword [d_reg0]
        push    dword [d_reg1+4]
        push    dword [d_reg1]
        

        call    random_gen
        add     esp, 16

        mov     eax, DWORD [game_target]
        mov     esi, DWORD [eax]

        fstp    QWORD [esi+8]

        ;call printGameTarget
        ; push 0
        ; call exit

        leave
        ret
