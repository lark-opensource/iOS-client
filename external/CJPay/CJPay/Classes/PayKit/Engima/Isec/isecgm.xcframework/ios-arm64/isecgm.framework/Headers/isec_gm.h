#ifndef __ISEC_GM_H__
#define __ISEC_GM_H__

#include "isec_config.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * \brief           sdk version
 *
 * \return          const string.
 */
const char* isec_gm_version(void);

/**
 * \brief           Generate random with length
 *
 * \param len       [in] the random length
 * \param output    [out] buffer that will hold the random
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_random(int len, unsigned char *output);

/**
 * \brief           Base64 encode
 *
 * \param input     [in] the plaintext to be encoded
 * \param ilen      [in] the plaintext length
 * \param output    [out] buffer that will hold the base64 string
 * \param olen      [in/out] base64 string length
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_base64_encode(const void *input, int ilen, char *output, int *olen);

/**
 * \brief           Base64 decode
 *
 * \param input     [in] the encodetext to be decoded
 * \param ilen      [in] the encodetext length
 * \param output    [out] buffer that will hold the plaintext
 * \param olen      [in/out] plaintext length
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_base64_decode(const char *input, int ilen, unsigned char *output, int *olen);


/**
 * \brief           Generate an SM2 keypair
 *
 * \param ctx       [out] SM2 context
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_sm2_genkey(SM2_CONTEXT *ctx);

/**
 * \brief           Free SM2 context
 *
 * \param ctx       [in] SM2 context
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_sm2_context_free(SM2_CONTEXT *ctx);

/**
 * \brief           Read key to SM2 context
 *
 * \param prikey    [in] external private key
 * \param prilen    [in] private key length
 * \param pubkey    [in] external public key
 * \param publen    [in] public key length
 * \param ctx       [out] SM2 context
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_sm2_read_key(const unsigned char *prikey, int prilen, const unsigned char *pubkey, int publen, isec_data_format_enum format, SM2_CONTEXT *ctx);

/**
 * \brief           Write key frome SM2 context
 *
 * \param ctx       [in] SM2 context
 * \param prikey    [out] output private key
 * \param prilen    [out] private key length
 * \param pubkey    [out] output public key
 * \param publen    [out] public key length
 *
 * \return          0 if successful, or a error code.
 */
int isec_gm_sm2_write_key(SM2_CONTEXT ctx, isec_data_format_enum format, unsigned char *prikey, int *prilen, unsigned char *pubkey, int *publen);

/**
 * \brief           Perform SM2 encryption
 *
 * \param ctx       [in] SM2 context
 * \param input     [in] the plaintext to be encrypted
 * \param ilen      [in] the plaintext length
 * \param output    [out] buffer that will hold the plaintext
 * \param olen      [in/out] will contain the plaintext length
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm2_encrypt(SM2_CONTEXT ctx, const unsigned char *input, int ilen, isec_data_format_enum format, unsigned char *output, int *olen);


/**
 * \brief           Perform SM2 decryption
 *
 * \param ctx       [in] SM2 context
 * \param input     [in] encrypted data
 * \param ilen      [in] the encrypted data length
 * \param output    [out] buffer that will hold the plaintext
 * \param olen      [in/out] will contain the plaintext length
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm2_decrypt(SM2_CONTEXT ctx, const unsigned char *input, int ilen, isec_data_format_enum format, unsigned char *output, int *olen);

/**
 * \brief           Compute SM2 signature of a previously hashed message
 *
 * \param ctx       [in] SM2 context
 * \param input     [in] the plaintext to be signed
 * \param ilen      [in] the plaintext length
 * \param output    [out] buffer that will hold the signature
 * \param olen      [in/out] will contain the signature length
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm2_sign(SM2_CONTEXT ctx, const unsigned char *input, int ilen, isec_data_format_enum format, unsigned char *output, int *olen);

/**
 * \brief           Compute SM2 signature of a previously hashed message
 *
 * \param ctx       [in] SM2 context
 * \param input     [in] the plaintext to be signed
 * \param ilen      [in] the plaintext length
 * \param sign      [in] signature value
 * \param siglen    [in] signature length
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm2_verify(SM2_CONTEXT ctx, const unsigned char *input, int ilen, isec_data_format_enum format, const unsigned char *sign, int siglen);

/**
 * \brief          SM3
 *
 * \param input    [in] buffer holding the data
 * \param ilen     [in] length of the input data
 * \param output   [out] SM3 checksum result(32 byte)
 * \param olen     [in/out] buffer of output, return real size
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm3(const unsigned char *input, int ilen, unsigned char *output, int *olen);


/**
 * \brief          SM3 HMAC
 *
 * \param key      [in] the hmac key
 * \param keylen   [in] length of the hmac key
 * \param input    [in] buffer holding the data
 * \param ilen     [in] length of the input data
 * \param output   [out] SM3 HMAC(32 byte)
 * \param olen     [in/out] buffer of output, return real size
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm3_hmac(const unsigned char *key, int keylen, const unsigned char *input, int ilen, unsigned char *output, int *olen);

/**
 * \brief          SM4 generate key
 *
 * \param output   [out] buffer that will hold the key
 * \param olen     [in/out] key length
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm4_genkey(unsigned char *output, int *olen);

/**
 * \brief          SM4 encrypt
 *
 * \param key      [in] key
 * \param keylen   [in] length of the key(16 bytes)
 * \param iv       [in] iv, not null when use CBC mode
 * \param ivlen    [in] length of the iv(16 bytes)
 * \param mode     [in] encrypt/decrypt mode
 * \param padding  [in] cipher padding
 * \param input    [in] the plaintext to be encrypted
 * \param ilen     [in] the plaintext length
 * \param output   [out] buffer that will hold the cipher
 * \param outlen   [in/out] buffer that will hold the cipher
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm4_encrypt(const unsigned char *key, int keylen, const unsigned char *iv, int ivlen, isec_cipher_mode_enum mode, isec_cipher_padding_enum padding, const unsigned char *input, int ilen, unsigned char *output, int *outlen);


/**
 * \brief          SM4 decrypt
 *
 * \param key      [in] key
 * \param keylen   [in] length of the key(16 bytes)
 * \param iv       [in] iv, not null when use CBC mode
 * \param ivlen    [in] length of the iv(16 bytes)
 * \param mode     [in] encrypt/decrypt mode
 * \param padding  [in] cipher padding
 * \param input    [in] the ciphertext to be decrypted
 * \param ilen     [in] the ciphertext length
 * \param output   [out] buffer that will hold the cipher
 * \param outlen   [in/out] buffer that will hold the cipher
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_sm4_decrypt(const unsigned char *key, int keylen, const unsigned char *iv, int ivlen, isec_cipher_mode_enum mode, isec_cipher_padding_enum padding, const unsigned char *input, int ilen, unsigned char *output, int *outlen);


/**
 * \brief          Message encrypt
 *
 * \param pubkey      [in] external public key
 * \param publen      [in] public key length
 * \param plain       [in] the plaintext to be encrypted
 * \param plainlen    [in] the plaintext length
 * \param cipher      [out]  output cipher(HMAC + SM4 key cipher + HMAC key cipher + plain cipher)
 * \param cipherlen   [in/out] length of the cipher
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_message_encrypt(const unsigned char *pubkey, int publen, const void *plain, int plainlen, unsigned char *cipher, int *cipherlen);

/**
 * \brief          Message decrypt
 *
 * \param cipher      [in] plain cipher(HMAC + plain cipher)
 * \param cipherlen   [in] length of the cipher
 * \param plain       [out] the plaintext
 * \param plainlen    [in/out] the plaintext length
 *
 * \return          0 if successful, or a error code
 */
int isec_gm_message_decrypt(const unsigned char *cipher, int cipherlen, unsigned char *plain, int *plainlen);


#ifdef __cplusplus
}
#endif

#endif // __ISEC_GM_H__
