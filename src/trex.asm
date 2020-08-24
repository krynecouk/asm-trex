    processor 6502

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Global Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

PlayerX byte
PlayerY byte
PlayerH byte
PlayerSpritePtr word
PlayerColorsPtr word
PlayerAnimOffset byte
PlayerAnimCounter byte
PlayerAnimSpeed byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Subroutines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg code
    org $F000

VerticalSync:
    lda #2
    sta VSYNC
    sta WSYNC
    sta WSYNC
    sta WSYNC
    lda #0
    sta VSYNC
    rts

VerticalBlank:
    ldy #0
    lda PlayerX
    and #%01111111              ; forces positive result
    jsr PositionObjectX
    lda #2
    sta VBLANK
    ldx #34                     ; 3 WSYNC consumed by PositionObjectX subroutine
.VerticalBlankLoop:
    sta WSYNC
    dex
    bne .VerticalBlankLoop
    lda #0
    stx VBLANK
    rts

;; A is a x-coordinate
;; Y is the object type (0:Player0, 1:,layer1, 2:Missile0, 3:Missile1, 4:Ball)
PositionObjectX:
    sta WSYNC
    sec                         ; set carry = 1
.DivideLoop:
    sbc #15
    bcs .DivideLoop             ; if carry is cleared (borrowed) then skip the jump
    eor #%0111
    asl                         ; HMP0 uses only 4 bits most significant bits
    asl
    asl
    asl
    sta HMP0,Y                  ; set fine position
    sta RESP0,Y                 ; reset 15-step position
    sta WSYNC
    sta HMOVE                   ; apply fine position offset
    rts

PrintScanlines:                 ; 2-line kernel
    ldx #96
.Scanline:
    txa
    sec
    sbc PlayerY
    cmp PlayerH
    bcc .PrintPlayer             ;  if carry flag set then PrintPlayer
    lda #0
.PrintPlayer:
    clc
    adc PlayerAnimOffset
    tay
    sta WSYNC
    sta WSYNC
    lda (PlayerSpritePtr),Y
    sta GRP0
    lda (PlayerColorsPtr),Y
    sta COLUP0
    lda #%101
    sta NUSIZ0
    dex
    bne .Scanline
    sta WSYNC
    rts

AnimateRun:
    lda PlayerAnimCounter
    and PlayerAnimSpeed
    beq .break                  ; branch on zero result
    lda #0
    sta PlayerAnimCounter
    lda PlayerH
    adc PlayerH
    cmp PlayerAnimOffset
    bne .Frame1
    jsr .Frame0
    rts
.Frame0:
    lda PlayerH
    sta PlayerAnimOffset
    rts
.Frame1:
    clc
    lda PlayerH
    adc PlayerH
    sta PlayerAnimOffset
    rts
.break:
    inc PlayerAnimCounter
    rts

Overscan:
    lda #2
    sta VBLANK
    ldx #30
.OverscanLoop:
    sta WSYNC
    dex
    bne .OverscanLoop
    lda #0
    sta VBLANK
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup Tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Bitmaps
PlayerFrame
    .byte #%00000000            ;%00
    .byte #%00010100            ;$26
    .byte #%00011100            ;$26
    .byte #%00111100            ;$26
    .byte #%01011100            ;$26
    .byte #%00011100            ;$26
    .byte #%00011111            ;$26
    .byte #%00010111            ;$44
    .byte #%00011111            ;$26
PlayerRunFrame0
    .byte #%00000000            ;%00
    .byte #%00010000            ;$26
    .byte #%00011100            ;$26
    .byte #%01111100            ;$26
    .byte #%00011100            ;$26
    .byte #%00011000            ;$26
    .byte #%00011111            ;$26
    .byte #%00010111            ;$44
    .byte #%00011111            ;$26
PlayerRunFrame1
    .byte #%00000000            ;%00
    .byte #%00000100            ;$26
    .byte #%00011100            ;$26
    .byte #%00111100            ;$26
    .byte #%01011100            ;$26
    .byte #%00011000            ;$26
    .byte #%00011111            ;$26
    .byte #%00010111            ;$44
    .byte #%00011111            ;$26

;; Colors
PlayerColors
    .byte #$00
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
PlayerRunColors0
    .byte #$00
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
PlayerRunColors1
    .byte #$00
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26
    .byte #$26

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; IO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IO:
.PlayerUp:
    lda #%00010000
    bit SWCHA
    bne .PlayerDown
    inc PlayerY
    jsr AnimateRun
    rts

.PlayerDown:
    lda #%00100000
    bit SWCHA
    bne .PlayerLeft
    dec PlayerY
    jsr AnimateRun
    rts

.PlayerLeft:
    lda #%01000000
    bit SWCHA
    bne .PlayerRight
    dec PlayerX
    lda #%1000
    sta REFP0
    jsr AnimateRun
    rts

.PlayerRight:
    lda #%10000000
    bit SWCHA
    bne .PlayerNoIO
    inc PlayerX
    lda #%0
    sta REFP0
    jsr AnimateRun
    rts

.PlayerNoIO:
    lda #0
    sta PlayerAnimOffset
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; App
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Start:
    CLEAN_START

    lda #40
    sta PlayerX

    lda #40
    sta PlayerY

    lda #9
    sta PlayerH

    lda #$C8                    ; NTSC green
    sta COLUBK

    lda #<PlayerFrame
    sta PlayerSpritePtr
    lda #>PlayerFrame
    sta PlayerSpritePtr + 1

    lda #<PlayerColors
    sta PlayerColorsPtr
    lda #>PlayerColors
    sta PlayerColorsPtr + 1

    lda #0
    sta PlayerAnimOffset

    lda #8
    sta PlayerAnimSpeed
    sta PlayerAnimCounter

Main:
    jsr VerticalSync
    jsr VerticalBlank
    jsr PrintScanlines
    jsr Overscan
    jsr IO
    jmp Main

    org $FFFC
    word Start
    word Start
