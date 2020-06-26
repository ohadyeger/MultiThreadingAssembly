section	.rodata			; we define (global) read-only variables in .rodata section
    global Func_scheduler
    global curr_drone
    global scheduler_run

    FMT1: db "scheduler, co %lx, called by %lx, pass %ld", 10, 0 

section .bss			; we define (global) uninitialized variables in .bss section
    
section	.data
    curr_drone:    dd 0
    reg:           dd 0
section .text

    extern end_co
    extern CORS
    extern resume
    extern printf
    extern CURR
    extern drones
    extern N
    extern reset_iteration
    extern drone_cos
    extern iteration
    extern K
    

Func_scheduler:
    call scheduler_run
    cmp eax, 1
    je .resume_printer

.run_drone:
    mov esi, dword [curr_drone];get ID

    dec esi
    shl esi, 2
    add esi, [drone_cos]
    mov ebx, [esi] ; resume a drone
    call resume
    jmp Func_scheduler

.resume_printer:
    mov ebx, [CORS+4*3] ; resume a printer
    call resume
    jmp .run_drone ; loop

scheduler_run:
        push    ebp
        mov     ebp, esp

        mov     eax, DWORD [curr_drone]
        mov     edx, eax
        mov     eax, DWORD [N]
        cmp     edx, eax
        jb      .choose_new_drone
        mov     DWORD [curr_drone], 1
        jmp     .check_if_print_time

.choose_new_drone:
        mov     eax, DWORD [curr_drone]
        add     eax, 1
        mov     DWORD [curr_drone], eax

.check_if_print_time:
        call    is_K
        mov     DWORD [reg], eax
        cmp     DWORD [reg], 0
        je      .ret
        mov     DWORD [iteration], 0
.ret:
        mov     eax, DWORD [reg]

        leave
        ret

is_K:
        push    ebp
        mov     ebp, esp

        mov     eax, DWORD [iteration]
        mov     edx, eax
        mov     eax, DWORD [K]
        cmp     edx, eax
        setnb   al
        movzx   eax, al

        leave
        ret