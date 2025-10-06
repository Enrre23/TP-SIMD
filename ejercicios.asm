; El valor a poner en los campos `<ejercicio>_hecho` una vez estén completados
TRUE  EQU 1
; El valor a dejar en los campos `<ejercicio>_hecho` hasta que estén completados
FALSE EQU 0

; Offsets a utilizar durante la resolución del ejercicio.
PARTICLES_COUNT_OFFSET    EQU 56 ; ¡COMPLETAR!
PARTICLES_CAPACITY_OFFSET EQU 64 ; ¡COMPLETAR!
PARTICLES_POS_OFFSET      EQU 72 ; ¡COMPLETAR!
PARTICLES_COLOR_OFFSET    EQU 80 ; ¡COMPLETAR!
PARTICLES_SIZE_OFFSET     EQU 88 ; ¡COMPLETAR!
PARTICLES_VEL_OFFSET      EQU 96 ; ¡COMPLETAR!

section .rodata

; La descripción de lo hecho y lo por completar de la implementación en C del
; TP.
global ej_asm
ej_asm:
  .posiciones_hecho: db TRUE
  .tamanios_hecho:   db TRUE
  .colores_hecho:    db TRUE
  .orbitar_hecho:    db FALSE
  ALIGN 8
  .posiciones: dq ej_posiciones_asm
  .tamanios:   dq ej_tamanios_asm
  .colores:    dq ej_colores_asm
  .orbitar:    dq ej_orbitar_asm

; Máscaras y valores que puede ser útil cargar en registros vectoriales.
;
; ¡Agregá otras que veas necesarias!
ALIGN 16
ceros:      dd  0.0,    0.0,     0.0,    0.0
unos:       dd  1.0,    1.0,     1.0,    1.0

section .text

; Actualiza las posiciones de las partículas de acuerdo a la fuerza de
; gravedad y la velocidad de cada una.
;
; Una partícula con posición `p` y velocidad `v` que se encuentra sujeta a
; una fuerza de gravedad `g` observa lo siguiente:
; ```
; p := (p.x + v.x, p.y + v.y)
; v := (v.x + g.x, v.y + g.y)
; ```
;
; void ej_posiciones(emitter_t* emitter, vec2_t* gravedad);
ej_posiciones_asm:
	push rbp
	mov rbp, rsp
	mov rcx, [rdi + PARTICLES_COUNT_OFFSET]
	sar rcx, 1
	mov rdx, [rdi + PARTICLES_POS_OFFSET]
	mov r8, [rdi + PARTICLES_VEL_OFFSET]
	xor r9, r9				;391
	movq xmm3, qword[rsi]
	movq xmm4, qword[rsi]
	unpcklpd xmm3, xmm4

	
.while:
	cmp r9, rcx
	je .fin

	imul r10, r9, 16
	
	movdqa xmm0, [rdx + r10] ;Cargamos las posciones
	movdqa xmm1, [r8 + r10]  ;Cargamos las velocidades
	
	addps xmm0, xmm1 
	movdqa [rdx + r10], xmm0

	addps xmm1, xmm3
	movdqa [r8 + r10], xmm1
	
	add r9, 1

	jmp .while

.fin:

	pop rbp
	ret

; Actualiza los tamaños de las partículas de acuerdo a la configuración dada.
;
; Una partícula con tamaño `s` y una configuración `(a, b, c)` observa lo
; siguiente:
; ```
; si c <= s:
;   s := s * a - b
; sino:
;   s := s - b
; ```
;
;emitter -> rdi, a -> xmm0, b -> xmm1, c -> xmm2
; void ej_tamanios(emitter_t* emitter, float a, float b, float c);
ej_tamanios_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r10, 0 ;r10 sera el indice
	mov r12, [rdi + PARTICLES_COUNT_OFFSET] ;Guardamos la cantida de particulas
	mov r13, [rdi + PARTICLES_SIZE_OFFSET] ;Puntero a tamaños
	sar r12, 2 
	pextrd r8d, xmm2, 0
	pinsrd xmm7, r8d, 0
	pinsrd xmm7, r8d, 1
	pinsrd xmm7, r8d, 2
	pinsrd xmm7, r8d, 3	;c

	pextrd r8d, xmm0, 0
	pinsrd xmm6, r8d, 0
	pinsrd xmm6, r8d, 1
	pinsrd xmm6, r8d, 2
	pinsrd xmm6, r8d, 3 ;a

	pextrd r8d, xmm1, 0
	pinsrd xmm5, r8d, 0
	pinsrd xmm5, r8d, 1
	pinsrd xmm5, r8d, 2
	pinsrd xmm5, r8d, 3 ;b 
		
.loop:
	

	cmp r10, r12
	je .fin

	imul r11, r10, 16 ;r11 = r10*16
	movdqa xmm4, [r13 + r11] ;Accedemos a tamaños
	
	VPCMPGTD xmm2, xmm7, xmm4 ; c > tam actual
	
	vandps xmm0, xmm2, xmm4	;xmm2 and xmm4

	vsubps xmm0, xmm0, xmm5 ; xmm0 - xmm5

	vandps xmm0, xmm0, xmm2 ;xmm2 and xmm4
	
	vandnps xmm1, xmm2, xmm4 ; (not xmm2) and xmm4

	vmulps xmm1, xmm1, xmm6 ; xmm1 = xmm1*a
	
	vsubps xmm1, xmm1, xmm5	; xmm1 = xmm1*a - b
	
	vandnps xmm1, xmm2, xmm1 

	vorps  xmm1, xmm1, xmm0

	movdqa [r13 + r11], xmm1

	add r10, 1

	JMP .loop



.fin:
	pop r13
	pop r12
	pop rbp
	ret

; Actualiza los colores de las partículas de acuerdo al delta de color
; proporcionado.
;
; Una partícula con color `(R, G, B, A)` ante un delta `(dR, dG, dB, dA)`
; observa el siguiente cambio:
; ```
; R = R - dR
; G = G - dG
; B = B - dB
; A = A - dA
; si R < 0:
;   R = 0
; si G < 0:
;   G = 0
; si B < 0:
;   B = 0
; si A < 0:
;   A = 0
; ```
;
; void ej_colores(emitter_t* emitter, SDL_Color a_restar);
ej_colores_asm:
	push rbp
	mov rbp, rsp
	push r12
	push r13

	mov r10, 0 ;r10 sera el indice
	mov r12, [rdi + PARTICLES_COUNT_OFFSET] ;Guardamos la cantida de particulas
	mov r13, [rdi + PARTICLES_COLOR_OFFSET]
	sar r12, 2

	pinsrd xmm0, esi, 0
	pinsrd xmm0, esi, 1
	pinsrd xmm0, esi, 2
	pinsrd xmm0, esi, 3

	mov r8, 0
	pinsrq xmm1, r8, 0
	pinsrq xmm1, r8, 1

.loop:
	cmp r10, r12 
	je .fin

	imul r11, r10, 16
	movdqa xmm4, [r13 + r11] ;Accedemos a los colores

	vPSUBUSB xmm2, xmm4, xmm0  ;Ralizamos la resta saturada

	vPMAXUB xmm2, xmm2, xmm1 					;Elegimos el maximo

	movdqa [r13 + r11], xmm2

	add r10, 1

	jmp .loop
	

.fin:
	pop r13
	pop r12
	pop rbp
	ret


; Calcula un campo de fuerza y lo aplica a cada una de las partículas,
; haciendo que tracen órbitas.
;
; La implementación ya está dada y se tiene en el enunciado una versión más
; "matemática" en caso de que sea de ayuda.
;
; El ejercicio es implementar una versión del código de ejemplo que utilice
; SIMD en lugar de operaciones escalares.
;
; void ej_orbitar(emitter_t* emitter, vec2_t* start, vec2_t* end, float r);
ej_orbitar_asm:
	ret
