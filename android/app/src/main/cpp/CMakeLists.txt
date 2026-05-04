cmake_minimum_required(VERSION 3.22.1)
project(motovox_native)

set(RNNOISE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/rnnoise)

add_library(
    rnnoise
    SHARED
    ${RNNOISE_DIR}/denoise.c
    ${RNNOISE_DIR}/rnn.c
    ${RNNOISE_DIR}/pitch.c
    ${RNNOISE_DIR}/kiss_fft.c
    ${RNNOISE_DIR}/celt_lpc.c
    ${RNNOISE_DIR}/nnet.c
    ${RNNOISE_DIR}/nnet_default.c
    ${RNNOISE_DIR}/parse_lpcnet_weights.c
    ${RNNOISE_DIR}/rnnoise_data_little.c
    ${RNNOISE_DIR}/rnnoise_tables.c
)

target_include_directories(rnnoise PRIVATE ${RNNOISE_DIR})

target_compile_options(rnnoise PRIVATE
    -O3
    -ffast-math
    -DHAVE_CONFIG_H
    -DRNNOISE_BUILD
    -DFLOAT_APPROX
)

target_link_libraries(rnnoise m)
