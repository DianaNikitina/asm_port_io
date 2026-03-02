.model tiny
.code
org 100h

locals @@

VIDEOSEG                equ 0b800h
COORDINATES_OF_CENTER   equ 7C6h
LEN_STR                 equ 80h
COLOR_STR               equ 0DBh
BEGIN_COMMAND_STR       equ 82h
SYMBOL_FRAME            equ 03h
COLOR_FRAME             equ 8Bh
TOP_STR                 equ 680h
BOTTOM_STR              equ 900h
NEXT_LINE               equ 160
LEFT_COLUMN             equ 720h
END_CODE                equ 4c00h
NULL_LEN_STR            equ 00h


Start:                  call Main
                        call Exit

;==================================
;call func for print entering str 
;call func for drawing frame
Main                    proc

                        call Print_str

                        call Draw_frame
                        
                        ret
                        endp       

;==================================
;save bx in global variable - Saved_pos
Print_str               proc

                        mov ax, VIDEOSEG
                        mov es, ax

                        mov bx, COORDINATES_OF_CENTER

                        mov cl, ds: [LEN_STR]
                        cmp cl, NULL_LEN_STR
                        JNE @@Early_end
                        call Exit


@@Early_end:              sub cl, 1                   ; without \n
                        xor ch, ch

                        mov si, BEGIN_COMMAND_STR
                        mov ah, COLOR_STR

Put_str:                mov al, ds: [si]
                        inc si

                        mov es: [bx], ax
                        add bx, 2                   ; bias (1 byte - symbol, 2 bytes - color)
                        LOOP Put_str

                        mov [Saved_pos], bx         

                        ret
                        endp

;==================================
;call 2 times - Put_frame_size_horizontall, Put_symbol_horizontall
;call 2 times - Put_frame_size_verticall, Put_symbol_verticall
Draw_frame                proc

                        mov al, SYMBOL_FRAME
                        mov ah, COLOR_FRAME

                        mov bx, TOP_STR
                        call Put_frame_size_horizontall
                        call Put_symbol_horizontall

                        mov bx, BOTTOM_STR
                        call Put_frame_size_horizontall
                        call Put_symbol_horizontall

                        mov bx, LEFT_COLUMN
                        call Put_frame_size_verticall
                        call Put_symbol_verticall

                        mov bx, [Saved_pos]
                        add bx, 4                   ;bias for beautiful frame
                        sub bx, NEXT_LINE                 
                        call Put_frame_size_verticall
                        call Put_symbol_verticall

                        ret
                        endp

;==================================
;draw horizontall line                                                                                                                                                                                                                         ; :))))))))) ( (C) sasha)
Put_symbol_horizontall  proc

@@Put_symbol:           mov es:[bx], ax
                        add bx, 2
                        LOOP @@Put_symbol

                        ret
                        endp

;==================================
;draw verticall line
Put_symbol_verticall    proc

@@Put_symbol:            mov es:[bx], ax
                        add bx, NEXT_LINE
                        LOOP @@Put_symbol

                        ret
                        endp

;==================================
;cl - size of horizontall line
Put_frame_size_horizontall proc

                        mov cl, ds: [LEN_STR]
                        add cl, 5                  ;bias for beautiful frame
                        xor ch, ch

                        ret
                        endp

;==================================
;cl - size of verticall line
Put_frame_size_verticall proc

                        add cl, 3                   ;height frame
                        xor ch, ch

                        ret
                        endp

Saved_pos dw 0
;==================================
Exit                    proc

                        mov ax, END_CODE
                        int 21h
                    
                        ret
                        endp


end     Start