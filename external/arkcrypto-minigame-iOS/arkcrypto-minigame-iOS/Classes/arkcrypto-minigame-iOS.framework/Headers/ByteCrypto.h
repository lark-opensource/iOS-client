#ifndef _BYTECRYPTO_H_
#define _BYTECRYPTO_H_

#include <stdint.h>
#include <stdio.h>

//#include "ByteCryptoCommon.h"

#ifdef  __cplusplus
extern "C" {
#endif

#define KEY_SEED_SIZE       32
#define SHA512_HASH_SIZE           ( 512 / 8 )

typedef enum
{
    BC_ERR_SUCCESS = 0,
    BC_ERR_MAGIC,
    BC_ERR_METHOD,
    BC_ERR_MEMORY,
    BC_ERR_LENGTH,
    BC_ERR_VERIFY_FAILED,
    BC_ERR_UNKNOWN,
} e_BYTE_CRYPTO_ERROR;

typedef enum
{
    BC_METHOD_AES_CBC,
    BC_METHOD_AES_CBC_KS,   // KS = with KeySeed
    BC_METHOD_AES_CBC_EBK,      // EBK = embed key
    BC_METHOD_RC4_KS,
    BC_METHOD_RC4_EBK,
    BC_METHOD_HMAC_SIGN_V1,
    BC_METHOD_UNKNOWN,
} e_CRYPTO_METHOD;

typedef struct _BC_KeySeed{
    uint8_t      bytes [KEY_SEED_SIZE];
} BC_KeySeed;


size_t getEncryptBufferSize(size_t inLen, uint32_t method);
size_t getDecryptBufferSize(size_t inLen);

size_t getEncryptBufferSizeNaked(size_t inLen, uint32_t method);
size_t getDecryptBufferSizeNaked(size_t inLen); 

uint32_t getCryptoMethod();

uint32_t isSupportedMethod(uint32_t method);

int byteCryptoEncrypt(const uint8_t* inBuffer,
                    const size_t inLen,
                    uint8_t *outBuffer,
                    size_t *outLen,
                    BC_KeySeed *keySeed,
                    uint16_t cryptMethod);

int byteCryptoDecrypt(const uint8_t* inBuffer,
                    const size_t inLen,
                    uint8_t *outBuffer,
                    size_t *outLen,
                    BC_KeySeed *keySeed);

int byteCryptoDecryptNaked(const uint8_t* inBuffer,
                    const size_t inLen,
                    uint8_t *outBuffer,
                    size_t *outLen,
                    BC_KeySeed *keySeed,
                    uint16_t cryptMethod);

int byteCryptoEncryptNaked(const uint8_t* inBuffer,
                    const size_t inLen,
                    uint8_t *outBuffer,
                    size_t *outLen,
                    BC_KeySeed *keySeed,
                    uint16_t cryptMethod);

int genKeySeed(BC_KeySeed *keyseed);

#ifdef  __cplusplus
}
#endif

#endif