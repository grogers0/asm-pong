;pause.asm - GRR - 11/21/06
;this module pauses to show the scoreboard

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

%include "keymap.mac"
%include "screen.mac"


;-- void _pause_game()
;	pauses the game and shows the score. Asks whether to start new game or
;	continue
global _pause_game
_pause_game:
	push ax
	push bx
	push cx
	push es
	push di

	;stop the game loop from triggering
	extern _game_paused
	ds mov word [_game_paused],1

	;re-enable interrupts (so keyboard input works)
	sti

	;set es to the video display
	mov ax,0xb800
	mov es,ax

	;clear the screen
	mov ax,0
	mov cx,0x2000
	mov di,0
	rep stosw

	;print the score
	cs mov cx,[score_str_len]
	mov di,0
	mov bx,0
	mov ah,0
.scorestr:
	cs mov al,[score_str+bx]
	PutChar ax,di,0
	add di,8
	inc bx
	loop .scorestr

	;player 1
	cs mov cx,[player_str_len]
	mov di,0
	mov bx,0
.player1str:
	cs mov al,[player1_str+bx]
	PutChar ax,di,8
	add di,8
	inc bx
	loop .player1str

	;print player 1's numerical score
	extern _score
	ds mov bx,[_score]
	push word 8
	push word di
	push word bx
	call print_num
	add sp,6

	;player 2
	cs mov cx,[player_str_len]
	mov di,0
	mov bx,0
.player2str:
	cs mov al,[player2_str+bx]
	PutChar ax,di,16
	add di,8
	inc bx
	loop .player2str

	;print player 2's numerical score
	ds mov bx,[_score+2]
	push word 16
	push word di
	push word bx
	call print_num
	add sp,6

	;display a help message
	cs mov cx,[help_str_len]
	mov di,0
	mov bx,0
.helpstr:
	cs mov al,[help_str+bx]
	PutChar ax,di,32
	add di,8
	inc bx
	loop .helpstr

	;display a second help message
	cs mov cx,[help_str2_len]
	mov di,0
	mov bx,0
.helpstr2:
	cs mov al,[help_str2+bx]
	PutChar ax,di,48
	add di,8
	inc bx
	loop .helpstr2

	;display a third help message
	cs mov cx,[help_str3_len]
	mov di,0
	mov bx,0
.helpstr3:
	cs mov al,[help_str3+bx]
	PutChar ax,di,56
	add di,8
	inc bx
	loop .helpstr3

	;display a fourth help message
	cs mov cx,[help_str4_len]
	mov di,0
	mov bx,0
.helpstr4:
	cs mov al,[help_str4+bx]
	PutChar ax,di,64
	add di,8
	inc bx
	loop .helpstr4


	;if game has been won (and not esc pressed) dont wait for esc unpress
	extern _is_game_won
	call _is_game_won
	cmp ax,0
	jne .getkey

	;if this is the first time, we show the help, dont wait for esc unpress
	extern _first_time
	mov ax,0
	ds cmp ax,[_first_time]
	je .escunpress

	;if this is the first time through, set that it is now not the first time
	ds mov word [_first_time],0

	;wait for Esc to be unpressed
	extern _key_status
.escunpress:
	ds mov al,[_key_status]
	test al,KEY_ESC
	jne .escunpress

.getkey:
	;wait for a key we want to look at is pressed
	ds mov al,[_key_status]

	test al,KEY_ESC				;highest priority if we want to quit
	jne .escpressed
	test al,KEY_N				;newgame is next highest priority
	jne .npressed
	test al,KEY_SPACEBAR		;continue game is lowest priority
	jne .spacebarpressed

	jmp .getkey

.escpressed:
	;wait for esc to be unpressed before registering, this way we won't record
	;the key down the next time as a pause instead of quitting
	ds mov al,[_key_status]
	test al,KEY_ESC
	jne .escpressed

	;after we are done waiting, tell the main process to quit
	extern _quit_now
	ds mov word [_quit_now],1
	jmp .exit

.npressed:
	;start a new game
	extern _new_game
	call _new_game

	jmp .exit

.spacebarpressed:
	;wait for space to be unpressed to continue
	ds mov al,[_key_status]
	test al,KEY_SPACEBAR
	jne .spacebarpressed

	jmp .exit

.exit:

	;disable interrupts (going back to the timer int)
	cli

	;allow the game loop to trigger
	ds mov word [_game_paused],0

	pop di
	pop es
	pop cx
	pop bx
	pop ax
	ret

score_str:		db "---Scores---"
score_str_len:	dw (score_str_len-score_str)

player1_str:	db "Player1:"
player2_str:	db "Player2:"
player_str_len: dw (player_str_len-player2_str)

help_str:		db "Press (Spacebar) to continue, press (N) for new game, press (Esc) to quit..."
help_str_len:	dw (help_str_len-help_str)

help_str2:		db "When in game, press (Esc) to pause and return to this screen,"
help_str2_len:	dw (help_str2_len-help_str2)

help_str3:		db "(Spacebar) launches the ball, (A) and (Z) control player 1,"
help_str3_len:	dw (help_str3_len-help_str3)

help_str4:		db "(Right Shift) and (Enter) control player 2."
help_str4_len:	dw (help_str4_len-help_str4)


;-- void print_num(int num, int x, int y)
;	print the number "num" starting at pixel (x,y) across the screen
;	NOTE: we are ignoring scores over 100 (the game will probably be to 7 anyways)
print_num:
	push bp
	mov bp,sp
	push ax
	push bx


	mov ax,[bp+4]
	mov bl,100
	div bl
	mov al,ah
	mov ah,0
	mov bl,10
	div bl
	;put the 10's place in ax, 1's place in bx
	mov bl,ah
	mov bh,0
	mov ah,0

	;print the 10's place from ax
	add ax,'0'			;add in the offset for '0', to convert to ascii
	PutChar ax, [bp+6],[bp+8]

	;print the 1's place from
	add bx,'0'
	mov ax,[bp+6]
	add ax,8
	PutChar bx, ax,[bp+8]

	pop bx
	pop ax
	pop bp
	ret
