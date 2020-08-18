    processor 6502

    include "vcs.h"
    include "macro.h"

    seg.u Variables
    org $80
PlayerH byte
PlayerX byte
PlayerY byte

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
    jsr PositionPlayerX
    lda #2
    sta VBLANK

    ldx #37
VerticalBlankLoop:
    sta WSYNC
    dex
    bne VerticalBlankLoop

    lda #0
    stx VBLANK
    rts

PositionPlayerX: 
    lda PlayerX
    and #%01111111              ; forces positive result

    sta WSYNC
    sta HMCLR                   ; clear X

    sec
PositionPlayerXLoop:
    sbc #15
    bcs PositionPlayerXLoop     ; getting modulo to A register

    eor #7
    asl                         ; HMP0 uses only 4 bits
    asl
    asl
    asl
    sta HMP0                    ; set fine position
    sta RESP0                   ; reset 15-step position
    sta WSYNC
    sta HMOVE                   ; apply fine position offset
    rts

Kernel:
    ldx #192
Scanline:
    txa
    sec
    sbc PlayerY
    cmp PlayerH
    bcc PrintPlayer             ;  if carry flag set then PrintPlayer
    lda #0
PrintPlayer:
    tay
    sta WSYNC

    lda PlayerBitmap,Y
    sta GRP0

    lda PlayerColor,Y
    sta COLUP0

    dex
    bne Scanline
    sta WSYNC
    rts

Overscan:
    lda #2
    sta VBLANK

    ldx #30
OverscanLoop:
    sta WSYNC
    dex
    bne OverscanLoop

    lda #0
    sta VBLANK
    rts

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

Start:
    CLEAN_START

    lda #10
    sta PlayerH

    lda #60
    sta PlayerX

    lda #90
    sta PlayerY

    lda #$C8                    ; NTSC green
    sta COLUBK

Main:
    jsr VerticalSync
    jsr VerticalBlank
    jsr Kernel
    jsr Overscan
    jmp Main

    org $FFFC
    .word Start
    .word Start
