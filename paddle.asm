;paddle.asm - GRR - 11/2/06
;set of functions dealing with the position and velocity of the paddle

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

%include "keymap.mac"
%include "paddle.mac"
%include "screen.mac"

;declare _paddle information global
global _paddle_position, _paddle_velocity

;global these to show up in MAP file, don't expect to need them global
global _paddle_intent

segment _BSS

_paddle_position:	resw 4			;x1,y1, x2,y2
_paddle_velocity:	resw 2			;v_y1, v_y2
_paddle_intent:		resw 2			;u/d1, u/d2

segment _TEXT

;-- void _init_paddle()
;	sets the starting position and velocity
global _init_paddle
_init_paddle:
	;initialize paddle 1 position
	ds mov word [_paddle_position],0
	ds mov word [_paddle_position+2],200/2 - PADDLE_HEIGHT/2

	;initialize paddle 2 position
	ds mov word [_paddle_position+4],639-PADDLE_WIDTH
	ds mov word [_paddle_position+6],200/2 - PADDLE_HEIGHT/2

	;initialize paddle 1 and 2 velocity
	ds mov word [_paddle_velocity],0
	ds mov word [_paddle_velocity+2],0

	ret


;-- void _update_paddle()
;	this function updates all position and velocity aspects of each paddle
global _update_paddle
_update_paddle:
	call _update_paddle_intent
	call _update_paddle_velocity
	call _update_paddle_position
	ret


;-- void _update_paddle_intent()
;	this function reads the keys pressed down and sets whether the intent was
;	to move each paddle up, down, or stationary.
;	values in _paddle_intent:
;		-1:	move paddle up
;		0:	keep paddle still
;		1:	move paddle down
global _update_paddle_intent
_update_paddle_intent:
	push ax
	push bx

	extern _key_status
	ds mov al,[_key_status]

	;check paddle 1's intent from A and Z keys
	mov bx,0
	test al,KEY_A
	je .contA
	dec bx
.contA:
	test al,KEY_Z
	je .contZ
	inc bx
.contZ:
	ds mov [_paddle_intent],bx

	;check paddle 2's intent from RIGHTSHIFT and ENTER keys
	mov bx,0
	test al,KEY_ENTER
	je .contENTER
	dec bx
.contENTER:
	test al,KEY_RIGHTSHIFT
	je .contRIGHTSHIFT
	inc bx
.contRIGHTSHIFT:
	ds mov [_paddle_intent+2],bx

	pop bx
	pop ax
	ret


;-- void _update_paddle_velocity()
;	this function checks _paddle_intent and sets the y velocity of the paddles
global _update_paddle_velocity
_update_paddle_velocity:
	push ax

	;NOTE: no paddle acceleration, intent = velocity

	;paddle 1
	ds mov ax,[_paddle_intent]
	ds mov [_paddle_velocity],ax

	;paddle 2
	ds mov ax,[_paddle_intent+2]
	ds mov [_paddle_velocity+2],ax

	pop ax
	ret


;-- void _update_paddle_position()
;	this function updates the paddle positions based on each paddles velocity
;	given in pixels/frame and clips them to the edge of the playing field
global _update_paddle_position
_update_paddle_position:
	push ax

	;update paddle 1's y position based on velocity
	ds mov ax,[_paddle_position+2]
	ds add ax,[_paddle_velocity]

	;clip paddle 1's position to the screen borders
	cmp ax,1
	jge .cont1top
	mov ax,1
	ds mov word [_paddle_velocity],0
.cont1top:
	cmp ax,199 - PADDLE_HEIGHT - 1
	jle .cont1bot
	mov ax,199 - PADDLE_HEIGHT - 1
	ds mov word [_paddle_velocity],0
.cont1bot:
	ds mov [_paddle_position+2],ax

	;update paddle 2's y position based on velocity
	ds mov ax,[_paddle_position+6]
	ds add ax,[_paddle_velocity+2]

	;clip paddle 2's position to the screen borders
	cmp ax,1
	jge .cont2top
	mov ax,1
	ds mov word [_paddle_velocity+2],0
.cont2top:
	cmp ax,199 - PADDLE_HEIGHT - 1
	jle .cont2bot
	mov ax,199 - PADDLE_HEIGHT - 1
	ds mov word [_paddle_velocity+2],0
.cont2bot:
	ds mov [_paddle_position+6],ax

	pop ax
	ret


;-- void _draw_paddles()
;	function to draw the paddles to the CGA screen at es
global _draw_paddles
_draw_paddles:
	push ax
	push bx

	;display paddle 1
	ds mov word ax,[_paddle_position+2]
	ds mov word bx,[_paddle_position]
	push ax
	push bx
	add ax,PADDLE_HEIGHT
	push ax
	add bx,PADDLE_WIDTH
	push bx

	extern _block
	call _block
	add sp,8

	;display paddle 2
	ds mov word ax,[_paddle_position+6]
	ds mov word bx,[_paddle_position+4]
	push ax
	push bx
	add ax,PADDLE_HEIGHT
	push ax
	add bx,PADDLE_WIDTH
	push bx

	extern _block
	call _block
	add sp,8

	pop bx
	pop ax
	ret
