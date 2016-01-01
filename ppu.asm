; ===============================
; oaktree
; Waterbear framework for SNES
; (c) 2015 oaktree Novelties
;
; FILE: ppu.asm
; DESCRIPTION: PPU Macros and
; subroutines.
; ===============================
.IFNDEF PPU_S
.DEFINE PPU_S
.INCLUDE "base.inc"
.INCLUDE "ppu.inc"
.INCLUDE "dma.inc"


;============================================================================
; PPU_SetVRAMWriteParams
;
; Description: Sets the write parameters for the PPU (Register $2115).
;			   This is waterbear's first function written!
; Author: Ash
;----------------------------------------------------------------------------
; In: incOnHigh -- TRUE to increment on write of high VRAM word $2119.
;				-- FALSE to increment on write of low VRAM word $2118.
;     incRate	-- Increment rate (selectable via PPU_IncRate_xxx consts).
;----------------------------------------------------------------------------
; Modifies: A
;----------------------------------------------------------------------------
.MACRO PPU_SetVRAMWriteParams ARGS incOnHigh, incRate
	; top bit determines increment on high or low VRAM word.
	; bottom two bits determine the increment rate
	lda #( ( incOnHigh << 7 ) | incRate )
	sta PPU_PORT_SETTINGS
.ENDM

;============================================================================
; PPU_SetVRAMAddress
;
; Description: Sets the VRAM destination address of the next read/write
;			   from/to PPU_VRAM_DATA ($2118).
; Author: Ash
;----------------------------------------------------------------------------
; In: address	--	The 16-bit address to point the next VRAM operation to.
;----------------------------------------------------------------------------
; Modifies: X
;----------------------------------------------------------------------------
.MACRO PPU_SetVRAMAddress ARGS address
	ldx #address
	stx PPU_VRAM_ADDRESS
.ENDM

;============================================================================
; PPU_WriteVRAM
;
; Description: Writes to VRAM using PPU_VRAM_DATA. This function does NOT
;			   use DMA; for this, use the appropriate DMA function instead.
; Author: Ash
;----------------------------------------------------------------------------
; In: word		--	If TRUE, writes a word (16-bit) to PPU_VRAM_DATA.
;					If FALSE, writes a byte.
;	  data		--	The data to be written
;----------------------------------------------------------------------------
; Modifies: A or X depending on the value of "word".
;----------------------------------------------------------------------------
.MACRO PPU_WriteVRAM ARGS word, data
	.IF word == TRUE
		ldx #data
		stx PPU_VRAM_DATA
	.ELSE
		lda #data
		sta PPU_VRAM_DATA
	.ENDIF
.ENDM

;============================================================================
; PPU_SetScreenMode
;
; Description: Sets the screen mode and associated PPU parameters.
; Author: Ash
;----------------------------------------------------------------------------
; In: doubleTileBG1	--
;	  doubleTileBG2 --
;	  doubleTileBG3 --
;	  doubleTileBG4 --	If TRUE for each BG, the tiles are "double size"
;						16x16 tiles instead of 8x8 tiles.
;	  mode1BG3Highest -- If TRUE and MODE 1 is specified, BG3 has the highest
;						 priority. Ignored by hardware if not in MODE 1.
;	  screenMode	-- 	The selected screen mode (PPU_Mode_X)
;----------------------------------------------------------------------------
; Modifies: A
;----------------------------------------------------------------------------
.MACRO PPU_SetScreenMode ARGS screenMode, mode1BG3Highest, doubleTileBG1, doubleTileBG2, doubleTileBG3, doubleTileBG4
	lda #( ( doubleTileBG4 << 7 ) | ( doubleTileBG3 << 6 ) | ( doubleTileBG2 << 5 ) | ( doubleTileBG1 << 4 ) | ( mode1BG3Highest << 3 ) | screenMode )
	sta PPU_SCREEN_MODE
.ENDM

;============================================================================
; PPU_SetTileMapAddr
;
; Description: Sets tilemap address and size. Tilemap addresses are
; 			   computed $0400 at a time beginning at "1".
; Author: Ash
;----------------------------------------------------------------------------
; In: tileMapOrigin	--	Sets the origin address (in multiples of $0400).
;						To set the origin to its first possible value, use
;						"1".
;	  mapSize		--  Size of the map.
;	  bgPlane		--  Specify which background this tilemap applies to.
;----------------------------------------------------------------------------
; Modifies: A
;----------------------------------------------------------------------------
.MACRO	PPU_SetTileMapAddr ARGS tileMapOrigin, mapSize, bgPlane
	lda #( ( tileMapOrigin << 2 ) | mapSize )
	sta	bgPlane
.ENDM

;============================================================================
; PPU_SetCharAddr
;
; Description: Sets the origin addr of character data (the tiles themselves)
; 			   for a background layer.
; Author: Ash
;----------------------------------------------------------------------------
; In:
;----------------------------------------------------------------------------
; Modifies:
;----------------------------------------------------------------------------


;============================================================================
; PPU_LoadPalette - Macro that loads palette information into CGRAM
; Author: Ash, bazz, Neviksti, Marc
;----------------------------------------------------------------------------
; In: SRC_ADDR -- 24 bit address of source data,
;     START -- Color # to start on,
;     SIZE -- # of COLORS to copy
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: A,X
; Requires: mem/A = 8 bit, X/Y = 16 bit
;----------------------------------------------------------------------------
.MACRO PPU_LoadPalette
    lda #\2
    sta $2121       ; Start at START color
    lda #:\1        ; Using : before the parameter gets its bank.
    ldx #\1         ; Not using : gets the offset address.
    ldy #(\3 * 2)   ; 2 bytes for every color
    jsr PPU_DMAPalette
.ENDM

;============================================================================
; PPU_DMAPalette -- Load entire palette using DMA
; Author: bazz
;----------------------------------------------------------------------------
; In: A:X  -- points to the data
;      Y   -- Size of data
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: none
;----------------------------------------------------------------------------
PPU_DMAPalette:
    phb
    php         					; Preserve Registers

    stx DMA_SOURCE_ADDR_CHANNEL_0   ; Store data offset into DMA source offset
    sta DMA_SOURCE_BANK_CHANNEL_0	; Store data bank into DMA source bank
    sty DMA_XFER_SIZE_CHANNEL_0		; Store size of data block

    stz DMA_CONTROL_CHANNEL_0		; Set DMA Mode (byte, normal increment)
    lda #$22    					; Set destination register ($2122 - CGRAM Write)
    sta DMA_DESTINATION_ADDR_CHANNEL_0
    lda #DMA_CHANNEL_0				; Initiate DMA transfer
    sta DMA_START_XFER

    plp
    plb
    rts         ; return from subroutine

;============================================================================
; PPU_LoadBlockToVRAM -- Macro that simplifies calling LoadVRAM to copy data to VRAM
;----------------------------------------------------------------------------
; In: sourceAddress -- 24 bit address of source data
;     destination   -- VRAM address to write to (WORD address!!)
;     numTiles		-- number of tiles in this block
;	  bitsPerPixel	-- the BPP of each block
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: A, X, Y
;----------------------------------------------------------------------------
;LoadBlockToVRAM SRC_ADDRESS, DEST, SIZE
;   requires:  mem/A = 8 bit, X/Y = 16 bit
.MACRO PPU_LoadBlockToVRAM ARGS sourceAddress, destination, numTiles, bitsPerPixel
    lda #$80
    sta PPU_PORT_SETTINGS       			; Set VRAM transfer mode to word-access, increment by 1

    ldx #destination         				; DEST
    stx PPU_VRAM_ADDRESS	 				; $2116: Word address for accessing VRAM.
    lda #:sourceAddress      				; SRCBANK
    ldx #sourceAddress       				; SRCOFFSET
    ldy #( 8 * bitsPerPixel * numTiles )  	; SIZE
    jsr PPU_LoadVRAM
.ENDM

;============================================================================
; PPU_LoadVRAM -- Load data into VRAM
;----------------------------------------------------------------------------
; In: A:X  -- points to the data
;     Y     -- Number of bytes to copy (0 to 65535)  (assumes 16-bit index)
;----------------------------------------------------------------------------
; Out: None
;----------------------------------------------------------------------------
; Modifies: none
;----------------------------------------------------------------------------
; Notes:  Assumes VRAM address has been previously set!!
;----------------------------------------------------------------------------
PPU_LoadVRAM:
    phb
    php         ; Preserve Registers

    stx DMA_SOURCE_ADDR_CHANNEL_0   ; Store Data offset into DMA source offset
    sta DMA_SOURCE_BANK_CHANNEL_0   ; Store data Bank into DMA source bank
    sty DMA_XFER_SIZE_CHANNEL_0     ; Store size of data block

    lda #$01
    sta DMA_CONTROL_CHANNEL_0	    ; Set DMA mode (word, normal increment)
    lda #$18    					; Set the destination register (VRAM write register)
    sta DMA_DESTINATION_ADDR_CHANNEL_0
    lda #DMA_CHANNEL_0				; Initiate DMA transfer (channel 1)
    sta DMA_START_XFER

    plp         ; restore registers
    plb
    rts         ; return

.ENDIF