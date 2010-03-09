;pixel.asm - GRR - 10/7/06
;a set of subroutines for writing and reading to the 640x200 CGA display

;-----------code
segment _TEXT public align=1 class=CODE use16


;-- void _write_char(int ascii, int x, int y)
;	prints the character with ascii code input ascii to (x,y) upper left corner
;	of the 8x8 box to the CGA screen
;	NOTE: this does not print to exact x pixel values, it truncates to 8 pixels
;	accuracy
global _write_char
_write_char:
	push bp
	mov bp,sp
	push ax
	push cx
	push si
	push di
	push ds

	;es is already set to 0xb800
	
	;set source seg and index to the char generator rom
	mov ax,0xf000			;segment for character generator rom
	mov ds,ax
	mov si,0xfa6e			;start of generator rom
	mov ax,[bp+4]
	mov cl,3
	shl ax,cl
	add si,ax				;add in ascii offset
	add si,7				;starting loop at end

	std

	mov cx,7
.loop:
	mov di,[bp+8]
	add di,cx
	push di
	push word [bp+6]
	call get_byte_addr
	add sp,4
	mov di,ax				;get dest offset

	movsb

	dec cx
	jge .loop

	pop ds
	pop di
	pop si
	pop cx
	pop ax
	pop bp
	ret
	
	
	
	


;-- void _write_pixel(int a, int x, int y);
;	prints a pixel at (x,y) on a 640x200 display
;	a is the value to write: either 0 or 1
;	NOTE: es is set to the display segment before entering the function
global _write_pixel
_write_pixel:
	push bp
	mov bp,sp
	push ax
	push bx
	push cx
	push dx

	push word [bp+8]			;y
	push word [bp+6]			;x
	call get_byte_addr
	mov bx,ax					;bx holds byte address
	call get_bit_addr
	add sp,4
	mov cx,ax					;cx holds bit address
	mov dl,0x80
	shr dl,cl					;offset a "1" into the bit address
	mov ax,[bp+4]
	cmp ax,0					;is a = 0?
	je .pixeloff				; yes: print pixel off
.pixelon:						; no: print pixel on
	es or [bx],dl				;or leaves everything untouched but the bit we turn on
	jmp .exit
.pixeloff:
	not dl						;invert dl
	es and [bx],dl				;and leaves everything untouched but the bit we turn off

.exit:
	pop dx
	pop cx
	pop bx
	pop ax
	pop bp
	ret


;-- void _read_pixel(int x, int y);
;	reads a pixel at (x,y) from a 640x200 display
;	ax returns the value read: either 0 or 1
;	NOTE: es is set to the display segment before entering the function
global _read_pixel
_read_pixel:
	push bp
	mov bp,sp
	push bx
	push cx
	push dx

	push word [bp+6]			;y
	push word [bp+4]			;x
	call get_byte_addr
	mov bx,ax					;bx holds byte address
	call get_bit_addr
	add sp,4
	mov cx,ax					;cx holds bit address
	mov dl,0x80
	shr dl,cl					;offset a "1" into the bit address
	es mov al,[bx]
	and al,dl
	cmp al,0					;is a = 0?
	je .pixeloff				; yes: pixel is off
.pixelon:						; no: pixel is on
	mov ax,1
	jmp .exit
.pixeloff:
	mov ax,0

.exit:
	pop dx
	pop cx
	pop bx
	pop bp
	ret


;--	int get_byte_addr(int x, int y)
;	function to find the byte that pixel (x,y) falls in
get_byte_addr:
	push bp
	mov bp,sp
	push bx
	push cx

	mov ax,[bp+4]				;x value
	mov cl,8
	div cl						;x/8 because 8 bits/byte
	mov ah,0
	push ax						;save for later

	mov ax,[bp+6]				;y value
	mov bl,2
	div bl						;ah = y%2, al = y/2
	cmp ah,0					;is y an even row?
	je .evenrow					; yes: y is even, starts at 0
.oddrow:						; no: y is odd, starts at a page offset
	push word 0x2000
	jmp .continue
.evenrow:
	push word 0
.continue:

	mov bl,80					;80 bytes per line
	mul bl						;ax = 80*y/2
	pop bx
	add ax,bx					;ax = 80*y/2 + pageoffset
	pop bx
	add ax,bx					;ax = 80*y/2 + pageoffset + x/8
	
	pop cx
	pop bx
	pop bp
	ret

;--	int get_bit_addr(int x, int y)
;	function to find the bit in the byte that pixel (x,y) falls in (ie 0-7)
get_bit_addr:
	push bp
	mov bp,sp
	push bx
	push dx

	mov ax,[bp+4]				;x value
	mov bl,8					;8 bits/byte
	div bl						;ah = x % 8 (the bit position in the byte)
	mov al,ah
	mov ah,0

	pop dx
	pop bx
	pop bp
	ret


;------ellipse functions-------
;want to have a seperate module but dos/tlink doesn't let me have more than 14


;-- void _XORellipse(int a, int b, int x0, int y0, int x, int y)
;	print the pixel (x,y) if it is in the ellipse defined by and XOR it
;	(x-x0)^2/a^2 + (y-y0)^2/b^2 <= 1
global _XORellipse
_XORellipse:
	;save CPU state
	push bp
	mov bp,sp
	push ax
	push bx

	push word [bp+14]			;is_pixel_in_ellipse uses the same arguments as
	push word [bp+12]			;-ellipse, so transfer them directly
	push word [bp+10]
	push word [bp+8]
	push word [bp+6]
	push word [bp+4]
	call is_pixel_in_ellipse
	add sp,12
	cmp ax,0					;if it is in the ellipse (if ax > 0) print
	je .outside

	mov bx,1
	jmp .composite

.outside:
	mov bx,0

.composite:
	push word [bp+14]			;y
	push word [bp+12]			;x
	call _read_pixel

	xor ax,bx
	push ax
	call _write_pixel
	add sp,6

.exit:
	;load saved cpu state
	pop bx
	pop ax
	pop bp
	ret


;-- void _ellipse(int a, int b, int x0, int y0, int x, int y)
;	print the pixel (x,y) if it is in the ellipse defined by
;	(x-x0)^2/a^2 + (y-y0)^2/b^2 <= 1
global _ellipse
_ellipse:
	;save CPU state
	push bp
	mov bp,sp
	push ax

	push word [bp+14]			;is_pixel_in_ellipse uses the same arguments as
	push word [bp+12]			;-ellipse, so transfer them directly
	push word [bp+10]
	push word [bp+8]
	push word [bp+6]
	push word [bp+4]
	call is_pixel_in_ellipse
	add sp,12
	cmp ax,0					;if it is in the ellipse (if ax > 0) print
	je .exit					;-pixel (x,y), otherwise (if ax = 0) finish without printing
.write:
	push word [bp+14]			;y
	push word [bp+12]			;x
	push word 1					;print it 'on'
	call _write_pixel
	add sp,6

.exit:
	;load saved cpu state
	pop ax
	pop bp
	ret

;-- int is_pixel_in_ellipse(int a, int b, int x0, int y0, int x, int y)
;	returns whether or not pixel (x,y) is inside the ellipse defined by
;	(x-x0)^2/a^2 + (y-y0)^2/b^2 <= 1  ie:
;	b^2*(x-x0)^2 + a^2*(y-y0)^2 <= a^2*b^2
;	if the pixel is in the ellipse, 1 is returned, otherwise 0
;	result is returned in register AX
is_pixel_in_ellipse:

	;save CPU state
	push bp
	mov bp,sp
	push bx
	push cx
	push dx
	push di

	;make a = abs(a)
	push word [bp+4]				;a
	call abs
	add sp,2
	push ax							;save a for later

	;make b = abs(b)
	push word [bp+6]				;b
	call abs
	add sp,2
	push ax							;save b for later

	;shift_x and shift_y scale the x and y pixel values based on a and b.
	;in order to accomodate a and b values that would overflow the limits of
	;16 bit precision, a and b, as well as (x-x0) and (y-y0) are shifted right
	;(the equivalent of dividing by 2) until a and b do not cause overflow.
	;in effect this allows larger values of a and b to be used, however if
	;large values are used, the precision degrades accordingly.

	;find the shift in x based on a
	mov di,sp
	push word [di+2]				;a
	call get_shift					;find shift in x
	add sp,2
	push ax							;shift_x
	
	;find the shift in y based on b
	mov di,sp
	push word [di+2]				;b
	call get_shift					;find shift in y
	add sp,2
	push ax							;shift_y

	;shift a and b and square, save them where a and b were
	mov di,sp
	mov cx,[di+2]					;shift_x
	mov ax,[di+6]					;a
	shr ax,cl
	mul ax
	mov [di+6],ax					;save (a >> shift_x)^2

	mov cx,[di]						;shift_y
	mov ax,[di+4]					;b
	shr ax,cl
	mul ax
	mov [di+4],ax					;save (b >> shift_y)^2

	;compute (b >> shift_y)^2*(abs(x-x0) >> shift_x)^2
	mov ax,[bp+12]					;x
	mov bx,[bp+8]					;x0
	sub ax,bx						;(x-x0)
	push ax
	call abs						;abs(x-x0)
	add sp,2
	mov cx,[di+2]					;shift_x
	shr ax,cl						;(abs(x-x0) >> shift_x)
	mul ax							;(abs(x-x0) >> shift_x)^2
	jo .outside						;overflow here means its out of the ellipse
	mov bx,[di+4]					;(b >> shift_y)^2
	mul bx							;(abs(x-x0) >> shift_x)^2*(b >> shift_y)^2
	push ax							;save for later
	push dx							; ..

	;compute (a >> shift_x)^2*(abs(y-y0) >> shift_y)^2
	mov di,sp
	mov ax,[bp+14]					;y
	mov bx,[bp+10]					;y0
	sub ax,bx						;(y-y0)
	push ax
	call abs						;abs(x-x0)
	add sp,2
	mov cx,[di+4]					;shift_y
	shr ax,cl						;(abs(y-y0) >> shift_y)
	mul ax							;(abs(y-y0) >> shift_y)^2
	jno .continue					;overflow here means its out of the ellipse

	add sp,4
	jmp .outside

.continue:
	mov bx,[di+10]					;(a >> shift_x)^2
	mul bx							;(abs(y-y0) >> shift_y)^2*(a >> shift_x)^2

	;compute Left Hand Side
	pop cx
	pop bx							;cx|bx=(abs(x-x0) >> shift_x)^2*(b >> shift_y)^2
	add ax,bx						;dx|ax=LHS
	adc dx,cx						; ..
	jc .outside						;carry here means overflow - but is this possible?
	push ax							;save LHS for later
	push dx							; ..

	;compute Right Hand Side
	mov di,sp
	mov bx,[di+8]					;(b >> shift_y)^2
	mov ax,[di+10]					;(a >> shift_x)^2
	mul bx							;dx|ax=(a >> shift_x)^2*(b >> shift_y)^2

	;compare LHS to RHS
	pop cx							;cx|bx=LHS
	pop bx							; ..
	sub ax,bx						;dx|ax=RHS-LHS
	sbb dx,cx						; ..

	;if dx is negative dx|ax is negative, and we are not in ellipse
	cmp dx,0
	jge .inside

.outside:
	mov ax,0
	jmp .exit

.inside:
	mov ax,1

.exit:
	add sp,8
	;load saved cpu state
	pop di
	pop dx
	pop cx
	pop bx
	pop bp
	ret


;-- int get_shift(int a)
;	gets the number of units to shift right so that a^2 unsigned fits into 16
;	bits, returns the result into AX
;	this allows a greater range for a and b, while losing precision if you 
;	use too large a range
get_shift:
	push bp
	mov bp,sp
	push cx

	mov cx,0				;initialize the loop counter cx = 0
.loop:
	mov ax,[bp+4]			;a
	shr ax,cl				;divide by 2 cl times
	mul ax
	jno .exit				;if there was no overflow, (a >> cl)^2 is 16 bits
	inc cx
	jmp .loop

.exit:
	mov ax,cx

	pop cx
	pop bp
	ret


;-- int abs(int x)
;	returns the absolute value of a 16 bit integer into AX
abs:
	push bp
	mov bp,sp

	mov ax,[bp+4]
	cmp ax,0
	jge .exit

	;if x is negative return the 2's compliment
	neg ax

.exit:
	pop bp
	ret
