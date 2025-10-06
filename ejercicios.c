#include <math.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include "color.h"
#include "ejercicios.h"
#include "emitter.h"


/**
 * Actualiza las posiciones de las partículas de acuerdo a la fuerza de
 * gravedad y la velocidad de cada una.
 *
 * Una partícula con posición `p` y velocidad `v` que se encuentra sujeta a
 * una fuerza de gravedad `g` observa lo siguiente:
 * ```
 * p := (p.x + v.x, p.y + v.y)
 * v := (v.x + g.x, v.y + g.y)
 * ```
 */
static void ej_posiciones_c(emitter_t* emitter, vec2_t* gravedad) {
	size_t count = emitter->particles_count;
	vec2_t* positions = emitter->particles_pos;
	vec2_t* velocities = emitter->particles_vel;
	

	for (size_t i = 0; i < count; i++) {
		(positions)[i].x = (velocities)[i].x + (positions)[i].x;
		(positions)[i].y = (velocities)[i].y + (positions)[i].y;
		(velocities)[i].y = (velocities)[i].y + gravedad-> y;
		(velocities)[i].x = (velocities)[i].x + gravedad-> x;
	}
}

/**
 * Actualiza los tamaños de las partículas de acuerdo a la configuración dada.
 *
 * Una partícula con tamaño `s` y una configuración `(a, b, c)` observa lo
 * siguiente:
 * ```
 * si c <= s:
 *   s := s * a - b
 * sino:
 *   s := s - b
 * ```
 */
static void ej_tamanios_c(emitter_t* emitter, float a, float b, float c) {
	size_t cantidad_de_particulas = emitter -> particles_count;
	float* puntero_a_tam = emitter -> particles_size;

	for(int i = 0; i < cantidad_de_particulas; i++){
		float tam_actual = puntero_a_tam[i];
		if(c <= tam_actual){
			tam_actual = tam_actual*a - b;
			puntero_a_tam[i] = tam_actual;
		}
		else{
			tam_actual = tam_actual - b;
			puntero_a_tam[i] = tam_actual;
		}


	}
}

/**
 * Actualiza los colores de las partículas de acuerdo al delta de color
 * proporcionado.
 *
 * Una partícula con color `(R, G, B, A)` ante un delta `(dR, dG, dB, dA)`
 * observa el siguiente cambio:
 * ```
 * R = R - dR
 * G = G - dG
 * B = B - dB
 * A = A - dA
 * si R < 0:
 *   R = 0
 * si G < 0:
 *   G = 0
 * si B < 0:
 *   B = 0
 * si A < 0:
 *   A = 0
 * ```
 */

uint8_t calcular_maximo(uint8_t c, uint8_t delta){
	uint8_t num = c - delta;

	if(c >= delta){ 
		return num; 
	}
	else{
		return 0;
	}
	
}

static void ej_colores_c(emitter_t* emitter, SDL_Color a_restar) {
	size_t cantidad_particulas = emitter -> particles_count;
	SDL_Color* puntero_a_colores = emitter ->particles_color;  
	for(int i = 0; i < cantidad_particulas; i++){
		SDL_Color color_actual = puntero_a_colores[i];

		uint8_t rojo = calcular_maximo(puntero_a_colores[i].r, a_restar.r);
		puntero_a_colores[i].r = rojo;
		
		uint8_t verde = calcular_maximo(puntero_a_colores[i].g, a_restar.g);
		puntero_a_colores[i].g = verde;

		uint8_t azul = calcular_maximo(puntero_a_colores[i].b, a_restar.b);
		puntero_a_colores[i].b = azul;

		uint8_t osucuro = calcular_maximo(puntero_a_colores[i].a, a_restar.a);
		puntero_a_colores[i].a = osucuro;
		
	}


}



/**
 * Calcula un campo de fuerza y lo aplica a cada una de las partículas,
 * haciendo que tracen órbitas.
 *
 * La implementación ya está dada y se tiene en el enunciado una versión más
 * "matemática" en caso de que sea de ayuda.
 *
 * El ejercicio es implementar una versión del código de ejemplo que utilice
 * SIMD en lugar de operaciones escalares.
 */
static void ej_orbitar_c(emitter_t* emitter, vec2_t* start, vec2_t* end, float r) {
	size_t count = emitter->particles_count;
	vec2_t* positions = emitter->particles_pos;

	for (size_t i = 0; i < count; i++) {
		vec2_t p = positions[i];

		vec2_t ba = { end->x - start->x,
		              end->y - start->y };
		vec2_t pa = { p.x    - start->x,
		              p.y    - start->y };

		float h = (pa.x * ba.x + pa.y * ba.y)
		        / (ba.x * ba.x + ba.y * ba.y);
		if (h < 0) h = 0;
		if (h > 1) h = 1;

		vec2_t q = { pa.x - h * ba.x,
		             pa.y - h * ba.y };

		float d = sqrtf(q.x * q.x + q.y * q.y);

		vec2_t delta = { q.x / d,
		                 q.y / d };
		delta = (vec2_t) {
			delta.x * 0.2588 - delta.y * 0.9659,
			delta.x * 0.9659 + delta.y * 0.2588
		};
		if (0 <= d-r) {
			delta = (vec2_t) {
				-delta.x,
				-delta.y
			};
		}
		positions[i].x += delta.x;
		positions[i].y += delta.y;
	}
}

/**
 * La descripción de lo hecho y lo por completar de la implementación en C del
 * TP.
 */
ejercicio_t ej_c = {
	.posiciones_hecho = false,
	.posiciones       = ej_posiciones_c,

	.tamanios_hecho   = false,
	.tamanios         = ej_tamanios_c,

	.colores_hecho    = false,
	.colores          = ej_colores_c,

	.orbitar_hecho    = false,
	.orbitar          = ej_orbitar_c
};
