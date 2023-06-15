;-------------------------------------------;
; Arquitectura de Computadores				;
; Tarea Corta 2: 2048  		;
; Profesor: Kirstein Gatjens Soto 			;
;											;
; Hecho por: Humberto José Cuadra Díaz 		;
; Carné: 200869205    						;
; Fecha: 21/04/2014		                    ;
;                                           ;
;-------------------------------------------;

;----------------------------------------------------------------------------------------------------------;
; TABLA DE RESULTADOS
;----------------------------------------------------------------------------------------------------------;
; Procedimiento					Resultado				Descripcion
;
; Imprimir Matriz 					A
; Usar Colores de fondo				A					Decidi usar fondos en vez de colorear el texto
;														porque se mira mucho mejor. El problema fue que
;														solo tenia 3 bits a mi disposicion debido a que,
;														para el fondo, el cuarto bit es de blinking.
;
; Movimientos adecuados hacia 		A
; los cuatro lados
;
; Union de celdas					A
; Uso de flechas direccionales		A
; Despliegue de ayuda con F1		A
; Acerca de							A
; Informar Game Over				A
; Informar Victoria					A
; Despliegue de score				A
; Resetear el juego					A
;
; Nuevos numeros en 				A
; celdas aleatorias
;
; Nuevo numero (2 o 4)				A					90% de las veces saldra un 2. Asi funciona el 
; de manera aleatoria									juego original.	
; 
; Guardar top 10					E					Se como implementarlo, pero me alcanzo el tiempo.
; en archivo								
;----------------------------------------------------------------------------------------------------------;


;MACROS

; Imprime TEXTO en la entrada estandar
; Si TEXTO no viene definido entonces se asume 
; que el texto ya viene en DS:[DX]
imprimir MACRO TEXTO
PUSH AX
PUSH DX

IFNB <TEXTO>
	LEA DX,TEXTO
ENDIF
MOV AH,09H
INT 21H

POP DX
POP AX
ENDM

IMPRIMIRSTRINGEN MACRO DESP,LARGO,BUFFER
LOCAL IMPRIMIRSTRINGPUNTAJE
PUSH BX
PUSH CX
PUSH DI
PUSH DX

MOV CX,LARGO
MOV DI,LARGO
MOV DH,0FH ; FONDO NEGRO LETRA BLANCA
MOV BX,DESP

IMPRIMIRSTRINGPUNTAJE:
MOV DL,BYTE PTR[BUFFER+ DI - 1]
MOV WORD PTR ES:[BX],DX
DEC DI
DEC BX
DEC BX
LOOP IMPRIMIRSTRINGPUNTAJE

POP DX
POP DI
POP CX
POP BX
ENDM

; Pone todo los elementos de un arreglo en 0
; ENTRADA:
; ARREGLO: Etiqueta del arreglo
; LARGO: Cantidad de elementos en arreglo
; TAMANO: Tamaño de cada elemento del arreglo (1 = byte, 2 = word, 4 = dword)
; SALIDA:
; ARREGLO con todos los elementos en 0

RESETEARARREGLO MACRO ARREGLO,LARGO, TAMANO
LOCAL LOOPRESETEAR
PUSH CX
PUSH SI

MOV CX,LARGO
XOR SI,SI
LOOPRESETEAR:
MOV WORD PTR[ARREGLO + SI],0
ADD SI,TAMANO
LOOP LOOPRESETEAR

POP CX
POP SI
ENDM
; Detiene el programa
SALIR MACRO
MOV AX, 4C00H
INT 21H
ENDM

; Imprime el caracter CHAR en la salida estandar
PRINTCHAR MACRO CHAR 
PUSH AX
PUSH DX

MOV AH,02H
MOV DL,CHAR
INT 21H

POP DX
POP AX
ENDM

Pila Segment Stack 'Stack'
	dw 2048 dup(?)
Pila Ends

Datos Segment

;Mensajes Acerca de y Ayuda
AcercaDe db "Acerca De",0Dh,0Ah,0Dh,0Ah,'$'
AcercaDe1 db "2048 es un juego que se basa en juntar celdas con numeros iguales moviendolos",0Dh,0Ah,'$'
AcercaDe10 db "de un lado a otro. ",0Dh,0Ah,'$'
AcercaDe2 db "Cuando el jugador mueve hacia una direccion, todos los numeros se arrastraran",0Dh,0Ah,'$'
AcercaDe20 db "hacia esa direccion.",0Dh,0Ah,'$'
AcercaDe3 db "Cuando dos numeros iguales se encuentran, entonces se suman y convergen en una",0Dh,0Ah,'$'
AcercaDe30 db "misma casilla.",0Dh,0Ah,'$'
AcercaDe4 db "El objetivo del juego es llegar a la casilla que valga 2048.",0Dh,0Ah,'$'
AcercaDe5 db "Cada vez que dos numeros converjan, se sumara ese valor al puntaje total.",0Dh,0Ah,'$'
AcercaDe6 db "En cada nuevo movimiento saldra un 2 o un 4 en un lugar aleatorio de la matriz.",0Dh,0Ah,0Dh,0Ah,'$'

Ayuda db "Como Jugar:",0Dh,0Ah,0Dh,0Ah,'$'
Ayuda1 db "1. Use las flechas direccionales para moverse de un lado a otro en el tablero.",0Dh,0Ah,'$'
Ayuda2 db "2. Si ya habia empezado un juego, presion S para reanudarlo.",0Dh,0Ah,'$'
Ayuda3 db "3. Para reiniciar el juego presione R.",0Dh,0Ah,'$'
Ayuda4 db "4. Para salir del programa presion Esc. $"


celdasDisp db 16 dup(0) ; Celdas disponibles (usado por una funcion para llenarlo de las direcciones de las celdas vacias)
filInicial db 4 ; Fila donde se empieza a graficar la matriz (centrada en pantalla)
colInicial db 26 ; Columna donde se empieza a graficar la matriz (centrada en pantalla)
capaCelda dw 6 dup(0) ; Representa una capa de las 3 capas de 6 words que contiene cada celda
pausa1 dw 426 ; Indican la longitud de las pausas usadas por el juego 426 * 200
pausa2 dw 200

; Variables para movimiento
modoAvance dw 1 dup(2,8,-2,-8) ; Indica cuantos espacios debe avanzar para ir a la siguiente celda, indexado por posicion de movimiento
matriz dw 4 dup(4 dup(0)) ; Matriz principal del juego
merged dw 16 dup(?) ; El arreglo merged sirve para que solo hay una union por celda
fil db 0 ; Fila actual de la cual se calculara la direccion
col db 0 ; Columna actual de la cual se calculara la direccion
siguiente dw 0 ; Indica cual es la direccion de la siguiente celda 'no vacia'
ultimo dw 0 ; Indica la direccion de la siguiente celda vacia
movido db 0 ; Indica si hubo un movimiento o no al presionar una flecha direccional
puntaje dw 0 ; Cuenta el puntaje actual del juego
puntajeString db "Puntaje: "
gano db 0 ; Indica si usuario vencio el juego, 1 si lo vencio, 0 si no
gameOver db 0
seguir db 1
msjGameOver db "Game Over!"
msjGano db "Felicidades ha Ganado!!"
msjJugarDeNuevo db "Pulse R para jugar de nuevo"
msjAyuda db "Presione F1 para ayuda.$"

; Ambas trasversales indican el patron de movimiento, sirven para recorrer la matriz y cambian dependiendo de la direccion de movimiento
trasversalUno db 4 dup(?)
trasversalDos db 4 dup(?)

bufferAsciiNumero db 5 dup(?) ;Guarda la representacion ascii del numero de una celda

Datos Ends

Codigo Segment
	Assume DS:Datos,CS:Codigo,SS:Pila

Inicio: 
mov ax,datos
mov ds,ax
mov ax,pila
mov ss,ax	

mov ax,0b800h ; Direccion inicio de pantalla
mov es,ax

call IniciarJuego

RevisarTecla:
mov ah,1
int 16h ; Interrupcion para revisar el buffer del teclado
jnz AtenderTecla

jmp RevisarTecla

AtenderTecla:
xor ah,ah
int 16h ; Interrupcion para obtener codigo de tecla (ah: BIOS, al: ASCII)

cmp ah,1 ; Si es Esc, salir
je Terminar

cmp ah,13h
je ResetearJuego

cmp ah,3Bh
je ImprimirAcerca

cmp ah,1Fh
je ReanudarJuego

cmp seguir,0
je RevisarTecla

cmp ah,4Bh ; Flecha izquierda
je MoverIzquierda

cmp ah,48h; Flecha arriba
je MoverArriba

cmp ah,4Dh ;Flecha derecha 
je MoverDerecha

cmp ah,50h ;Flecha abajo
je MoverAbajo

jmp RevisarTecla

ImprimirAcerca:
call imprimirAyuda
jmp RevisarTecla

ReanudarJuego:
xor bp,bp
mov ax,3
int	10h
imprimir msjAyuda
call dibujarMatriz
jmp RevisarTecla

ResetearJuego:
call iniciarJuego
jmp RevisarTecla

MoverIzquierda:
mov bp,0
call moverCeldas
jmp RevisarTecla

MoverArriba:
mov bp,2
call moverCeldas
jmp RevisarTecla

MoverDerecha:
mov bp,4
call moverCeldas
jmp RevisarTecla

MoverAbajo:
mov bp,6
call moverCeldas
jmp RevisarTecla

Terminar:
; Despejar pantalla
mov ax,3
int	10h

Salir

iniciarJuego proc near
mov ax, 3                          
int 10h 	;interrupcion de pantalla (bios)

imprimir msjAyuda
;Despejamos la matriz
resetearArreglo matriz 16 2
;Reseteamos el puntaje
mov puntaje,0
mov gano,0
mov gameOver,0
mov seguir,1

xor bp,bp

call insertarCeldaAleatoria
call pausar ; Pausar para evitar que salga siempre el mismo numero dos veces al comenzar el juego
call insertarCeldaAleatoria

call dibujarMatriz

ret
endp

; Funcion que mueve todas las celdas hacia una direccion
; ENTRADA:
; BP: Direccion de movimiento (0 izq, 2 arriba, 4 der, 6 abajo)
; SALIDA:
; matriz: matriz llena con los numeros correspondientes
; 
moverCeldas proc near
push ax
push bp
push bx
push cx
push di
push dx
push si

resetearArreglo merged 16 2 
call crearTrasversales
mov movido,0
mov cx,4
xor si,si ; Si es el desplazamiento que recorre ambas trasversales

; Comienza el ciclo para recorrer el primer arreglo de trasversales
CicloMovimientoUno:
; Se toma el indice de la fila de la trasversal uno 
mov al,byte ptr[trasversalUno + si]
mov fil,al
; El uno se usa como "null" para indicar que no hay celda proxima con un valor
; Se usa uno debido a que nunca va a haber una direccion impar en la matriz
mov siguiente,1 
mov ultimo,1

; Comienza el ciclo para recorrer el segundo arreglo de trasversales (analogo a un for dentro de otro for)
push cx
push si
mov cx,4
xor si,si
CicloMovimientoDos:
; Se toma el indice de la columna de la trasversal dos
mov al,byte ptr[trasversalDos + si] 
mov col,al 
; Obtiene la direccion real del par ordenado (fil,col) 
; Se debe tomar en cuenta que si la direccion es arriba o abajo 
; entonces se invertira el par ordenado por (col,fil)
call direccionEnMatriz ; Ahora DI contendra la direccion de la celda actual

cmp ultimo,1 ; Si ultimo esta en 1 significa que la siguiente celda disponible hacia la direccion deseada, es la misma actual
jne ObtenerValorCelda

mov ultimo,di ; Se iguala ultimo a la celda actual

ObtenerValorCelda:
mov ax,word ptr[matriz + di] ; Obtener el valor de la celda actual

cmp siguiente,1 ; Si no hay siguiente disponible entonces saltarse a la comparacion CeldaVacia
je CeldaVacia

; Se busca en el arreglo merged para saber si esta celda ya fue unida con otra en un ciclo anterior
; Si es 1 fue unida, si es 0 entonces todavia no
mov bx,siguiente
mov dx,word ptr[merged + bx]
cmp dx,1
je CeldaVacia

; En caso de que no haya sido unida, entonces se comparan los valores de la celda actual con la siguiente
mov dx,word ptr[matriz + bx]
cmp ax,dx
jne CeldaVacia

; Si son iguales entonces se hace la suma y el movimiento:
add ax,dx ; Suma las dos celdas iguales

cmp ax, 2048 
jne SeguirUnion

mov gano,1

SeguirUnion:
mov word ptr[matriz + bx],ax ; Mueve el nuevo valor a la direccion que contenia "siguiente"
mov word ptr[matriz + di],0 ; Resetea el valor de la celda actual
mov word ptr[merged + bx],1 ; Edita el arreglo merged para indicar que esta celda y fue unida con otra (para evitar que hayan dos uniones en una movida)
add puntaje,ax ; Se suma al puntaje actual el nuevo valor unido

; La siguiente celda disponible (ultimo) es igual a la direccion "siguiente" menos una celda
; Dependiendo de la direccion en que sea la movida, se va a saber que celda es la anterior a la siguiente
; para esto se usa el arreglo modoAvance que sirve como mapa e indica cuanto le debe sumar o restar a la direccion "siguiente" para llegar a ella
add bx,word ptr[modoAvance + bp]
mov ultimo,bx 
mov movido,1
jmp SeguirLoop

ConejoCicloMovPrimero:
jmp CicloMovimientoDos

ConejoCicloMovSegundo:
jmp CicloMovimientoUno

CeldaVacia:
cmp ax,0
jne ActualIgualUltimo
; Si la celda actual esta vacia, y el valor de ultimo no es 0, entonces el nuevo valor de ultimo sera la celda actual
mov bx,ultimo
mov dx,word ptr[matriz + bx]
cmp dx,0
je SeguirLoop

mov ultimo,di
jmp SeguirLoop

ActualIgualUltimo:
cmp di,ultimo
je IgualarSiguienteActual
; Si ultimo es diferente de la celda actual, entonces hay que mover la celda actual a ultimo
mov bx,ultimo
mov word ptr[matriz + bx],ax ; Se mueve el valor de la celda actual a la posicion ultimo
mov word ptr[matriz + di],0 ; Se restea la celda actual
mov siguiente,bx ; Siguiente es ahora ultimo, debido a que es la siguiente celda que contiene un valor
mov dx,word ptr[modoAvance + bp] ; Caso analogo a cuando se unen, se debe encontrar la celda anterior a ultimo
add bx,dx
mov ultimo,bx
mov movido,1

jmp SeguirLoop

IgualarSiguienteActual:
mov siguiente,di ; En caso de que exista un valor y este no haya sido movido a ninguna parte, entonces este sera el siguiente valor dispnible

AvanzarColumnaUltimo:
mov ultimo,1 ; Indica que no se ha encontra aun una celda vacia disponible

SeguirLoop:
inc si
loop ConejoCicloMovPrimero
pop si
pop cx
inc si
loop ConejoCicloMovSegundo

xor bp,bp ; Se resetea bp para que no interfiera en otras llamadas a la funcion direccionEnMatriz

cmp movido,1
jne TerminarMovimiento

call insertarCeldaAleatoria
call dibujarMatriz

cmp gano,1
jne RevisarGameOver

imprimirStringEn 0D82h 23 msjGano 
jmp JugarDeNuevo

RevisarGameOver:
call esGameOver
cmp gameOver,1
jne TerminarMovimiento

imprimirStringEn 0D68h 10 msjGameOver

JugarDeNuevo:
mov seguir,0
imprimirStringEn 0E2Ah 27 msjJugarDeNuevo

TerminarMovimiento:
pop si
pop dx
pop di
pop cx
pop bx
pop bp
pop ax
ret
endp

; Funcion que determina si termino el juego
; ENTRADA:
; matriz: se verifica en la matriz si hay movimientos o espacios dispnibles
; SALIDA:
; gameOver: Se pone en 1 si el juego termino

esGameOver proc near
push ax
push bx
push cx
push di
push dx
push si

call celdasDisponibles

cmp bx,0
ja TerminarGameOverConejo 

call crearTrasversales
xor si,si
mov cx,4
GameOver1:
; Se toma el indice de la fila de la trasversal uno 
mov ah,byte ptr[trasversalUno + si]
mov fil,ah
push cx
push si
mov cx,4
xor si,si
GameOver2:
; Se toma el indice de la columna de la trasversal dos
mov al,byte ptr[trasversalDos + si] 
mov col,al 

call direccionEnMatriz

mov dx,word ptr[matriz + di]

;Probar celda a la izquierda
dec col

cmp col,0
jl CompararDerecha

call direccionEnMatriz
mov bx, word ptr[matriz + di]
cmp bx,dx
je UnionEncontrada

jmp CompararDerecha

TerminarGameOverConejo:
jmp TerminarGameOver

GameOver1Conejo:
jmp GameOver1

GameOver2Conejo:
jmp GameOver2

; Probar celda a la derecha
CompararDerecha:
inc col
inc col

cmp col,3
ja CompararArriba

call direccionEnMatriz

mov bx, word ptr[matriz + di]
cmp bx,dx
je UnionEncontrada

CompararArriba:
dec col
dec fil

cmp fil,0
jl CompararAbajo

call direccionEnMatriz
mov bx, word ptr[matriz + di]
cmp bx,dx
je UnionEncontrada

CompararAbajo:
inc fil
inc fil

cmp fil,3
ja SeguirLoopGameOver

call direccionEnMatriz
mov bx, word ptr[matriz + di]
cmp bx,dx
je UnionEncontrada

jmp SeguirLoopGameOver

UnionEncontrada:
mov gameOver,2

SeguirLoopGameOver:
dec fil
inc si
loop GameOver2Conejo
pop si
pop cx
inc si
loop GameOver1Conejo

cmp gameOver,2
je ResetearGameOver

mov gameOver,1

jmp TerminarGameOver

ResetearGameOver:
mov gameOver,0

TerminarGameOver:
pop si
pop dx
pop di
pop cx
pop bx
pop ax
ret
endp

; Funcion que crea dos lista de trasversales
; que indican como se recorrera la matriz dependiendo de la direccion
crearTrasversales proc near
push ax
push bx
push cx
push si

xor bx,bx
mov cx,4
CicloCrear:
mov byte ptr[trasversalUno + bx],bl
mov byte ptr[trasversalDos + bx],bl
inc bx
loop CicloCrear
cmp bp,4 
je RevertirTrasversalDos

cmp bp,6
je RevertirTrasversalDos

jmp TerminarTrasversales
;LIMPIAR
RevertirTrasversalUno:
lea bx,trasversalUno
jmp RevertirTrasversal

RevertirTrasversalDos:
lea bx,trasversalDos

RevertirTrasversal:
xor si,si
mov cx,4
mov al,3
CicloRevertir:
mov byte ptr[bx + si],al
inc si
dec al
loop CicloRevertir

TerminarTrasversales:
pop si
pop cx
pop bx
pop ax
ret
endp


; Funcion que dibuja la matriz
; Cada celda es de 6 words de ancho
; Cada celda es de 3 words de alto
; Cada separador de celdas, tanto verticales como horizontales, es de 1 word y siempre de fondo negro
; ENTRADA:
; filIncial: La matriz tiene un margen vertical de 4 w
; colInicial: La matriz tiene un margen izquierdo de 26 w

dibujarMatriz proc near
push ax
push bx
push dx
push si

mov dl,filInicial
xor dh,dh

mov fil,0
mov col,0

call imprimirPuntaje

DibujarCeldasFil:
; Ambas suman antes de dibujar
inc dl ; Cuenta el numero de filas recorridas (Filas de la consola, no de la matriz)
inc dh ; Cuenta numero de filas y se resetea cada 3 (alto de la celda)
mov col,0 ;Se resetea la columna cada vez que se cambia de fila

cmp dh,4 ;Si se dibujaron tres filas en la consola, se debe aumentar una fila a la matriz
jb EmpezarDibujo

cmp fil,3 ; Si se dibujaron las cuatro filas de la matriz, terminar
je TerminarDibujo

inc fil
inc dl ;Aqui se incrementa en uno el contador de filas para insertar un separador vertical
mov dh,1 ; El contador de filas de consola vuelve a uno

EmpezarDibujo:
mov al,160      ; Se calcula la siguiente direccion fisica en consola
mul dl			; dl * 160 + colInicial * 2
xor bh, bh
mov bl, colInicial
shl bx,1
add bx,ax

xor si,si
call capaActual ; Se obtiene la capa actual de la celda de la consola

DibujarCeldasCol:
add bx,2
inc si
inc si

mov ax,word ptr[capaCelda + si - 2]
mov word ptr es:[bx],ax     

cmp si,12
je Separador

jmp DibujarCeldasCol

Separador:
cmp col,3 ; Si se dibujaron las 4 columnas de esta fila, seguir a la siguiente fila 
je DibujarCeldasFil 

add bx,2 ; Saltarse un espacio para separar celdas horizontalmente 
xor si,si
inc col
call capaActual ; Capa de la siguiente celda, debido a que aumentamos una columna 
jmp DibujarCeldasCol

TerminarDibujo:
pop si
pop dx
pop bx
pop ax
ret
endp

; Funcion que devuelve la capa de una celda en la matriz
; ENTRADA:
; DH: Un numero del 1 al 3 que indica cual de las 3 capas de la celda se debe devolver
; Si la capa es 2 entonces se debe devoler el numero representado
; fil,col: Direccion abstracta de la celda
; SALIDA:
; capaCelda: Buffer de 6 words que representa la capa de una celda, cada word tiene un caracter ascii con background y foreground
capaActual proc near
push ax
push bx
push cx
push di
push dx
push si

mov bh,dh

call direccionEnMatriz
mov ax,word ptr[matriz + di] ; Obtener valor de la celda
mov dx,7020h ; Por defecto usar espacio con fondo gris claro

cmp ax,0 ; Usar por defecto si la celda esta vacia
je LlenarCapa

call obtenerColor

LlenarCapa:
mov cx,6
xor si,si
CicloLlenado:
mov word ptr[capaCelda + si],dx
inc si
inc si
loop CicloLlenado

cmp bh,2 ; Si la capa es la segunda, esta debe contener el numero
je AgregarNumero

jmp FinalizarCapaActual

AgregarNumero:
cmp ax,0 ; Si el numero es 0 (Celda vacia) no dibujarlo
je FinalizarCapaActual

mov si,4 ; Por defecto empezar el numero en el 3er espacio (Para numeros de 2 y 3 digitos)
call numeroEnAscii ;Obtiene la representacion en ascii del numero
mov cx,di
xor di,di
; Cada celda tiene 6 words de ancho
cmp cx,1 ; Si el numero es de 1 digito, empezar en el 4to espacio
je CuartoEspacio

cmp cx,4 ; Si el numero es de 4 digitos, empezar en el 2do espacio
je SegundoEspacio

jmp InsertarEnCapa

CuartoEspacio:
mov si,6
jmp InsertarEnCapa

SegundoEspacio:
mov si,2

InsertarEnCapa:
mov al,byte ptr[bufferAsciiNumero + di] ; Obtener digito en Ascii
mov byte ptr[capaCelda + si],al ; Agregar digito ascii en su correspondiente posicion
inc si
inc si
inc di
loop InsertarEnCapa 

FinalizarCapaActual:
pop si
pop dx
pop di
pop cx
pop bx
pop ax
ret
endp

imprimirPuntaje proc near
push ax
push bx
push cx
push di
push dx


; Imprimir puntaje
mov ax,puntaje
call numeroEnAscii
mov bx,24Ah ; Ultimo word esquina superior derecha de matriz
mov cx,di
mov dh,0Fh ; Fondo negro letra blanca
ImprimirPuntajeCiclo:
mov dl,byte ptr[bufferAsciiNumero + di - 1]
mov word ptr es:[bx],dx
dec di
dec bx
dec bx
loop ImprimirPuntajeCiclo

imprimirStringEn bx 8 puntajeString

pop dx
pop di
pop cx
pop bx
pop ax
ret
endp

; Funcion que retorna colores dependiendo del numero contenido en la celda
; ENTRADA:
; AX: Numero contenido en la celda
; SALIDA:
; DH: Colores (Background y Foreground)

obtenerColor proc near
push ax

cmp ax,4 ; 2 y 4
jbe GrisClaro

cmp ax,8  
je CafeBlanca

cmp ax,16
je CafeNegra

cmp ax,32
je Magenta

cmp ax,64
je Rojo

cmp ax,256 ; 128 y 256 
jbe Cyan

cmp ax,1024 ; 512 y 1024
jbe Azul

Verde: ; 2048
mov dh,2Fh ; Letra blanca fondo verde 
jmp TerminarColores

GrisClaro:
mov dh,70h ; Letra negra fondo Gris Claro
jmp TerminarColores

CafeBlanca:
mov dh,6Fh ; Letra blanca fondo cafe
jmp TerminarColores

CafeNegra:
mov dh,60h ; Letra gris fondo cafe
jmp TerminarColores

Magenta:
mov dh,5Fh ; Letra blanca fondo magenta
jmp TerminarColores

Rojo:
mov dh,4Fh ; Letra blanca fondo rojo
jmp TerminarColores

Cyan:
mov dh,30h ; Letra negra fondo cyan
jmp TerminarColores

Azul:
mov dh,1Fh ; Letra blanca fondo azul

TerminarColores:
pop ax
ret
endp

; Funcion que obtiene la direccion fisica de una celda en la matriz
; ENTRADA:
; fil: Fila actual
; col: Columna actual
; BP: Direccion de movimiento
; SALIDA:
; DI: Direccion fisica o -1 si Fil o Col estan fuera de rango
direccionEnMatriz proc near
push ax
push bx
push dx

mov dh,fil
mov dl,col

 ; Si la direccion de movimiento es hacia arriba o abajo 
 ; entonces se debe invertir la fila con la columna antes de obtener la direccion
cmp bp,2 ; Arriba
je InvertirFilaConColumna

cmp bp,6 ; Abajo
je InvertirFilaConColumna

jmp ContinuarComparacion

InvertirFilaConColumna:
mov dh,col
mov dl,fil

ContinuarComparacion:
cmp fil,0
jl FueraDeRango

cmp fil,3
ja FueraDeRango

cmp col,0
jl FueraDeRango

cmp col,3
ja FueraDeRango

mov al,8 ; Calcular direccion: fil*8 + col*2
mul dh
xor bh,bh
mov bl,dl
shl bx,1
add bx,ax
mov di,bx
jmp TerminarDireccion

FueraDeRango:
mov di,-1
jmp TerminarDireccion


TerminarDireccion:
pop dx
pop bx
pop ax

ret
endp


; Funcion que agrega una nueva celda a la matriz aleatoriamente
insertarCeldaAleatoria proc near
push bx
push cx
push dx
push si

call celdasDisponibles
call random ; Devuelve un valor que se usara como indice en CeldasDisp

call siguienteValor 
mov si,dx
mov bl,byte ptr[celdasDisp + si] ; BL contiene el desplazamiento de la celda a modificar
mov word ptr[matriz + bx],cx ; CX contiene el nuevo valor a insertar 

pop si
pop dx
pop cx
pop bx
ret
endp


; Funcion que retorna aletoriamente un 2 o 4
; La funcion retornara un 2 el 90% de las veces
; SALIDA:
; CX: Valor de retorno

siguienteValor proc near
push bx
push dx

mov bx,10 ; Queremos un numero aleatorio del 0 al 9
call random
cmp dl,9
je RetornarCuatro

mov cx,2
jmp FinalizarValor

RetornarCuatro:
mov cx,4

FinalizarValor:
pop dx
pop bx
ret
endp

;Funcion que retorna la cantidad y las direcciones de las celdas vacias
;ENTRADA:
;Matriz: Matriz del juego
;SALIDA:
;CeldasDisp: Arreglo de 16 bytes conteniendo los desplazamientos de las celdas vacias
;BX: Cantidad de celdas disponibles
celdasDisponibles proc near
push ax
push cx
push di
push si

xor bx,bx ; Recorre la matriz
xor di,di ; Cuenta el numero de celdas disponibles
xor si,si ; Recorre el arreglo de resultados

mov cx,16 ; Tamaño de la matriz: 4 x 4

BuscarDisp:
mov ax,word ptr[matriz + bx] 
cmp ax,0 ; 0 indica celda vacia
je InsCelda
inc bx
inc bx
loop BuscarDisp

jmp finalizarIns

InsCelda:
mov byte ptr[celdasDisp + si],bl
inc si ; Incrementar 1 vez si para avanzar 1 espacio en el arreglo
inc bx
inc bx ; Incrementar dos veces bx para avanzar una celda
inc di ; Incrementar la cantidad de celdas disponibles
loop BuscarDisp

finalizarIns:
mov bx,di

pop si
pop di
pop cx
pop ax
ret
endp  

; Funcion que retorna un numero aleatorio
; ENTRADA:
; BX : Limite tope para el numero aleatorio (Ej: 10 devuelve un numero del 0 al 9)
; SALIDA:
; DX: Numero aleatorio de resultado
random proc near
push ax
push bx
push cx

mov ah, 00h  ; interrupcion para obtener tick de reloj   
int 1Ah      

mov  ax, dx
xor dx,dx
div  bx ; El residuo de la division retorna un numero entre 0 y el rango proporcionado en bx       

pop cx
pop bx
pop ax
   
ret   
endp

; Convierte numero natural a su representacion en ascii
; ENTRADA:
; AX: Numero a imprimir
; SALIDA:
; bufferAsciiNumero: Buffer donde se guarda cada digito del numero
; DI: Numero de digitos del numero
numeroEnAscii proc near
push ax
push bx
push cx
push dx

mov dx,0

mov bx,0Ah
xor cx,cx 
xor di,di ; Se usa como desplazamiento sobre el buffer de resultado

cicloConversion:
div bx ; Se divide el numero original entre 10
add dx,30h ; Se le suma 30h al residuo para convertirlo en ASCII
push dx ; Se inserta el nuevo ASCII en la pila para luego sacarlos en orden inverso
inc cx ; CX es el contador de digitos total, se usa luego para un loop
xor dx,dx
cmp ax,0 ; Si el cociente es 0 entonces siginifica que ya se recorrieron todos los digitos
je guardarNumero

jmp cicloConversion


guardarNumero:
pop dx
mov byte ptr[bufferAsciiNumero + di],dl
inc di
loop guardarNumero

pop dx
pop cx
pop bx
pop ax

ret
endp

pausar proc near
push cx

mov cx, pausa1       ; hacemos una pausa de veinte millones de nops
p1:     
push cx
mov cx, pausa2
p2:     
nop
loop p2
pop cx
loop p1

pop cx
ret
endp

imprimirAyuda proc near
; Despejar pantalla
mov ax,3
int	10h
imprimir AcercaDe
imprimir AcercaDe1
imprimir AcercaDe10
imprimir AcercaDe2
imprimir AcercaDe20
imprimir AcercaDe3
imprimir AcercaDe30
imprimir AcercaDe4
imprimir AcercaDe5
imprimir AcercaDe6

imprimir Ayuda
imprimir Ayuda1
imprimir Ayuda2
imprimir Ayuda3
imprimir Ayuda4
ret
endp

Codigo ends
end Inicio