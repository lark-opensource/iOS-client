/* Copyright 2015, Kenneth MacKay. Licensed under the BSD 2-clause license. */

#ifndef _BDUECC_VLI_H_
#define _BDUECC_VLI_H_

#include "BDuECC.h"
#include "BDTypes.h"

/* Functions for raw large-integer manipulation. These are only available
   if BDuECC.c is compiled with BDuECC_ENABLE_VLI_API defined to 1. */
#ifndef BDuECC_ENABLE_VLI_API
    #define BDuECC_ENABLE_VLI_API 0
#endif

#ifdef __cplusplus
extern "C"
{
#endif

#if BDuECC_ENABLE_VLI_API

void BDuECC_vli_clear(BDuECC_word_t *vli, wordcount_t num_words);

/* Constant-time comparison to zero - secure way to compare long integers */
/* Returns 1 if vli == 0, 0 otherwise. */
BDuECC_word_t BDuECC_vli_isZero(const BDuECC_word_t *vli, wordcount_t num_words);

/* Returns nonzero if bit 'bit' of vli is set. */
BDuECC_word_t BDuECC_vli_testBit(const BDuECC_word_t *vli, bitcount_t bit);

/* Counts the number of bits required to represent vli. */
bitcount_t BDuECC_vli_numBits(const BDuECC_word_t *vli, const wordcount_t max_words);

/* Sets dest = src. */
void BDuECC_vli_set(BDuECC_word_t *dest, const BDuECC_word_t *src, wordcount_t num_words);

/* Constant-time comparison function - secure way to compare long integers */
/* Returns one if left == right, zero otherwise */
BDuECC_word_t BDuECC_vli_equal(const BDuECC_word_t *left,
                           const BDuECC_word_t *right,
                           wordcount_t num_words);

/* Constant-time comparison function - secure way to compare long integers */
/* Returns sign of left - right, in constant time. */
cmpresult_t BDuECC_vli_cmp(const BDuECC_word_t *left, const BDuECC_word_t *right, wordcount_t num_words);

/* Computes vli = vli >> 1. */
void BDuECC_vli_rshift1(BDuECC_word_t *vli, wordcount_t num_words);

/* Computes result = left + right, returning carry. Can modify in place. */
BDuECC_word_t BDuECC_vli_add(BDuECC_word_t *result,
                         const BDuECC_word_t *left,
                         const BDuECC_word_t *right,
                         wordcount_t num_words);

/* Computes result = left - right, returning borrow. Can modify in place. */
BDuECC_word_t BDuECC_vli_sub(BDuECC_word_t *result,
                         const BDuECC_word_t *left,
                         const BDuECC_word_t *right,
                         wordcount_t num_words);

/* Computes result = left * right. Result must be 2 * num_words long. */
void BDuECC_vli_mult(BDuECC_word_t *result,
                   const BDuECC_word_t *left,
                   const BDuECC_word_t *right,
                   wordcount_t num_words);

/* Computes result = left^2. Result must be 2 * num_words long. */
void BDuECC_vli_square(BDuECC_word_t *result, const BDuECC_word_t *left, wordcount_t num_words);

/* Computes result = (left + right) % mod.
   Assumes that left < mod and right < mod, and that result does not overlap mod. */
void BDuECC_vli_modAdd(BDuECC_word_t *result,
                     const BDuECC_word_t *left,
                     const BDuECC_word_t *right,
                     const BDuECC_word_t *mod,
                     wordcount_t num_words);

/* Computes result = (left - right) % mod.
   Assumes that left < mod and right < mod, and that result does not overlap mod. */
void BDuECC_vli_modSub(BDuECC_word_t *result,
                     const BDuECC_word_t *left,
                     const BDuECC_word_t *right,
                     const BDuECC_word_t *mod,
                     wordcount_t num_words);

/* Computes result = product % mod, where product is 2N words long.
   Currently only designed to work for mod == curve->p or curve_n. */
void BDuECC_vli_mmod(BDuECC_word_t *result,
                   BDuECC_word_t *product,
                   const BDuECC_word_t *mod,
                   wordcount_t num_words);

/* Calculates result = product (mod curve->p), where product is up to
   2 * curve->num_words long. */
void BDuECC_vli_mmod_fast(BDuECC_word_t *result, BDuECC_word_t *product, BDuECC_Curve curve);

/* Computes result = (left * right) % mod.
   Currently only designed to work for mod == curve->p or curve_n. */
void BDuECC_vli_modMult(BDuECC_word_t *result,
                      const BDuECC_word_t *left,
                      const BDuECC_word_t *right,
                      const BDuECC_word_t *mod,
                      wordcount_t num_words);

/* Computes result = (left * right) % curve->p. */
void BDuECC_vli_modMult_fast(BDuECC_word_t *result,
                           const BDuECC_word_t *left,
                           const BDuECC_word_t *right,
                           BDuECC_Curve curve);

/* Computes result = left^2 % mod.
   Currently only designed to work for mod == curve->p or curve_n. */
void BDuECC_vli_modSquare(BDuECC_word_t *result,
                        const BDuECC_word_t *left,
                        const BDuECC_word_t *mod,
                        wordcount_t num_words);

/* Computes result = left^2 % curve->p. */
void BDuECC_vli_modSquare_fast(BDuECC_word_t *result, const BDuECC_word_t *left, BDuECC_Curve curve);

/* Computes result = (1 / input) % mod.*/
void BDuECC_vli_modInv(BDuECC_word_t *result,
                     const BDuECC_word_t *input,
                     const BDuECC_word_t *mod,
                     wordcount_t num_words);

#if BDuECC_SUPPORT_COMPRESSED_POINT
/* Calculates a = sqrt(a) (mod curve->p) */
void BDuECC_vli_mod_sqrt(BDuECC_word_t *a, BDuECC_Curve curve);
#endif

/* Converts an integer in BDuECC native format to big-endian bytes. */
void BDuECC_vli_nativeToBytes(uint8_t *bytes, int num_bytes, const BDuECC_word_t *native);
/* Converts big-endian bytes to an integer in BDuECC native format. */
void BDuECC_vli_bytesToNative(BDuECC_word_t *native, const uint8_t *bytes, int num_bytes);

unsigned BDuECC_curve_num_words(BDuECC_Curve curve);
unsigned BDuECC_curve_num_bytes(BDuECC_Curve curve);
unsigned BDuECC_curve_num_bits(BDuECC_Curve curve);
unsigned BDuECC_curve_num_n_words(BDuECC_Curve curve);
unsigned BDuECC_curve_num_n_bytes(BDuECC_Curve curve);
unsigned BDuECC_curve_num_n_bits(BDuECC_Curve curve);

const BDuECC_word_t *BDuECC_curve_p(BDuECC_Curve curve);
const BDuECC_word_t *BDuECC_curve_n(BDuECC_Curve curve);
const BDuECC_word_t *BDuECC_curve_G(BDuECC_Curve curve);
const BDuECC_word_t *BDuECC_curve_b(BDuECC_Curve curve);

int BDuECC_valid_point(const BDuECC_word_t *point, BDuECC_Curve curve);

/* Multiplies a point by a scalar. Points are represented by the X coordinate followed by
   the Y coordinate in the same array, both coordinates are curve->num_words long. Note
   that scalar must be curve->num_n_words long (NOT curve->num_words). */
void BDuECC_point_mult(BDuECC_word_t *result,
                     const BDuECC_word_t *point,
                     const BDuECC_word_t *scalar,
                     BDuECC_Curve curve);

/* Generates a random integer in the range 0 < random < top.
   Both random and top have num_words words. */
int BDuECC_generate_random_int(BDuECC_word_t *random,
                             const BDuECC_word_t *top,
                             wordcount_t num_words);

#endif /* BDuECC_ENABLE_VLI_API */

#ifdef __cplusplus
} /* end of extern "C" */
#endif

#endif /* _BDUECC_VLI_H_ */
