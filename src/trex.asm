    processor 6502

    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Global Variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80

PlayerH byte
PlayerX byte
PlayerY byte

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Subroutines
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

    ldx #35                     ; 2 WSYNC consumed by PositionObjectX subroutine
.VerticalBlankLoop:
    sta WSYNC
    dex
    bne .VerticalBlankLoop

    lda #0
    stx VBLANK
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; A=X
; Y=0 : Player0
; Y=1 : Player1
; Y=2 : Missile0
; Y=3 : Missile1
; Y=4 : Ball
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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

PositionPlayerY:
    ldx #192
.Scanline:
    txa
    sec
    sbc PlayerY
    cmp PlayerH
    bcc .PrintPlayer             ;  if carry flag set then PrintPlayer
    lda #0
.PrintPlayer:
    tay
    sta WSYNC

    lda PlayerBitmap,Y
    sta GRP0

    lda PlayerColor,Y
    sta COLUP0

    dex
    bne .Scanline
    sta WSYNC
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
; Lookup Tables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
PlayerBitmap:
    byte #%00000000
    byte #%00101000
    byte #%01111000
    byte #%10111000
    byte #%10111000
    byte #%00111100
    byte #%00110000
    byte #%00111111
    byte #%00101111
    byte #%00111111

PlayerColor:
    byte #$00
    byte #$48
    byte #$48
    byte #$48
    byte #$48
    byte #$48
    byte #$48
    byte #$48
    byte #$48
    byte #$48

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
IO: 
.PlayerUp:
    lda #%00010000
    bit SWCHA
    bne .PlayerDown
    inc PlayerY

.PlayerDown:
    lda #%00100000
    bit SWCHA
    bne .PlayerLeft
    dec PlayerY

.PlayerLeft:
    lda #%01000000
    bit SWCHA
    bne .PlayerRight
    dec PlayerX
    lda #%1000
    sta REFP0

.PlayerRight:
    lda #%10000000
    bit SWCHA
    bne .PlayerNoIO
    inc PlayerX
    lda #%0
    sta REFP0

.PlayerNoIO:
    rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; App
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Start:
    CLEAN_START

    lda #10
    sta PlayerH

    lda #40
    sta PlayerX

    lda #90
    sta PlayerY

    lda #$C8                    ; NTSC green
    sta COLUBK

Main:
    jsr VerticalSync
    jsr VerticalBlank
    jsr PositionPlayerY
    jsr Overscan
    jsr IO
    jmp Main

    org $FFFC
    .word Start
    .word Start
