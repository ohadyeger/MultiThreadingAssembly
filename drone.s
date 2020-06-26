section	.rodata			; we define (global) read-only variables in .rodata section
    global Func_drone
    global drone_ptr
    global load_to_array
    global create_drone
    global generate_pos
    global drone_run
    
    FMT1: db "drone, co %lx, called by %lx, pass %ld", 10, 0 
    winner_fmt: db "Drone id %d: I am a winner", 10, 0
    destroyed_fmt: db "destroyed by %d", 10, 0
    test_fmt: db "testing %lf", 10, 0

    d_sixty:        dq 60.0
    d_neg_sixty:    dq -60.0
    d_fifty:        dq 50.0
    d_three_sixty:  dq 360.0
    d_ninety:       dq 90.0
    d_hundred:      dq 100.0
    d_zero:         dq 0.0

section .bss			; we define (global) uninitialized variables in .bss section
    drone_ptr:      resb 1

section	.data			; we define (global) read-only variables in .rodata section

    reg0:          dd 0.0
    reg1:          dd 0.0
    d_reg0:        dq 0.0
    d_reg1:        dq 0.0
    d_reg2:        dq 0.0
    d_reg3:        dq 0.0
    d_reg4:        dq 0.0
    d_reg5:        dq 0.0
    d_reg6:        dq 0.0
    d_reg_Test:    dq 0.0
    
section .text

    extern CORS
    extern printGameTarget
    extern resume
    extern printf
    extern CURR
    extern drone_run2
    extern drones
    extern drone_array
    extern board_size
    extern degrees
    extern malloc
    extern random_gen
    extern free_position
    global play_drone
    extern my_sin
    extern my_cos
    extern my_abs
    extern iteration
    extern game_target
    extern mayDestroy
    extern T
    extern exit
    extern printBoard

%macro print_test 0
        fst qword [d_reg_Test]
        push dword [d_reg_Test+4]
        push dword [d_reg_Test]
        push test_fmt
        call printf
        add esp, 12
%endmacro

Func_drone:
    pop esi
    push esi
    mov dword[drone_ptr], esi
    call drone_run

    mov ebx, [CORS+4*eax] ; resume a scheduler
    call resume
    jmp Func_drone

load_to_array:
        push    ebp
        mov     ebp, esp
        sub     esp, 16
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax]
        sub     eax, 1
        mov     DWORD [ebp-4], eax
        mov     eax, DWORD [drone_array]
        mov     edx, DWORD [ebp-4]
        sal     edx, 2
        add     edx, eax
        mov     eax, DWORD [drone_ptr]
        mov     DWORD [edx], eax
        leave
        ret

create_drone:
        push    ebp
        mov     ebp, esp

        sub     esp, 40
        sub     esp, 12
        push    12
        call    malloc
        add     esp, 16
        mov     DWORD [d_reg6], eax
        sub     esp, 12
        push    24
        call    malloc
        add     esp, 16
        mov     edx, eax
        mov     eax, DWORD [d_reg6]
        mov     DWORD [eax+4], edx

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

        fstp    QWORD [d_reg2]

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

        fstp    QWORD [d_reg3]

        fld     tword [degrees]
        fstp    QWORD [d_reg0]
        fldz
        fstp    QWORD [d_reg1]

        push    dword [d_reg0+4]
        push    dword [d_reg0]
        push    dword [d_reg1+4]
        push    dword [d_reg1]    

        call    random_gen
        add     esp, 16

        fstp    QWORD [ebp-40]
        mov     eax, DWORD [d_reg6]
        mov     eax, DWORD [eax+4]
        fld     QWORD [d_reg2]
        fstp    QWORD [eax]
        mov     eax, DWORD [d_reg6]
        mov     eax, DWORD [eax+4]
        fld     QWORD [d_reg3]
        fstp    QWORD [eax+8]
        mov     eax, DWORD [d_reg6]
        mov     eax, DWORD [eax+4]
        fld     QWORD [ebp-40]
        fstp    QWORD [eax+16]
        mov     eax, DWORD [d_reg6]
        mov     edx, DWORD [ebp+8]
        mov     DWORD [eax], edx
        mov     eax, DWORD [d_reg6]
        mov     DWORD [eax+8], 0
        mov     eax, DWORD [d_reg6]

        leave
        ret


play_drone:
        push    ebp
        mov     ebp, esp
        sub     esp, 8
        mov     edx, DWORD [game_target]
        mov     eax, DWORD [drone_ptr]
        sub     esp, 8
        push    edx
        push    eax
        call    mayDestroy
        add     esp, 16
        test    eax, eax
        je      .run_scheduler
        ;call    printGameTarget
        mov     eax, DWORD [drone_ptr]
        mov     edx, DWORD [eax+8]
        add     edx, 1
        mov     DWORD [eax+8], edx
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+8]
        mov     edx, eax
        mov     eax, DWORD [T]
        cmp     edx, eax
        jb      .destroyed
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax]
        sub     esp, 8
        push    eax
        push    winner_fmt
        call    printf
        add     esp, 16
        mov     eax, 0
        jmp     .return
.destroyed:
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax]
        sub     esp, 8
        push    eax
        push    destroyed_fmt
        ;call    printf
        add     esp, 16
        mov     eax, 1
        jmp     .return
.run_scheduler:
        mov     eax, 2
.return:
        leave
        ret

drone_run:
        push    ebp
        mov     ebp, esp
        call    gen
        ; push 0
        ; call exit
        mov     eax, DWORD [iteration]
        add     eax, 1
        mov     DWORD [iteration], eax
        call    play_drone
        leave
        ret

gen:
        push    ebp
        mov     ebp, esp

        push     dWORD [d_sixty+4]
        push     dWORD [d_sixty]
        push     dWORD [d_neg_sixty+4]
        push     dWORD [d_neg_sixty]
        call    random_gen

        ;print_test

        fstp    QWORD [d_reg0]; reg0<-rand(-60,60)

        push     dWORD [d_fifty+4]
        push     dWORD [d_fifty]
        push     dWORD [d_zero+4]
        push     dWORD [d_zero]
        call    random_gen
        ;print_test
        fstp    QWORD [d_reg1] ; reg1<-rand(0,50)

        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+16];load drone_ptr->pos->alpha
        fld     QWORD [d_reg0]; load delta_alpha
        
        faddp   
        ;print_test
        fstp    QWORD [d_reg3];reg3<-drone_ptr->pos->alpha + delta_alpha

        fld     QWORD [d_three_sixty]
        fld     QWORD [d_reg3]
        fucomip 
        fstp    
        jb      .fix_alpha    ;if reg3 < 360 cont.
        fld     QWORD [d_reg3]
        fld     QWORD [d_three_sixty]
        fsubp   
        ;print_test
        fstp    QWORD [d_reg3]; reg3 <- reg3 - 360
        jmp     .cont1
.fix_alpha:
        fld     QWORD [d_reg3]
        fldz
        fucomip 

        fstp    
        jbe     .cont1 ;if reg3 > 0 cont.
        fld     QWORD [d_reg3]
        fld     QWORD [d_three_sixty]
        faddp   
        ;print_test
        fstp    QWORD [d_reg3]; reg3 <- reg3 + 360
.cont1:
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax]; load position x
        fstp    QWORD [d_reg5];reg5 <-drone->pos->x
        sub     esp, 8
        push    DWORD [d_reg3+4]
        push    DWORD [d_reg3]
        call    my_cos
        add     esp, 16
        fmul    QWORD [d_reg1]
        fadd    QWORD [d_reg5]
        fstp    QWORD [d_reg2];reg2 <- new_x

        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+8]; load position y
        fstp    QWORD [d_reg5];reg5 <-drone->pos->y
        sub     esp, 8
        push    DWORD [d_reg3+4]
        push    DWORD [d_reg3]
        call    my_sin
        add     esp, 16
        fmul    QWORD [d_reg1]
        fadd    QWORD [d_reg5]
        fstp    QWORD [d_reg4];reg4 <- new_y

        fld     QWORD [d_hundred]
        fld     QWORD [d_reg2]
        fucomip 
        fstp    
        jbe     .cont2
        fld     QWORD [d_reg2]
        fld     QWORD [d_hundred]
        fsubp  
        fstp    QWORD [d_reg2]
        jmp     .cont3
.cont2:
        fld     QWORD [d_reg2]
        fldz
        fucomip 
        fstp    
        jbe     .cont3
        fld     QWORD [d_reg2]
        fld     QWORD [d_hundred]
        faddp   
        fstp    QWORD [d_reg2]
.cont3:
        fld     QWORD [d_hundred]
        fld     QWORD [d_reg4]
        fucomip 
        fstp    
        jbe     .cont4
        fld     QWORD [d_reg4]
        fld     QWORD [d_hundred]
        fsubp   
        fstp    QWORD [d_reg4]
        jmp     .cont5
.cont4:
        fld     QWORD [d_reg4]
        fldz
        fucomip 
        fstp   
        jbe     .cont5
        fld     QWORD [d_reg4]
        fld     QWORD [d_hundred]
        faddp   
        fstp    QWORD [d_reg4]

.cont5:
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+4]
        fld     QWORD [d_reg2]
        fstp    QWORD [eax]
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+4]
        fld     QWORD [d_reg4]
        fstp    QWORD [eax+8]
        mov     eax, DWORD [drone_ptr]
        mov     eax, DWORD [eax+4]
        fld     QWORD [d_reg3]
        fstp    QWORD [eax+16]
        
        leave
        ret

