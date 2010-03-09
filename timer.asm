;timer.asm - GRR - 11/2/06
;set of functions dealing with the timer interrupt running the game loop

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

%include "keymap.mac"

%define TIMER_PORT 0x40


segment _BSS

;global these to show up in MAP file, don't expect to need them global
global old_timer_int

old_timer_int:	resd	1		;global to save the old cs:ip for int 0x08


;sets the timer count to use
timer_count:	resw 1

global _game_paused, _player_with_ball, _game_running, _first_time

_game_paused:	resw	1		;sets whether the timer interrupt does anything
_player_with_ball: resw 1		;sets who has the ball in hand
_game_running: resw 1			;sets whether the game is running, or a player has the ball in hand

_first_time: resw 1				;if this is set, pause immediately to show help

segment _TEXT


;-- void timer_int()
;	this function replaces int 0x08
timer_int:
	push ax

	;ponk sound even when paused, so it doesn't keep playing the same note
	;all the time when we are paused
	extern _sound_tick
	call _sound_tick

	;if we are paused, just exit without updating anything
	ds mov ax,[_game_paused]
	cmp ax,0
	jne .done

	;if this is the first time and we need to pause to show the help, do it
	mov ax,0
	ds cmp ax,[_first_time]
	jne .pause

	;if we have pressed Esc while active pause the game
	extern _key_status
	ds mov al,[_key_status]
	test al,KEY_ESC
	jne .pause

	extern _is_game_won
	call _is_game_won
	cmp ax,0
	jne .pause

	jmp .donepause

.pause:
	extern _pause_game

	;end the interrupt here since the key interrupt is lower priority than timer
	;and we need the key interrupt for the _pause_game function
	mov al,0x20
	out 0x20,al

	call _pause_game
	jmp .exit

.donepause:

	extern _update_paddle
	call _update_paddle

	mov ax,0
	ds cmp [_game_running],ax
	jne .update

	;see if spacebar is pressed, then set the game running
	ds mov ax,[_key_status]
	test ax,KEY_SPACEBAR
	jne .spacebar

	;init instead of update on the ball keep is locked to the players paddle
	extern _init_ball
	call _init_ball
	jmp .print

.spacebar:

	ds mov word [_game_running],1

.update:

	extern _update_ball
	call _update_ball

.print:

	extern _print_screen
	call _print_screen

.done:

	mov al,0x20
	out 0x20,al

.exit:

	pop ax
	iret							;dont chain this interrupt, don't need to


;-- void _install_timer_int()
;	install our interrupt for the timer counter
;	NOTE: ds is set by beginCOM to _BSS
global _install_timer_int
_install_timer_int:
	push es
	push dx
	push ax

	;allow timer interrupts
	ds mov word [_game_paused],0

	;save the old int 0x08 location
	mov ax,0					;segment 0 where interrupts are installed
	mov es,ax

	cli

	es mov ax,[0x08*4+2]		;interrupt table has 4 bytes per entry
	ds mov [old_timer_int+2],ax
	es mov ax,[0x08*4]
	ds mov [old_timer_int],ax

	;install the new int 0x08
	mov ax,cs
	es mov [0x08*4+2],ax
	mov ax,timer_int
	es mov [0x08*4],ax

	sti

	;set the new timer frequency
	call _reset_speed

	pop ax
	pop dx
	pop es
	ret

;-- _uninstall_timer_int()
;	uninstall our timer handler interrupt
;	NOTE: ds is set by beginCOM to _BSS
global _uninstall_timer_int
_uninstall_timer_int:
	push es
	push dx
	push ax

	;install the old int 0x08
	mov ax,0					;segment 0 where interrupts are installed
	mov es,ax

	cli

	ds mov ax,[old_timer_int+2]
	es mov [0x08*4+2],ax		;interrupt table has 4 bytes per entry
	ds mov ax,[old_timer_int]
	es mov [0x08*4],ax

	sti

	;set the old timer frequency
	mov al,0x36						;control word
	mov dx,TIMER_PORT+3
	out dx,al
	mov dx,TIMER_PORT
	;set for 18.2Hz (count from 65536 = 0x0000)
	mov al,0
	out dx,al
	out dx,al

	pop ax
	pop dx
	pop es
	ret

;-- void set_speed()
;	function to set the timer counter to the module variable timer_count
set_speed:
	push ax
	push dx

	mov al,0x36						;control word
	mov dx,TIMER_PORT+3
	out dx,al
	mov dx,TIMER_PORT

	ds mov ax,[timer_count]

	out dx,al
	mov al,ah
	out dx,al

	pop dx
	pop ax
	ret

;-- void _reset_speed()
;	function to reset the timer to 100Hz, the default speed
global _reset_speed
_reset_speed:
	push ax
	push dx

	ds mov word [timer_count],0x2e9c

	call set_speed

	pop dx
	pop ax
	ret

;-- void _increase_speed()
;	increase the speed of the timer by 1 tick
global _increase_speed
_increase_speed:
	;ret

	push ax

	ds mov ax,[timer_count]
	cmp ax,0x400			;if the count is below 400, dont make any faster
	jle .continue

	sub ax,0x400
.continue:
	ds mov [timer_count],ax

	call set_speed

	pop ax
	ret
