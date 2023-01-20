title "Test 3: Prueba 3 Colisiones" ; Título de trabajo que se está realizando
	.model small 	; Modelo de memoria, siendo small -> 64 kb de programa y 64 kb para datos.
	.386			; Indica versión del procesador
	.stack 512		; Tamaño de segmento de stack en bytes



;------------
;-- Macros --
;------------

    delimita_mouse_h    macro minimo,maximo
    mov cx,minimo   ;establece el valor mínimo horizontal en CX
    mov dx,maximo   ;establece el valor máximo horizontal en CX
    mov ax,7        ;opcion 7
    int 33h         ;llama interrupcion 33h para manejo del mouse
    endm

	minutosSistema macro
		mov ah,2ch
        int 21h
        mov [reloj_previo],cl
	endm

	ticks_inicio macro
		; Poner en cero
		mov ah,01h
		int 1ah
	endm

	ticks_final macro
		; Leer cantidad de ticks
		mov ah,0h
		int 1ah

		mov [end_time],cx
	endm

    borrar_bufferTeclado macro
        ; Limpiar buffer del teclado
        mov ax ,0C00h;
        int 21h
    endm

limpiando_pantalla macro

    ; Modo de video: en este caso será en modo texto 03 con 16 colores
		mov ax,0003h
		int 10h	

        oculta_cursor_teclado
		apaga_cursor_parpadeo
		call DIBUJA_UI
		muestra_cursor_mouse
		posiciona_cursor_mouse 320d,16d
endm

posicion_cursor macro renglon,columna
	mov dh,renglon	;dh = renglon
	mov dl,columna	;dl = columna
	mov bx,0
	mov ax,0200h 	;preparar ax para interrupcion, opcion 02h
	int 10h 		;interrupcion 10h y opcion 02h. Cambia posicion del cursor
endm 

EliminacionFilas macro n
    ; Columnas 1 a 29
    ; Se empieza desde el renglon-1 hasta 1
    mov [renglon],n
        mov ah,07h
        mov al,1
        mov bh,cNegro
        mov ch,lim_superior
        mov cl,lim_izquierdo
        mov dh,[renglon]
        mov dl,lim_derecho
        int 10h

endm

colisionar_inferior_macro macro
	; Checar muros
        cmp [test_y],lim_inferior
        jz et_ActivarColision

        mov bl,cNegro			
	    or bl,bgNegro
        cmp al,32
        jnz et_ActivarColision

        jmp ignorar_proc_verificarcolores_Colison


        ;-----------------------
        
        et_ActivarColision:
            ;inc [lineas_puntos] 
            mov [bool_colision],1
        
        ignorar_proc_verificarcolores_Colison:
endm

ObtenerColorPosicion macro columna_x,renglon_y
    posicion_cursor renglon_y,columna_x
    mov ah,08h
    mov bh,0
    int 10h
    ; ah:color      al: caracter
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

inicializar_bl_principal macro
    ; Esta es la posición inicial de la pieza
    mov [posicion_pieza_caida_horizontal],0
    mov [posicion_pieza_caida_vertical],0
endm

; Macro usada para impresión de cadenas con color
imprime_cadena_color macro cadena,long_cadena,color,bg_color
	mov ah,13h				;preparar AH para interrupcion, opcion 13h
	lea bp,cadena 			;BP como apuntador a la cadena a imprimir
	mov bh,0				;BH = numero de pagina
	mov bl,color 			
	or bl,bg_color 			;BL = color del caracter
							;'color' define los 4 bits menos significativos 
							;'bg_color' define los 4 bits más significativos 
	mov cx,long_cadena		;CX = longitud de la cadena, se tomarán este número de localidades a partir del apuntador a la cadena
	int 10h 				;int 10h, AH=09h, imprime el caracter en AL con el color BL
endm

; Macro usada para eventos de mouse
    lee_mouse   macro
        mov ax,0003h
        int 33h
    endm

comprueba_mouse 	macro
	mov ax,0		;opcion 0
	int 33h			;llama interrupcion 33h para manejo del mouse, devuelve un valor en AX
					;Si AX = 0000h, no existe el driver. Si AX = FFFFh, existe driver
endm


; Macro para obtener la posicion actual del bloque principal de la figura en movimiento
bl_princ_posicion_actual macro ; -> ah:horizontal al:vertical
    xor ax,ax
    mov ah,[bl_prin_x]    ; Movimiento horizontal
    mov al,[bl_prin_y]    ; Movimiento vertical
    add ah,[posicion_pieza_caida_horizontal]
    add al,[posicion_pieza_caida_vertical]
endm


.data
string1_Tetris      db                  "           ,----,                 ,----,                               "
    string1_Tetris_Fin db ""

    string2_Tetris      db                  "         ,/   .`|               ,/   .`|                               "
    string2_Tetris_Fin db ""

    string3_Tetris      db                  "       ,`   .'  :   ,---,.    ,`   .'  :,-.----.     ,---,  .--.--.    "
    string3_Tetris_Fin db ""

    string4_Tetris      db                  "     ;    ;     / ,'  .' |  ;    ;     /\    /  \ ,`--.' | /  /    '.  "
    string4_Tetris_Fin db ""

    string5_Tetris      db                  "   .'___,/    ,',---.'   |.'___,/    ,' ;   :    \|   :  :|  :  /`. /  "
    string5_Tetris_Fin db ""

    string6_Tetris      db                  "   |    :     | |   |   .'|    :     |  |   | .\ ::   |  ';  |  |--`   "
    string6_Tetris_Fin db ""

    string7_Tetris      db                  "   ;    |.';  ; :   :  |-,;    |.';  ;  .   : |: ||   :  ||  :  ;_     "
    string7_Tetris_Fin db ""

    string8_Tetris      db                  "   `----'  |  | :   |  ;/|`----'  |  |  |   |  \ :'   '  ; \  \    `.  "
    string8_Tetris_Fin db ""

    string9_Tetris      db                  "       '   :  ; |   :   .'    '   :  ;  |   : .  /|   |  |  `----.   \ "
    string9_Tetris_Fin db ""

    string10_Tetris     db                  "       |   |  ' |   |  |-,    |   |  '  ;   | |  \'   :  ;  __ \  \  | "
    string10_Tetris_Fin db ""

    string11_Tetris     db                  "       '   :  | '   :  ;/|    '   :  |  |   | ;\  \   |  ' /  /`--'  / "
    string11_Tetris_Fin db ""

    string12_Tetris     db                  "       ;   |.'  |   |    \    ;   |.'   :   ' | \.'   :  |'--'.     /  "
    string12_Tetris_Fin db ""

    string13_Tetris     db                  "       '---'    |   :   .'    '---'     :   : :-' ;   |.'   `--'---'   "
    string13_Tetris_Fin db ""

    string14_Tetris     db                  "                |   | ,'                |   |.'   '---'                "
    string14_Tetris_Fin db ""

    string15_Tetris     db                  "                `----'                  `---'                          "
    string15_Tetris_Fin db ""



    autor  db "AUTOR - VAZQUEZ MARTINEZ FREDIN ALBERTO"
    fin_autor db ""
    noname db "                                       "
    fin_noname db ""

    renglon     db      0
    string_1    db      "Hola$"
    string_2    db      10,10,"Adios$"
    string_mouse_no_found       db      "No se encontraron los drivers del mouse"

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
    numero_aleatorio                db 1h
    

;;;;;;;;;;;;;;;;
;; Colisiones ;;
;;;;;;;;;;;;;;;;

    
    bool_colision               db      0 ; -> Valor general
    bool_izq 					db 		0
    bool_der 					db 		0
    


    bool_col_inferior           db      0
    bool_col_izq                db      0
    bool_col_der                db      0

    col_aux 		db 		0
    ren_aux 		db 		0
    lim_superior 	equ		1
    lim_inferior 	equ		23
    lim_izquierdo 	equ		1
    lim_derecho 	equ		30

    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Eliminación de filas ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;;
    contador_para_eliminar  db  0
    renglon_actual      db  0
    columna_actual db 0
    contador_loop_2 db  0


    ;;;;;;;;;;;;;;;;;;;;;;;;;
    ;; Colocación de texto ;;
    ;;;;;;;;;;;;;;;;;;;;;;;;;

            ; NEXT
    ; Posición del texto NEXT
    next_col 		equ  	30+4
    next_ren 		equ  	4
    ; Texto NEXT
    nextStr			db 		175," NEXT:       ",174
    finNextStr 		db 		""

            ; Título
    ; Posicion
    titulo_col 		equ  	30+4
    titulo_ren 		equ  	0
    ;Texto
    titulolStr			db 		"TETRIS - Fredin Alberto V",160,"zquez Mart",161,"nez"
    finTituloStr 		db 		""

        ; GAME OVER
    gameover_col        equ      29
    gameover_ren        equ     11
    ; Texto
    gameoverStr         db  173,"  G A M E   O V E R  ",33
    finGAMEOVERStr      db      ""

        ; Nivel actual
    level_col           equ      34
    level_ren           equ      10
    levelStr 		    db 		"LEVEL"
    finlevelStr 		db 		""

        ; Lineas realizadas
    lines_col           equ      34
    lines_ren           equ      12
    linesStr 		    db 		"LINES"
    finlinesStr 		db 		""

        ; Puntaje más alto
    hiscore_col         equ     34
    hiscore_ren		    equ     14
    hiscoreStr		    db 		"HI-SCORE"
    finhiscoreStr		db 		""


    ; PUNTOS
    level_actual		dw      1
    lineas_puntos		dw 		0
    hiscore_puntos 		dw 		0
    blank				db 		"     "
    diez 			dw 		10
    conta 			db 		0 		;Contador auxiliar para algunas operaciones



    tmp1            db      0
    tmp2            db      0
    tmp3            db      0
    tmp4            db      0
    actual_piece_random	 db 	0
    next_piece_random	 db 	0


    ; Actualizar el nivel actual
    velocidad_caida		dw 		33
    velocidad_caida_temporal dw 33
    ticks 			dw		0 		;contador de ticks
    tick_ms			dw 		55 		;55 ms por cada tick del sistema, esta variable se usa para operación de MUL convertir ticks a segundos
    mil				dw		1000 	;dato de valor decimal 1000 para operación DIV entre 1000
    
    ; Variables para controlar el flujo de cambio entre niveles
    tick_cambio		dw		100
    level_cambiar	dw		13
    tres 			dw		3
    reloj_previo	db      0
    reloj_2			db      0
    diferencia_tiempo db 0

    start_time		dw 		0
    end_time		dw 		0


    ;;;;;;;;;;;;;;;;;;;;;
    ;; Pieza siguiente ;;
    ;;;;;;;;;;;;;;;;;;;;;
    arreglo_posiciones_bloques_horizontal_next  db 0,0,0,0
    arreglo_posiciones_bloques_vertical_next    db 0,0,0,0



    ;;;;;;;;;;;;;;;;;;;;;;
    ;; VARIABLES PARA BOTONES
    ;;;;;;;;;;;;;;;;;;;;;;
    ;Botón STOP
    stop_col        equ     lim_derecho+15
    stop_ren        equ     lim_inferior-4
    stop_izq        equ     stop_col
    stop_der        equ     stop_col+2
    stop_sup        equ     stop_ren
    stop_inf        equ     stop_ren+2

    ;Botón PAUSE
    pause_col       equ     lim_derecho+25
    pause_ren       equ     lim_inferior-4
    pause_izq       equ     pause_col
    pause_der       equ     pause_col+2
    pause_sup       equ     pause_ren
    pause_inf       equ     pause_ren+2

    ;Botón PLAY
    play_col        equ     lim_derecho+35
    play_ren        equ     lim_inferior-4
    play_izq        equ     play_col
    play_der        equ     play_col+2
    play_sup        equ     play_ren
    play_inf        equ     play_ren+2

    ;Variables que sirven de parámetros de entrada para el procedimiento IMPRIME_BOTON
    boton_caracter  db      0
    boton_renglon   db      0
    boton_columna   db      0
    boton_color     db      0


    ; Mouse
    ocho            db      8


    contador_Columnas db  0
    contador_Renglones db 0

    indice_renglones	db 0
    indice_columnas 	db 0


    ; 			Impresión
	divisor	db		10d
	cont	dw		0d
	printer	dw 		0d
	z 		dw		0d
	list_ 	dw   	21d


    ; Colisiones
    test_x db 0
    test_y db 0
    original_x db 0
    original_y db 0





.code

                                        ; -----------
                                        ; -- PROCEDIMIENTOS 
                                        ; ----------

                                        ; ---------- Números random --------------

    
    RANDOM_NUMBERS proc         ; Número random - resultado en ah
        xor ax,ax
        xor bx,bx
        xor dx,dx

        ; Interrupción para obtener el tiempo de la computadora
        mov ah,00h
        int 1ah
        xor ax,ax   ; Resultado en dx, me quedo solo 8 bits
        mov al,dl   ; Lo divido para reducir el número random de 0 a 6
        mov bx,7h
        div bl
        xor dx,dx 
        
        ret 
    endp


                                    ; ---------- INTERFAZ GRÁFICA DE USUARIO -------------

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
		call IMPRIMIR_TEXTOS
		call IMPRIME_BOTONES
		;call IMPRIME_DATOS_INICIALES
		ret
	endp

    ; ------------------
    ; -- IMPRESIÓN DE BOTONES 
    ; ------------------
    IMPRIME_BOTONES proc
		;Botón STOP
		mov [boton_caracter],254d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],stop_ren
		mov [boton_columna],stop_col
		call IMPRIME_BOTON
		;Botón PAUSE
		mov [boton_caracter],19d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],pause_ren
		mov [boton_columna],pause_col
		call IMPRIME_BOTON
		;Botón PLAY
		mov [boton_caracter],16d
		mov [boton_color],bgAmarillo
		mov [boton_renglon],play_ren
		mov [boton_columna],play_col
		call IMPRIME_BOTON
		ret
	endp

    IMPRIME_BOTON proc
	 	;background de botón
		mov ax,0600h 		;AH=06h (scroll up window) AL=00h (borrar)
		mov bh,cRojo	 	;Caracteres en color amarillo
		xor bh,[boton_color]
		mov ch,[boton_renglon]
		mov cl,[boton_columna]
		mov dh,ch
		add dh,2
		mov dl,cl
		add dl,2
		int 10h
		mov [col_aux],dl
		mov [ren_aux],dh
		dec [col_aux]
		dec [ren_aux]
		posicion_cursor [ren_aux],[col_aux]
		colorear_celda [boton_caracter],cRojo,[boton_color]
	 	ret 			;Regreso de llamada a procedimiento
	endp	 			;Indica fin de procedimiento IMPRIME_BOTON para el ensamblador

    ;;;;;;;;;;
    ;; IMPRESION DE TEXTOS
    ;;;;;;;;;;
    IMPRIMIR_TEXTOS proc
        ;Imprime cadena "NEXT"
        posicion_cursor next_ren,next_col
        imprime_cadena_color nextStr,finNextStr-nextStr,cGrisClaro,bgNegro
        
        posicion_cursor titulo_ren,titulo_col
        imprime_cadena_color titulolStr,finTituloStr-titulolStr,cGrisClaro,bgNegro

        posicion_cursor level_ren,level_col
        imprime_cadena_color levelStr,finlevelStr-levelStr,cGrisClaro,bgNegro

        posicion_cursor lines_ren,lines_col
        imprime_cadena_color linesStr,finlinesStr-linesStr,cGrisClaro,bgNegro

        posicion_cursor hiscore_ren,hiscore_col
        imprime_cadena_color hiscoreStr,finhiscoreStr-hiscoreStr,cGrisClaro,bgNegro

        ret
    endp


                                    ; ---------- CONSTRUCCIÓN DE PIEZAS -------------
; 1. Cuadrado
    cuadrado_figura proc
        mov [color_pieza_caracter],cRojo
        mov [color_pieza_fondo],bgRojo

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
        mov [color_pieza_caracter],cCyan
        mov [color_pieza_fondo],bgCyan

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
        mov [color_pieza_caracter],cRojoClaro
        mov [color_pieza_fondo],bgRojoClaro

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
        mov [color_pieza_caracter],cVerde
        mov [color_pieza_fondo],bgVerde

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
        mov [color_pieza_caracter],cMagentaClaro
        mov [color_pieza_fondo],bgMagentaClaro

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
        mov [color_pieza_caracter],cAzulClaro
        mov [color_pieza_fondo],bgAzulClaro

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

        mov [color_pieza_caracter],cAmarillo
        mov [color_pieza_fondo],bgAmarillo

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


    ; Dibujo de la pieza en pantalla usando el arreglo
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


    ; Imprimiendo la pieza seleccionada
    PRINT_FIGURA_SELEC proc
        
        mov ah,[actual_piece_random]

        lea di,[arreglo_posiciones_bloques_horizontal]
		lea si,[arreglo_posiciones_bloques_vertical]
        

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
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call cuadrado_figura
            jmp flujo2

        s_selec_2:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call s_normal_figura
            jmp flujo2

        s_inv_selec_2:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call s_invertida_figura
            jmp flujo2

        L_selec_2:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call L_figura
            jmp flujo2

        L_inv_selec_2:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call L_invertida_figura
            jmp flujo2

        t_selec_2:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call t_figura
            jmp flujo2

        linea_selec_2:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            add ah,[posicion_pieza_caida_horizontal]
            add al,[posicion_pieza_caida_vertical]
            call linea_figura
            jmp flujo2

        ; Continuación de flujo para ignorar todas las demás etiquetas.
        flujo2:

        ret
    endp


    ; Eliminando posicion anterior
    ELIMINAR_PIEZA_ANTERIOR proc
        mov cx,4
        loop_proceso_eliminar:
            push cx

            push si
            push di

            ; Macro para colorear
            posicion_cursor [si],[di]	; Se va a esa posición
            colorear_celda 32,cNegro,bgNegro	; Se colorea

            pop di
            pop si

            inc di
            inc si

            pop cx
            loop loop_proceso_eliminar

        ret
    endp


                                ; ---------- GENERAR PRIMER PIEZA ALEATORIA -------------
    PIEZA_ALEATORIA proc

        mov ah,[actual_piece_random]

        ; Obteniendo la primera posición para guardar cada bloque
        lea di,[arreglo_posiciones_bloques_horizontal]
        lea si,[arreglo_posiciones_bloques_vertical]

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
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call cuadrado_figura
            jmp flujo1

        s_selec:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call s_normal_figura
            jmp flujo1

        s_inv_selec:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call s_invertida_figura
            jmp flujo1

        L_selec:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call L_figura
            jmp flujo1

        L_inv_selec:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call L_invertida_figura
            jmp flujo1

        t_selec:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call t_figura
            jmp flujo1

        linea_selec:
            mov ah,[bl_prin_x]    ; Movimiento horizontal
            mov al,[bl_prin_y]    ; Movimiento vertical
            call linea_figura
            jmp flujo1

        flujo1:

        ret
    endp


                                            ; --- DELAY PROCEDURAL ----
    DELAY proc
        xor di,di
        mov di,09FFFh
        paso1:  
            mov cx,[velocidad_caida]        ; Más cercano a 0 la caída es más rapida
        paso2:
            loop paso2
        dec di
        jnz paso1
        ret
    endp


                                        ; ---------- COLISIONES -------------
    COLISION_IZQUIERDA proc
        mov [bool_izq],0

        lea di,[arreglo_posiciones_bloques_horizontal]
        lea si,[arreglo_posiciones_bloques_vertical]

        mov cx,4
        loop_proceso_colision_izq:
            push cx

            push si
            push di

            dec [di]        
            inc [si]    
            
            ObtenerColorPosicion [di],[si]
            call COLOR_COLISION_IZQ
            
    ;   SISTEMA VISOR PARA LA DETECCIÓN DE COLISIONES - ACTIVAR PARA ENTENDER CÓMO FUNCIONA LAS COLISIONES
            ;posicion_cursor [si],[di]	; Se va a esa posición
            ;colorear_celda 64,cGrisClaro,bgGrisClaro	; Se colorea
            ;call DELAY

            inc [di]
            dec [si]

            pop di
            pop si

            cmp [bool_izq],1
            jz colision_izq_esta_activada
            
            inc di
            inc si

            pop cx
            loop loop_proceso_colision_izq
        
        colision_izq_esta_activada:
        ret
    endp

    COLISION_DERECHA proc
        mov [bool_der],0

        lea di,[arreglo_posiciones_bloques_horizontal]
        lea si,[arreglo_posiciones_bloques_vertical]

        mov cx,4
        loop_proceso_colision_der:
            push cx

            push si
            push di

            inc [di]   
            inc [si]         
            
            ObtenerColorPosicion [di],[si]
            call COLOR_COLISION_DER
            
    ;   SISTEMA VISOR PARA LA DETECCIÓN DE COLISIONES - ACTIVAR PARA ENTENDER CÓMO FUNCIONA LAS COLISIONES
            ;posicion_cursor [si],[di]	; Se va a esa posición
            ;colorear_celda 64,cGrisClaro,bgGrisClaro	; Se colorea
            ;call DELAY

            dec [di]
            dec [si]

            pop di
            pop si

            cmp [bool_der],1
            jz colision_der_esta_activada
            
            inc di
            inc si

            pop cx
            loop loop_proceso_colision_der
        
        colision_der_esta_activada:
        ret
    endp

    COLOR_COLISION_DER proc
        cmp [di],lim_derecho
        jz et_ActivarColision_der
        mov bl,cNegro			
	    or bl,bgNegro
        cmp ah,bl
        jz ignorar_Colison_der
        et_ActivarColision_der:
            mov [bool_der],1
        ignorar_Colison_der:
        ret
    endp

    COLOR_COLISION_IZQ proc
        cmp [di],lim_izquierdo
        jz et_ActivarColision_izq
        mov bl,cNegro			
	    or bl,bgNegro
        cmp ah,bl
        jz ignorar_Colison_izq
        et_ActivarColision_izq:
            mov [bool_izq],1
        ignorar_Colison_izq:
        ret
    endp


    COLISION_INFERIOR proc
        mov [bool_colision],0

        lea di,[arreglo_posiciones_bloques_horizontal]
        lea si,[arreglo_posiciones_bloques_vertical]

        mov cx,4
        loop_proceso_colision:
            push cx

            push si
            push di

            inc [si]            
            
            ObtenerColorPosicion [di],[si]
            call CHECANDO_COLOR_COLISION
            
    ;   SISTEMA VISOR PARA LA DETECCIÓN DE COLISIONES - ACTIVAR PARA ENTENDER CÓMO FUNCIONA LAS COLISIONES
            ;posicion_cursor [si],[di]	; Se va a esa posición
            ;colorear_celda 64,cGrisClaro,bgGrisClaro	; Se colorea
            ;call DELAY

            dec [si]

            pop di
            pop si

            cmp [bool_colision],1
            jz colision_esta_activada
            
            inc di
            inc si

            pop cx
            loop loop_proceso_colision
        
        colision_esta_activada:
        ret
    endp

    
    ;;;;;; Checando cada color para ver si hay colisión 
    CHECANDO_COLOR_COLISION proc
        
        ; Checar muros
        cmp [si],lim_inferior
        jz et_ActivarColision

        mov bl,cNegro			
	    or bl,bgNegro
        cmp ah,bl
        jz ignorar_proc_verificarcolores_Colison


        ;-----------------------
        
        et_ActivarColision:
            mov [bool_colision],1
        
        ignorar_proc_verificarcolores_Colison:
        ret
    endp




                                ;------------ IMPRESIÓN DE NÚMEROS --------------
    PRINT_NUMBERS proc		; Función para imprimir de 0 a 65535
		xor ax,ax
		mov bp,sp   ; Se colocan los apuntadores a la pila en lsa misma posición, para imprimir
			
		mov dx,[z]
		mov [printer],dx
		mov [cont],0d

		repetir:	; Función para obtener dígitos de un número
			cmp [printer],0d ; Es mayor a cero entonces se sigue dividiendo
			jnz cierto	
			jmp pila
			cierto:

				cmp [printer],2550d 	; Si es mayor a este no puedo usar solo 8 bits, uso 16 bits
				ja 	p16Bits
				jmp p8Bits

				p16Bits:
					; Se usa registros dx ax
					xor dx,dx				; Limpiarlo
					mov ax,[printer]		; ah->residuo  al->cociente
					mov bx,10d
					div bx

					; dx->residuo   ax-> cociente
					mov [printer],ax		; Se reasigna el cociente
					add dx,30h		; Se obtiene el residuo en ascii

					push dx			; Se agrega el número a imprimir
					inc [cont]
					jmp repetir

				p8Bits:
					xor dx,dx				; Limpiarlo
					mov ax,[printer]		; ah->residuo  al->cociente
					div [divisor]

					mov dl,ah		; Pasando residuo
					add dl,30h

					xor bx,bx
					mov bl,al
					mov [printer],bx		; pasando cociente

					push dx			; Se agrega el número a imprimir
					inc [cont]
					jmp repetir

			pila:
				cmp [cont],0d   ; Comparación para alterar solo las banderas
				jz leave_	; Si la comparación es igual a 0 entonces z=1 por ende termina

				; Nota que se guarda siempre valores de 16 bits
				pop ax
				mov dx,ax	; Accediendo a datos
				mov ah,02h
				int 21h
				dec [cont]
				jmp pila

		leave_:		
			ret				
			endp	

    IMPRIME_BX proc
            mov ax,bx
            mov cx,5
        div10:
            xor dx,dx
            div [diez]
            push dx
            loop div10
            mov cx,5
        imprime_digito:
            mov [conta],cl
            posicion_cursor [ren_aux],[col_aux]
            pop dx
            or dl,30h
            colorear_celda dl,cBlanco,bgNegro
            xor ch,ch
            mov cl,[conta]
            inc [col_aux]
            loop imprime_digito
            ret
        endp
                   
                   
                                ; ---------- MOVIMIENTOS DE LA PIEZA -------------
    ; Lectura de teclado durante la caída 
    LECTURA_TECLADO proc
        xor ax,ax
        ; INT 
        mov ah,01h
		int 16h 	; Responde a la pregunta si alguna tecla fue presionada

		; Se comprueba del buffer del teclado para ver si una tecla fue presionada
		    ; En este caso la tecla sí fue presionada, se lee la tecla
            jnz tecla_presionada	
            
            ; En caso que no fue presionada me salgo
            jmp salir_lect_teclado  

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

            ; Bajar rapido pieza
            cmp al,'s'
            jz bajar_rapido

            ; En caso que ninguna tecla valida fuera presionada 
            jmp salir_lect_teclado      


        movimiento_izq:
            ; Hay colision, por ende no se hace
            cmp [bool_izq],1
            jz  salir_lect_teclado 

            dec [posicion_pieza_caida_horizontal]
            jmp salir_lect_teclado
        
        movimiento_der:
            cmp [bool_der],1
            jz  salir_lect_teclado 

            inc [posicion_pieza_caida_horizontal]
            jmp salir_lect_teclado
        
        rotar_pieza_actual:
            cmp [bool_der],0
            jz der_compro

            sub [posicion_pieza_caida_horizontal],2
            jmp rot

            der_compro:
                cmp [bool_izq],0
                jz rot

                add [posicion_pieza_caida_horizontal],2

            rot:
            call ROTACION
            jmp salir_lect_teclado


        bajar_rapido:
            ; Sería disminuir temporalmente el tiempo de delay
            mov [velocidad_caida],3
            jmp salir_lect_teclado


        salir_lect_teclado:
        ; Para evitar acumulación de instrucciones dadas por el teclado
        borrar_bufferTeclado
        ret
    endp


                                    ; ---------- ROTACIÓN DE PIEZAS -------------

    ROTACION proc
        xor ax,ax
        mov al,[actual_piece_random]

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



                                    ; ---------- EVENTOS DE MOUSE -------------
    OBTENER_COORDENADAS_MOUSE proc
        ;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
        mouse:
            lee_mouse
        conversion_mouse:
            ;Leer la posicion del mouse y hacer la conversion a resolucion
            ;80x25 (columnas x renglones) en modo texto
            mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
            div [ocho] 			;Division de 8 bits
                                ;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah 			;Descartar el residuo de la division anterior
            mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

            mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
            div [ocho] 			;Division de 8 bits
                                ;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah 			;Descartar el residuo de la division anterior
            mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

            ;Aquí se revisa si se hizo clic en el botón izquierdo
            test bx,0001h 		                    ;Para revisar si el boton izquierdo del mouse fue presionado
            ;jz continuar_flujo_sin_mouse 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse
                                                    ; Pero en este caso se debe de continuar con el flujo del juego 
        
        ret
    endp

    CERRAR_VENTANA proc
        ; CERRAR VENTANA
        cmp dx,0
            je boton_x
            jmp salir_cerrar_ventana
        boton_x:
            jmp boton_x1
        ;[X] se encuentra en renglon 0 y entre columnas 76 y 78
        boton_x1:
            cmp cx,76
            jge boton_x2
            jmp salir_cerrar_ventana
        boton_x2:
            cmp cx,78
            jbe boton_x3
            jmp salir_cerrar_ventana
        boton_x3:
            ;Se cumplieron todas las condiciones
            jmp salir
            jmp salir_cerrar_ventana
        
        salir_cerrar_ventana:
        ret
    endp   

    INICIARJUEGO proc
        ; --- LÓGICA DE MOUSE -     Botón para Iniciar juego
        ; -------------------

            mouse_no_clic_inicio:
            lee_mouse
            test bx,0001h
            jnz mouse_no_clic_inicio
        ;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
        mouse_inicio:
            lee_mouse
        conversion_mouse_inicio:
            ;Leer la posicion del mouse y hacer la conversion a resolucion
            ;80x25 (columnas x renglones) en modo texto
            mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
            div [ocho] 			;Division de 8 bits
                                ;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah 			;Descartar el residuo de la division anterior
            mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

            mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
            div [ocho] 			;Division de 8 bits
                                ;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah 			;Descartar el residuo de la division anterior
            mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

            ;Aquí se revisa si se hizo clic en el botón izquierdo
            test bx,0001h 		;Para revisar si el boton izquierdo del mouse fue presionado
            jz mouse_inicio 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;Aqui va la lógica de la posicion del mouse;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Si el mouse presiona salir
            ; CERRAR VENTANA
            cmp dx,0
                je boton_x_inicio
                jmp segundo_evento_inicio
            boton_x_inicio:
                jmp boton_x1_inicio
            ;[X] se encuentra en renglon 0 y entre columnas 76 y 78
            boton_x1_inicio:
                cmp cx,76
                jge boton_x2_inicio
                jmp segundo_evento_inicio
            boton_x2_inicio:
                cmp cx,78
                jbe boton_x3_inicio
                jmp segundo_evento_inicio
            boton_x3_inicio:
                ;Se cumplieron todas las condiciones
                jmp salir
                jmp segundo_evento_inicio

            segundo_evento_inicio:
            ;Si el mouse fue presionado en el renglon 19,20,21
            ;se va a revisar si fue dentro del boton play
            cmp dx,19
            je boton_play_19
            
            cmp dx,20
            je boton_play_20

            cmp dx,21
            je boton_play_21

            
            jmp mouse_no_clic_inicio
            

        boton_play_19:
            jmp boton_play_19_1
        ;Lógica para revisar si el mouse fue presionado en el botón play
        ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
        boton_play_19_1:
            cmp cx,65
            jge boton_play_19_2
            jmp mouse_no_clic_inicio
        boton_play_19_2:
            cmp cx,67
            jbe boton_play_19_3
            jmp mouse_no_clic_inicio
        boton_play_19_3:
            jmp Inicio_juego

            jmp mouse_no_clic_inicio


        boton_play_20:
            jmp boton_play_20_1
        ;Lógica para revisar si el mouse fue presionado en el botón play
        ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
        boton_play_20_1:
            cmp cx,65
            jge boton_play_20_2
            jmp mouse_no_clic_inicio
        boton_play_20_2:
            cmp cx,67
            jbe boton_play_20_3
            jmp mouse_no_clic_inicio
        boton_play_20_3:
            jmp Inicio_juego

            jmp mouse_no_clic_inicio

        
        boton_play_21:
            jmp boton_play_21_1
        ;Lógica para revisar si el mouse fue presionado en el botón play
        ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
        boton_play_21_1:
            cmp cx,65
            jge boton_play_21_2
            jmp mouse_no_clic_inicio
        boton_play_21_2:
            cmp cx,67
            jbe boton_play_21_3
            jmp mouse_no_clic_inicio
        boton_play_21_3:
            jmp Inicio_juego

            jmp mouse_no_clic_inicio

    ; ------------------
    ; --- FIN DE LÓGICA DE MOUSE
    ; -------------------
    Inicio_juego:
        ret
    endp
                        
    PAUSAR_JUEGO proc
                cmp dx,19
                je boton_pause_19
                
                cmp dx,20
                je boton_pause_20

                cmp dx,21
                je boton_pause_21
                jmp salir_pausar_juego

                ; Interpretación de mouse
                boton_pause_19:
                jmp boton_pause_19_1
                ;Lógica para revisar si el mouse fue presionado en el botón play
                ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
                boton_pause_19_1:
                    cmp cx,55
                    jge boton_pause_19_2
                    jmp salir_pausar_juego
                boton_pause_19_2:
                    cmp cx,57
                    jbe boton_pause_19_3
                    jmp salir_pausar_juego
                boton_pause_19_3:
                    jmp esperar_inicio

                    jmp salir_pausar_juego


                boton_pause_20:
                    jmp boton_pause_20_1
                ;Lógica para revisar si el mouse fue presionado en el botón play
                ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
                boton_pause_20_1:
                    cmp cx,55
                    jge boton_pause_20_2
                    jmp salir_pausar_juego
                boton_pause_20_2:
                    cmp cx,57
                    jbe boton_pause_20_3
                    jmp salir_pausar_juego
                boton_pause_20_3:
                    jmp esperar_inicio

                    jmp salir_pausar_juego

                boton_pause_21:
                    jmp boton_pause_21_1
                ;Lógica para revisar si el mouse fue presionado en el botón play
                ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
                boton_pause_21_1:
                    cmp cx,55
                    jge boton_pause_21_2
                    jmp salir_pausar_juego
                boton_pause_21_2:
                    cmp cx,57
                    jbe boton_pause_21_3
                    jmp salir_pausar_juego
                boton_pause_21_3:
                    jmp esperar_inicio

                    jmp salir_pausar_juego


            esperar_inicio:
                call INICIARJUEGO


            salir_pausar_juego:
        ret
    endp



                                ; ---------- MENSAJES PARA MOSTRAR EN PANTALLA -----
    GAME_OVER_PANTALLA proc
        posicion_cursor gameover_ren,gameover_col
        imprime_cadena_color gameoverStr,finGAMEOVERStr-gameoverStr,cRojo,bgNegro
        ret
    endp


                        ; ---------------- MOSTRAR SIGUIENTE PIEZA EN PANTALLA -------------
    UPDATE_NEXT proc
        ; Actualización de números random
        mov bl,[next_piece_random]
        mov [actual_piece_random],bl
        mov [next_piece_random],ah
        

        lea di,[arreglo_posiciones_bloques_horizontal_next]
        lea si,[arreglo_posiciones_bloques_vertical_next]

        cmp [id_cuadrado],ah
        jz c_selec_1

        cmp [id_linea],ah
        jz linea_selec_1

        cmp [id_t],ah
        jz t_selec_1

        cmp [id_s_normal],ah
        jz s_selec_1

        cmp [id_s_invertido],ah
        jz s_inv_selec_1

        cmp [id_L],ah
        jz L_selec_1

        cmp [id_L_invertida],ah
        jz L_inv_selec_1


        ; Llamada de procedimiento correspondiente para impresión de figura
        c_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call cuadrado_figura
            jmp flujo1_1

        s_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call s_normal_figura
            jmp flujo1_1

        s_inv_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call s_invertida_figura
            jmp flujo1_1

        L_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call L_figura
            jmp flujo1_1

        L_inv_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call L_invertida_figura
            jmp flujo1_1

        t_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call t_figura
            jmp flujo1_1

        linea_selec_1:
            mov ah,44    ; Movimiento horizontal
            mov al,4    ; Movimiento vertical
            call linea_figura
            jmp flujo1_1

        flujo1_1:
        

        ret
    endp



                                ; -------- TEXTOS DINÁMICOS - SCORE & HISCORE ----------------

    BORRA_SCORE proc
		mov [lineas_puntos],0
        posicion_cursor lines_ren,lines_col+20 		;posiciona el cursor relativo a lines_ren y score_col
		imprime_cadena_color blank,5,cBlanco,bgNegro 	;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
		ret
	endp

    BORRA_HISCORE proc  ; Se mantiene
        posicion_cursor hiscore_ren,hiscore_col+20 	;posiciona el cursor relativo a hiscore_ren y hiscore_col
		imprime_cadena_color blank,5,cBlanco,bgNegro 	;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
		ret
	endp

    REINICIAR_LEVEL proc
		; Se reinicia tanto el nivel comom la velocidad 
        mov [velocidad_caida],33
        mov [velocidad_caida_temporal],33

        mov [level_actual],1
        posicion_cursor lines_ren,lines_col+20 		;posiciona el cursor relativo a lines_ren y score_col
		imprime_cadena_color blank,5,cBlanco,bgNegro 	;imprime cadena blank (espacios) para "borrar" lo que está en pantalla
		ret
	endp

                                     ; -------- ------ IMPRESIONES ------- ----------
    IMPRIMIR_SCORE proc
        
        mov [ren_aux],lines_ren
		mov [col_aux],lines_col+20
		mov bx,[lineas_puntos]
		call IMPRIME_BX
        ret
    endp


    IMPRIMIR_HISCORE proc
        
        mov [ren_aux],hiscore_ren
		mov [col_aux],hiscore_col+20

        mov dx,dx
        mov dx,[hiscore_puntos]
        cmp [lineas_puntos],dx
        jg actualiza_puntos_hiscore
        jmp ignorar_actualizacion

            actualiza_puntos_hiscore:
                mov dx,[lineas_puntos]
                mov [hiscore_puntos],dx

        ignorar_actualizacion:
		mov bx,[hiscore_puntos]
		call IMPRIME_BX
        ret
    endp


    IMPRIMIR_LEVEL proc
        
        mov [ren_aux],level_ren
		mov [col_aux],level_col+20
		mov bx,[level_actual]
		call IMPRIME_BX
		
        ret
    endp

                                  
                            ; ----------- ACTUALIZACIÓN DE DIFICULTAD DE NIVEL --------------
    ; DIFERENTES MANERAS DE CAMBIAR EL NIVEL
    CAMBIO_NIVEL_RELOJ proc
        ; Interrupción
        mov ah,2ch
        int 21h
        
        mov [reloj_2],cl

        mov [diferencia_tiempo],cl
        xor cx,cx
        mov cl,[reloj_previo]
        sub [diferencia_tiempo],cl

        cmp [diferencia_tiempo],1
        jge actualizar_reloj 
        jmp no_actualizar_reloj

            actualizar_reloj:
                xor cx,cx
                mov cl,[reloj_2]
                mov [reloj_previo],cl

                cmp [velocidad_caida],3
                jz no_aumentar_velocidad

                    sub [velocidad_caida],3
                    sub [velocidad_caida_temporal],3

                no_aumentar_velocidad:  ; Se supone que la velocidad es la máxima
                inc [level_actual]

        no_actualizar_reloj:
        ret
    endp             

    CAMBIAR_NIVEL_TICKS proc
        
        cmp [end_time],60000
        jge cambio_ticks
        jmp salir_cambio_ticks

            cambio_ticks:
                ticks_inicio
                cmp [velocidad_caida],3
                jz no_aumentar_velocidad_ticks

                    sub [velocidad_caida],3
                    sub [velocidad_caida_temporal],3

                no_aumentar_velocidad_ticks:  ; Se supone que la velocidad es la máxima
                inc [level_actual]

        salir_cambio_ticks:
        ret
    endp
                                    
                                    
                                    ; ----------- Eliminación de filas --------------
    ; La actualización de la variable [lineas_puntos] se realizará aquí, se utilizará una rutina similar a la limpieza de la pantalla
    ; inc [lineas_puntos]  

    VERIFICAR_ELIMINADO proc

        mov cx,lim_inferior     ; Cantidad de renglones
        mov [indice_renglones],lim_superior

        loop_renglones:
            push cx
            mov [indice_columnas],lim_izquierdo
            
            loop_columnas:

                ; Instrucciones del segundo ciclo
                ObtenerColorPosicion [indice_columnas],[indice_renglones]   ; ah-> color   al -> carácter
                        mov bl,cNegro			
                        or bl,bgNegro
                cmp ah,bl       ; Espacio vacío, no interesa seguir
                jz salir_columnas

                ; Condiciones para salir del segundo ciclo
                cmp [indice_columnas],lim_derecho
                jz et_eliminar_fila

                inc [indice_columnas]    
                jmp loop_columnas
            
            ; Etiqueta para saber si es necesario eliminar, en caso que no se ignora esta.
            et_eliminar_fila:
                    ; ANIMACION DE ELIMINACIÓN
                    call ANIMACION_BORRADO_FILA_PASO_1
                    call ANIMACION_BORRADO_FILA_PASO_2
                    ; Macro que recorre el primer renglon hasta el actual-1
                    mov bl,[indice_renglones]
                    EliminacionFilas bl
                    inc [lineas_puntos]  

            salir_columnas:
            inc [indice_renglones]
            pop cx
            loop loop_renglones
        ret
    endp
    

    ANIMACION_BORRADO_FILA_PASO_1 proc
        mov [indice_columnas],lim_izquierdo
        loop_ani_fila_1:
            
            posicion_cursor [indice_renglones],[indice_columnas]	; Se va a esa posición
            colorear_celda 32,cBlanco,bgBlanco	; Se colorea

            call DELAY_ANIMACIONES


            cmp [indice_columnas],lim_derecho
                jz terminar_animacion_1
            inc [indice_columnas]   
            jmp loop_ani_fila_1

        terminar_animacion_1:
        ret
    endp

    ANIMACION_BORRADO_FILA_PASO_2 proc
        mov [indice_columnas],lim_izquierdo
        loop_ani_fila_2:
            
            posicion_cursor [indice_renglones],[indice_columnas]	; Se va a esa posición
            colorear_celda 32,cNegro,bgNegro	; Se colorea

            call DELAY_ANIMACIONES


            cmp [indice_columnas],lim_derecho
                jz terminar_animacion_2
            inc [indice_columnas]   
            jmp loop_ani_fila_2

        terminar_animacion_2:
        ret
    endp


    DELAY_ANIMACIONES proc
        xor di,di
        mov di,00FFFh
        paso1_1:  
            mov cx,1
        paso2_1:
            loop paso2_1
        dec di
        jnz paso1_1
        ret 
        ret
    endp

                                        ; --------- REINICIO DE ROTACIÓN ------------
    REINCIAR_ROTACION proc
        lea di,[bloques_cuadrado]
        lea si,[original_cuadrado]
        mov cx,6
        re_cuadrado:
        push si
        push di
            push cx

            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_cuadrado


        lea di,[bloques_s_normal]
        lea si,[original_s_normal]
        mov cx,6
        re_s:
        push si
        push di
            push cx


            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_s


        lea di,[bloques_s_invertido]
        lea si,[original_s_invertido]
        mov cx,6
        re_s_inv:
        push si
        push di
            push cx


            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_s_inv


        lea di,[bloques_linea]
        lea si,[original_linea]
        mov cx,6
        re_linea:
        push si
        push di
            push cx


            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_linea


        lea di,[bloques_t]
        lea si,[original_t]
        mov cx,6
        re_t:
        push si
        push di
            push cx


            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_t


        lea di,[bloques_L]
        lea si,[original_L]
        mov cx,6
        re_L:
        push si
        push di
            push cx

            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_L


        lea di,[bloques_L_invertida]
        lea si,[original_L_invertida]
        mov cx,6
        re_L_inv:
        push si
        push di
            push cx


            xor ax,ax
            mov al,[si]
            mov [di],al

        pop cx
        pop di
            pop si

            inc si
            inc di

        loop re_L_inv




        ret
    endp



                                        ; ------ LIMPIANDO LA PANTALLA ------
    ; Se realizará la limpieza de la pantalla colocando espacios en blanco además de color negro, así se tiene controlado la zona
    ; se juego
    LIMPIAR_ZONAJUEGO proc
        mov cx,lim_inferior     ; Cantidad de renglones
        
        mov [indice_renglones],lim_superior

        loop_zona:
            push cx
            mov [indice_columnas],lim_izquierdo

            loop_zona_2:

                posicion_cursor [indice_renglones],[indice_columnas]
                colorear_celda 32,cNegro,bgNegro

                cmp [indice_columnas],lim_derecho
                jz salir_loop_zona_2

                inc [indice_columnas]    
                jmp loop_zona_2
            
            salir_loop_zona_2:
            inc [indice_renglones]
            pop cx
            loop loop_zona
        ret
    endp



                    ; ANIMACION PROCEDDIMIENTOS
DELAY_ANIMACION_INTRO proc
        xor di,di
        mov di,0FFFFh
        paso1_2:  
            mov cx,10
        paso2_2:
            loop paso2_2
        dec di
        jnz paso1_2
        ret 
        ret
    endp

INTRO_ANIMACION proc
    ;mov ax,@data
    ;mov ds,ax
    ;mov es,ax

    ; Modo de video: en este caso será en modo texto 03 con 16 colores
        mov ax,0003h
        int 10h 

        oculta_cursor_teclado
        apaga_cursor_parpadeo

        posicion_cursor 3,2
        imprime_cadena_color string1_Tetris,string1_Tetris_Fin-string1_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 4,2
        imprime_cadena_color string2_Tetris,string2_Tetris_Fin-string2_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 5,2
        imprime_cadena_color string3_Tetris,string3_Tetris_Fin-string3_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 6,2
        imprime_cadena_color string4_Tetris,string4_Tetris_Fin-string4_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 7,2
        imprime_cadena_color string5_Tetris,string5_Tetris_Fin-string5_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 8,2
        imprime_cadena_color string6_Tetris,string6_Tetris_Fin-string6_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 9,2
        imprime_cadena_color string7_Tetris,string7_Tetris_Fin-string7_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 10,2
        imprime_cadena_color string8_Tetris,string8_Tetris_Fin-string8_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 11,2
        imprime_cadena_color string9_Tetris,string9_Tetris_Fin-string9_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 12,2
        imprime_cadena_color string10_Tetris,string10_Tetris_Fin-string10_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 13,2
        imprime_cadena_color string11_Tetris,string11_Tetris_Fin-string11_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 14,2
        imprime_cadena_color string12_Tetris,string12_Tetris_Fin-string12_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 15,2
        imprime_cadena_color string13_Tetris,string13_Tetris_Fin-string13_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 16,2
        imprime_cadena_color string14_Tetris,string14_Tetris_Fin-string14_Tetris,cGrisClaro,bgNegro

        call DELAY_ANIMACION_INTRO

        posicion_cursor 23,20
            imprime_cadena_color autor,fin_autor-autor,cBlanco,bgNegro

        mov cx,5
        print_name:
            push cx
            posicion_cursor 23,20
            imprime_cadena_color autor,fin_autor-autor,cNegro,bgNegro
            call DELAY_ANIMACION_INTRO
            posicion_cursor 23,20
            imprime_cadena_color autor,fin_autor-autor,cBlanco,bgNegro
            call DELAY_ANIMACION_INTRO
            pop cx
            loop print_name

        muestra_cursor_mouse
        

        mov [boton_caracter],16d
        mov [boton_color],bgGrisClaro
        mov [boton_renglon],19
        mov [boton_columna],36
        call IMPRIME_BOTON_START
        
        call INICIARJUEGO_INTRO

    ret
endp

; PROCEDIMIENTO EXTRA - ANIMACIÓN

IMPRIME_BOTON_START proc
        ;background de botón
        mov ax,0600h        ;AH=06h (scroll up window) AL=00h (borrar)
        mov bh,cNegro        ;Caracteres en color amarillo
        xor bh,[boton_color]
        mov ch,[boton_renglon]
        mov cl,[boton_columna]
        mov dh,ch
        add dh,2
        mov dl,cl
        add dl,6
        int 10h
        mov [col_aux],dl
        mov [ren_aux],dh
        dec [col_aux]
        dec [ren_aux]
        posicion_cursor 20,39
        colorear_celda [boton_caracter],cNegro,[boton_color]
        ret             ;Regreso de llamada a procedimiento
    endp                ;Indica fin de procedimiento IMPRIME_BOTON para el ensambladors


INICIARJUEGO_INTRO proc
        
            mouse_no_clic_inicio_intro:
            

            lee_mouse
            test bx,0001h
            jnz mouse_no_clic_inicio_intro
        ;Lee el mouse y avanza hasta que se haga clic en el boton izquierdo
        mouse_inicio_intro:

            lee_mouse
        conversion_mouse_inicio_intro:
            
                

            ;Leer la posicion del mouse y hacer la conversion a resolucion
            ;80x25 (columnas x renglones) en modo texto
            mov ax,dx           ;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
            div [ocho]          ;Division de 8 bits
                                ;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah           ;Descartar el residuo de la division anterior
            mov dx,ax           ;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

            mov ax,cx           ;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
            div [ocho]          ;Division de 8 bits
                                ;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah           ;Descartar el residuo de la division anterior
            mov cx,ax           ;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

            ;Aquí se revisa si se hizo clic en el botón izquierdo
            test bx,0001h       ;Para revisar si el boton izquierdo del mouse fue presionado
            jz mouse_inicio_intro             ;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse

        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        ;Aqui va la lógica de la posicion del mouse;
        ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            ; Si el mouse presiona salir

            ;Si el mouse fue presionado en el renglon 19,20,21
            ;se va a revisar si fue dentro del boton play
            cmp dx,19
            je boton_play_19_intro
            
            cmp dx,20
            je boton_play_20_intro

            cmp dx,21
            je boton_play_21_intro

            
            jmp mouse_no_clic_inicio_intro
            

        boton_play_19_intro:
            jmp boton_play_19_1_intro
        ;Lógica para revisar si el mouse fue presionado en el botón play
        ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
        boton_play_19_1_intro:
            cmp cx,38
            jge boton_play_19_2_intro
            jmp mouse_no_clic_inicio_intro
        boton_play_19_2_intro:
            cmp cx,40
            jbe boton_play_19_3_intro
            jmp mouse_no_clic_inicio_intro
        boton_play_19_3_intro:
            jmp Inicio_juego_intro

            jmp mouse_no_clic_inicio


        boton_play_20_intro:
            jmp boton_play_20_1_intro
        ;Lógica para revisar si el mouse fue presionado en el botón play
        ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
        boton_play_20_1_intro:
            cmp cx,38
            jge boton_play_20_2_intro
            jmp mouse_no_clic_inicio_intro
        boton_play_20_2_intro:
            cmp cx,40
            jbe boton_play_20_3_intro
            jmp mouse_no_clic_inicio_intro
        boton_play_20_3_intro:
            jmp Inicio_juego_intro

            jmp mouse_no_clic_inicio_intro

        
        boton_play_21_intro:
            jmp boton_play_21_1_intro
        ;Lógica para revisar si el mouse fue presionado en el botón play
        ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
        boton_play_21_1_intro:
            cmp cx,38
            jge boton_play_21_2_intro
            jmp mouse_no_clic_inicio_intro
        boton_play_21_2_intro:
            cmp cx,40
            jbe boton_play_21_3_intro
            jmp mouse_no_clic_inicio_intro
        boton_play_21_3_intro:
            jmp Inicio_juego_intro

            jmp mouse_no_clic_inicio_intro



    ; ------------------
    ; --- FIN DE LÓGICA DE MOUSE
    ; -------------------
    Inicio_juego_intro:
        ret
    endp



                            ; --------------------- LIMPIEZA DE ARREGLOS DE POSICIONES -------------------------
    LIMPIAR_ARREGLOS proc
        lea di,[arreglo_posiciones_bloques_horizontal_next]
        lea si,[arreglo_posiciones_bloques_vertical_next]
        
        mov [di],0
        mov [si],0
        mov [di+1],0
        mov [si+1],0
        mov [di+2],0
        mov [si+2],0
        mov [di+3],0
        mov [si+3],0


        lea di,[arreglo_posiciones_bloques_horizontal]
        lea si,[arreglo_posiciones_bloques_vertical]
        
        mov [di],0
        mov [si],0
        mov [di+1],0
        mov [si+1],0
        mov [di+2],0
        mov [si+2],0
        mov [di+3],0
        mov [si+3],0

        ret
    endp



                                    ; -----------
                                    ; -- INICIO FLUJO PRINCIPAL DEL JUEGO
                                    ; ----------
    main:
        
        ; ------------------------------------------------
        ; ------ B L O Q U E   P R E  - G A M E ----------
        ; ------------------------------------------------
        
        mov ax,@data
        mov ds,ax
        mov es,ax
        ; Antes de iniciar con todo será necesario verificar las existencia de drivers del mouse
        comprueba_mouse		;macro para revisar driver de mouse
	    xor ax,0FFFFh		;compara el valor de AX con FFFFh, si el resultado es zero, entonces existe el driver de mouse
        jz existen_drivers

            ; No existen
            lea dx,string_mouse_no_found
            mov ah,09h
            int 21h
            jmp salir

        existen_drivers:

        call RANDOM_NUMBERS         ;   -> ah es el número aleatorio
        mov [next_piece_random],ah

        call INTRO_ANIMACION

        ;Se escoge un número aleatorio

        ; Se inicializa la pantalla a valores predeterminados junto con la interfaz
        limpiando_pantalla

        borrar_bufferTeclado
        call LIMPIAR_ZONAJUEGO


        ; Evento para iniciar juego con el mouse - No se puede hacer otra cosa hasta cerrar
        ;call INICIARJUEGO
        

        ; Juego iniciado, se toma la hora
        minutosSistema
        ;ticks_inicio

        

        ; REINICIO DE DATOS DE PANTALLA
        call BORRA_SCORE
        call BORRA_HISCORE
        call REINICIAR_LEVEL

        ; ------------------------------------------------
        ; ------ B L O Q U E   P R E  - G A M E ----------
        ; ------------------------------------------------


        siguiente_pieza:
            delimita_mouse_h 260,630

            ;call REINCIAR_ROTACION

            ; Valores a sumar para movimiento del bloque principal - 
            ; posicion_pieza_caida_horizontal],[posicion_pieza_caida_vertical]  
            inicializar_bl_principal
            
            ; INCREMENTO DE DIFICULTAD
            call CAMBIO_NIVEL_RELOJ
            ;ticks_final
            ;call CAMBIAR_NIVEL_TICKS

            ; Generando la siguiente pieza aleatoria actual y siguiente
            call RANDOM_NUMBERS
            call UPDATE_NEXT
            call PIEZA_ALEATORIA

            ; Imprimiendo los puntajes            
            call IMPRIMIR_SCORE
            call IMPRIMIR_HISCORE
            call IMPRIMIR_LEVEL

            ; Antes de iniciar ver si el jugador perdió
                lea di,[arreglo_posiciones_bloques_horizontal]
                lea si,[arreglo_posiciones_bloques_vertical]
                call ELIMINAR_PIEZA_ANTERIOR

                call COLISION_INFERIOR
                cmp [bool_colision],1
                jz game_over

                call PIEZA_ALEATORIA
            
            gameplay:
                delimita_mouse_h 260,630

                ; EVENTOS DEL MOOUSE PARA BOTONES
                                                    
                ; Evento para cerrar juego:
                call OBTENER_COORDENADAS_MOUSE
                jz continuar_flujo_sin_mouse
                call CERRAR_VENTANA
                
                ; Evento para pausar juego:
                call PAUSAR_JUEGO


            ; -------- BLOQUE DE EVENTO DE REINICIO DE JUEGO ---------
                ; Evento para reiniciar juego:
                ; Lectura de mouse
                cmp dx,19
                je boton_reset_19
                
                cmp dx,20
                je boton_reset_20

                cmp dx,21
                je boton_reset_21
                jmp continuar_flujo_sin_mouse

                ; Interpretación de mouse
                boton_reset_19:
                jmp boton_reset_19_1
                ;Lógica para revisar si el mouse fue presionado en el botón play
                ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
                boton_reset_19_1:
                    cmp cx,45
                    jge boton_reset_19_2
                    jmp continuar_flujo_sin_mouse
                boton_reset_19_2:
                    cmp cx,47
                    jbe boton_reset_19_3
                    jmp continuar_flujo_sin_mouse
                boton_reset_19_3:
                    jmp main

                    jmp continuar_flujo_sin_mouse


                boton_reset_20:
                    jmp boton_reset_20_1
                ;Lógica para revisar si el mouse fue presionado en el botón play
                ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
                boton_reset_20_1:
                    cmp cx,45
                    jge boton_reset_20_2
                    jmp continuar_flujo_sin_mouse
                boton_reset_20_2:
                    cmp cx,47
                    jbe boton_reset_20_3
                    jmp continuar_flujo_sin_mouse
                boton_reset_20_3:
                    jmp main

                    jmp continuar_flujo_sin_mouse

                boton_reset_21:
                    jmp boton_reset_21_1
                ;Lógica para revisar si el mouse fue presionado en el botón play
                ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
                boton_reset_21_1:
                    cmp cx,45
                    jge boton_reset_21_2
                    jmp continuar_flujo_sin_mouse
                boton_reset_21_2:
                    cmp cx,47
                    jbe boton_reset_21_3
                    jmp continuar_flujo_sin_mouse
                boton_reset_21_3:
                    jmp main

                    jmp continuar_flujo_sin_mouse
            ; -------- FIN DE BLOQUE DE EVENTO DE REINICIO DE JUEGO ---------


            ; Si no hay evento del mouse simplemente se continua
            continuar_flujo_sin_mouse:


                call DELAY

                call CAMBIO_NIVEL_RELOJ
                ;ticks_final
                ;call CAMBIAR_NIVEL_TICKS


                ; Checar por bajar rapido
                xor dx,dx
                mov dx,[velocidad_caida_temporal]
                cmp [velocidad_caida],dx
                    jnz diferente_velocidad_caida
                    jmp misma_velocidad

                        diferente_velocidad_caida:
                            mov [velocidad_caida],dx


            misma_velocidad:

                                                    ; Movimientos de las piezas
                ; Para esto se tendrá que comprobar primero colsisión y después ver el movimiento que se puede hacer
                lea di,[arreglo_posiciones_bloques_horizontal]
                lea si,[arreglo_posiciones_bloques_vertical]
                call ELIMINAR_PIEZA_ANTERIOR

                call COLISION_INFERIOR
                cmp [bool_colision],1
                
                    ; Existe colision inferior
                    jz parar_caida
                    
                    ;No hubo colision inferior
                    jmp continuar_caida


                    parar_caida:
                        ; Imprimiendo última posicion y eliminando la anterior
                        call PRINT_FIGURA_SELEC

                        ; Eliminando la pieza NEXT
                        lea di,[arreglo_posiciones_bloques_horizontal_next]
                        lea si,[arreglo_posiciones_bloques_vertical_next]
                        call ELIMINAR_PIEZA_ANTERIOR

                        call VERIFICAR_ELIMINADO
                
                        ; Reinicio de variable
                        mov [bool_colision],0

                        ; Actulizando score
                        call IMPRIMIR_SCORE

                        call LIMPIAR_ARREGLOS
                        call REINCIAR_ROTACION

                        ; Siguiente pieza
                        jmp siguiente_pieza



                continuar_caida:
                    ; Fue posible realizar un movimiento hacia abajo
                    inc [posicion_pieza_caida_vertical]
                
                    ; Ver movimientos horizontales
                    call COLISION_IZQUIERDA

                    call COLISION_DERECHA


                    ; En este punto se tendrá activado las colisiones, entonces se sabe qué movimiento horizontal es posible realizar.
                    call LECTURA_TECLADO

                    
                    call PRINT_FIGURA_SELEC
                    jmp gameplay


        ; -------------------------------------------------
        ; ------  B L O Q U E  -  G A M E  O V E R --------
        ; -------------------------------------------------
        game_over:
            ; Generación de la última pieza
            call PIEZA_ALEATORIA

            ; El jugador a perdido, se muestra mensaje 
            call GAME_OVER_PANTALLA

            ; Evento para ver qué opción escoger con el mouse
        mouse_no_clic_go:
            lee_mouse
            test bx,0001h
            jnz mouse_no_clic_go
        mouse_go:
            lee_mouse
        conversion_mouse_go:
            ;Leer la posicion del mouse y hacer la conversion a resolucion
            ;80x25 (columnas x renglones) en modo texto
            mov ax,dx 			;Copia DX en AX. DX es un valor entre 0 y 199 (renglon)
            div [ocho] 			;Division de 8 bits
                                ;divide el valor del renglon en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah 			;Descartar el residuo de la division anterior
            mov dx,ax 			;Copia AX en DX. AX es un valor entre 0 y 24 (renglon)

            mov ax,cx 			;Copia CX en AX. CX es un valor entre 0 y 639 (columna)
            div [ocho] 			;Division de 8 bits
                                ;divide el valor de la columna en resolucion 640x200 en donde se encuentra el mouse
                                ;para obtener el valor correspondiente en resolucion 80x25
            xor ah,ah 			;Descartar el residuo de la division anterior
            mov cx,ax 			;Copia AX en CX. AX es un valor entre 0 y 79 (columna)

            ;Aquí se revisa si se hizo clic en el botón izquierdo
            test bx,0001h 		;Para revisar si el boton izquierdo del mouse fue presionado
            jz mouse_go 			;Si el boton izquierdo no fue presionado, vuelve a leer el estado del mouse



        ; EVENTO PARA CERRAR JUEGO
            cmp dx,0
            je boton_x_go
            jmp segundo_evento
        boton_x_go:
            jmp boton_x1_go
        ;Lógica para revisar si el mouse fue presionado en [X]
        ;[X] se encuentra en renglon 0 y entre columnas 76 y 78
        boton_x1_go:
            cmp cx,76
            jge boton_x2_go
            jmp segundo_evento
        boton_x2_go:
            cmp cx,78
            jbe boton_x3_go
            jmp segundo_evento
        boton_x3_go:
            ;Se cumplieron todas las condiciones
            jmp salir

            jmp segundo_evento
            ;jmp mouse_no_clic
    
    segundo_evento:
        ; EVENTO PARA REINICIAR
        ; Lectura de mouse
            cmp dx,19
            je boton_play_19_go
            
            cmp dx,20
            je boton_play_20_go

            cmp dx,21
            je boton_play_21_go
            jmp mouse_no_clic_go


        ; Interpretación de mouse
            boton_play_19_go:
            jmp boton_play_19_1_go
            ;Lógica para revisar si el mouse fue presionado en el botón play
            ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
            boton_play_19_1_go:
                cmp cx,45
                jge boton_play_19_2_go
                jmp mouse_no_clic_go
            boton_play_19_2_go:
                cmp cx,47
                jbe boton_play_19_3_go
                jmp mouse_no_clic_go
            boton_play_19_3_go:
                jmp main

                jmp mouse_no_clic_go


            boton_play_20_go:
                jmp boton_play_20_1_go
            ;Lógica para revisar si el mouse fue presionado en el botón play
            ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
            boton_play_20_1_go:
                cmp cx,45
                jge boton_play_20_2_go
                jmp mouse_no_clic_go
            boton_play_20_2_go:
                cmp cx,47
                jbe boton_play_20_3_go
                jmp mouse_no_clic_go
            boton_play_20_3_go:
                jmp main

                jmp mouse_no_clic_go

            
            boton_play_21_go:
                jmp boton_play_21_1_go
            ;Lógica para revisar si el mouse fue presionado en el botón play
            ;PLAY se encuentra en renglon 19 y entre columnas 65 y 67
            boton_play_21_1_go:
                cmp cx,45
                jge boton_play_21_2_go
                jmp mouse_no_clic_go
            boton_play_21_2_go:
                cmp cx,47
                jbe boton_play_21_3_go
                jmp mouse_no_clic_go
            boton_play_21_3_go:
                jmp main

                jmp mouse_no_clic_go
        

    salir:
        mov ax,4C00h
        int 21h
        end main

                                    ; -----------
                                    ; -- FIN FLUJO PRINCIPAL DEL JUEGO
                                    ; ----------

    
    
