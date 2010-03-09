;keyboard.asm - GRR - 11/1/06
;this module takes the keyboard input and encodes it into a status integer that
;	can be read through functions to determine what key is pressed

%include "keymap.mac"

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16



;global to set which keys are currently pressed
global _key_status

segment _BSS

_key_status:	resb 1

;global these to show up in MAP file, don't expect to need them global
global old_key_int

old_key_int:	resd	1		;global to save the old cs:ip for int 0x09 

segment _TEXT


;-- void key_interrupt()
;	This replaces INT 0x09 and reads the keyboard
key_int:
	push ax
	push bx
	push cx

	;get the current key press and set the flag accordingly
	in al,0x60
	ds mov bl,[_key_status]

	cmp al,SCAN_A
	je .akeydown
	cmp al,SCAN_A+0x80
	je .akeyup

	cmp al,SCAN_N
	je .nkeydown
	cmp al,SCAN_N+0x80
	je .nkeyup

	cmp al,SCAN_Z
	je .zkeydown
	cmp al,SCAN_Z+0x80
	je .zkeyup

	cmp al,SCAN_ESC
	je .esckeydown
	cmp al,SCAN_ESC+0x80
	je .esckeyup

	cmp al,SCAN_ENTER
	je .enterkeydown
	cmp al,SCAN_ENTER+0x80
	je .enterkeyup

	cmp al,SCAN_RIGHTSHIFT
	je .rightshiftkeydown
	cmp al,SCAN_RIGHTSHIFT+0x80
	je .rightshiftkeyup

	cmp al,SCAN_SPACEBAR
	je .spacebarkeydown
	cmp al,SCAN_SPACEBAR+0x80
	je .spacebarkeyup
	jmp .exit


.akeydown:
	or bl,KEY_A
	jmp .exit
.akeyup:
	mov cl,KEY_A
	not cl
	and bl,cl
	jmp .exit

.nkeydown:
	or bl,KEY_N
	jmp .exit
.nkeyup:
	mov cl,KEY_N
	not cl
	and bl,cl
	jmp .exit

.zkeydown:
	or bl,KEY_Z
	jmp .exit
.zkeyup:
	mov cl,KEY_Z
	not cl
	and bl,cl
	jmp .exit

.esckeydown:
	or bl,KEY_ESC
	jmp .exit
.esckeyup:
	mov cl,KEY_ESC
	not cl
	and bl,cl
	jmp .exit

.enterkeydown:
	or bl,KEY_ENTER
	jmp .exit
.enterkeyup:
	mov cl,KEY_ENTER
	not cl
	and bl,cl
	jmp .exit

.rightshiftkeydown:
	or bl,KEY_RIGHTSHIFT
	jmp .exit
.rightshiftkeyup:
	mov cl,KEY_RIGHTSHIFT
	not cl
	and bl,cl
	jmp .exit

.spacebarkeydown:
	or bl,KEY_SPACEBAR
	jmp .exit
.spacebarkeyup:
	mov cl,KEY_SPACEBAR
	not cl
	and bl,cl
	jmp .exit


.exit:
	ds mov [_key_status],bl

	mov al,0x20						;send end-of-interrupt signal to 8259
	out 0x20,al						;interrupt controller

	pop cx
	pop bx
	pop ax
	iret


;-- void _install_key_int()
;	install our key handler interrupt
;	NOTE: ds is set by beginCOM to _BSS
global _install_key_int
_install_key_int:
	push es
	push ax

	;initialize the _key_status to blank
	ds mov byte [_key_status],0

	;save the old int 0x09 location
	mov ax,0					;segment 0 where interrupts are installed
	mov es,ax

	es mov ax,[0x09*4+2]		;interrupt table has 4 bytes per entry
	ds mov [old_key_int+2],ax
	es mov ax,[0x09*4]
	ds mov [old_key_int],ax

	;install the new int 0x09
	mov ax,cs
	es mov [0x09*4+2],ax
	mov ax,key_int
	es mov [0x09*4],ax

	pop ax
	pop es
	ret

;-- _uninstall_key_int()
;	uninstall our key handler interrupt
;	NOTE: ds is set by beginCOM to _BSS
global _uninstall_key_int
_uninstall_key_int:
	push ax
	push es

	;install the new old 0x09
	mov ax,0					;segment 0 where interrupts are installed
	mov es,ax

	ds mov ax,[old_key_int+2]
	es mov [0x09*4+2],ax		;interrupt table has 4 bytes per entry
	ds mov ax,[old_key_int]
	es mov [0x09*4],ax

	pop es
	pop ax
	ret




