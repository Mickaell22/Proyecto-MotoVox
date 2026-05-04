/* config.h mínimo para compilar RNNoise en Android (ARM64, inferencia solamente) */
#ifndef RNNOISE_CONFIG_H
#define RNNOISE_CONFIG_H

#define HAVE_CONFIG_H 1

/* Modo inferencia — no entrenamiento */
#define TRAINING 0

/* Permite optimizaciones de punto flotante (requerido si se usa -ffast-math o -O3 agresivo) */
#define FLOAT_APPROX 1

/* Los pesos están compilados en rnnoise_data_little.c */
/* #undef USE_WEIGHTS_FILE */

/* ARM64 tiene lrint en libm */
#define HAVE_LRINT 1
#define HAVE_LRINTF 1

#endif
