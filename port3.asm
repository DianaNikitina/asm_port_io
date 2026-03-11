.model tiny
.data


;array      
        reg_ax      db 'ax = '
        LEN_AX      equ $ - reg_ax
        reg_bx      db 'bx = ', '$'
        reg_cx      db 'cx = ', '$'
        reg_dx      db 'dx = ', '$'
        reg_si      db 'si = ', '$'
        reg_di      db 'di = ', '$'
        reg_bp      db 'bp = ', '$'
        reg_sp      db 'sp = ', '$'
        reg_ds      db 'ds = ', '$'
        reg_es      db 'es = ', '$'
        reg_ss      db 'ss = ', '$'
        reg_cs      db 'cs = ', '$'
        reg_ip      db 'ip = ', '$'
        Len_Digit   db 0



.code
org 100h


locals @@


SYMBOL                  equ 11
VIDEOSEG                equ 0b800h
COORDINATES_OF_CENTER   equ 7C6h
COLOR_STR               equ 0DBh
BEGIN_COMMAND_STR       equ 82h
SYMBOL_FRAME            equ 03h
COLOR_FRAME             equ 8Bh
TOP_STR                 equ 680h
BOTTOM_STR              equ 900h
NEXT_LINE               equ 160
LEFT_COLUMN             equ 720h
END_CODE                equ 4c00h
NULL_LEN_STR            equ 00h
SCAN_CODE_SHIFT         equ 036h
SCAN_CODE_MINUS         equ 04ah
CLEAN_COLOR             equ 00h
ADDRESS_INT_09H         equ 4*09h
TRS                     equ 3100h
CLEAN_SYMBOL            equ ' '

Start:      
                        ; ES = 0000 --> zero segment contains int table
                        mov ax, 0
                        mov es, ax


                        ; BX = 4 * 09h --> address of int 09h
                        mov bx, ADDRESS_INT_09H


                        ; save address of int 09h
                        mov ax, es:[bx]
                        mov cs:[OldKeyboardInterruptOffset],  ax
                        mov ax, es:[bx + 2]
                        mov cs:[OldKeyboardInterruptSegment], ax
                        
                        ; es = segment int table
                        mov ax, 0
                        mov es, ax
                        ; address int 09h function in int table (offset)
                        mov bx, ADDRESS_INT_09H
                        ; es:[bx] = 0000:0036
                        ;                |
                        ;                |
                        ;               \/
                        ;[][][][][][][][0012:5288][][][][][][]
                        ;[][][][][][][][offset Str_new, cs][][][][][][]


                        ; cs:[offset Str_new] = address of our function


                        ; clear interrupt flag --> prohibit interruptions
                        cli
                        ; es = 0000
                        ;[][][][][][][][0012:5288][][][][][][]
                        mov word ptr es:[bx], offset Str_new
                        ;[][][][][][][][offset Str_new, 5288][][][][][][]
                        ; <---------------------- can not interrupt
                        ; cs = code segment
                        mov word ptr es:[bx + 2], cs
                        ;[][][][][][][][offset Str_new, cs][][][][][][]
                        ; set interrupt flag --> allow interruptions
                        sti


                        ; TSR = terminate and stay resident
                        mov ax, TRS
                        ; DX = memory to stay resident in paragraphs (= 16 bytes)
                        mov dx, offset End_of_programm
                        ; DX / 16
                        shr dx, 4
                        ; + 1 in case not dividable by 16
                        inc dx
                        ; DOS func int
                        int 21h


Str_new                 proc

                        ;push regs in stack to save value
                        push ax
                        push bx
                        push cx
                        push dx
                        push si
                        push di
                        push ds
                        push es

                        ;read 60 port in al
                        in al, 60h
                        ;compare al with scancode shift 
                        cmp al, SCAN_CODE_SHIFT
                        ;if != check scancode '-'
                        jne Check_cleaner
                        ;call func print ax =
                        call Print_str
                        ;call func draw frame
                        call Draw_frame
                        ;jump label exit_code
                        jmp Exit_code

                        ;compare al with scancode '-'
Check_cleaner:          cmp al, SCAN_CODE_MINUS
                        ;if != jump label exit_code
                        jne Exit_code
                        ;else call func to clean screen
                        call Cleaner

Exit_code:              ; AL = value of 61h port (keyboard controller port)
                        in al, 61h
                        ; 80h = 1000 0000b
                        ; set first AL bit to 1 (1st bit == 1 ==> disable keyboard)
                        or al, 80h
                        ; value of 61h port = AL (keyboard controller port)
                        out 61h, al
                        ; AL = 0111 1111b = 7fh
                        ; set first AL bit to 0 (1st bit == 0 ==> enable keyboard)
                        and al, not 80h
                        ; value of 61h port = AL (keyboard controller port)
                        out 61h, al


                        ; 20h - signal End of Interrupt
                        mov al, 20h ; 0010 0000
                        ; out --> write al in port 20h
                        ; port 20h = Interrupt Controller port
                        out 20h, al


                        pop  es
                        pop  ds
                        pop  di
                        pop  si
                        pop  dx
                        pop  cx
                        pop  bx
                        pop  ax
                        
                        ; iret ; stack -> offset+segment


                        db 0eah ; jmp far old09ofs:old09seg
                        OldKeyboardInterruptOffset   dw 0
                        OldKeyboardInterruptSegment  dw 0


                        ; old09ofs dw 0
                        ; old09seg dw 0
Str_new                 endp


                        ret
                        endp
;==================================
Cleaner                 proc
                        push ax
                        push bx
                        push cx
                        push dx

                        mov ax, VIDEOSEG
                        mov es, ax

                        ; ' ' on black bg
                        mov ah, CLEAN_COLOR   
                        mov al, CLEAN_SYMBOL

                        ;top line of frame 
                        mov bx, TOP_STR

                        ;quantities str
                        mov dx, 6              

Clean_Rows:
                        ;len str frame
                        mov cl, LEN_AX
                        ;add len value ax
                        add cl, cs:[Len_Digit] 
                        add cl, 6
                        ;ch = 0              
                        xor ch, ch

                        ;start current str
                        push bx             

Clean_Cols:             ;put ' '
                        mov es:[bx], ax
                        ;bias (1 byte - symbol, 2 bytes - color)      
                        add bx, 2              
                        LOOP Clean_Cols        

                        ;next str
                        pop bx                 
                        add bx, NEXT_LINE 

                        ;reduce counter_str
                        dec dx
                        ;if != 0 clean next str                 
                        jnz Clean_Rows       

                        pop dx
                        pop cx
                        pop bx
                        pop ax
                        ret
Cleaner                 endp

;==================================
;print ax value
;di - save top stack
;ax = ax / 10 , dx = ax % 10
;dl = ax % 10 + '0' = '0' - '9'
;dx -> stack; cx = len_number, cl = Len_Digit
Get_AX                  proc


                        pop di

                        mov cx, 0
conv_num:
                        mov dx, 0
                        mov bx, 10
                        div bx             ; ax = ax / 10, dx = ax % 10
                        add dl, '0'        ; ax % 10 + '0'
                        push dx            ; -> stack
                        inc cx
                        cmp ax, 0
                        jne conv_num


                        mov [Len_Digit], cl
                        
                        push di

                        ret
                        endp
;==================================
;save bx in global variable - Saved_pos
;bx - coord
Print_str               proc


                        mov ax, VIDEOSEG
                        mov es, ax


                        mov bx, COORDINATES_OF_CENTER
                        
                        mov si, offset reg_ax
                        mov ah, COLOR_STR
                        mov cx, LEN_AX


Print_str_ax:           mov al, cs: [si]
                        mov es:[bx], ax
                        inc si
                        add bx, 2                   ; bias (1 byte - symbol, 2 bytes - color)
                        LOOP Print_str_ax


                        mov [Saved_pos], bx


                        call Get_AX


                        mov cx, word ptr [Len_Digit]
                        xor ch, ch
                        mov ah, COLOR_STR


                        mov bx, [Saved_pos]


Put_value_ax:           pop dx
                        mov al, dl
                        mov es: [bx], ax
                        add bx, 2                   ; bias (1 byte - symbol, 2 bytes - color)
                        LOOP Put_value_ax


                        mov [Saved_pos], bx         


                        ret
                        endp


;==================================
;call 2 times - Put_frame_size_horizontall, Put_symbol_horizontall
;call 2 times - Put_frame_size_verticall, Put_symbol_verticall
Draw_frame              proc


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
                        add bx, 4                   ;bias for beautiful frame
                        sub bx, NEXT_LINE                 
                        call Put_frame_size_verticall
                        call Put_symbol_verticall


                        ret
                        endp


;==================================
;draw horizontall line                                                                                                                                                                                                                         ; :))))))))) ( (C) sasha)
Put_symbol_horizontall  proc


@@Put_symbol:           mov es:[bx], ax
                        add bx, 2
                        LOOP @@Put_symbol


                        ret
                        endp


;==================================
;draw verticall line
Put_symbol_verticall    proc


@@Put_symbol:           mov es:[bx], ax
                        add bx, NEXT_LINE
                        LOOP @@Put_symbol


                        ret
                        endp


;==================================
;cl - size of horizontall line
Put_frame_size_horizontall proc


                        add cl, LEN_AX
                        add cl, [Len_Digit]
                        add cl, 6                  ;bias for beautiful frame


                        ret
                        endp


;==================================
;cl - size of verticall line
Put_frame_size_verticall proc


                        add cl, 3                   ;height frame
                        xor ch, ch


                        ret
                        endp


Saved_pos dw 0


;==================================
Exit                    proc


                        mov ax, END_CODE
                        int 21h


                        ret
                        endp
                        
End_of_programm:                        
end                     Start

