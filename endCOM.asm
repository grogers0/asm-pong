;endCOM.asm wmh 2006-02-17 finishing up code for building (small model) .exe file to run on PC
;Purpose of this module is to identify the end of code and to create a stack allocation for a small model exe file.
;The .obj code from this module should be placed last on the tlink .obj module list.

;-----------code
segment _TEXT public align=1 class=CODE use16   ;Borland code segment begins
;this is linked last, so this is point is just beyond the end of code in TEXT
global _CODEEND
_CODEEND:					;value of this label is used to calculate code segment allocation/data segment start for startup code

;-----------uninitialized data and stack -- !!last, after everything
segment _BSS public align=16 class=BSS use16  ;Borland nomenclature for uninitialized variable and stack allocations area (in ES,SS)
;this is linked last, so this point is just beyond the end of other variable which may have been defined in BSS

global _IMAGE	
_IMAGE:			resb 0x4000	;create the 'drawing area' where the image to be displayed will be composed

stacklimit:		resb 0x400	;reserve an 'adequate' stack area (!!error possible if this produces BSS greater than 64k)			
global _STACKBASE			;will be used to initialize sp in startup code (!!mask it there to guarantee even boundary for SP)
_STACKBASE:		


