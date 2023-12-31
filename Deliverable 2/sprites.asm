  .inesprg 1   ; 1x 16KB PRG code
  .ineschr 1   ; 1x  8KB CHR data
  .inesmap 0   ; mapper 0 = NROM, no bank swapping
  .inesmir 1   ; background mirroring
  

;;;;;;;;;;;;;;;

    
  .bank 0
  .org $C000 
RESET:
  SEI          ; disable IRQs
  CLD          ; disable decimal mode
  LDX #$40
  STX $4017    ; disable APU frame IRQ
  LDX #$FF
  TXS          ; Set up stack
  INX          ; now X = 0
  STX $2000    ; disable NMI
  STX $2001    ; disable rendering
  STX $4010    ; disable DMC IRQs

vblankwait1:       ; First wait for vblank to make sure PPU is ready
  BIT $2002
  BPL vblankwait1

clrmem:
  LDA #$00
  STA $0000, x
  STA $0100, x
  STA $0300, x
  STA $0400, x
  STA $0500, x
  STA $0600, x
  STA $0700, x
  LDA #$FE
  STA $0200, x    ;move all sprites off screen
  INX
  BNE clrmem
   
vblankwait2:      ; Second wait for vblank, PPU is ready after this
  BIT $2002
  BPL vblankwait2



; ************** NEW CODE ****************
LoadPalettes:
  LDA $2002    ; read PPU status to reset the high/low latch
  LDA #$3F
  STA $2006    ; write the high byte of $3F00 address
  LDA #$00
  STA $2006    ; write the low byte of $3F00 address
  LDX #$00
LoadPalettesLoop:
  LDA palette, x        ;load palette byte
  STA $2007             ;write to PPU
  INX                   ;set index to next byte
  CPX #$20            
  BNE LoadPalettesLoop  ;if x = $20, 32 bytes copied, all done


LoadSprites:

  LDX #$00              ; start at 0

LoadSpritesLoop:

  LDA sprites, x        ; load data from address (sprites + x)
  STA $0200, x          ; store into RAM address ($0200 + x)
  INX                   ; X = X + 1
  CPX #$60              ; Compare X to hex $10, decimal 16
  BNE LoadSpritesLoop   ; Branch to LoadSpritesLoop if compare was Not Equal to zero

                        ; if compare was equal to 16, continue down

  LDA #%10000000
  STA $2000

  LDA #%00010000   ; enable sprites
  STA $2001

Forever:
  JMP Forever     ;jump back to Forever, infinite loop
  
 

NMI:
  LDA #$00
  STA $2003  ; set the low byte (00) of the RAM address
  LDA #$02
  STA $4014  ; set the high byte (02) of the RAM address, start the transfer
  
  RTI        ; return from interrupt
 
;;;;;;;;;;;;;;  
  
  
  
  .bank 1
  .org $E000
palette:
  .db $0F,$31,$32,$33,$0F,$35,$36,$37,$0F,$39,$3A,$3B,$0F,$3D,$3E,$0F
  .db $0F,$1C,$15,$14,$0F,$02,$38,$3C,$0F,$1C,$15,$14,$0F,$02,$38,$3C

sprites:

     ;vert tile attr horiz

 
  ; Standing
  .db $70, $11, $00, $80   ;sprite 0
  .db $70, $12, $00, $88   ;sprite 1
  .db $78, $21, $00, $80   ;sprite 0
  .db $78, $22, $00, $88   ;sprite 1
  ; Walk
  .db $80, $13, $00, $80   ;sprite 0
  .db $80, $14, $00, $88   ;sprite 1
  .db $88, $23, $00, $80   ;sprite 2
  .db $88, $24, $00, $88   ;sprite 3
  ;jump
  .db $90, $15, $00, $80   ;sprite 0
  .db $90, $16, $00, $88   ;sprite 1
  .db $98, $25, $00, $80   ;sprite 2
  .db $98, $26, $00, $88   ;sprite 3
  
  
  .db $70, $17, $00, $A0   ;sprite 0
  .db $70, $18, $00, $A8   ;sprite 1
  .db $78, $27, $00, $A0   ;sprite 2
  .db $78, $28, $00, $A8   ;sprite 3
  
    ; Standing
  .db $70, $12, $40, $90   ;sprite 0
  .db $70, $11, $40, $98   ;sprite 1
  .db $78, $22, $40, $90   ;sprite 0
  .db $78, $21, $40, $98   ;sprite 1
  ; Walk
  .db $80, $14, $40, $90   ;sprite 0
  .db $80, $13, $40, $98   ;sprite 1
  .db $88, $24, $40, $90   ;sprite 2
  .db $88, $23, $40, $98   ;sprite 3
  ;jump
  .db $90, $16, $40, $90   ;sprite 0
  .db $90, $15, $40, $98   ;sprite 1
  .db $98, $26, $40, $90   ;sprite 2
  .db $98, $25, $40, $98   ;sprite 3
  
  .db $90, $17, $40, $A0   ;sprite 0
  .db $90, $18, $40, $A8   ;sprite 1'
  .db $98, $27, $40, $A0   ;sprite 2
  .db $98, $28, $40, $A8   ;sprite 3
  
  
  .org $FFFA     ;first of the three vectors starts here
  .dw NMI        ;when an NMI happens (once per frame if enabled) the 
                   ;processor will jump to the label NMI:
  .dw RESET      ;when the processor first turns on or is reset, it will jump
                   ;to the label RESET:
  .dw 0          ;external interrupt IRQ is not used in this tutorial
  
  
;;;;;;;;;;;;;;  
  
  
  .bank 2
  .org $0000
  .incbin "pain.chr"   ;includes 8KB graphics file from SMB1