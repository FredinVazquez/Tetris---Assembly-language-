title "Prueba de piezas cayendo " ; Título de trabajo que se está realizando
	.model small 	; Modelo de memoria, siendo small -> 64 kb de programa y 64 kb para datos.
	.386			; Indica versión del procesador
	.stack 512		; Tamaño de segmento de stack en bytes


;;;;;;;;;;;;
;; Macros ;;
;;;;;;;;;;;;

;1. Para mover el cursor a una posición
; Description
; 	Esta macros sirve para poder mover el cursor en una posición dada y realizar el coloreo en esa zona
posicion_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm 


;2. Impresión de color en la zona del cursor
; Description:
; 	Aquí se estará realizando el coloreo correspondiente al color tomado en ese momento con el carácter de ese momento
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


; 3. Ocultar cursor
oculta_cursor_teclado	macro
	mov ah,01h 		;Opcion 01h
	mov cx,2607h 	;Parametro necesario para ocultar cursor
	int 10h 		;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm


;4. Apagar parpadeo
apaga_cursor_parpadeo	macro
	mov ax,1003h 		;Opcion 1003h
	xor bl,bl 			;BL = 0, parámetro para int 10h opción 1003h
  	int 10h 			;int 10, opcion 01h. Cambia la visibilidad del cursor del teclado
endm


;5. Posición de mouse
posiciona_cursor_mouse	macro columna,renglon
	mov dx,renglon
	mov cx,columna
	mov ax,4		;opcion 0004h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm


; 6. Mostrar cursor mouse
muestra_cursor_mouse	macro
	mov ax,1		;opcion 0001h
	int 33h			;int 33h para manejo del mouse. Opcion AX=0001h
					;Habilita la visibilidad del cursor del mouse en el programa
endm



.data

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Diferentes colores que se tiene en ensamblador ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables sobre la pieza actual ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	color_actual 	db 		0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables sobre la pieza a imprimir ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	color_pieza_imprimir	db		0
	color_pieza_fondo		db 		0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables auxiliares para colocar la pieza en pantalla ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	index_renglon_aux		db 		0
	index_columna_aux		db 		0
	contador				db 		0
	control_speedup 		db 		0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Posición de impresión para cada pieza inicial ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;Valores de referencia para la posición inicial de la primera pieza
	ini_columna 	equ 	30/2
	ini_renglon 	equ 	0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Coordenadas de la posición de referencia para la pieza en el área de juego ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	pieza_col		db 		ini_columna
	pieza_ren		db 		ini_renglon

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Arreglo de posiciones para dibujar para figura ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	arreglo_posiciones_renglones			db 		0,0,0,0
	arreglo_posiciones_columnas				db 		0,0,0,0
	posicion_anterior_vertical_figura		db 		0
	posicion_anterior_horizontal_figura		db 		0
	r_al_anterior							db 		0
	r_ah_anterior							db 		0
	mov_horizontal_der						db		0
	mov_horizontal_izq						db  	0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Variables para dibujar la interfaz ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
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


;;;;;;;;;;;;;;;;;;;;;;
;; String de prueba ;;
;;;;;;;;;;;;;;;;;;;;;;
cadena db "continua flujo aqui$"


;;;;;;;;;;;;;;;;;;;;;;;;
;; Bordes de colisión ;;
;;;;;;;;;;;;;;;;;;;;;;;;
	limite_lateral_izquierdo	dw		1 
	limite_lateral_derecho 		dw		30
	limite_inferior 			db		21


;;;;;;;;;;;;;;;;;;;;;;;;
;; Diferentes figuras ;;
;;;;;;;;;;;;;;;;;;;;;;;;
	figura_cuadrado 					dw 		1h
	figura_s_normal						dw 		2h

	arreglo_figuras_disponibles			dw 		1h,2h,3h,4h,5h,6h,7h,8h ; 8h específica final de arreglo
	indice_arreglo						dw 		0h

	figura_del_arreglo					dw		0h



;;;;;;;;;;;;;;;;;;;;;;;
;; Valores booleanos ;;
;;;;;;;;;;;;;;;;;;;;;;;
	tecla_SI_presionada 		dw 		0 ; 0-> No presionada 1->1 sí presionada


;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Arreglo de colisiones ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;
	arreglo_colisiones			dw		560 dup(0)
	posicion_colision 			dw  	0


.code
	
	;;;;;;;;;;;;;;;;;;;;
	;; Procedimientos ;;
	;;;;;;;;;;;;;;;;;;;;

; Procedimiento 1
	cuadrado proc
		; Description
				;;;;;;;;;;;;
				;; Procedimiento usado para dibujar un cuadrado según el color escogido
				;; 1. Primero se selecciona el color
				;; 2. Se obtiene el arreglo de posiciones para dibujar cada cuadro
				;; 3. Se van coloreando cada posición para formar la figura
				;;;;;;;;;;;;
		mov [color_pieza_imprimir],cRojoClaro
		mov [color_pieza_fondo],bgRojoClaro

		mov al,[arreglo_posiciones_renglones]
		mov ah,[index_columna_aux]

		; al -> vertical
		; ah -> horizontal

		; Incremento de velocidad - Segundo control -> Más velocidad
		;add al,[control_speedup]

		; Una vez conseguido la posición en pantalla se accede a cada posición del arreglo usando si y di para colorerarlo
		inc al
		call comprobacion_colision
		inc ah
		call comprobacion_colision
		inc al
		call comprobacion_colision
		dec ah
		call comprobacion_colision

		
		mov al,[arreglo_posiciones_renglones]
		mov ah,[index_columna_aux]
		; EN caso que sea valido su colocación se guarda esta posición, en caso que no sea valido se usa estas posiciones anteriores
		mov [r_al_anterior],al
		mov [r_ah_anterior],ah

		inc al
		mov [si],al
		mov [di],ah

		inc ah
		mov [si+1],al
		mov [di+1],ah

		inc al
		mov [si+2],al
		mov [di+2],ah

		dec ah
		mov [si+3],al
		mov [di+3],ah


		call dibujar_pieza_seleccionada
		ret 
	endp


; Segunda figura:
		;;;;;;;
		;; 	 **		   	
		;;	**		  
		;;;;;;;
	s_figure proc
		mov [color_pieza_imprimir],cVerdeClaro
		mov [color_pieza_fondo],bgVerdeClaro

		mov al,[arreglo_posiciones_renglones]
		mov ah,[index_columna_aux]


		; Incremento de velocidad - Segundo control -> Más velocidad
		;add al,[control_speedup]

		inc al
		call comprobacion_colision
		inc ah
		call comprobacion_colision
		dec al
		call comprobacion_colision
		inc ah
		call comprobacion_colision

		mov al,[arreglo_posiciones_renglones]
		mov ah,[index_columna_aux]
		; En caso que sea valido su colocación se guarda esta posición, en caso que no sea valido se usa estas posiciones anteriores
		mov [r_al_anterior],al
		mov [r_ah_anterior],ah


		; Inicio de posición para colorear
		inc al
		mov [si],al
		mov [di],ah
		inc ah
		mov [si+1],al
		mov [di+1],ah
		dec al
		mov [si+2],al
		mov [di+2],ah
		inc ah
		mov [si+3],al 		
		mov [di+3],ah


		call dibujar_pieza_seleccionada
		ret
	endp


;;;;;;;;;;;;
	comprobacion_colision proc
		; Comprobación de colisión
		mov [posicion_colision],0h
			; tengo ya al y ah
			xor bx,bx
			xor cx,cx
			mov bl,al

			mov ch,ah
			mov cl,al
			
			; Ahora verificar si es el borde
			cmp al,[limite_inferior]
			jz colision_existe_inferior

			; Obtención de número de casilla
			mov [posicion_colision], bx
			dec [posicion_colision]
			xor bx,bx
			mov bl,ah
			mov ax,28d
			mul [posicion_colision]
			mov [posicion_colision],ax
			add [posicion_colision],bx

			; Transformación de número de casilla en índice
			dec [posicion_colision]
			mov ax,[posicion_colision]
			mov bx,2h
			mul bx
			mov [posicion_colision],ax

			; Ahora verificar en esa casilla si está o no prendido
			mov bx,[posicion_colision]

			; Se deberá checar si es colisión propiciado por un movimiento horizontal, en caso que sí se tendrá que
			; realizar un movimiento hacia abajo, en caso que no significa que la colisión sí es de la parte inferior
			cmp [arreglo_colisiones+bx],1h
			jz tipo_colision

			mov al,cl
			mov ah,ch

		ret
	endp


	tipo_colision:
		cmp [mov_horizontal_der],1h
		jz colision_existe_derecho

		cmp [mov_horizontal_izq],1h
		jz colision_existe_izquierdo

		jmp colision_existe_inferior



; 1.3: Coloreo de negro o espacio en su defecto
	update_piece proc
		mov cx,4 
		mov [color_pieza_imprimir],cNegro
		loop_proceso_dibujo:
			push cx

			; Se agrega cada posición que se va a colorear
			push si 		; Movimiento entre renglones - vertical
			push di 		; Movimiento entre columnas - horizontal

			; Macro para colorear
			posicion_cursor [si],[di]	; Se va a esa posición
			colorear_celda 254,[color_pieza_imprimir],bgNegro	; Se colorea
			;call delay

			pop di
			pop si

			inc di
			inc si

			pop cx
			loop loop_proceso_dibujo
		ret
	endp




; Procedimiento 2
	dibujar_pieza_seleccionada proc
		
		; Description
				;;;;;;;;;;;;
				;; Dibuja la pieza seleccionada
				;;;;;;;;;;;;
		mov cx,4 
		loop_proceso_eliminacion:
			push cx

			; Se agrega cada posición que se va a colorear
			push si 		; Movimiento entre renglones - vertical
			push di 		; Movimiento entre columnas - horizontal

			; Macro para colorear
			posicion_cursor [si],[di]	; Se va a esa posición
			colorear_celda 254,[color_pieza_imprimir],[color_pieza_fondo]	; Se colorea


			pop di
			pop si

			inc di
			inc si

			pop cx
			loop loop_proceso_eliminacion


		ret
	endp


; 3. Dibujo de la interfaz
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

		ret
	endp


	; 4. Delay proc
	;DELAY 500000 (7A120h).
	delay proc   
	  ; Primer control de velocidad 
	  mov cx, 2      ;HIGH WORD.
	  mov ah, 86h    ;WAIT.
	  int 15h
	  ret
	delay endp 


	; 5. Lectura del teclado para saber que movimiento realizar
	lectura_entrada_movimiento proc
		mov ah,01h
		int 16h 	; Responde a la pregunta si alguna tecla fue presionada

		; Se comprueba del buffer del teclado para ver si una tecla fue presionada
		jnz tecla_si_fue_presionada	; En este caso la tecla sí fue presionada, se lee la tecla

		ret 						; En caso de que no fue presionada salgo 
	endp


	; 6. Procedimiento para generar la siguiente pieza de forma aleatoria
	generar_pieza_random proc
		xor ax,ax
		xor bx,bx

		mov bx,[indice_arreglo]
		mov ax,[arreglo_figuras_disponibles + bx]
		mov [figura_del_arreglo],ax

		add [indice_arreglo],2
		cmp [figura_del_arreglo],2h
		jz  reiniciar_selector

		call figura_seleccionada_impresion

		ret
	endp


	; 7. Procedimiento para reiniciar el selector de figuras - temporal
	reiniciar_selector:
		mov [indice_arreglo],0h
		;jmp finish
		call generar_pieza_random ;-> Se tendría que volver a escoger


	; 8. Selector de figura a imprimir 
	figura_seleccionada_impresion	proc
		mov ax,[figura_del_arreglo]

		cmp [figura_cuadrado],ax
		;xor ax,ax
		jz cuadrado_seleccionado

		cmp [figura_s_normal],ax
		;xor ax,ax
		jz s_seleccionado

		ret
	endp


	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Etiquetas para saltos ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
	cuadrado_seleccionado:
		call cuadrado
		jmp continuar
	s_seleccionado:
		call s_figure
		jmp continuar

	tecla_si_fue_presionada:
		; Se realiza la lectura d ela tecla desde el buffer
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
    	jz movimiento_horizontal_izquierda
    	cmp al,'d'
		jz movimiento_horizontal_derecha

		; Movimiento hacia abajo - speed
		cmp al,'s'
		jz movimiento_speedup

		; Quitar:
		cmp al,'q'
		jz finish

    	

	;;; Etiquetas de movimientos ;;;
    movimiento_horizontal_izquierda:
    	dec [posicion_anterior_vertical_figura]
    	
    	mov ax,[limite_lateral_izquierdo]
    	cmp [posicion_anterior_vertical_figura],al
    	jz colision_existe_izquierdo		; True: no se hace ningún movimiento lateral

    	inc [contador]						; False: se continua de forma normal
    	mov [mov_horizontal_izq],1h
		jmp movimiento_caida_normal

    movimiento_horizontal_derecha:
    	inc [posicion_anterior_vertical_figura]

    	mov ax,[limite_lateral_derecho]
    	cmp [posicion_anterior_vertical_figura],al
    	jz colision_existe_derecho

    	inc [contador]
		mov [mov_horizontal_der],1h
    	jmp movimiento_caida_normal

    movimiento_speedup:
    	mov [control_speedup],1
    	inc [contador]
    	jmp movimiento_caida_normal



    ;;; Etiquetas de colisiones ;;;
    colision_existe_izquierdo:
    	inc [posicion_anterior_vertical_figura]
    	inc [contador]
		mov [mov_horizontal_der],0h
		mov [mov_horizontal_izq],0h
    	jmp movimiento_caida_normal
    colision_existe_derecho:
    	dec [posicion_anterior_vertical_figura]
    	inc [contador]
		mov [mov_horizontal_der],0h
		mov [mov_horizontal_izq],0h
    	jmp movimiento_caida_normal
    colision_existe_inferior:
    	; Volvemos a la posición inicial
		mov al,[r_al_anterior]
		mov ah,[r_ah_anterior]


    	mov bx,[figura_del_arreglo]
    	
    	cmp [figura_cuadrado],bx
    	jz cuadrado_antes_eliminar

    	cmp [figura_s_normal],bx
    	jz s_antes_eliminar

    	continuacion_flujo:
		call dibujar_pieza_seleccionada
		jmp repeticion_siguiente_pieza
		;jmp finish

	insertando_pieza_tabla proc
		;;;;;;;;;;;;;;;;;;;;
			mov [posicion_colision],0
			; tengo ya al y ah
			xor bx,bx
			xor cx,cx
			;Se tiene que preservar los valores originales de al y ah
			mov ch,ah
			mov cl,al

			mov bl,al

			; Obtención de número de casilla
			mov [posicion_colision], bx
			dec [posicion_colision]
			xor bx,bx
			mov bl,ah
			mov ax,28d
			mul [posicion_colision]
			mov [posicion_colision],ax
			add [posicion_colision],bx

			; Transformación de número de casilla en índice
			dec [posicion_colision]
			mov ax,[posicion_colision]
			mov bx,2h
			mul bx
			mov [posicion_colision],ax

			; Asignando
			mov bx,[posicion_colision]
			mov [arreglo_colisiones+bx],1h
			
			mov al,cl
			mov ah,ch
			;;;;;;;;;;;;;;;;;;;;;;;;;
			ret
		endp


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Figura - Dar un paso anterior ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		cuadrado_antes_eliminar:
			inc al
			mov [si],al
			mov [di],ah
			call insertando_pieza_tabla

			inc ah
			mov [si+1],al
			mov [di+1],ah
			call insertando_pieza_tabla

			inc al
			mov [si+2],al
			mov [di+2],ah
			call insertando_pieza_tabla

			dec ah
			mov [si+3],al
			mov [di+3],ah
			call insertando_pieza_tabla
			
			jmp continuacion_flujo


		s_antes_eliminar:
			inc al
			mov [si],al
			mov [di],ah
			call insertando_pieza_tabla

			inc ah
			mov [si+1],al
			mov [di+1],ah
			call insertando_pieza_tabla

			dec al
			mov [si+2],al
			mov [di+2],ah
			call insertando_pieza_tabla

			inc ah
			mov [si+3],al
			mov [di+3],ah	
			call insertando_pieza_tabla
			
			jmp continuacion_flujo


	;;;;;;;;;;;;;;;;;;;;;
	;; Flujo principal ;;
	;;;;;;;;;;;;;;;;;;;;;

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
		

		; Aquí anteriormente se debió escogido la pieza por medio del proc pieza_next, después se obtiene la posición incial
		; del arreglo de posiciones para poder dibujar cada cuadro correspondiente y así armar la figura
repeticion_siguiente_pieza:	
		
		mov cx,4
		xor bx,bx
		loop_clear_arreglo:
			mov [arreglo_posiciones_renglones+bx],0h
			mov [arreglo_posiciones_columnas+bx],0h
			inc bx
			loop loop_clear_arreglo

		lea di,[arreglo_posiciones_columnas]
		lea si,[arreglo_posiciones_renglones]
		xor ax,ax

		mov [posicion_anterior_vertical_figura],15
		mov [posicion_anterior_horizontal_figura],0

		; Se obtiene la posición para la pieza principal a imprimir
		mov al,[posicion_anterior_vertical_figura]
		mov ah,[posicion_anterior_horizontal_figura]
		mov [index_columna_aux],al
		mov [index_renglon_aux],ah
		mov [pieza_col],al
		mov [pieza_ren],ah


		; Dibujo de un cuadrado		
		;call cuadrado
		;call s_figure
		call generar_pieza_random
	
	; Prueba de movimiento hacia abajo
	
	loop_gaming:
		call delay	
		
		lea di,[arreglo_posiciones_columnas]
		lea si,[arreglo_posiciones_renglones]
		call update_piece

		lea di,[arreglo_posiciones_columnas]
		lea si,[arreglo_posiciones_renglones]
		
		; Movimiento: Horizontal o speedup
		xor ax,ax
		
		; Antes de realizar la impresión de la figura se tiene que ver si hay colisión
		call lectura_entrada_movimiento
		
		; Si no hay aumento de velocidad no hay speedup
		mov [control_speedup],0

		
		jmp movimiento_caida_normal

		


	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	;; Etiqueas de movimientos ;;
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	movimiento_caida_normal:

		mov al,posicion_anterior_vertical_figura
		mov ah,posicion_anterior_horizontal_figura

		mov [index_columna_aux],al
		mov [index_renglon_aux],ah
		mov [pieza_col],al
		mov [pieza_ren],ah

		; Lectura de teclado para movimiento
		xor ax,ax
		
		;call cuadrado
		;call s_figure
		call figura_seleccionada_impresion
		continuar:
		jmp loop_gaming


	finish:
		mov ax,4C00h
		int 21h
		end main
