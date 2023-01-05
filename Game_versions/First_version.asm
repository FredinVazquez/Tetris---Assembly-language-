title "Test 1: Diferentes piezas aleatorias " ; Título de trabajo que se está realizando
	.model small 	; Modelo de memoria, siendo small -> 64 kb de programa y 64 kb para datos.
	.386			; Indica versión del procesador
	.stack 512		; Tamaño de segmento de stack en bytes



;------------
;-- Macros --
;------------
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



oculta_cursor_teclado	macro
	mov ah,01h 		;Opcion 01h
	mov cx,2607h 	;Parametro necesario para ocultar cursor
	int 10h 		;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm



apaga_cursor_parpadeo	macro
	mov ax,1003h 		;Opcion 1003h
	xor bl,bl 			;BL = 0, parámetro para int 10h opción 1003h
  	int 10h 			;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm



posiciona_cursor_mouse	macro columna,renglon
	mov dx,renglon
	mov cx,columna
	mov ax,4		;opcion 0004h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm



muestra_cursor_mouse	macro
	mov ax,1		;opcion 0001h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm


; Macro usada para obtener la posición original en la que se encuentra actualmente el bloque principal de la figura a utilizar
colocar_bl_principal    macro       ; Devuelve ah (horizontal), al (vertical)
    xor ax,ax
    mov ah,[bl_prin_x]
    mov al,[bl_prin_y]
    add ah,[posicion_pieza_caida_horizontal]
    add al,[posicion_pieza_caida_vertical]
endm




; Macro usada para limpiar la matriz de colisiones



;-----------------------------------------------------
;-- Diferentes datos que se usarán para el programa -- 
;-----------------------------------------------------

.data
    string_1    db      "Hola$"
    string_2    db      10,10,"Adios$"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bloque principal para cada figura ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    bl_prin_x     db      15
    bl_prin_y     db      2

    inicio_pieza_x      db       15
    inicio_pieza_y      db       2


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bloques para el marco del juego ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Valor ASCII de caracteres para el marco del programa
marcoEsqInfIzq 		equ 	200d 	;'╚'
marcoEsqInfDer 		equ 	188d	;'╝'
marcoEsqSupDer 		equ 	187d	;'╗'
marcoEsqSupIzq 		equ 	201d 	;'╔'
marcoCruceVerSup	equ		203d	;'╦'
marcoCruceHorDer	equ 	185d 	;'╣'
marcoCruceVerInf	equ		202d	;'╩'
marcoCruceHorIzq	equ 	204d 	;'╠'
marcoCruce 			equ		206d	;'╬'
marcoHor 			equ 	205d 	;'═'
marcoVer 			equ 	186d 	;'║'

;Data
hiscore_ren	 	equ 	10
hiscore_col 	equ 	lim_derecho+7
level_ren	 	equ 	12
level_col 		equ 	lim_derecho+7
lines_ren	 	equ 	14
lines_col 		equ 	lim_derecho+7

;Botón STOP
stop_col 		equ 	lim_derecho+15
stop_ren 		equ 	lim_inferior-4
stop_izq 		equ 	stop_col
stop_der 		equ 	stop_col+2
stop_sup 		equ 	stop_ren
stop_inf 		equ 	stop_ren+2

;Botón PAUSE
pause_col 		equ 	lim_derecho+25
pause_ren 		equ 	lim_inferior-4
pause_izq 		equ 	pause_col
pause_der 		equ 	pause_col+2
pause_sup 		equ 	pause_ren
pause_inf 		equ 	pause_ren+2

;Botón PLAY
play_col 		equ 	lim_derecho+35
play_ren 		equ 	lim_inferior-4
play_izq 		equ 	play_col
play_der 		equ 	play_col+2
play_sup 		equ 	play_ren
play_inf 		equ 	play_ren+2


col_aux 		db 		0
ren_aux 		db 		0
lim_superior 	equ		1
lim_inferior 	equ		23
lim_izquierdo 	equ		1
lim_derecho 	equ		30


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Bloques de para formar figuras ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

                               ; (x,y)
    bloques_cuadrado        db   0,-1, -1,-1, -1,0
    bloques_s_normal        db   -1,0, 0,-1, 1,-1
    bloques_s_invertido     db   0,-1, -1,-1, 1,0
    bloques_linea           db   0,-1, 0,1, 0,2
    bloques_t               db   -1,0, 0,1, 1,0
    bloques_L               db   0,-1, 0,1, 1,1
    bloques_L_invertida     db   0,-1, 1,-1, 0,1

    ; Reiniciando en caso de una rotación
    original_cuadrado        db   0,-1, -1,-1, -1,0
    original_s_normal        db   -1,0, 0,-1, 1,-1
    original_s_invertido     db   0,-1, -1,-1, 1,0
    original_linea           db   0,-1, 0,1, 0,2
    original_t               db   -1,0, 0,1, 1,0
    original_L               db   0,-1, 0,1, 1,1
    original_L_invertida     db   0,-1, 1,-1, 0,1

    contador_rotar           db   0


; ID de figuras
    id_cuadrado     db  0
    id_s_normal     db  1
    id_s_invertido  db  2
    id_linea        db  3
    id_t            db  4
    id_L            db  5
    id_L_invertida  db  6 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Arreglo de posiciones ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    arreglo_posiciones_bloques_horizontal      db  0,0,0,0
    arreglo_posiciones_bloques_vertical        db  0,0,0,0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables para definir el color de la piza ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    color_pieza_caracter                        db      0
    color_pieza_fondo                           db      0 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Colores usados para las piezas ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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



;;;;;;;;;;;;;;;;;;;;;;;
;; Caída de la pieza ;;
;;;;;;;;;;;;;;;;;;;;;;;
    posicion_pieza_caida_horizontal db 0h
    posicion_pieza_caida_vertical   db 0h


;;;;;;;;;;;;;;;;;;;;;;;
;; Elección de pieza ;;
;;;;;;;;;;;;;;;;;;;;;;;
    numero_aleatorio                db 0h
    

;;;;;;;;;;;;;;;;
;; Colisiones ;;
;;;;;;;;;;;;;;;;
    matriz_colisiones           db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db      1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db      1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db      1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1
                                db		30 dup(1)


	posicion_colision 			dw  	0

    limite_inferior             db      21
    limite_derecho              db      30  
    limite_izq                  db      1

    bool_colision               db      0 ; -> Valor general
    
    bool_col_inferior           db      0
    bool_col_izq                db      0
    bool_col_der                db      0


    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Eliminación de filas ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    fila                        db      0
    crenglones                      db 0h
    cfilas                      db 0h
    posicion                    db 0h


.code

; Procedimiento para delay
    DELAY_PROC proc
        xor di,di
        mov di,0FFFFh
        paso1:  
            mov cx,15
        paso2:
            loop paso2
        dec di
        jnz paso1
        ret 
    endp

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Procedimientos para formas figuras ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-----------------------
;-- Sección para dibujar las piezas y eliminar la pieza anterior
;-----------------------

; Agregar posición de cada pieza al arreglo para la dibujar

; 1. Cuadrado
    cuadrado_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cRojo
        mov [color_pieza_fondo],bgRojo

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]


; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_cuadrado]
        add al,[bloques_cuadrado+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_cuadrado]
        sub al,[bloques_cuadrado+1]

        ; Tercer bloque
        add ah,[bloques_cuadrado+2]
        add al,[bloques_cuadrado+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_cuadrado+2]
        sub al,[bloques_cuadrado+3]

        ; Cuarto bloque
        add ah,[bloques_cuadrado+4]
        add al,[bloques_cuadrado+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_cuadrado+4]
        sub al,[bloques_cuadrado+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA 
        ret
    endp

; 2. S normal
    s_normal_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cGrisClaro
        mov [color_pieza_fondo],bgGrisClaro

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_s_normal]
        add al,[bloques_s_normal+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_s_normal]
        sub al,[bloques_s_normal+1]

        ; Tercer bloque
        add ah,[bloques_s_normal+2]
        add al,[bloques_s_normal+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_s_normal+2]
        sub al,[bloques_s_normal+3]

        ; Cuarto bloque
        add ah,[bloques_s_normal+4]
        add al,[bloques_s_normal+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_s_normal+4]
        sub al,[bloques_s_normal+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA 
        ret
    endp


; 3. S invertida
    s_invertida_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cRojoClaro
        mov [color_pieza_fondo],bgRojoClaro

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_s_invertido]
        add al,[bloques_s_invertido+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_s_invertido]
        sub al,[bloques_s_invertido+1]

        ; Tercer bloque
        add ah,[bloques_s_invertido+2]
        add al,[bloques_s_invertido+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_s_invertido+2]
        sub al,[bloques_s_invertido+3]

        ; Cuarto bloque
        add ah,[bloques_s_invertido+4]
        add al,[bloques_s_invertido+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_s_invertido+4]
        sub al,[bloques_s_invertido+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA 
        ret
    endp


; 4. Linea
    linea_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cVerde
        mov [color_pieza_fondo],bgVerde

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_linea]
        add al,[bloques_linea+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_linea]
        sub al,[bloques_linea+1]

        ; Tercer bloque
        add ah,[bloques_linea+2]
        add al,[bloques_linea+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_linea+2]
        sub al,[bloques_linea+3]

        ; Cuarto bloque
        add ah,[bloques_linea+4]
        add al,[bloques_linea+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_linea+4]
        sub al,[bloques_linea+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA
        ret
    endp


; 5. T
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
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
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


; 6. L
    L_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cAzulClaro
        mov [color_pieza_fondo],bgAzulClaro

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_L]
        add al,[bloques_L+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_L]
        sub al,[bloques_L+1]

        ; Tercer bloque
        add ah,[bloques_L+2]
        add al,[bloques_L+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_L+2]
        sub al,[bloques_L+3]

        ; Cuarto bloque
        add ah,[bloques_L+4]
        add al,[bloques_L+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_L+4]
        sub al,[bloques_L+5]

        ; Procedimiento para dibujar la pieza una vez obtenido las posiciones
        call DIBUJAR_PIEZA
        ret
    endp



; 7. L invertida
    L_invertida_figura proc
        xor ax,ax
        mov [color_pieza_caracter],cAmarillo
        mov [color_pieza_fondo],bgAmarillo

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]

; SEGUNDO SE COLOCAN CADA POSICION DENTRO DEL ARREGLO
        
        ; Primer bloque - base
        mov ah,[bl_prin_x]    ; Movimiento horizontal
        mov al,[bl_prin_y]    ; Movimiento vertical
        add ah,[posicion_pieza_caida_horizontal]
        add al,[posicion_pieza_caida_vertical]
        mov [di],ah
        mov [si],al

        ; Segundo bloque
        add ah,[bloques_L_invertida]
        add al,[bloques_L_invertida+1]
        mov [di+1],ah
        mov [si+1],al
        sub ah,[bloques_L_invertida]
        sub al,[bloques_L_invertida+1]

        ; Tercer bloque
        add ah,[bloques_L_invertida+2]
        add al,[bloques_L_invertida+3]
        mov [di+2],ah
        mov [si+2],al
        sub ah,[bloques_L_invertida+2]
        sub al,[bloques_L_invertida+3]

        ; Cuarto bloque
        add ah,[bloques_L_invertida+4]
        add al,[bloques_L_invertida+5]
        mov [di+3],ah
        mov [si+3],al
        sub ah,[bloques_L_invertida+4]
        sub al,[bloques_L_invertida+5]

        call DIBUJAR_PIEZA
        ret
    endp


; Dibujo de pieza actual por medio del arreglo de posiciones 
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


; Quitar pieza anterior para simular caida
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


;-----------------------
;-- Sección para la colisiones de las piezas
;-----------------------

; Para esto se tendrá que comprobar si hay colision al generar cada cuadro 
; COMPROBADOR GENERAL - DEVUELVE VALOR BOOLEANO
COMPROBAR_COLISION proc
    ; La información de la posición de la pieza está en al (vertical) y ah (horizontal)


    ; Segundo, se checa colisión entre piezas
    mov [posicion_colision],0h
    xor bx,bx
	xor cx,cx
	mov bl,al

	mov ch,ah
	mov cl,al

    ; Obtención de número de casilla
	mov [posicion_colision], bx
	dec [posicion_colision]
	xor bx,bx
	mov bl,ah
    mov ax,30d
	mul [posicion_colision]
	mov [posicion_colision],ax
	add [posicion_colision],bx

    ; Transformación de número de casilla en índice
	dec [posicion_colision]

    ; Ahora verificar en esa casilla si está o no prendido
	mov bx,[posicion_colision]
    cmp [matriz_colisiones+bx],0h
	jnz colision_existe

    mov al,cl ; Devolviendo los valores originales 
	mov ah,ch


    ; Si no hay colisión se termina el procedimiento
    jmp terminar_flujo_col


        colision_existe:
            mov [bool_colision],1
            jmp regresar_con_colision

    terminar_flujo_col:
    ret
endp



; COMPROBADOR EN ESPECÍFICO - REALIZA LOS INCREMENTOS Y DECREMENTOS PARA DAR SENTIDO A LOS MOVIMIENTOS

    COMPROBAR_COLISION_INFERIOR proc
        
        ; Primero obtenemos la posición del bloque principal
        colocar_bl_principal    

        ; Ya una vez obteniendo la posición del bloque principal se tendrá que checar las diferentes posiciones, en este caso la inferior
        inc al

        call CHECAR_PIEZA_COLISIONA 
        regresar_con_colision:
        ret
    endp

    COMPROBAR_COLISION_IZQUIERDA proc
        colocar_bl_principal
        dec ah
        call CHECAR_PIEZA_COLISIONA
        ret
    endp

    COMPROBAR_COLISION_DERECHA proc
        colocar_bl_principal
        inc ah
        call CHECAR_PIEZA_COLISIONA
        ret
    endp




; Ahora se checa qué pieza es la que se tiene que verificar su colisión
    CHECAR_PIEZA_COLISIONA proc 
        ; Ahora checar la colisión de acuerdo a la pieza que se está utilizando, para eso comparamos el número random con cada id
        xor bx,bx
        mov bl,[numero_aleatorio]

        cmp [id_cuadrado],bl
        jz col_inferior_c

        cmp [id_linea],bl
        jz col_inferior_linea

        cmp [id_t],bl
        jz col_inferior_t

        cmp [id_s_normal],bl
        jz col_inferior_s

        cmp [id_s_invertido],bl
        jz col_inferior_s_inv

        cmp [id_L],bl
        jz col_inferior_L

        cmp [id_L_invertida],bl
        jz col_inferior_L_inv


    ;Etiquetas de colisiones
        col_inferior_c:
            call COLISION_CUADRADO
            jmp flujo_colision_terminar
        
        col_inferior_linea:
            call COLISION_LINEA
            jmp flujo_colision_terminar

        col_inferior_t:
            call COLISION_T
            jmp flujo_colision_terminar

        col_inferior_s:
            call COLISION_S
            jmp flujo_colision_terminar

        col_inferior_s_inv:
            call COLISION_S_INV
            jmp flujo_colision_terminar

        col_inferior_L:
            call COLISION_L
            jmp flujo_colision_terminar

        col_inferior_L_inv:
            call COLISION_L_INV
            jmp flujo_colision_terminar

        
        flujo_colision_terminar:
        ret
    endp


; Procedimientos para checar la colision con cada figura

    COLISION_CUADRADO proc
        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_cuadrado

        ; Segundo bloque
        add ah,[bloques_cuadrado]
        add al,[bloques_cuadrado+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_cuadrado]
        sub al,[bloques_cuadrado+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_cuadrado

        ; Tercer bloque
        add ah,[bloques_cuadrado+2]
        add al,[bloques_cuadrado+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_cuadrado+2]
        sub al,[bloques_cuadrado+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_cuadrado

        ; Cuarto bloque
        add ah,[bloques_cuadrado+4]
        add al,[bloques_cuadrado+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_cuadrado+4]
        sub al,[bloques_cuadrado+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_cuadrado

        ; Etiqueta para terminar con el flujo
        terminar_flujo_col_cuadrado:
        ret
    endp


    COLISION_LINEA proc
        ; PRIMERO CHECAR SI CADA PIEZA PUEDE COLOCARSE

        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_Linea

        ; Segundo bloque
        add ah,[bloques_linea]
        add al,[bloques_linea+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_linea]
        sub al,[bloques_linea+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_Linea

        ; Tercer bloque
        add ah,[bloques_linea+2]
        add al,[bloques_linea+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_linea+2]
        sub al,[bloques_linea+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_Linea

        ; Cuarto bloque
        add ah,[bloques_linea+4]
        add al,[bloques_linea+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_linea+4]
        sub al,[bloques_linea+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_Linea

        terminar_flujo_col_Linea:
        ret
    endp


    COLISION_S proc
        ; PRIMERO CHECAR SI CADA PIEZA PUEDE COLOCARSE

        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_s

        ; Segundo bloque
        add ah,[bloques_s_normal]
        add al,[bloques_s_normal+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_s_normal]
        sub al,[bloques_s_normal+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_s

        ; Tercer bloque
        add ah,[bloques_s_normal+2]
        add al,[bloques_s_normal+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_s_normal+2]
        sub al,[bloques_s_normal+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_s

        ; Cuarto bloque
        add ah,[bloques_s_normal+4]
        add al,[bloques_s_normal+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_s_normal+4]
        sub al,[bloques_s_normal+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_s

        terminar_flujo_col_s:
        ret
    endp


    COLISION_S_INV proc
        ; PRIMERO CHECAR SI CADA PIEZA PUEDE COLOCARSE

        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_s_inv

        ; Segundo bloque
        add ah,[bloques_s_invertido]
        add al,[bloques_s_invertido+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_s_invertido]
        sub al,[bloques_s_invertido+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_s_inv

        ; Tercer bloque
        add ah,[bloques_s_invertido+2]
        add al,[bloques_s_invertido+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_s_invertido+2]
        sub al,[bloques_s_invertido+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_s_inv

        ; Cuarto bloque
        add ah,[bloques_s_invertido+4]
        add al,[bloques_s_invertido+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_s_invertido+4]
        sub al,[bloques_s_invertido+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_s_inv

        terminar_flujo_col_s_inv:
        ret
    endp


    COLISION_T proc
        ; PRIMERO CHECAR SI CADA PIEZA PUEDE COLOCARSE

        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_t

        ; Segundo bloque
        add ah,[bloques_t]
        add al,[bloques_t+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_t]
        sub al,[bloques_t+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_t

        ; Tercer bloque
        add ah,[bloques_t+2]
        add al,[bloques_t+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_t+2]
        sub al,[bloques_t+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_t

        ; Cuarto bloque
        add ah,[bloques_t+4]
        add al,[bloques_t+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_t+4]
        sub al,[bloques_t+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_t

        terminar_flujo_col_t:
        ret
    endp


    COLISION_L proc
        ; PRIMERO CHECAR SI CADA PIEZA PUEDE COLOCARSE

        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_L

        ; Segundo bloque
        add ah,[bloques_L]
        add al,[bloques_L+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_L]
        sub al,[bloques_L+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_L

        ; Tercer bloque
        add ah,[bloques_L+2]
        add al,[bloques_L+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_L+2]
        sub al,[bloques_L+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_L

        ; Cuarto bloque
        add ah,[bloques_L+4]
        add al,[bloques_L+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_L+4]
        sub al,[bloques_L+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_L

        terminar_flujo_col_L:
        ret
    endp


    COLISION_L_INV proc

        ; PRIMERO CHECAR SI CADA PIEZA PUEDE COLOCARSE

        ; Primer bloque - base
        call COMPROBAR_COLISION

        cmp [bool_colision],1
        jz terminar_flujo_col_L_inv

        ; Segundo bloque
        add ah,[bloques_L_invertida]
        add al,[bloques_L_invertida+1]
        call COMPROBAR_COLISION
        sub ah,[bloques_L_invertida]
        sub al,[bloques_L_invertida+1]

        cmp [bool_colision],1
        jz terminar_flujo_col_L_inv

        ; Tercer bloque
        add ah,[bloques_L_invertida+2]
        add al,[bloques_L_invertida+3]
        call COMPROBAR_COLISION
        sub ah,[bloques_L_invertida+2]
        sub al,[bloques_L_invertida+3]

        cmp [bool_colision],1
        jz terminar_flujo_col_L_inv

        ; Cuarto bloque
        add ah,[bloques_L_invertida+4]
        add al,[bloques_L_invertida+5]
        call COMPROBAR_COLISION
        sub ah,[bloques_L_invertida+4]
        sub al,[bloques_L_invertida+5]

        cmp [bool_colision],1
        jz terminar_flujo_col_L_inv

        terminar_flujo_col_L_inv:
        ret
    endp



;;;;;;;
;; Agregar pieza a la matriz de colisiones para poder agregar más colisiones
;;;;;;;
    INSERTAR_PIEZA proc
    mov cx,4

    lea di,[arreglo_posiciones_bloques_horizontal]
	lea si,[arreglo_posiciones_bloques_vertical]

    loop_insertar_piezas:
        push cx

        push si
        push di

        call INCORPORANDO_BLOQUE

        pop di
        pop si

        inc di
        inc si

        pop cx
        loop loop_insertar_piezas
    ret
    endp

    INCORPORANDO_BLOQUE proc
        ; Tenemos la posición de la pieza en al,ah
        mov [posicion_colision],0h
        xor bx,bx
        xor cx,cx
        
        mov bl,[si]

        mov ch,[di]
        mov cl,[si]

        ; Obtención de número de casilla
        mov [posicion_colision], bx
        dec [posicion_colision]
        xor bx,bx
        mov bl,[di]
        mov ax,30d
        mul [posicion_colision]
        mov [posicion_colision],ax
        add [posicion_colision],bx

        ; Transformación de número de casilla en índice
        dec [posicion_colision]

        ; Ahora verificar en esa casilla si está o no prendido
        mov bx,[posicion_colision]
        mov [matriz_colisiones+bx],1

        mov [si],cl ; Devolviendo los valores originales 
        mov [di],ch
        ret
    endp



;---------------------------
;-- Sección para checar si es necesario eliminar un renglón, esto se hace cada vez que es colocada una pieza
;---------------------------
    CHECAR_ELIMINAR_RENGLON proc
        
        ; En este caso se tendrá que recorrer el último renglón, en caso que esté lleno se va a recorrer el renglón de arriba
        mov [posicion],0h   ; Este sirve para acceder a una fila en especial
        mov [crenglones],1   ;-> Este sirve de contador para columnas
        mov [cfilas],1
        mov [fila_llena],1


        ; Se inicia a recorrer todas las filas para saber si está llena, en caso que sí se baja el reglón de arriba

        recorrer_filas: 
            recorrer_colummas:
                ; Verificando si esta llena esa celda o no
                mov [posicion],[cfilas]
                dec [posicion]
                mov ax,[posicion]
                mov bx,28
                mul bx
                mov [posicion],ax
                xor bx,bx
                mov bl,[crenglones]
                add [posicion],bl
                mov bx,[posicion]

                cmp [matriz_colisiones+bx],0
                jz

                inc [crenglones]
                cmp [crenglones],28h
                jz salir_columnas

            
            salir_columnas:
            inc [cfilas]
            
            cmp [cfilas],23
            jz salir_filas
            
            loop recorrer_filas
        
        salir_filas:
        ret
    endp



;-----------------------
;-- Sección para la generación de piezas aleatorias
;-----------------------

; Generar números aleatorios: 
; Número random - resultado en ah
RANDOM_NUMBERS proc
    xor ax,ax
    xor bx,bx
    xor dx,dx

    ; Interrupción para obtener el tiempo de la computadora
    mov ah,00h
    int 1ah
    xor dh,dh   ; Resultado en dx, me quedo solo 8 bits
    mov ax,dx   ; Lo divido para reducir el número random de 0 a 6
    mov bx,7h
    div bl
    xor dx,dx 
    
    ret 
endp


; Elegir una figura de forma pseudo-aleatoria
PIEZA_ALEATORIA proc
    call RANDOM_NUMBERS     ; El número aleatorio se encuentra en ah

    mov [numero_aleatorio],ah

    cmp [id_cuadrado],ah
    jz c_selec

    cmp [id_linea],ah
    jz linea_selec

    cmp [id_t],ah
    jz t_selec

    cmp [id_s_normal],ah
    jz s_selec

    cmp [id_s_invertido],ah
    jz s_inv_selec

    cmp [id_L],ah
    jz L_selec

    cmp [id_L_invertida],ah
    jz L_inv_selec


    ; Llamada de procedimiento correspondiente para impresión de figura
    c_selec:
        call cuadrado_figura
        jmp flujo1

    s_selec:
        call s_normal_figura
        jmp flujo1

    s_inv_selec:
        call s_invertida_figura
        jmp flujo1

    L_selec:
        call L_figura
        jmp flujo1

    L_inv_selec:
        call L_invertida_figura
        jmp flujo1

    t_selec:
        call t_figura
        jmp flujo1

    linea_selec:
        call linea_figura
        jmp flujo1

    flujo1:

    ret
endp



; Reinicio de piezas para su posición original
    REINICIANDO_PIEZAS proc
        xor bx,bx
        mov si,0h   ; Indice para acceder a cada posición

        mov cx,5
        reiniciando:
            mov bl,[original_cuadrado+si]
            mov [bloques_cuadrado+si],bl
            xor bx,bx

            mov bl,[original_s_normal+si]
            mov [bloques_s_normal+si],bl
            xor bx,bx

            mov bl,[original_s_invertido+si]
            mov [bloques_s_invertido+si],bl
            xor bx,bx

            mov bl,[original_linea+si]
            mov [bloques_linea+si],bl
            xor bx,bx

            mov bl,[original_t+si]
            mov [bloques_t+si],bl
            xor bx,bx

            mov bl,[original_L+si]
            mov [bloques_L+si],bl
            xor bx,bx

            mov bl,[original_L_invertida+si]
            mov [bloques_L_invertida+si],bl
            xor bx,bx

            inc si

            loop reiniciando

        ret
    endp


    ; ROTACIÓN DE PIEZAS: antes de rotar necesito saber qué figura de su arreglo de bloques tendrá que ser modificado, para eso se 
    ; tiene que escoger definir con anterioridad di y si  
    ROTACION proc
        xor ax,ax
        mov al,[numero_aleatorio]

        cmp [id_cuadrado],al
        jz leerCuadrado

        cmp [id_s_normal],al
        jz leerS

        cmp [id_s_invertido],al
        jz leerSInvertida

        cmp [id_linea],al
        jz leerLinea

        cmp [id_t],al
        jz leerT

        cmp [id_L],al
        jz leerL

        cmp [id_L_invertida],al
        jz leerLInvertida

        jmp continuar_flujo_rotacion

        ;Etiquetas:

            leerCuadrado:
                lea di,[bloques_cuadrado]
                lea si,[bloques_cuadrado+1]
                jmp continuar_flujo_rotacion

            leerS:
                lea di,[bloques_s_normal]
                lea si,[bloques_s_normal+1]
                jmp continuar_flujo_rotacion

            leerSInvertida:
                lea di,[bloques_s_invertido]
                lea si,[bloques_s_invertido+1]
                jmp continuar_flujo_rotacion
            
            leerLinea:
                lea di,[bloques_linea]
                lea si,[bloques_linea+1]
                jmp continuar_flujo_rotacion
            
            leerT:
                lea di,[bloques_t]
                lea si,[bloques_t+1]
                jmp continuar_flujo_rotacion
            
            leerL:
                lea di,[bloques_L]
                lea si,[bloques_L+1]
                jmp continuar_flujo_rotacion

            leerLInvertida:
                lea di,[bloques_L_invertida]
                lea si,[bloques_L_invertida+1]
                jmp continuar_flujo_rotacion

continuar_flujo_rotacion:

        mov [contador_rotar],0
        loop_intercambio:
            xor ax,ax
            xor bx,bx

            mov al,[si]
            mov bl,[di]
            
            xchg al,bl
            
            not al
            add ax, 00000001B

            mov [si],al
            mov [di],bl

            add si,2
            add di,2

            cmp [contador_rotar],2
            jz salir_ciclo
            
            inc [contador_rotar]
        jmp loop_intercambio

        salir_ciclo:
        
        ret
    endp



; Flujo principal 
    main:
        mov ax,@data
        mov ds,ax
        mov es,ax

        ; Modo de video: en este caso será en modo texto 03 con 16 colores
		mov ax,3h 	
		int 10h	

        oculta_cursor_teclado
		apaga_cursor_parpadeo
		call DIBUJA_UI
		muestra_cursor_mouse
		posiciona_cursor_mouse 320d,16d


    continuar_flujo_con_otra_pieza:
        ; Reiniciar piezas en caso que hubiera rotación anteriormente
        ;call REINICIANDO_PIEZAS

        ; Limpiar arreglo donde se colocan las piezas de cada figura
        mov cx,4
		xor bx,bx
        
        loop_clear_arreglo:
			mov [arreglo_posiciones_bloques_horizontal+bx],0h
			mov [arreglo_posiciones_bloques_vertical+bx],0h
			inc bx
			loop loop_clear_arreglo

        ; Esta es la posición inicial de la pieza
        mov [posicion_pieza_caida_horizontal],0
        mov [posicion_pieza_caida_vertical],0

        ; Creación de pieza a utilizar hasta caer en el suelo
        call PIEZA_ALEATORIA

    gameplay:

        call DELAY_PROC

        ; Checando colisiones con piezas
        call COMPROBAR_COLISION_INFERIOR
        cmp [bool_colision],1   
        jz activar_colision_inferior
        
        ; Movimientos:
        call MOV_CAIDA
        
        
        call COMPROBAR_COLISION_DERECHA
        cmp [bool_colision],1 
        jz activar_colision_derecha

        call COMPROBAR_COLISION_IZQUIERDA
        cmp [bool_colision],1 
        jz activar_colision_izquierda

        ;call REINICIANDO_PIEZAS
        call LECT_TECLADO       ; Verificando si hay una entrada
        
        
        ; Instrucciones para imprimir pieza
        flujo_lectura:
        call ELIMINAR_PIEZA_ANTERIOR
        call PRINT_FIGURA_SELEC
        jmp continua_flujo_gameplay

        ; Etiquetas:
            activar_colision_inferior:
                mov [bool_col_inferior],1
                call ELIMINAR_PIEZA_ANTERIOR
                call PRINT_FIGURA_SELEC
                call INSERTAR_PIEZA             ; En la matriz de colisiones se tiene que insertar la pieza
                ;call CHECAR_ELIMINAR_RENGLON

                mov [bool_col_inferior],0
                mov [bool_colision],0
                jmp continuar_flujo_con_otra_pieza

            activar_colision_derecha:
                mov [bool_col_der],1
                jmp flujo_lectura


            activar_colision_izquierda:
                mov [bool_col_izq],1
                jmp flujo_lectura

        continua_flujo_gameplay:
        ; Reinicio de valores booleanos para el siguiente movimiento
        mov [bool_col_der],0
        mov [bool_col_izq],0
        mov [bool_colision],0

        jmp gameplay




    ; Procedimientos de movimientos
    MOV_CAIDA proc
        inc [posicion_pieza_caida_vertical]     ; Se va avanzando hacia abajo

        ret
    endp


    LECT_TECLADO proc
        mov ah,01h
		int 16h 	; Responde a la pregunta si alguna tecla fue presionada

		; Se comprueba del buffer del teclado para ver si una tecla fue presionada
		jnz tecla_presionada	; En este caso la tecla sí fue presionada, se lee la tecla
        
        jmp salir_lect_teclado  ; En caso que no fue presionada me salgo

        tecla_presionada:
            mov ah,0
		    int 16h 	; la tecla presionada se encuentra en al

            ; Limpiar buffer del teclado
            push ax    
            mov ah, 6 ; direct console I/O
            mov dl, 0FFh ; input mode
            int 21h 
            pop ax
        
            ; Movimiento horizontal
            cmp al,'a'
            jz movimiento_izq
            cmp al,'d'
            jz movimiento_der

            ; Rotación de pieza
            cmp al,'w'
            jz rotar_pieza_actual    

        ; Extra - Quitar:
            cmp al,'q'
            jz salir

            jmp salir_lect_teclado      ; En caso que ninguna tecla valida fuera presionada 


        movimiento_izq:
            ; Hay colision, por ende no se hace
            cmp [bool_col_izq],1
            jz  salir_lect_teclado 

            dec [posicion_pieza_caida_horizontal]
            ;call ELIMINAR_PIEZA_ANTERIOR
            ;call PRINT_FIGURA_SELEC
            jmp salir_lect_teclado
        
        movimiento_der:
            cmp [bool_col_der],1
            jz  salir_lect_teclado 

            inc [posicion_pieza_caida_horizontal]
            ;call ELIMINAR_PIEZA_ANTERIOR
            ;call PRINT_FIGURA_SELEC
            jmp salir_lect_teclado
        
        rotar_pieza_actual:
            call ROTACION
            jmp salir_lect_teclado

        salir_lect_teclado:
        ret
    endp

    


    ; Imprimir la figura que fue seleccionada
    PRINT_FIGURA_SELEC proc
        
        mov ah,[numero_aleatorio]

        cmp [id_cuadrado],ah
        jz c_selec_2

        cmp [id_linea],ah
        jz linea_selec_2

        cmp [id_t],ah
        jz t_selec_2

        cmp [id_s_normal],ah
        jz s_selec_2

        cmp [id_s_invertido],ah
        jz s_inv_selec_2

        cmp [id_L],ah
        jz L_selec_2

        cmp [id_L_invertida],ah
        jz L_inv_selec_2
        
        ; Etiquetas para seleccionar qué procedimiento llamar
        c_selec_2:
            call cuadrado_figura
            jmp flujo2

        s_selec_2:
            call s_normal_figura
            jmp flujo2

        s_inv_selec_2:
            call s_invertida_figura
            jmp flujo2

        L_selec_2:
            call L_figura
            jmp flujo2

        L_inv_selec_2:
            call L_invertida_figura
            jmp flujo2

        t_selec_2:
            call t_figura
            jmp flujo2

        linea_selec_2:
            call linea_figura
            jmp flujo2

        ; Continuación de flujo para ignorar todas las demás etiquetas.
        flujo2:

        ret
    endp




    ;---------------------
    ;-- DIBUJANDO UI
    ;---------------------
    DIBUJA_UI proc
		;imprimir esquina superior izquierda del marco
		posicion_cursor 0,0
		colorear_celda marcoEsqSupIzq,cGrisClaro,bgNegro
		
		;imprimir esquina superior derecha del marco
		posicion_cursor 0,79
		colorear_celda marcoEsqSupDer,cGrisClaro,bgNegro
		
		;imprimir esquina inferior izquierda del marco
		posicion_cursor 24,0
		colorear_celda marcoEsqInfIzq,cGrisClaro,bgNegro
		
		;imprimir esquina inferior derecha del marco
		posicion_cursor 24,79
		colorear_celda marcoEsqInfDer,cGrisClaro,bgNegro
		
		;imprimir marcos horizontales, superior e inferior
		mov cx,78 		;CX = 004Eh => CH = 00h, CL = 4Eh 
	marcos_horizontales:
		mov [col_aux],cl
		;Superior
		posicion_cursor 0,[col_aux]
		colorear_celda marcoHor,cGrisClaro,bgNegro
		;Inferior
		posicion_cursor 24,[col_aux]
		colorear_celda marcoHor,cGrisClaro,bgNegro
		
		mov cl,[col_aux]
		loop marcos_horizontales

		;imprimir marcos verticales, derecho e izquierdo
		mov cx,23 		;CX = 0017h => CH = 00h, CL = 17h 
	marcos_verticales:
		mov [ren_aux],cl
		;Izquierdo
		posicion_cursor [ren_aux],0
		colorear_celda marcoVer,cGrisClaro,bgNegro
		;Derecho
		posicion_cursor [ren_aux],79
		colorear_celda marcoVer,cGrisClaro,bgNegro
		;Interno
		posicion_cursor [ren_aux],lim_derecho+1
		colorear_celda marcoVer,cGrisClaro,bgNegro

		mov cl,[ren_aux]
		loop marcos_verticales

		;imprimir marcos horizontales internos
		mov cx,79-lim_derecho-1 		
	marcos_horizontales_internos:
		push cx
		mov [col_aux],cl
		add [col_aux],lim_derecho
		;Interno superior 
		posicion_cursor 8,[col_aux]
		colorear_celda marcoHor,cGrisClaro,bgNegro

		;Interno inferior
		posicion_cursor 16,[col_aux]
		colorear_celda marcoHor,cGrisClaro,bgNegro

		mov cl,[col_aux]
		pop cx
		loop marcos_horizontales_internos

		;imprime intersecciones internas	
		posicion_cursor 0,lim_derecho+1
		colorear_celda marcoCruceVerSup,cGrisClaro,bgNegro
		posicion_cursor 24,lim_derecho+1
		colorear_celda marcoCruceVerInf,cGrisClaro,bgNegro

		posicion_cursor 8,lim_derecho+1
		colorear_celda marcoCruceHorIzq,cGrisClaro,bgNegro
		posicion_cursor 8,79
		colorear_celda marcoCruceHorDer,cGrisClaro,bgNegro

		posicion_cursor 16,lim_derecho+1
		colorear_celda marcoCruceHorIzq,cGrisClaro,bgNegro
		posicion_cursor 16,79
		colorear_celda marcoCruceHorDer,cGrisClaro,bgNegro

		;imprimir [X] para cerrar programa
		posicion_cursor 0,76
		colorear_celda '[',cGrisClaro,bgNegro
		posicion_cursor 0,77
		colorear_celda 'X',cRojoClaro,bgNegro
		posicion_cursor 0,78
		colorear_celda ']',cGrisClaro,bgNegro

		;imprimir título
		posicion_cursor 0,37
		;imprime_cadena_color [titulo],finTitulo-titulo,cBlanco,bgNegro
		;call IMPRIME_TEXTOS
		;call IMPRIME_BOTONES
		;call IMPRIME_DATOS_INICIALES
		ret
	endp


    salir:
        mov ax,4C00h
        int 21h
        end main
