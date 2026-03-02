.model tiny
.code 
org 100h
VIDEOSEG equ 0b800h

Start: 	mov ax,VIDEOSEG
	mov es, ax
	mov bx, 0
	mov si, 82h
	mov cx, 10
	
L:	mov al, ds: [si]
	mov ah, 4eh
	add si, 1
	add bx, 2

	mov es:[bx], ax
	LOOP L

	mov ax, 4c00h
	int 21h
end	Start	 