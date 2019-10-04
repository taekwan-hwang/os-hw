[ORG 0x00]
[BITS 16]

SECTION .text

START:
    mov ax, 0x1000
    mov ds, ax
    mov es, ax

    .RAMSIZE:
    ;;hyebeen ing *^_^* start
;;get system memory map
; int 0x15    
; AX = E820h
; EAX = 0000E820h
; EDX = 534D4150h ('SMAP')
; EBX = continuation value or 00000000h to start at beginning of map
; ECX = size of buffer for result, in bytes (should be >= 20 bytes)
; ES:DI -> buffer for result (see #00581)

    ; mov ax, ss
    ; add ax, bp
    ; add ax, 1
    ; mov es, ax
    
    xor di, di
    xor bx, bx    
    mov cx, 20
    ; mov dx, ;SMAP
    mov ax, 0xE820
    int 0x15 ;get system memory map

;     jc .GETSYSTEMMEMORYMAP_ERROR
;     jmp .GETSYSTEMMEMORYMAP_SUCCESS

; .GETSYSTEMMEMORYMAP_ERROR:
;     push GETSYSTEMMEMORYMAP_ERROR_MESSAGE    
;     push 3                      
;     push 0                       
;     call .PRINTMESSAGE            
;     add  sp, 6 

;     jmp .SET_A20GATE

; .GETSYSTEMMEMORYMAP_SUCCESS:
;     push RAMSIZEMESSAGE    
;     push 3                      
;     push 0                       
;     call .PRINTMESSAGE            
;     add  sp, 6  

;output :: [ ecx ] buffer size ,[ ebx ] continuation ,[ es:di ] Buffer Pointer, [ cf ] Carry Flag = Non-Carry - indicates no error
;;hyebeen ing *^_^* end   

.SET_A20GATE:
    mov ax, 0x2401
    int 0x15 ; using bios, enable a20 gate

    jc .A20GATEERROR
    jmp .A20GATESUCCESS

.A20GATEERROR:
    in al, 0x92 ; using system port, enable a20 gate
    or al, 0x02
    and al, 0xFE
    out 0x92, al

.A20GATESUCCESS:    
    cli
    lgdt [ GDTR ]

    mov eax, 0x4000003B
    mov cr0, eax

    jmp dword 0x18: ( PROTECTEDMODE - $$ + 0x10000 )

;;;;;;;;;;;;;;;;;;
;;보호모드로 진입;;
;;;;;;;;;;;;;;;;;;

[BITS 32]
PROTECTEDMODE:
    mov ax, 0x20
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0xFFFE
    mov ebp, 0xFFFE

    push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000 )
    push 4
    push 0
    call PRINTMESSAGE
    add esp, 12

    jmp dword 0x18: 0x10200 ; C 언어 커널이 존재하는 0x10200 어드레스로 이동하여 C 언어 커널 수행

PRINTMESSAGE:
    push ebp
    mov ebp, esp
    push esi
    push edi
    push eax
    push ecx
    push edx
    
    mov eax, dword [ ebp + 12 ]
    mov esi, 160
    mul esi
    mov edi, eax

    mov eax, dword [ ebp + 8 ]
    mov esi, 2
    mul esi
    add edi, eax

    mov esi, dword [ ebp + 16 ]

.MESSAGELOOP:
    mov cl, byte [ esi ]
    cmp cl, 0
    je .MESSAGEEND

    mov byte [ edi + 0xB8000 ], cl

    add esi, 1
    add edi, 2

    jmp .MESSAGELOOP

.MESSAGEEND:
    pop edx
    pop ecx
    pop eax
    pop edi
    pop esi
    pop ebp
    ret

;;;;;;;;;;;;;;;;;;;;
;;   데이터 영역   ;;
;;;;;;;;;;;;;;;;;;;;

align 8, db 0

dw 0x0000
GDTR:
    dw GDTEND - GDT - 1
    dd ( GDT - $$ + 0x10000 )
GDT:
    NULLDescriptor:
        dw 0x0000
        dw 0x0000
        db 0x00
        db 0x00
        db 0x00
        db 0x00

	IA_32eCODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A ; P=1, DPL= 0, CODE SEGMENT, EXECUTE/READ
		db 0xAF ; G=1, D= 0, L=1, LIMIT[19:16]
		db 0x00


	IA_32eDATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xAF
		db 0x00


    CODEDESCRIPTOR:     
        dw 0xFFFF       ; Limit [15:0]
        dw 0x0000       ; Base [15:0]
        db 0x00         ; Base [23:16]
        db 0x9A         ; P=1, DPL=0, Code Segment, Execute/Read
        db 0xCF         ; G=1, D=1, L=0, Limit[19:16]
        db 0x00         ; Base [31:24]  

    DATADESCRIPTOR:
        dw 0xFFFF
        dw 0x0000
        db 0x00
        db 0x92         ; P=1, DPL=0, Data Segment, Read/Write
        db 0xCF
        db 0x00
GDTEND:

RAMSIZEMESSAGE: db 'RAM Size:', 0
GETSYSTEMMEMORYMAP_ERROR_MESSAGE: db 'get system memory map interrupt error ~!!', 0
SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success~!!', 0

times 512 - ( $ - $$ )  db  0x00
