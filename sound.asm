;sound.asm - GRR - 11/1/06
;this module houses the speaker sound for pong

%include "sound.mac"

segment _BSS public align=16 class=BSS use16
segment _TEXT public align=1 class=CODE use16

segment _BSS

sound_done:		resw 1			;sets whether a sound is done playing or not
active_sound:	resw 1			;sets the currently playing sound by ID
sound_count:	resw 1			;counter for time for current note
sound_note:		resw 1			;note in the sound
sound_length:	resw 1			;length of the currently playing sound
sound_begin:	resw 1			;pointer to the beginning of the current sound

segment _TEXT

;-- void _init_sound()
;	initializes sound global variables
global _init_sound
_init_sound:
	ds mov word [sound_done],0

	ret

;-- void _play_sound(int id)
;	function to play a sound.  Adjust the sounds attributes by changing
;	the values in the ponk_data array and recompiling. select the sound by its
;	"ID".  For ID use the macros defined in sound.mac
global _play_sound
_play_sound:
	push bp
	mov bp,sp
	push ax
	push bx

	cli					;prevent interrupts

	call speaker_on		;turning the speaker on before we write the pitch
						;prevents it from not actually turning on the first time
						;we play a sound

	;set the sound to play as the currently playing sound
	mov bx,[bp+4]
	ds mov [active_sound],bx

	;set the length of the currently playing sound
	shl bx,1							;multiply by two for bytes in a word
	cs mov ax,[sound_length_table+bx]	;sound_length_table is an array of data
	ds mov [sound_length],ax

	;set the pointer to the start of the current data
	cs mov bx,[sound_data_table+bx]		;sound_data_table is an array of pointer
	ds mov [sound_begin],bx
	
	;set the pitch for the first note, next notes will be updated automatically
	;set the pitch based on ID
	cs push word [bx]
	call set_pitch
	add sp,2

	;reset the count and the note data
	ds mov word [sound_count],0
	ds mov word [sound_note],0
	ds mov word [sound_done],0

.exit:
	sti					;turn interrupts back on
	pop bx
	pop ax
	pop bp
	ret


;-- void _sound_tick()
;	this function is called on the timer interrupt (with cli on) and updates the
;	note and pitch of the current sound if necessary.
global _sound_tick
_sound_tick:
	push ax
	push bx
	push cx
	push si
	
	;if the sound is done, don't have anything to update so exit
	mov ax,0
	ds cmp [sound_done],ax
	jne .exit

.stepcount:
	ds inc word [sound_count]

	ds mov bx,[sound_begin]
	ds mov si,[sound_note]
	mov cl,2
	shl si,cl
	cs mov ax,[bx+si+2]				;delay data is at [begin + note*4 + 2]

	ds cmp ax,[sound_count]
	jne .exit

.stepnote:
	ds mov word [sound_count],0		;reset count
	ds inc word [sound_note]

	ds mov ax,[sound_length]
	ds cmp [sound_note],ax
	je .donesound

	;set the speaker to the new note
	ds mov bx,[sound_begin]
	ds mov si,[sound_note]
	mov cl,2
	shl si,cl
	cs push word [bx+si]			;sound data is at [begin + note*4]
	call set_pitch
	add sp,2
	jmp .exit

.donesound:
	ds mov word [sound_done],1		;tell everyone that the ponk sound is done
	call speaker_off

.exit:
	pop si
	pop cx
	pop bx
	pop ax
	ret

;---stored data arrays---

;this table is an array that stores the length of each sound in number of notes
sound_length_table:
	dw (data_winround.end - data_winround)/4
	dw (data_paddlehit.end - data_paddlehit)/4
	dw (data_wallhit.end - data_wallhit)/4
.end

;this table is an array that stores the addresses of the start of each array
;of data. (an array of pointers to arrays of data)
sound_data_table:
	dw data_winround
	dw data_paddlehit
	dw data_wallhit
.end

data_winround:
	dw	1300,10
	dw	1500,10
	dw	1700,10
	dw	2000,10
.end

data_paddlehit:
	dw 1500,10
.end

data_wallhit:
	dw 1000,10
.end


;-- void speaker_on()
;	turns the speaker on
speaker_on:
	push ax

	in al,0x61
	or al,0x03
	out 0x61,al

	pop ax
	ret


;-- void speaker_off()
;	turns the speaker off
speaker_off:
	push ax

	in al,0x61
	and al,0xfc
	out 0x61,al

	pop ax
	ret


;-- void set_pitch(int pitch)
;	set the pitch of a currently playing sound.  pitch = 1.91 MHz / freq
set_pitch:
	push bp
	mov bp,sp
	push ax

	;set the speaker pitch
	mov al,0xb6
	out 0x43,al
	mov ax,[bp+4]
	out 0x42,al
	mov al,ah
	out 0x42,al

	pop ax
	pop bp
	ret


