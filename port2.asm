.model tiny
.code
org 100h

Start:  mov ax, 3509h
        int 21h
        mov cs:old09ofs, bx
        mov bx, es
        mov cs:old09seg, bx

        push 0
        pop es

        cli
        mov bx, 09h*4
        mov word ptr es:[bx], offset Str_new
        mov word ptr es:[bx+2], cs
        sti

        mov ax, 3100h
        mov dx, (offset End_of_programm - offset Start + 15) / 16 + 10h
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

        in al, 61h
        or al, 80h
        out 61h, al
        and al, not 80h
        out 61h, al

        mov al, 20h
        out 20h, al

        pop es
        pop bx
        pop ax
        
        db 0eah  
old09ofs dw 0
old09seg dw 0
Str_new endp

End_of_programm:
end Start
