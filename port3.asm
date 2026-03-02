.model tiny
.data

        
        reg_ax   db 'ax = ', '$'
        reg_bx   db 'bx = ', '$'
        reg_cx   db 'cx = ', '$'
        reg_dx   db 'dx = ', '$'
        reg_si   db 'si = ', '$'
        reg_di   db 'di = ', '$'
        reg_bp   db 'bp = ', '$'
        reg_sp   db 'sp = ', '$'
        reg_ds   db 'ds = ', '$'
        reg_es   db 'es = ', '$'
        reg_ss   db 'ss = ', '$'
        reg_cs   db 'cs = ', '$'
        reg_ip   db 'ip = ', '$'

.code
org 100h

END_CODE    equ 4c00h
SYMBOL      equ 03h

Start:      
            call Main
            call Exit

Main        proc

            mov ah, 09h
            mov dx, offset reg_ax               ;print str: "reg_ax = "
            int 21h

            mov ax, SYMBOL
            call PrintAX

            ret 
            endp

;print ax value
;ax = ax / 10 , dx = ax % 10
;dl = ax % 10 + '0' = '0' - '9'
;dx -> stack; cx = len_number
PrintAX     proc
            push ax
            push bx
            push cx
            push dx

            mov cx, 0          

conv_num:
            mov dx, 0
            mov bx, 10
            div bx             ; ax = ax / 10, dx = ax % 10
            add dl, '0'        ; ax % 10 + '0'
            push dx            ; -> stack
            inc cx
            cmp ax, 0
            jne conv_num

print_char:
            pop dx             ; DL = num
            mov ah, 02h        ; print char
            int 21h
            loop print_char

            pop dx
            pop cx
            pop bx
            pop ax
            ret
            endp


Exit        proc

            mov ax, END_CODE
            int 21h

            ret
            endp
             
end         Start
