;==============================================================================
; WaterBear SNES Development Kit
;
; FILE: ppu.asm
; DESCRIPTION: PPU-specific routines and constants
; (c) 2016-2017 Neon Dragon Enterprises (ne0ndrag0n)
;==============================================================================
.IFNDEF PPU
.DEFINE PPU

.DEFINE     DisplayOptions      $2100
.DEFINE     PaletteSelection    $2121
.DEFINE     PaletteData         $2122

.DEFINE     DMAEnableChannels   $420B

.DEFINE     DMAControl_0        $4300
.DEFINE     DMADestination_0    $4301
.DEFINE     DMASource_0         $4302
.DEFINE     DMASourceBank_0     $4304
.DEFINE     DMAXferSize_0       $4305

;==============================================================================
; Load palette into CGRAM. Begins by setting up required crap
; Modifies: A, X, and Y
; Mode: 8-bit A, 16-bit X and Y
;==============================================================================
.MACRO LoadPalette ARGS SrcAddr, Start, Size
  lda #Start
  sta PaletteSelection      ; Begin at this colour number

  lda #:SrcAddr             ; Load bank into A
  ldx #SrcAddr              ; Load address into X
  ldy #( Size * 2 )         ; Each colour is 2 bytes

  jsr LoadDMAPalette
.ENDM

;==============================================================================
; Load display options
; Modifies: A
; Mode: 8-bit A
;==============================================================================
.MACRO lda_DisplayOptions ARGS disabled, brightness
  lda #( ( disabled << 7 ) | brightness )
.ENDM

.ENDIF

.BANK 0
.ORG 0
.SECTION "PPUMethods" SEMIFREE

;==============================================================================
; Load entire palette using DMA
; Arguments:
; A - Bank of source data
; X - Address of source data
; Y - Size of data
;==============================================================================
LoadDMAPalette:
  phb
  php

  sta DMASourceBank_0
  stx DMASource_0
  sty DMAXferSize_0               ; Submit all our source parameters to the DMA registers

  stz DMAControl_0                ; CPU to PPU, Auto-Increment, 1 address write-twice

  lda #( PaletteData & $00FF )
  sta DMADestination_0            ; Destination register is $2122, with the $21 assumed

  lda #%00000001
  sta DMAEnableChannels           ; Send the data to DMA Channel 0

  plp
  plb
  rts

.ENDS
