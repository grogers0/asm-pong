;composte.asm - GRR - 10/9/06
;	this module holds a set of subroutines to composite an image

segment _TEXT public class=CODE use16

;-- void _Composite(int sourceSEG, int sourceIMAGE, int destSEG, int destIMAGE)
;	this function composites (xor's) the image [(cs+sourceSEG):sourceIMAGE]
;		with the image [(cs+destSEG):destIMAGE]
;	the segments are relative
global _Composite
_Composite:
	push bp
	mov bp,sp
	push si
	push di
	push es
	push ds
	push ax
	push cx


	;load the source segment and image into ds:si
	mov ax,cs
	add ax,[bp+4]
	mov ds,ax
	mov si,[bp+6]

	;load the destination segment and image into es:di
	mov ax,cs
	add ax,[bp+8]
	mov es,ax
	mov di,[bp+10]

	mov cx,0
.loop:
	;load the word from ds:si and then XOR it into the word at es:di
	lodsw
	es xor ax,[di]
	stosw

	add cx,2
	cmp cx,0x4000
	jb .loop

	pop cx
	pop ax
	pop ds
	pop es
	pop di
	pop si
	pop bp
	ret


;-- void _Composite_to_display(int sourceSEG, int sourceIMAGE)
;	this function composites (xor's) the image [(cs+sourceSEG):sourceIMAGE]
;		to the 640x200 CGA display, the segments are relative
global _Composite_to_display
_Composite_to_display:
	push bp
	mov bp,sp
	push si
	push di
	push es
	push ds
	push ax
	push cx

	;load the source segment and image into ds:si
	mov ax,cs
	add ax,[bp+4]
	mov ds,ax
	mov si,[bp+6]

	;load the destination segment and image into es:di
	mov ax,0xb800
	mov es,ax
	mov di,0

	cld						;increment si/di so clear decrement flag

	mov cx,0
.loop:
	;load the word from ds:si and then XOR it into the word at es:di
	lodsw
	es xor ax,[di]
	stosw

	add cx,2
	cmp cx,0x4000
	jb .loop

	pop cx
	pop ax
	pop ds
	pop es
	pop di
	pop si
	pop bp
	ret


;-- void _Copy_to_display(int sourceSEG, int sourceIMAGE)
;	this function copies the image [(cs+sourceSEG):sourceIMAGE]
;		to the 640x200 CGA display
global _Copy_to_display
_Copy_to_display:
	push bp
	mov bp,sp
	push si
	push di
	push es
	push ds
	push ax
	push cx

	;load the source segment and image into ds:si
	mov ax,cs
	add ax,[bp+4]
	mov ds,ax
	mov si,[bp+6]

	;load the destination segment and image into es:di
	mov ax,0xb800
	mov es,ax
	mov di,0

	cld						;increment si/di so clear decrement flag

	mov cx,0x2000			;move words, 0x2000 words is 0x4000 bytes
	rep movsw

	pop cx
	pop ax
	pop ds
	pop es
	pop di
	pop si
	pop bp
	ret
