.model tiny
.code
org 100h
VIDEOSEG equ 0b800h

Start:	mov ax, VIDEOSEG
	mov es, ax
	mov bx, 7c6h

	mov cx, 10

	mov al, 03h
	mov ah, 5Bh

Heart:  mov es:[bx], ax
	add bx, 2
	LOOP Heart

	mov ax, 4c00h
	int 21h

end	Start	