.model tiny
.code
org 100h

locals @@

SYMBOL                  equ 11
VIDEOSEG                equ 0b800h
COORDINATES_OF_CENTER   equ 5E6h
COLOR_STR               equ 0DBh
BEGIN_COMMAND_STR       equ 82h
SYMBOL_FRAME            equ 03h
COLOR_FRAME             equ 8Bh
TOP_STR                 equ 4A0h
BOTTOM_STR              equ 900h
NEXT_LINE               equ 160
LEFT_COLUMN             equ 720h
END_CODE                equ 4c00h
NULL_LEN_STR            equ 00h
SCAN_CODE_SHIFT         equ 036h ; Right Shift
SCAN_CODE_MINUS         equ 04ah ; Minus
CLEAN_COLOR             equ 00h
ADDRESS_INT_09H         equ 4*09h
TRS                     equ 3100h
CLEAN_SYMBOL            equ ' '
REG_COUNT               equ 13

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

Str_new                 proc
                        ;save ax in stack
                        push ax
                        ;read 60 port in al
                        in al, 60h
                        ;compare al with scancode shift
                        cmp al, SCAN_CODE_SHIFT
                        ;if == check scancode '-'
                        je  @@Draw_Screen
                        ;compare al with scancode minus
                        cmp al, SCAN_CODE_MINUS
                        ;if == clean screen
                        je  @@Clean_Screen
                        ;else do nothing
                        jmp @@Pass_To_Bios

@@Draw_Screen:
                        ;restore reg ax out of stack
                        pop ax
                        
                        ;save regs in stack
                        push ax
                        push bx
                        push cx
                        push dx
                        push si
                        push di
                        push bp
                        push ds
                        push es

                        ;bp = sp (stack pointer)
                        mov bp, sp
                        
                        ;put value regs in array
                        ;use cs for save new value
                        ;bp + i, where i - index pushed regs value. i+1 value = 16 - i, i = 0, ... , 16
                        mov ax, [bp + 16]
                        mov cs:[reg_values + 0], ax  ; ax
                        mov ax, [bp + 14]
                        mov cs:[reg_values + 2], ax  ; bx
                        mov ax, [bp + 12]
                        mov cs:[reg_values + 4], ax  ; cx
                        mov ax, [bp + 10]
                        mov cs:[reg_values + 6], ax  ; dx
                        mov ax, [bp + 8]
                        mov cs:[reg_values + 8], ax  ; si
                        mov ax, [bp + 6]
                        mov cs:[reg_values + 10], ax ; di
                        mov ax, [bp + 4]
                        mov cs:[reg_values + 12], ax ; bp

                        ;calc old sp 
                        mov ax, bp
                        ;add 24 = 12*2, 12 - point in array for reg bp (last added reg)
                        ;2 - byte takes regs (size of word)
                        add ax, 24
                        ;set reg sp
                        mov cs:[reg_values + 14], ax ; sp
                        ;set reg ds
                        mov ax, [bp + 2]
                        mov cs:[reg_values + 16], ax ; ds
                        ;set reg es
                        mov ax, [bp + 0]
                        mov cs:[reg_values + 18], ax ; es

                        ;set reg ss
                        mov ax, ss
                        mov cs:[reg_values + 20], ax ; ss

                        ;get cs and ip in int stack 
                        mov ax, [bp+20]
                        mov cs:[reg_values + 22], ax ; cs
                        mov ax, [bp+18]
                        mov cs:[reg_values + 24], ax ; ip

                        call Print_str
                        call Draw_frame

                        ;restore regs out of stack before jump in bios
                        pop es
                        pop ds
                        pop bp
                        pop di
                        pop si
                        pop dx
                        pop cx
                        pop bx
                        pop ax
                        
                        push ax ; Для @@Pass_To_Bios
                        jmp @@Pass_To_Bios

@@Clean_Screen:
                        pop ax
                        
                        push ax
                        push bx
                        push cx
                        push dx
                        push es
                        
                        call Cleaner

                        pop es
                        pop dx
                        pop cx
                        pop bx
                        pop ax
                        
                        push ax 
                        jmp @@Pass_To_Bios

@@Pass_To_Bios:
                        pop ax
                        jmp dword ptr cs:[OldKeyboardInterruptOffset]

OldKeyboardInterruptOffset   dw 0
OldKeyboardInterruptSegment  dw 0

Str_new                 endp

;==================================
Cleaner                 proc
                        mov ax, VIDEOSEG
                        mov es, ax

                        mov ah, CLEAN_COLOR   
                        mov al, CLEAN_SYMBOL

                        mov bx, TOP_STR
                        mov dx, REG_COUNT + 2   

Clean_Rows:
                        push bx
                        call Put_frame_size_horizontall ; mov cx
Clean_Cols:             
                        mov es:[bx], ax
                        add bx, 2              
                        loop Clean_Cols        

                        pop bx                 
                        add bx, NEXT_LINE 

                        dec dx
                        jnz Clean_Rows       

                        ret
Cleaner                 endp

;==================================
Get_AX                  proc
                       
                        pop cs:[Temp_Ret]
                        mov cx, 0
conv_num:
                        mov dx, 0
                        mov bx, 10
                        div bx             
                        add dl, '0'        
                        push dx            
                        inc cx
                        cmp ax, 0
                        jne conv_num

                        mov cs:[Len_Digit], cl
                        push cs:[Temp_Ret]
                        ret
Temp_Ret                dw 0
Get_AX                  endp

;==================================
Print_str               proc
                        mov ax, VIDEOSEG
                        mov es, ax

                        mov bx, TOP_STR
                        add bx, NEXT_LINE

                        mov si, offset reg_names
                        mov di, offset reg_values
                        mov cx, REG_COUNT

Print_Loop:
                        push cx
                        push bx 

                        add bx, 2 

                        mov cx, 5
                        mov ah, COLOR_STR
Print_Name:
                        mov al, cs:[si]
                        mov es:[bx], ax
                        inc si
                        add bx, 2
                        loop Print_Name

                        mov ax, cs:[di]
                        add di, 2       
                        
                        mov cs:[Saved_pos], bx
                        call Get_AX
                        
                        mov cl, cs:[Len_Digit]
                        xor ch, ch
                        mov ah, COLOR_STR
                        mov bx, cs:[Saved_pos]

Put_value:
                        pop dx
                        mov al, dl
                        mov es:[bx], ax
                        add bx, 2
                        loop Put_value

                        pop bx
                        add bx, NEXT_LINE
                        pop cx
                        loop Print_Loop

                        ret
Print_str               endp

;==================================
Draw_frame              proc
                        mov al, SYMBOL_FRAME
                        mov ah, COLOR_FRAME

                        mov bx, TOP_STR
                        call Put_frame_size_horizontall
                        call Put_symbol_horizontall

                        mov bx, TOP_STR
                        mov cx, REG_COUNT + 1
Calc_bottom:
                        add bx, NEXT_LINE
                        loop Calc_bottom
                        call Put_frame_size_horizontall
                        call Put_symbol_horizontall

                        mov bx, TOP_STR + NEXT_LINE
                        call Put_frame_size_verticall
                        call Put_symbol_verticall

                        mov bx, TOP_STR + NEXT_LINE
                        call Put_frame_size_horizontall
                        shl cx, 1
                        add bx, cx
                        sub bx, 2
                        call Put_frame_size_verticall
                        call Put_symbol_verticall

                        ret
Draw_frame              endp

;==================================
Put_symbol_horizontall  proc
@@Put_symbol:           mov es:[bx], ax
                        add bx, 2
                        loop @@Put_symbol
                        ret
Put_symbol_horizontall  endp

;==================================
Put_symbol_verticall    proc
@@Put_symbol:           mov es:[bx], ax
                        add bx, NEXT_LINE
                        loop @@Put_symbol
                        ret
Put_symbol_verticall    endp

;==================================
Put_frame_size_horizontall proc
                        mov cx, 14 
                        ret
Put_frame_size_horizontall endp

;==================================
Put_frame_size_verticall proc
                        mov cx, REG_COUNT 
                        ret
Put_frame_size_verticall endp


reg_names               db 'ax = '
                        db 'bx = '
                        db 'cx = '
                        db 'dx = '
                        db 'si = '
                        db 'di = '
                        db 'bp = '
                        db 'sp = '
                        db 'ds = '
                        db 'es = '
                        db 'ss = '
                        db 'cs = '
                        db 'ip = '

reg_values              dw REG_COUNT dup(0) 

Len_Digit               db 0
Saved_pos               dw 0

;==================================
Exit                    proc
                        mov ax, END_CODE
                        int 21h
                        ret
Exit                    endp
                        
End_of_programm:        
                        end Start
