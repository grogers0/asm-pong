;ball.asm - GRR - 11/23/06
;functions relating to ball position

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

%include "screen.mac"
%include "ball.mac"
%include "paddle.mac"
%include "sound.mac"

segment _BSS

global _ball_position, _ball_velocity

_ball_position:	resw 2
_ball_velocity:	resw 2

segment _TEXT

;-- void _init_ball()
;	sets the starting position and velocity
global _init_ball
_init_ball:
	push ax

	extern _paddle_position, _player_with_ball

	ds mov ax,[_player_with_ball]
	cmp ax,1
	jne .player2

.player1:

	ds mov ax,[_paddle_position]
	add ax,PADDLE_WIDTH+BALL_RADIUS-1
	ds mov [_ball_position],ax

	ds mov ax,[_paddle_position+2]
	add ax,PADDLE_HEIGHT/2
	ds mov [_ball_position+2],ax

	jmp .done

.player2:

	ds mov ax,[_paddle_position+4]
	sub ax,BALL_RADIUS-1
	ds mov [_ball_position],ax

	ds mov ax,[_paddle_position+6]
	add ax,PADDLE_HEIGHT/2
	ds mov [_ball_position+2],ax

.done:

	ds mov word [_ball_velocity],0
	ds mov word [_ball_velocity+2],0

	pop ax
	ret


;-- void _update_ball()
;	this function updates all position and velocity aspects of the ball
global _update_ball
_update_ball:
	call _update_ball_velocity
	call _update_ball_position
	ret


;-- void _update_ball_velocity()
;	this function checks collisions and updates the velocity vector of the ball
global _update_ball_velocity
_update_ball_velocity:

	;;;not implemented yet

	ret

;-- void _update_ball_position()
;	this function updates the ball position based on the velocity vector
global _update_ball_position
_update_ball_position:
	push ax
	push bx

	;update x position
	ds mov ax,[_ball_position]
	ds add ax,[_ball_velocity]
	ds mov [_ball_position],ax

	;update y position
	ds mov ax,[_ball_position+2]
	ds add ax,[_ball_velocity+2]
	ds mov [_ball_position+2],ax

	;perform collision detection on paddle 1 and update velocity accordingly
	extern _paddle_position
	ds push word [_ball_position+2]
	ds push word [_ball_position]
	ds push word [_paddle_position+2]
	ds push word [_paddle_position]
	call _collision
	add sp,8
	cmp ax,0
	je .paddle1donecoll
	;since collision with left paddle occurred, point ball to the right
	ds mov ax,[_ball_velocity]
	cmp ax,1
	je .paddle1donecoll
	;do this stuff only the first time it collides with the paddle
	extern _increase_speed
	call _increase_speed

	ds mov word [_ball_velocity],1
	extern _paddle_velocity
	ds mov ax,[_paddle_velocity]
	ds add [_ball_velocity+2],ax
	extern _play_sound
	push word SOUND_PADDLEHIT
	call _play_sound
	add sp,2
.paddle1donecoll:

	;perform collision detection on paddle 2 and update velocity accordingly
	ds push word [_ball_position+2]
	ds push word [_ball_position]
	ds push word [_paddle_position+6]
	ds push word [_paddle_position+4]
	call _collision
	add sp,8
	cmp ax,0
	je .paddle2donecoll
	;since collision with right paddle occurred, point ball to the left
	ds mov ax,[_ball_velocity]
	cmp ax,-1
	je .paddle2donecoll
	;do this stuff only the first time it collides with the paddle
	call _increase_speed

	ds mov word [_ball_velocity],-1
	ds mov ax,[_paddle_velocity+2]
	ds add [_ball_velocity+2],ax
	push word SOUND_PADDLEHIT
	call _play_sound
	add sp,2
.paddle2donecoll:


	;clip x position to the screen
	ds mov ax,[_ball_position]
	cmp ax,BALL_RADIUS
	jge .contxleft
	mov ax,BALL_RADIUS
	ds mov word [_ball_velocity],0
	ds mov word [_ball_velocity+2],0
	push word 2
	extern _win_round
	call _win_round
	push word SOUND_WINROUND
	call _play_sound
	add sp,4
.contxleft:
	cmp ax,639 - BALL_RADIUS
	jle .contxright
	mov ax,639 - BALL_RADIUS
	ds mov word [_ball_velocity],0
	ds mov word [_ball_velocity+2],0
	push word 1
	call _win_round
	push word SOUND_WINROUND	
	call _play_sound
	add sp,4
.contxright:
	ds mov [_ball_position],ax


	;bounce the ball off the top and bottom borders
	ds mov ax,[_ball_position+2]
	cmp ax,BALL_RADIUS+1
	jge .contytop
	mov ax,BALL_RADIUS+1
	mov bx,0
	ds sub bx,[_ball_velocity+2]
	ds mov [_ball_velocity+2],bx
	push word SOUND_WALLHIT
	call _play_sound
	add sp,2
.contytop:
	cmp ax,199-BALL_RADIUS-1
	jle .contybot
	mov ax,199-BALL_RADIUS-1
	mov bx,0
	ds sub bx,[_ball_velocity+2]
	ds mov [_ball_velocity+2],bx
	push word SOUND_WALLHIT
	call _play_sound
	add sp,2
.contybot:
	ds mov [_ball_position+2],ax


	pop bx
	pop ax
	ret


;-- void _draw_ball()
;	this function draws the ball on the screen
global _draw_ball
_draw_ball:
	push ax
	push bx
	push cx
	push dx

	ds mov ax,[_ball_position]
	ds mov bx,[_ball_position+2]

	;draw the ellipse for the ball
	;DrawE _ellipse, ax,bx, BALL_RADIUS, BALL_RADIUS

	;block instead of ellipse (ellipse looks ugly)
	mov cx,ax
	mov dx,bx

	sub ax,BALL_RADIUS
	sub bx,BALL_RADIUS
	add cx,BALL_RADIUS
	add dx,BALL_RADIUS

	DrawBlock ax,bx, cx,dx

	pop dx
	pop cx
	pop bx
	pop ax
	ret


;-- int _collision(int x_paddle, int y_paddle, int x_ball, int y_ball)
;	This routine detects whether a collision between a paddle and a ball occurs
;	Return Value:
;		non-zero:	collision occurred
;		zero:		collision did not occur
;	Algorithm: we assume for collision detection that the ball is represented
;		by a square, with (2*radius + 1) pixels each side.
;	For the ball to have hit the paddle, in 1-D the leftmost edge of the ball
;		must be to the left of or at the rightmost edge of the paddle.  This is
;		the same for all 4 edges, so we simply test this 1-D condition 4 
;		different times.
global _collision
_collision:
	push bp
	mov bp,sp
	push bx

	;test x bounds for right side of paddle
	mov ax,[bp+4]				;paddle x position
	add ax,PADDLE_WIDTH			;paddle width
	mov bx,[bp+8]				;ball x position
	sub bx,BALL_RADIUS			;ball width
	cmp ax,bx
	jl .nocollision

	;test x bounds for left side of paddle
	mov ax,[bp+4]				;paddle x position
	mov bx,[bp+8]				;ball x position
	add bx,BALL_RADIUS			;ball width
	inc bx						;ball width does not include starting point
	cmp ax,bx
	jg .nocollision

	;test y bounds for bottom side of paddle
	mov ax,[bp+6]				;paddle y position
	add ax,PADDLE_HEIGHT		;paddle height
	mov bx,[bp+10]				;ball y position
	sub bx,BALL_RADIUS			;ball height
	cmp ax,bx
	jl .nocollision

	;test y bounds for top side of paddle
	mov ax,[bp+6]				;paddle y position
	mov bx,[bp+10]				;ball y position
	add bx,BALL_RADIUS			;ball height
	inc bx						;ball height does not include starting point
	cmp ax,bx
	jg .nocollision


	mov ax,1
	jmp .exit

.nocollision:
	mov ax,0

.exit:
	pop bx
	pop bp
	ret
