;beginCOM.asm wmh 2006-02-17 startup code for building a "small model" .COM file to run on PC
;
;There is no such thing as a "small model" .com file (.com files are "tiny").  However, this file provides the 
; startup code for an application which is to be constructed to run on the PC  with separate program and
; data segments but without the complexity of startup modules such as Borlands C0s.obj. Purpose of this exercise
; is to provide a simple vehicle for retargeting applications to a ROM environment such as on the P14 microprocessor board.  
;
;The application source(s) should be always written according to the 'small' model (e.g. 64K text and 64K BSS),
; then assembled/compiled to .obj files and linked to an .exe with TLINK.  *However*, the resulting .exe is not
; ready to be run on the PC or elsewhere until it is converted to a binary (e.g. .com) file by DECAP.
;
;What beginCOM.asm does is place the starting segment registers (DS,ES,SS) at a location beyond the
; (calculated) end of of the code segment, place the starting stack pointer at the end of allocated  
; memory requested in endCOM.asm, then correct the starting code segment value so that it (the code segment value)
; is consistent with the assembly-time assumption 0-offset binaries (.exe file asumption) rather than 0x100-offset
; binaries (.com file loader behavior). A different set of activities would be performed if the code was instead to 
; be targeted to the P14, e.g. we would recast the programs as beginBIN and endBIN. 

;The following must all be true:
;	1) the file beginCOM.asm exists, has been assembled by NASM to beginCOM.obj, and is linked by TLINK to the application *first*;
;   2) the file endCOM.asm exists, has been assembled by NASM to endCOM.obj, and linked by TLINK to the application *last*;
;   3) the application is written according to the 'small' model (not more than 64K of code and 64K of data)
;	4) the application's entry point has global label '_MAIN'
;	5) the application will not place *anything* in the _DATA segment (_TEXT and _BSS only are permitted). 
;	6) after linking, the applications's .exe file will be converted by DECAP to a .com file


;The sequence of segment definitions in startCOM is mandatory and determines the layout of the .exe file
; when loaded into PC memory in the order _TEXT, _DATA, _BSS as per the order below. 
;
;The 'align=' value is mandatory for each of the _TEXT, _DATA, and _BSS segments defined in this module but may
; be any value (to save space) for other following modules compiled using this module. 

;-----------definitions
extern _MAIN  		;exit this module to _MAIN defined in a 'C' 'main()' or asm .obj module, 
extern _STACKBASE	;calculated in endCOM.asm after all _BSS data allocations			
extern _CODEEND		; ""                                _TEXT code ""


;-----------code
segment _TEXT public align=1 class=CODE use16   ;Borland code segment begins, aligned to byte and using 16 bit instructions
global _cold_start		;label this, in case we ever need to restart from the beginning

;!! note -- no ORG 0x100 !!(even though this will be loaded on the PC as a .com program)

_cold_start: 			;(re)do all initializations


	;set runtime 'home' segment values
	mov ax,_BSS			;get *relative segment* value for data, stack
	mov bx,cs			;get current (.com) file code segment start
	add bx,0x10			;correct it by 0x10 paragraphs (e.g. 0x100 .com loadpoint offset)
						;bx now holds the *segment* address of the start of code as if it were an .exe file.
	add ax,bx			;now add it to the end of code offset (in paragraphs) previously calculated
	mov ds,ax			;and put the other segments at the corrected end-of-code sgement value
	mov es,ax			; ..
	mov ss,ax			;(this could be a potential problem in PC environment unless debugger is tricky enuf)
	mov sp,_STACKBASE	;_STACKBASE value is set in endCOM.asm
	and sp,0xFFFE		;  and masked here to place SP on an even boundary
	
	;bx currently holds the *segment* address of the start of code as if it were an .exe file.
	;We assume that the program was written to begin the application at cs:_MAIN, but because it was loaded
	; as a .com rather than an .exe, this entry point is actually cs:_MAIN+0x100. This by itself would
	; be ok as long as all jumps were relative, but would fail for absolute jumps and also for cs-override
	; access to data. By modifying cs to correspond to the actual entry point of the .com file at cs+0x100
	; we are repairing the damage caused when the binary was loaded 0x100 after the start of cs. 
	;do a dummy far return to the '_MAIN' to correct .com segment 'misteak'
	push bx
	push word _MAIN
	retf		;essentially 'jmp far [sp]' and clean up the stack as you leave. 

;-----------initialized data -- !!defined here, but don't put ANYTHING in the _DATA segment
segment _DATA public align=16 class=DATA use16   ;Borland nomenclature for initialized variables (in DS)	!!comment out??								

;-----------uninitialized data and stack -- !!after everything
;create a segment for program variables and stack
segment _BSS public align=16 class=BSS use16	;Borland nomenclature for uninitialized variable and stack allocations area (in ES,SS)
