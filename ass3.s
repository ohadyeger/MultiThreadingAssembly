section	.rodata

    global game_target
    global degrees
    global drone_cos
    global drones
    global stack
    global CURR
    global CORS
    global board_size
    global d
    global seed
    global N
    global K
    global T
    global iteration
    global beta
    global drone_array

   random_gen_constant: dd 65535
   board_size:          dt 100.0
   degrees:             dt 360.0
   scan_d:  db "%d",0
   scan_lf: db "%lf",0
   scan_hu: db "%hu",0
   print_hu: db "%hu",10,0
   print_lf: db "%lf",10,0

section	.data			; we define (global) read-only variables in .rodata section

    N:              dd 0
    T:              dd 0
    K:              dd 0
    beta:           dq 0.0
    d:              dq 0.0
    seed:           dd 0
    iteration:      dd 0

    game_target:    dd 0
    drone_array:    dd 0

    end:            dd Func_end
                    dd STK0+STKSZ
    
    scheduler_co:   dd Func_scheduler ; struct of scheduler
                    dd STK1+STKSZ

    target_co:      dd Func_target ; struct of target
                    dd STK2+STKSZ
    
    printer_co:     dd Func_printer ; 
                    dd STK3+STKSZ
                    
    CORS:           
        dd end 
        dd target_co 
        dd scheduler_co
        dd printer_co

    drone_cos:      dd 0
    stack:          dd 0
    drones:         dd 0
    x0:             dt 0.0
    xz:             dt 0.0
    d_reg:          dq 0.0
    one_eighty:     dt 180.0
    degree:         dt 90.0

section .bss			; we define (global) uninitialized variables in .bss section

    STKSZ       equ 16*1024
    CODEP       equ 0 ; offset of pointer to co-routine function in co-routine struct
    SPP         equ 4 ; offset of pointer to co-routine stack in co-routine struct 

    CURR:       resd    1
    SPT:        resd    1 ; temporary stack pointer
    SPMAIN:     resd    1 ; stack pointer of main

    STK0:       resb STKSZ
    STK1:       resb STKSZ
    STK2:       resb STKSZ
    STK3:       resb STKSZ

%macro calc_1 1
    mov eax, dword [ebp+12]
    mov dword [d_reg+4], eax
    mov eax, dword [ebp+8]
    mov dword [d_reg], eax
    fld qword [d_reg]
    %1
%endmacro

%macro calc_2 1
    mov eax, dword [ebp+12]
    mov dword [d_reg+4], eax
    mov eax, dword [ebp+8]
    mov dword [d_reg], eax
    fld qword [d_reg]

    mov eax, dword [ebp+20]
    mov dword [d_reg+4], eax
    mov eax, dword [ebp+16]
    mov dword [d_reg], eax
    fld qword [d_reg]
    %1
%endmacro

section .text
	extern Func_scheduler
    extern Func_target
    extern Func_drone
    extern Func_printer
    extern create_drone
    extern load_to_array
    extern drone_ptr
    extern target_run
    extern exit
    extern malloc
    extern sscanf
    extern free
    extern printf
   

    global end_co
    global load_args
    global resume
    global initCo
    global initDrone
    global initDrones
    global startCo
    global endCo
    global do_resume
    global mayDestroy
    global degToRad
    global arctan
    global my_abs
    global pow_2
    global my_sqrt
    global my_sin
    global my_cos
    global get_new_bit
    global random_gen
    global init_board
    global init_drone_threads
    global main
    global free_position
    global free_target

main:
        lea     ecx, [esp+4]
        and     esp, -16
        push    DWORD [ecx-4]
        push    ebp
        mov     ebp, esp
        push    ecx
        sub     esp, 4
        mov     eax, ecx
        push    DWORD [eax+4]
        call    load_args
        add     esp, 4
        call    init_board
        call    init_drone_threads
        mov     eax, DWORD [N]
        push    eax
        call    initDrones
        add     esp, 4
        
        push    2
        call    startCo
        add     esp, 4
        call    free_drone_cos
        call    free_target
        call    free_drone_array
        mov     eax, 0
        mov     ecx, DWORD [ebp-4]
        leave
        lea     esp, [ecx-4]
        ret

initCo:
    push ebp
	mov ebp, esp

    mov ebx, dword [ebp+8] ; get co-routine ID number
    mov ebx, [4*ebx + CORS] ; get pointer to COi struct
    mov eax, [ebx+CODEP] ; get initial EIP value – pointer to COi function
    mov [SPT], esp ; save ESP value
    mov esp, [EBX+SPP] ; get initial ESP value – pointer to COi stack
    push eax ; push initial “return” address
    pushfd ; push flags
    pushad ; push all other registers
    mov [ebx+SPP], esp ; save new SPi value (after all the pushes)
    mov esp, [SPT] ; restore ESP value
    
    mov esp, ebp	
	pop ebp
    ret

initDrone:
    push ebp
	mov ebp, esp

    mov eax, dword  [ebp+8]    ;create drone
    inc eax
    push eax
    call create_drone
    add esp, 4
    mov dword [drone_ptr], eax
    push eax
    call load_to_array
    add esp, 4

    mov ebx, dword [ebp+8] ; get co-routine ID number
    mov esi, [drone_cos]
    mov ebx, [4*ebx + esi] ; get pointer to COi struct
    mov eax, [ebx+CODEP];  get initial EIP value – pointer to COi function
    mov [SPT], esp ; save ESP value
    mov esp, [ebx+SPP] ; get initial ESP value – pointer to COi stack

    mov esi, dword [ebp+8]

    push dword [drone_ptr]
    push eax ; push initial “return” address
    pushfd ; push flags
    pushad ; push all other registers
    
    
    ;push eax

    mov [ebx+SPP], esp ; save new SPi value (after all the pushes)
    mov esp, [SPT] ; restore ESP value
    
    mov esp, ebp	
	pop ebp
    ret

initDrones:
        push    ebp
        mov     ebp, esp
        sub     esp, 24
        mov     DWORD [ebp-12], 0
        jmp     .after
.new_drone:
        sub     esp, 12
        push    DWORD [ebp-12]
        call    initDrone
        add     esp, 16
        add     DWORD [ebp-12], 1
.after:
        mov     eax, DWORD [ebp-12]
        cmp     eax, DWORD [ebp+8]
        jl      .new_drone
        leave
        ret

startCo:
    push ebp
	mov ebp, esp
    
    pushad ; save registers of main ()
    mov [SPMAIN], esp ; save ESP of main ()

    mov ebx, [ebp+8] ; gets ID of a scheduler co-routine
    mov ebx, [ebx*4 + CORS] ; gets a pointer to a scheduler struct
    jmp do_resume ; resume a scheduler co-routine

resume: ; save state of current co-routine
    pushfd
    pushad
    mov edx, [CURR]
    mov [edx+SPP], esp ; save current ESP
    
do_resume: ; load ESP for resumed co-routine
    mov ESP, [EBX+SPP]
    mov [CURR], EBX
    popad ; restore resumed co-routine state
    popfd
    ret ; "return" to resumed co-routine  

end_co:
    mov esp, [SPMAIN] ; restore ESP of main()
    popad ; restore registers of main()
    mov esp, ebp	
	pop ebp
    ret

Func_end:
    jmp end_co ; resume main

;utilities---------------------------------------------->

degToRad:
    push ebp
	mov ebp, esp

    mov eax, dword [ebp+12]
    mov dword [d_reg+4], eax
    mov eax, dword [ebp+8]
    mov dword [d_reg], eax
    fldpi
    fmul qword [d_reg]
    fld tword [one_eighty]
    fdivp

    leave
    ret
     
arctan:
    push ebp
	mov ebp, esp

    calc_2 fpatan
    
    leave
    ret

my_abs:
    push ebp
	mov ebp, esp
    
    calc_1 fabs

    leave
    ret

pow_2:
    push ebp
	mov ebp, esp

    mov eax, dword [ebp+12]
    mov dword [d_reg+4], eax
    mov eax, dword [ebp+8]
    mov dword [d_reg], eax
    fld qword [d_reg]
    fld qword [d_reg]
    fmulp

    leave
    ret

my_sqrt:
    push ebp
	mov ebp, esp

    calc_1 fsqrt

    leave
    ret

my_sin:
    push ebp
	mov ebp, esp

    calc_1 fsin

    leave
    ret

my_cos:
    push ebp
	mov ebp, esp

    calc_1 fcos

    leave
    ret

get_new_bit:;(lsfr)
    push ebp
    mov ebp, esp

    mov eax, dword [ebp+8]
    mov edx, eax
    shr edx, 2
    xor eax, edx
    shr edx, 1
    xor eax, edx
    shr edx, 2
    xor eax, edx

    leave
    ret

random_gen: ;(double, double)
    push ebp
    mov ebp, esp
   
    mov ecx, 16
.get_bit:
    movzx eax, word [seed]
    mov edx, eax
    shr edx, 2
    xor eax, edx
    shr edx, 1
    xor eax, edx
    shr edx, 2
    xor eax, edx ;eax<-bit
    shl eax, 15 ; eax<-bit << 15    

.get_lsfr:
    movzx edx, word [seed] ;edx<-lfsr

    shr edx, 1
    or eax, edx ;eax <-(lfsr >> 1) | (bit << 15)

.new_seed:
    mov word [seed], ax
    loop .get_bit
    ;
    ; push word [seed]
    ; push print_hu
    ; call printf
    ; add esp, 8
    ;
    fild dword [seed]  

    ; fst qword [d_reg]
    ; push dword[d_reg+4]
    ; push dword[d_reg]
    ; push print_lf
    ; call printf
    ; add esp, 8

    fidiv dword [random_gen_constant]

    ; fst qword [d_reg]
    ; push dword[d_reg+4]
    ; push dword[d_reg]
    ; push print_lf
    ; call printf
    ; add esp, 8

    calc_2 fsubrp ;load 2 args
    ;fsubrp ;max - min
    
    fmulp

    calc_1 faddp

    ; fst qword [d_reg]
    ; push dword[d_reg+4]
    ; push dword[d_reg]
    ; push print_lf
    ; call printf
    ; add esp, 8

    leave
    ret

init_board:
        push    ebp
        mov     ebp, esp
    
        push    esi
        push    4
        call    malloc
        add     esp, 4
        
        mov     DWORD [game_target], eax
        mov     esi, DWORD [game_target]

        push    24
        call    malloc
        add     esp, 4

        mov     DWORD [esi], eax

        call    target_run

        push    0
        call    initCo
        add     esp, 4

        push    1
        call    initCo
        add     esp, 4

        push    2
        call    initCo
        add     esp, 4

        push    3
        call    initCo
        add     esp, 4
        pop esi

        leave
        ret

mayDestroy:
        push    ebp
        mov     ebp, esp

        sub     esp, 72
        mov     eax, DWORD [ebp+12]
        mov     eax, DWORD [eax]
        fld     QWORD [eax]
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax]
        fsubp   
        mov     eax, DWORD [ebp+12]
        mov     eax, DWORD [eax]
        fld     QWORD [eax+8]
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+8]
        fsubp   
        fxch    
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        call    arctan
        add     esp, 16
        fstp    QWORD [ebp-24]
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+16]
        fsub    QWORD [ebp-24]
        sub     esp, 8
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        call    my_abs
        add     esp, 16
        fstp    QWORD [ebp-16]
        fldpi
        fld     QWORD [ebp-16]
        fucomip 
        fstp    
        jbe     .after_if
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+16]
        fld     QWORD [ebp-24]
        fucomip 
        fstp    
        jbe     .alpha_smaller
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+16]
        fldpi
        faddp  
        fsub    QWORD [ebp-24]
        sub     esp, 8
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        call    my_abs
        add     esp, 16
        fstp    QWORD [ebp-16]
        jmp     .after_if
.alpha_smaller:
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+16]
        fldpi
        fsubp   
        fsub    QWORD [ebp-24]
        sub     esp, 8
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        call    my_abs
        add     esp, 16
        fstp    QWORD [ebp-16]
.after_if:
        fld     QWORD [ebp-16]
        fld     QWORD [beta]
        fucomip 
        fstp    
        seta    al
        movzx   eax, al
        mov     DWORD [ebp-28], eax
        mov     eax, DWORD [ebp+12]
        mov     eax, DWORD [eax]
        fld     QWORD [eax+8]
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax+8]
        fsubp   
        sub     esp, 8
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        call    pow_2
        add     esp, 16
        fstp    QWORD [ebp-64]
        mov     eax, DWORD [ebp+12]
        mov     eax, DWORD [eax]
        fld     QWORD [eax]
        mov     eax, DWORD [ebp+8]
        mov     eax, DWORD [eax+4]
        fld     QWORD [eax]
        fsubp   
        sub     esp, 8
        lea     esp, [esp-8]
        fstp    QWORD [esp]
        call    pow_2
        add     esp, 16
        fadd    QWORD [ebp-64]
        fstp    QWORD [ebp-40]
        sub     esp, 8
        push    DWORD [ebp-36]
        push    DWORD [ebp-40]
        call    my_sqrt
        add     esp, 16
        fstp    QWORD [ebp-40]
        fld     QWORD [ebp-40]
        fld     QWORD [d]
        fucomip 
        fstp    
        seta    al
        movzx   eax, al
        mov     DWORD [ebp-44], eax
        cmp     DWORD [ebp-28], 0
        je      .return_f
        cmp     DWORD [ebp-44], 0
        je      .return_f
        mov     eax, 1
        jmp     .return
.return_f:
        mov     eax, 0
.return:
        leave
        ret



free_position:  ;input:(position*):
        push    ebp
        mov     ebp, esp

        cmp     DWORD [ebp+8], 0    ;if pos == NULL:
        je      .end                ;       then: return        
        push    DWORD [ebp+8]       ;       else: free(pos)
        call    free

.end:
        leave
        ret

free_target:
        push    ebp
        mov     ebp, esp

        mov eax, DWORD [game_target] ; eax = (target*) game_target

        cmp     eax, 0    ;if gameTarget == NULL:
        je      .end                      ;       then: return        

        mov eax, DWORD [game_target]

        push   dword [eax]             ;free game_target->pos
        call    free_position

        ;mov     eax, DWORD [game_target]  ;game_target->pos = NULL
        ;mov     DWORD [eax], 0

        push DWORD [game_target]                        ; free struct target
        call free
        mov DWORD [game_target],  0

.end:
        leave
        ret

init_drone_threads:
        push    ebp
        mov     ebp, esp
        push    ebx
        sub     esp, 20
        mov     eax, DWORD [N]
        sal     eax, 2
        sub     esp, 12
        push    eax
        call    malloc
        add     esp, 16
        mov     DWORD [drone_cos], eax
        mov     eax, DWORD [N]
        add     eax, 1
        sal     eax, 2
        sub     esp, 12
        push    eax
        call    malloc
        add     esp, 16
        mov     DWORD [drone_array], eax
        mov     DWORD [ebp-12], 0
        jmp     .for_cond
.for_loop:
        mov     eax, DWORD [drone_cos]
        mov     edx, DWORD [ebp-12]
        sal     edx, 2
        lea     ebx, [eax+edx]
        sub     esp, 12
        push    12
        call    malloc
        add     esp, 16
        mov     DWORD [ebx], eax
        mov     eax, DWORD [drone_cos]
        mov     edx, DWORD [ebp-12]
        sal     edx, 2
        add     eax, edx
        mov     eax, DWORD [eax]
        mov     DWORD [eax], Func_drone
        mov     eax, DWORD [drone_cos]
        mov     edx, DWORD [ebp-12]
        sal     edx, 2
        add     eax, edx
        mov     ebx, DWORD [eax]
        sub     esp, 12
        push    16384
        call    malloc
        add     esp, 16
        mov     DWORD [ebx+8], eax
        mov     eax, DWORD [drone_cos]
        mov     edx, DWORD [ebp-12]
        sal     edx, 2
        add     eax, edx
        mov     eax, DWORD [eax]
        mov     edx, DWORD [eax+8]
        mov     eax, DWORD [drone_cos]
        mov     ecx, DWORD [ebp-12]
        sal     ecx, 2
        add     eax, ecx
        mov     eax, DWORD [eax]
        add     edx, 16384
        mov     DWORD [eax+4], edx
        add     DWORD [ebp-12], 1
.for_cond:
        mov     eax, DWORD [N]
        cmp     DWORD [ebp-12], eax
        jl      .for_loop
        mov     ebx, DWORD [ebp-4]
        leave
        ret

load_args:
        push    ebp
        mov     ebp, esp
        sub     esp, 8
        mov     eax, DWORD [ebp+8]
        add     eax, 4
        mov     eax, DWORD [eax]
        sub     esp, 4
        push    N
        push    scan_d
        push    eax
        call    sscanf
        add     esp, 16
        mov     eax, DWORD [ebp+8]
        add     eax, 8
        mov     eax, DWORD [eax]
        sub     esp, 4
        push    T
        push    scan_d
        push    eax
        call    sscanf
        add     esp, 16
        mov     eax, DWORD [ebp+8]
        add     eax, 12
        mov     eax, DWORD [eax]
        sub     esp, 4
        push    K
        push    scan_d
        push    eax
        call    sscanf
        add     esp, 16
        mov     eax, DWORD [ebp+8]
        add     eax, 16
        mov     eax, DWORD [eax]
        sub     esp, 4
        push    beta
        push    scan_lf
        push    eax
        call    sscanf
        add     esp, 16
        mov     eax, DWORD [ebp+8]
        add     eax, 20
        mov     eax, DWORD [eax]
        sub     esp, 4
        push    d
        push    scan_lf
        push    eax
        call    sscanf
        add     esp, 16
        mov     eax, DWORD [ebp+8]
        add     eax, 24
        mov     eax, DWORD [eax]
        sub     esp, 4
        push    seed
        push    scan_hu
        push    eax
        call    sscanf
        add     esp, 16
        leave
        ret

free_drone_array:
        push    ebp
        mov     ebp, esp
        sub     esp, 24

        mov     DWORD [ebp-12], 0           ;[ebp-12] = i = 0
.dbg0:

.for_start:
        mov     edx, DWORD [ebp-12]         ;edx = [ebp-12] = i
        mov     eax, DWORD [N]            ; eax = N
        cmp     edx, eax                    ; if i == N
        jnb     .for_end                    ; go to end of for
.dbg1:

        mov     eax, DWORD  [drone_array]     ; eax = drone_array
        mov     edx, DWORD  [ebp-12]        ; edx = i
        sal     edx, 2                      ; edx  = 4*i
        add     eax, edx                    ; eax = eax + 4*i
        mov     eax, DWORD [eax]            ; eax = drone[i]
.dbg2:
        mov     eax, DWORD [eax+4]          ; eax = drone[i]->pos
        sub     esp, 12
        push    eax                         ;
        call    free                        ; free(drone[i]->pos)
        add     esp, 16
.dbg3:

        mov     eax, DWORD [drone_array]      ; eax = drone_array
        mov     edx, DWORD  [ebp-12]        ; edx = i
        sal     edx, 2                      ; edx  = 4*i
        add     eax, edx                    ; eax = eax + 4*i
.dbg4:
        mov     eax, DWORD [eax]            ; eax = drone[i]
        sub     esp, 12
        push    eax
        call    free                        ;free(drone_array[i]);
.dbg5:

        add     esp, 16
        
        add     DWORD [ebp-12], 1       ;i++
        jmp     .for_start
.for_end:
        mov     eax, DWORD [drone_array]      ; eax = drone_array
        sub     esp, 12
        push    eax
        call    free                        ;free(drone_array)
        add     esp, 16
        mov     DWORD [drone_array], 0    ;drone_array = NULL
        
        leave
        ret

free_drone_cos:
        push    ebp
        mov     ebp, esp
        sub     esp, 24
        mov     DWORD [ebp-12], 0
        jmp     .loop_cond
.loop_body:
        mov     eax, DWORD [drone_cos]
        mov     edx, DWORD [ebp-12]
        sal     edx, 2
        add     eax, edx
        mov     eax, DWORD [eax]
        mov     eax, DWORD [eax+8]
        sub     esp, 12
        push    eax
        call    free
        add     esp, 16
        mov     eax, DWORD [drone_cos]
        mov     edx, DWORD [ebp-12]
        sal     edx, 2
        add     eax, edx
        mov     eax, DWORD [eax]
        sub     esp, 12
        push    eax
        call    free
        add     esp, 16
        add     DWORD [ebp-12], 1
.loop_cond:
        mov     eax, DWORD [N]
        cmp     DWORD [ebp-12], eax
        jl      .loop_body
        mov     eax, DWORD [drone_cos]
        sub     esp, 12
        push    eax
        call    free
        add     esp, 16
        mov     DWORD [drone_cos], 0
        leave
        ret