/*********************************************************************
* Filename:   md5.h
* Author:     Brad Conte (brad AT bradconte.com)
* Copyright:
* Disclaimer: This code is presented "as is" without any guarantees.
* Details:    Defines the API for the corresponding MD5 implementation.
*********************************************************************/

#ifndef _UTIL_MD5_H_
#define _UTIL_MD5_H_

#ifdef __cplusplus
extern "C" {
#endif

/*************************** HEADER FILES ***************************/
#include <stdint.h>

/****************************** MACROS ******************************/
#define MD5_BLOCK_SIZE 16               // MD5 outputs a 16 byte digest

typedef struct {
   uint8_t data[64];
   uint32_t datalen;
   unsigned long long bitlen;
   uint32_t state[4];
} MD5_CTX;

/*********************** FUNCTION DECLARATIONS **********************/
void md5_init(MD5_CTX *ctx);
void md5_update(MD5_CTX *ctx, const void* data, size_t len);
void md5_final(MD5_CTX *ctx, void* hash);
void md5_buffer(void* hash, const void* data, size_t len);
    
#ifdef __cplusplus
}
#endif

#endif /* _UTIL_MD5_H_ */
