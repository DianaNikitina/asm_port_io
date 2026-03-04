;😂😂😂😂😂
.model tiny
.code
org 100h

Start:  
        ; ES = 0000 --> zero segment contains int table
        mov ax, 0
        mov es, ax

        ; BX = 4 * 09h --> address of int 09h
        mov bx, 4 * 09h

        ; save address of int 09h
        mov ax, es:[bx]
        mov cs:[OldKeyboardInterruptOffset],  ax
        mov ax, es:[bx + 2]
        mov cs:[OldKeyboardInterruptSegment], ax
        
        ; es = segment int table
        mov ax, 0
        mov es, ax
        ; address int 09h function in int table (offset)
        mov bx, 09h*4
        ; es:[bx] = 0000:0036
        ;                |
        ;                |
        ;               \/
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
        mov ax, 3100h
        ; DX = memory to stay resident in paragraphs (= 16 bytes)
        mov dx, offset End_of_programm
        ; DX / 16
        shr dx, 4
        ; + 1 in case not dividable by 16
        inc dx
        ; DOS func int
        int 21h

Str_new proc
        push ax
        push bx
        push es

        push 0b800h
        pop es
        mov bx, (5*80 + 40) * 2
        mov ah, 4eh
        in al, 60h
        mov es:[bx], ax

        ; AL = value of 61h port (keyboard controller port)
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

        pop es
        pop bx
        pop ax
        
        ; iret ; stack -> offset+segment

        db 0eah ; jmp far old09ofs:old09seg
OldKeyboardInterruptOffset   dw 0
OldKeyboardInterruptSegment  dw 0

; old09ofs dw 0
; old09seg dw 0
        endp

End_of_programm:
end Start
