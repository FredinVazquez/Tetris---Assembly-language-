title "Rotación de piezas " ; Título de trabajo que se está realizando
	.model small 	; Modelo de memoria, siendo small -> 64 kb de programa y 64 kb para datos.
	.386			; Indica versión del procesador
	.stack 512		; Tamaño de segmento de stack en bytes


posicion_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm 



colorear_celda macro caracter,color,bg_color
	mov ah,09h				;preparar AH para interrupcion, opcion 09h
	mov al,caracter 		;AL = caracter a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,1				;CX = numero de veces que se imprime el caracter
							;CX es un argumento necesario para opcion 09h de int 10h
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm




.data

    arreglo_posiciones_bloques_horizontal      db  0,0,0,0
    arreglo_posiciones_bloques_vertical        db  0,0,0,0

    bl_prin_x               db      15
    bl_prin_y               db      2

    bloques_t               db  0,-1, 1,-1, 0,1
    bloques_t_1             db   0,1, 1,0, 0,-1
                                 ;-1,0, 0,-1, 1,0 
                                 ;0,1, -1,0, 0,-1
                                 ;0,-1, 1,0, 0,1
    
    color_pieza_caracter                        db      0
    color_pieza_fondo                           db      0 


    ;Valores de color para carácter
	cNegro 			equ		00h
	cAzul 			equ		01h
	cVerde 			equ 	02h
	cCyan 			equ 	03h
	cRojo 			equ 	04h
	cMagenta 		equ		05h
	cCafe 			equ 	06h
	cGrisClaro		equ		07h
	cGrisOscuro		equ		08h
	cAzulClaro		equ		09h
	cVerdeClaro		equ		0Ah
	cCyanClaro		equ		0Bh
	cRojoClaro		equ		0Ch
	cMagentaClaro	equ		0Dh
	cAmarillo 		equ		0Eh
	cBlanco 		equ		0Fh

	;Valores de color para fondo de carácter
	bgNegro 		equ		00h
	bgAzul 			equ		10h
	bgVerde 		equ 	20h
	bgCyan 			equ 	30h
	bgRojo 			equ 	40h
	bgMagenta 		equ		50h
	bgCafe 			equ 	60h
	bgGrisClaro		equ		70h
	bgGrisOscuro	equ		80h
	bgAzulClaro		equ		90h
	bgVerdeClaro	equ		0A0h
	bgCyanClaro		equ		0B0h
	bgRojoClaro		equ		0C0h
	bgMagentaClaro	equ		0D0h
	bgAmarillo 		equ		0E0h
	bgBlanco 		equ		0F0h


    temp_swap       db      0h


.code

    ROTACION proc
        lea di,[bloques_t]
		lea si,[bloques_t+1]

        mov cx,0
        loop_intercambio:
            xor ax,ax
            xor bx,bx

            mov al,[si]
            mov bl,[di]

            
            xchg al,bl
            
            cmp al,0
            
            not al
            add ax, 00000001B

            mov [si],al
            mov [di],bl

            

            add si,2
            add di,2

           
           cmp cx,2
            jz salir_ciclo
            
            inc cx
        jmp loop_intercambio

        salir_ciclo:
        
        ret
    endp


    t_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cMagentaClaro
        mov [color_pieza_fondo],bgMagentaClaro

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_t]
        add al,[bloques_t+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_t]
        sub al,[bloques_t+1]

        ; Tercer bloque
        add ah,[bloques_t+2]
        add al,[bloques_t+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_t+2]
        sub al,[bloques_t+3]

        ; Cuarto bloque
        add ah,[bloques_t+4]
        add al,[bloques_t+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_t+4]
        sub al,[bloques_t+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA
        ret
    endp


    t_figura_rot proc
        xor ax,ax
        mov [color_pieza_caracter],cMagentaClaro
        mov [color_pieza_fondo],bgMagentaClaro

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_t_1]
        add al,[bloques_t_1+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_t_1]
        sub al,[bloques_t_1+1]

        ; Tercer bloque
        add ah,[bloques_t_1+2]
        add al,[bloques_t_1+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_t_1+2]
        sub al,[bloques_t_1+3]

        ; Cuarto bloque
        add ah,[bloques_t_1+4]
        add al,[bloques_t_1+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_t_1+4]
        sub al,[bloques_t_1+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA
        ret
    endp


    DIBUJAR_PIEZA proc
    mov cx,4

    loop_proceso_dibujo:
        push cx

        push si
        push di

        ; Macro para colorear
        posicion_cursor [si],[di]	; Se va a esa posición
        colorear_celda 254,[color_pieza_caracter],[color_pieza_fondo]	; Se colorea

        pop di
        pop si

        inc di
        inc si

        pop cx
        loop loop_proceso_dibujo
    ret
    endp


    ELIMINAR_PIEZA_ANTERIOR proc
        lea di,[arreglo_posiciones_bloques_horizontal]
        lea si,[arreglo_posiciones_bloques_vertical]

        mov [color_pieza_caracter],cNegro
        mov cx,4
        loop_proceso_eliminar:
            push cx

            push si
            push di

            ; Macro para colorear
            posicion_cursor [si],[di]	; Se va a esa posición
            colorear_celda 254,[color_pieza_caracter],bgNegro	; Se colorea

            pop di
            pop si

            inc di
            inc si

            pop cx
            loop loop_proceso_eliminar

        ret
    endp



    main:
        mov ax,@data
        mov ds,ax
        mov es,ax

        mov ax,3h 	
		int 10h	

        call t_figura
        call ELIMINAR_PIEZA_ANTERIOR
        call ROTACION
        call ROTACION
        call ROTACION
        call ROTACION
        ;call ROTACION

        call t_figura



    salir:
        mov ax,4C00h
        int 21h
        end main
