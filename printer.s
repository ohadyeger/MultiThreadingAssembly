section	.rodata			; we define (global) read-only variables in .rodata section
    FMT2: db "printer, co %lx, called by %lx, pass %ld", 10, 0 
    ERR_ID_FMT: db "id should be between %d and %d",10,0

    FMT_PRINT_BOARD: db "%.2f,%.2f",10,0 ;
    FMT_PRINT_DRONE: db "%d,%.2f,%.2f,%.2f,%d",10, 0

section .bss			; we define (global) uninitialized variables in .bss section

section .text

    global Func_printer

    extern CORS
    extern resume
    extern printf
    extern CURR
    extern game_target
    extern N
    extern putchar
    extern scheduler_run
    extern drone_array
    extern printBoard2
    global get_drone
    global printBoard
    global printDrone
    global printGameTarget

Func_printer:
    call printBoard
    mov ebx, [CORS+4*2] ; resume a scheduler
    call resume
    jmp Func_printer

printBoard:
    push ebp
	mov ebp, esp

    call printGameTarget

    ;insert 1 to the first cell: i = [ebp - 4] = 1
    push dword 1 ; esp = ebp - 4

.L1:
 ;if i == N go to .L1_END
    mov     edx, dword  [ebp - 4]   ;edx = i
    cmp     edx, [N]                  ; i == N ?
    jg .L1_END
 ;else:
    push dword [ebp - 4]                  
    call get_drone
    push eax                        ; [ebp - 8] = get_drone
    call printDrone
    add esp, 8
    
    add dword [ebp -4] , 1    ; i ++
    jmp .L1
    
.L1_END:

    mov esp, ebp	
	pop ebp
    ret

;FMT_id: db "%d\n",0
printDrone:    
    push ebp
	mov ebp, esp  

    mov     ebx, dword [ebp+8] ;  drone* drone= ebx = [ebp+8]
    mov     edx , [ebx+4] ; edx = drone pos

    push dword [ebx+8]  ; push destroyed_targets

    ;push drone pos->alpha
    push dword [edx+20]  ;pushes 32 bits (MSB)
    push dword [edx+16]    ;pushes 32 bits (LSB)

    ;push drone pos->y
    push dword [edx+12]  ;pushes 32 bits (MSB)
    push dword [edx+8]    ;pushes 32 bits (LSB)

    ;push drone pos->x
    push dword [edx+4]  ;pushes 32 bits (MSB)
    push dword [edx]    ;pushes 32 bits (LSB)

    ; push drone id
    push    dword [ebx]

    push    dword FMT_PRINT_DRONE
    call    printf
    add     esp, 8
    
    mov esp, ebp	
	pop ebp
    ret

printGameTarget:
    push ebp
	mov ebp, esp

    ;push game_target->pos->y
    mov     edx , game_target
    mov     edx, [edx] ; edx = pos   
    mov     edx, [edx] ; edx = x
    push dword [edx+12]  ;pushes 32 bits (MSB)
    push dword [edx+8]    ;pushes 32 bits (LSB)
    ;push game_target->pos->x
    mov     edx , game_target
    mov     edx, [edx] ; edx = pos
    mov     edx, [edx] ; edx = x
    push dword [edx+4]  ;pushes 32 bits (MSB)
    push dword [edx]    ;pushes 32 bits (LSB)

    push FMT_PRINT_BOARD
    call printf

    mov esp, ebp	
	pop ebp
    ret

get_drone:
        push ebp
	    mov ebp, esp

        mov     eax, DWORD [ebp+8]
        test    eax, eax
        jle     .error
        cmp     eax, DWORD [N]
        ja      .error
        mov     edx, DWORD [drone_array]
        mov     eax, DWORD [edx-4+eax*4]
.ret:
        leave
        ret
.error:

        push    DWORD [N]
        push    1
        push    ERR_ID_FMT
        call    printf
        add     esp, 12
        mov     eax, 0
        jmp     .ret