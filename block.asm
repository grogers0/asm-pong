;block.asm - GRR - 10/25/06
;	set of functions to draw a block (rectangle) on the screen

segment _TEXT public align=1 class=CODE use16

extern _write_pixel

;-- void _block(int x1, int y1, int x2, int y2)
;	Writes a rectangle to the 640x200 CGA screen (es is defined before entry)
;	(x1,y1) and (x2,y2) can be any corner of the rectangle (inclusive)
global _block
_block:
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx
	push si

	;find x_start from the min(x1,x2)
	mov ax,[bp+4]
	push ax
	mov ax,[bp+8]
	push ax
	call min
	mov cx,ax				;cx stores x_start

	;find x_end from max(x1,x2)
	call max
	add sp,4
	mov dx,ax				;dx stores x_end

	;find y_end from the max(y1,y2)
	mov ax,[bp+6]
	push ax
	mov ax,[bp+10]
	push ax
	call max
	mov bx,ax				;bx stores y_end

	;find y_start from min(y1,y2)
	call min				;ax stores y_start
	add sp,4
	push ax					;save y_start away to make looping faster
	mov si,sp				;si points to y_start

.loopx:						;loop through x with cx
	ss mov ax,[si]

.loopy:						;loop through y with ax
	push ax					;y
	push cx					;x
	push word 1				;pixel on
	call _write_pixel		;write pixel (x,y)
	add sp,6

	inc ax
	cmp ax,bx
	jbe .loopy

	inc cx
	cmp cx,dx
	jbe .loopx

	add sp,2				;"pop" y_start

	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret


;--	int min(int a, int b)
;	find the minimum of two unsigned numbers
min:
	push bp
	mov bp,sp
	push bx

	mov ax,[bp+4]
	mov bx,[bp+6]

	cmp ax,bx
	jbe .exit			;if ax is the min, don't switch
	mov ax,bx			;if bx is min, set ax=bx
.exit:
	pop bx
	pop bp
	ret


;--	int max(int a, int b)
;	find the minimum of two unsigned numbers
max:
	push bp
	mov bp,sp
	push bx

	mov ax,[bp+4]
	mov bx,[bp+6]

	cmp ax,bx
	jae .exit			;if ax is the max, don't switch
	mov ax,bx			;if bx is max, set ax=bx
.exit:
	pop bx
	pop bp
	ret
	
