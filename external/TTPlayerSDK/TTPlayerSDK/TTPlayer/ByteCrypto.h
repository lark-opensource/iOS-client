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
    BC_METHOD_RC4,
    BC_METHOD_RC4_EBK,
    BC_METHOD_HMAC_SIGN_V1,
    BC_METHOD_UNKNOWN,
} e_CRYPTO_METHOD;

size_t TTVideo_getEncryptBufferSize(size_t inLen, uint32_t method);
size_t TTVideo_getDecryptBufferSize(size_t inLen);

uint32_t TTVideo_getCryptoMethod();

uint32_t TTVideo_isSupportedMethod(uint32_t method);

int TTVideo_byteCryptoEncrypt(const uint8_t* inBuffer,
                    const size_t inLen,
                    uint8_t *outBuffer,
                    size_t *outLen,
                    uint8_t *keySeed,
                    uint16_t cryptMethod);

int TTVideo_byteCryptoDecrypt(const uint8_t* inBuffer,
                    const size_t inLen,
                    uint8_t *outBuffer,
                    size_t *outLen,
                    uint8_t *keySeed);

int TTVideo_genKeySeed(uint8_t *key);

#ifdef  __cplusplus
}
#endif

#endif