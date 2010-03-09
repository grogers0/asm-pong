;score.asm - GRR - 11/23/06
;	functions to keep track of the score

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

;the score to play to
%define WIN_LIMIT 7

segment _BSS

global _score
_score:	resw 2

segment _TEXT


;-- void _init_score()
;	resets the score to 0-0
global _init_score
_init_score:
	ds mov word [_score],0
	ds mov word [_score+2],0
	ret


;-- void _win_round(int player)
;	function to win the round for player "player"
;	this increments player's score and gives them the ball.
global _win_round
_win_round:
	push bp
	mov bp,sp
	push ax

	mov ax,[bp+4]

	push word ax
	extern _reset_round
	call _reset_round
	add sp,2

	cmp ax,1
	jne .player2

.player1:
	ds inc word [_score]
	jmp .exit

.player2:
	ds inc word [_score+2]

.exit:
	pop ax
	pop bp
	ret


;-- int _is_game_won()
;	function to check if anyone has reached a high enough score to win the game
global _is_game_won
_is_game_won:
	ds mov ax,[_score]
	cmp ax,WIN_LIMIT
	je .gameover

	ds mov ax,[_score+2]
	cmp ax,WIN_LIMIT
	je .gameover

.notover:
	mov ax,0
	jmp .exit

.gameover:
	mov ax,1

.exit:
	ret
