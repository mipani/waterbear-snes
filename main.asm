;== Include memorymap, header info, and SNES initialization routines
.INCLUDE "header.inc"
.INCLUDE "InitSNES.asm"
.INCLUDE "debug.inc"
.INCLUDE "system.inc"
.INCLUDE "memory.inc"

.BANK 0
.ORG 0
.SECTION "MainCode"

Start:
        InitSNES            ; Init Snes :)

				Stage_VBlank VBlank_Dynamic_Demo

				lda #%10000000
				sta $4200				; enable the vblank

main:
        jmp main

;==============================================================================
; MAX 2270 cycles.
; Push and pop anything you're going to fuck up.
VBlank:
	pha
	php
	phb

	Set_A_16Bit
	lda VBlankFunctionPointer.w
	cmp #$0000
	beq VBlank_Exit

Handler:
	; Branch to this function pointer as a subroutine, then clear out the pointer.
	; It's up to you to "jmp VBlank_Finally" when you're all done.
	jmp (VBlankFunctionPointer)

VBlank_Finally:
	; After a function is called, set it to null so it doesn't get called again on next VBlank.
	Set_A_16Bit
	lda.w #$0000
	sta VBlankFunctionPointer.w ; Rip this shit down on the way out

VBlank_Exit:
	plb
	plp
	pla
  RTI
;==============================================================================

;==============================================================================
; load $DEAD to $0010 as a demo of vblank dynamic dispatch
VBlank_Dynamic_Demo:
	lda #$0BB0
	sta VBlankDemoDestination1.w
	jmp VBlank_Finally

.ENDS

; stuff we'll revisit later
.BANK 1
.ORG 0
.SECTION "Data"

; 2bpp

TileData:
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $FF, $00, $FF, $FF, $00, $FF, $FF, $FF, $FF, $FF, $00, $00, $FF, $00, $FF

Palette:
    .db $00, $00, $1F, $42, $E0, $7F, $FF, $7F

; alternate reality game/story aspects for adventerous ROM-hacking players
.DB "biologiscan EGER 1993 by <author> <version>"
.DB "Copyright (c) Corvis Simulation Systems. All rights reserved.",0
.DB "Corvis Arcadia Information-Specific Life Extension "
.DB "This Arcadia unit was compiled on 1993-03-20 09:23:57 GMT",0
.DB "License Key",0
.DB "License Information",0
.DB "Enter your Corvis Arcadia license key below.",0
.DB "Simulation inaccessible without license key.",0
.DB "Arcadia world D E B U G",0
.DB "1b09696d-2672-41af-b2da-14b6893c3ebe",0
.DB "Participant Franklin O. Holmes",0
.DB "MRI + CAT upload",0
.DB "up/1993-03-10 dob/1963-05-17 dod/1993-03-11",0
.DB "backup taken?",0
.DB "cause of death: adenocarcinoma [IV] dx. early 1992",0
.DB "YES",0
.DB "NO",0
.DB "Corvis ISLE Explorers - Group VI",0
.DB "Welcome to %s",0
.INCBIN "corvis.txt"
.DB "group 6 notes: "
.DB "Elkington, a town with 50 other ISLE explorers. "
.DB $34 $42 $52 $00 $01 $33 $22
.DB "the simulation well but so far, he has not adapted well"
.DB 7,7,"very upset and reports a 'blood-curdling scream' "
.DB "when the control deck is"
.ENDS
