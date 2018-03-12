[ORG 0x00]
[BITS 16]

SECTION .text

START:
	mov ax, 0x1000
	mov ds, ax
	mov es, ax

	;A20 gate activation
	;When the conversion using the BIOS fails, attempt to convert to system controll port

	;Using BIOS services, A20 gate activation
	mov ax, 0x2401
	int 0x15

	jc .A20GATEERROR ; Verify that A20 gate activation was successful
	jmp .A20GATESUCCESS

.A20GATEERROR:
	;When generate error, attempt to convert to system controll port
	in al, 0x92
	or al, 0x02
	and al, 0xFE
	out 0x92, al

.A20GATESUCCESS:
	cli
	lgdt[GDTR]

	;enter to protect mode
	;disable paging, disable cache, internal FPU, disable align check, enable protectedmode
	mov eax, 0x4000003B
	mov cr0, eax

	jmp dword 0x18: (PROTECTEDMODE - $$ + 0x10000)

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

	push ( SWITCHSUCCESSMESSAGE - $$ + 0x10000)
	push 2
	push 0
	call PRINTMESSAGE
	add esp, 12

	jmp dword 0x18: 0x10200 ; move c kernel code

; function code area
PRINTMESSAGE:
	push ebp
	mov ebp, esp
	push esi
	push edi
	push eax
	push ecx
	push edx

	mov eax, dword [ebp+12]
	mov esi,160
	mul esi
	mov edi, eax

	mov eax, dword[ebp+8]
	mov esi, 2
	mul esi
	add edi, eax

	mov esi, dword[ebp+16]

	.MESSAGELOOP:
		mov cl, byte[esi]

		cmp cl, 0
		je .MESSAGEEND

		mov byte[edi+0xB8000], cl

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

; data area

align 8, db 0

dw 0x0000

GDTR:
	dw GDTEND - GDT -1
	dd (GDT - $$ + 0x10000)

GDT:

	NULLDESCRIPTOR:
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
		db 0x9A
		db 0xAF
		db 0x00

	IA_32eDATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xAF
		db 0x00

	CODEDESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x9A
		db 0xCF
		db 0x00

	DATADESCRIPTOR:
		dw 0xFFFF
		dw 0x0000
		db 0x00
		db 0x92
		db 0xCF
		db 0x00

GDTEND:

SWITCHSUCCESSMESSAGE: db 'Switch To Protected Mode Success!!', 0

times 512-($-$$) db 0x00
