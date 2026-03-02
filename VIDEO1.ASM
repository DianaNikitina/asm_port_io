.model tiny
.code
org 100h
VIDEOSEG equ 0b800h

Start:	mov ax, VIDEOSEG
	mov es, ax
	mov bx, 7C6h
	
	mov al, '*'
	mov ah, 4eh
	mov cx, 10

L:	mov es:[bx], ax
	add bx, 2
	LOOP L

	mov ax, 4c00h
	int 21h
end	Start	