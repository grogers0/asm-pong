;screen.asm - GRR - 10/25/06
;	functions to print the pong board

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16


extern _write_pixel
%include "screen.mac"


global _print_screen
_print_screen:
	push ax
	push bx
	push cx
	push es

	;clear the data in _IMAGE
	extern _IMAGE
	ClearImage _BSS,_IMAGE

	;draw the new data into _IMAGE
	mov bx,ds					;set es to _BSS, draw to _IMAGE
	mov ax,_IMAGE
	mov cl,4					;shr 4 == divide by 16
	shr ax,cl
	add bx,ax					;add the _IMAGE offset to _BSS, keep in mind
	mov es,bx					;_BSS is align=16 so this is okay

	call draw_field				;draw the field to the image segment

	extern _draw_paddles
	call _draw_paddles

	extern _draw_ball
	call _draw_ball

	;draw the finished image from _IMAGE to the screen
	push word _IMAGE
	push word _BSS
	extern _Copy_to_display
	call _Copy_to_display
	add sp,4

	pop es
	pop cx
	pop bx
	pop ax
	ret



;-- void draw_field()
;	function to display the "field", ie. the top and bottom border, and the net
draw_field:

	;draw the top and bottom borders
	DrawBlock 0,0, 639,0
	DrawBlock 0,199, 639,199

	;draw the net as 6 dashes equally spaced
	%assign n_dashes 6
	%assign i 0
	%rep n_dashes
		DrawBlock 640/2,(200*i)/(n_dashes*2-1), 640/2,(200*(i+1))/(n_dashes*2-1)
		%assign i i+2
	%endrep

	ret

