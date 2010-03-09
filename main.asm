;main.asm - GRR - 11/2/06
;main program loop

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

segment _BSS

global _quit_now
_quit_now:	resw	1

segment _TEXT

;press a,z and rightshift,enter to move the positions of the paddles, esc to exit
global _main
_main:
	;get and save starting video mode
	mov ah,0x0f	  		   ;BIOS 'Get video mode' -- result in ah
	int 0x10			   ; ..
	push ax			   	   ;and save for later restoration

	mov ax,0x0006	;initialize PC video screen so we can write directly to it (someday)
	int 0x10		;..

	mov ax,0xB800	;0xB800 is the beginning of the segment controlling  the
	mov es,ax		;-video display, keep it in the 'extra' segment register

	ds mov word [_quit_now],0

	extern _install_key_int
	call _install_key_int

	call _set_first_time

	call _new_game

	extern _install_timer_int
	call _install_timer_int

	extern _init_sound
	call _init_sound

.loop:
	ds mov ax,[_quit_now]
	cmp al,0
	je .loop

	extern _uninstall_timer_int
	call _uninstall_timer_int

	extern _uninstall_key_int
	call _uninstall_key_int

	;restore the startup video mode (see note)
	pop ax	 	 		 	    ;original video mode in al
	mov ah,0					; should restore screen configuration (but not contents)
	int 0x10

	mov ax,0x4C00				;DOS terminate process function (4C) with exit code 0
	int 0x21


;-- void _new_game()
;	resets the game and clears the score
global _new_game
_new_game:
	push word 1
	call _reset_round
	add sp,2

	extern _init_score
	call _init_score
	
	ret


;-- void _reset_round(int player_has_ball)
;	resets the game and gives player "player_has_ball" the ball but does
;	not clear the score
global _reset_round
_reset_round:
	push bp
	mov bp,sp
	push ax

	extern _init_paddle, _init_ball, _game_running, _player_with_ball, _reset_speed

	ds mov word [_game_running],0
	mov ax,[bp+4]
	ds mov [_player_with_ball],ax

	call _init_paddle
	call _init_ball
	call _reset_speed

	pop ax
	pop bp
	ret

;-- void _set_first_time()
;	sets that we should pause immediately regardless of having pressed Esc
global _set_first_time
_set_first_time:
	extern _first_time
	ds mov word [_first_time],1
	ret
