#ifndef __ISEC_CONFIG_H__
#define __ISEC_CONFIG_H__

#ifdef __cplusplus
extern "C" {
#endif

/* ISEC ERROR CODE */
/* FUNCTION */
#define ISEC_RTN_NONE                   0x00000000      /* success */
#define ISEC_RTN_FAIL                   0x0A000001      /* fail */
#define ISEC_RTN_INTERNAL               0x0A000002      /* internal error */
#define ISEC_RTN_PARAM_NULL             0x0A000003      /* null parameter */
#define ISEC_RTN_PARAM_INVALID          0x0A000004      /* invalid parameter */
#define ISEC_RTN_BUFFER_TOO_SMALL       0x0A000005      /* buffer too small */
#define ISEC_RTN_NOT_SUPPORT            0x0A000006      /* not support */
#define ISEC_RTN_MAC_DIFFERENT          0x0A000007      /* compare mac different */
/* SYSTEM */
#define ISEC_RTN_FILE_NOT_EXIST         0x0A010001      /* file not exist */
#define ISEC_RTN_MEMORY                 0x0A010002      /* memory error */
/* algorithm */
#define ISEC_RTN_KEY_INVALID            0x0A020001      /* invalid key */
#define ISEC_RTN_IV_INVALID             0x0A020002      /* invalid iv */
#define ISEC_RTN_AAD_INVALID            0x0A020003      /* invalid aad */
#define ISEC_RTN_TAG_INVALID            0x0A020004      /* invalid tag */
#define ISEC_RTN_ENCODE_FAIL            0x0A020005      /* encode error */
#define ISEC_RTN_DECODE_FAIL            0x0A020006      /* decode error */
#define ISEC_RTN_HASH_FAIL              0x0A020007      /* digest error */
#define ISEC_RTN_HMAC_FAIL              0x0A020008      /* HMAC error */
#define ISEC_RTN_CMAC_FAIL              0x0A020009      /* CMAC error */
#define ISEC_RTN_SIGN_FAIL              0x0A02000A      /* signature error */
#define ISEC_RTN_VERIFY_FAIL            0x0A02000B      /* signature verify error */
#define ISEC_RTN_ENCRYPT_FAIL           0x0A02000C      /* encrypt error */
#define ISEC_RTN_DECRYPT_FAIL           0x0A02000D      /* decrypt error */

/**
 * @BRIEF length define
 *
 */
#ifndef ISEC_MAX_MD_LEN
#define ISEC_MAX_MD_LEN             64      /* max digest length */
#endif

#ifndef ISEC_MAX_KEY_LEN
#define ISEC_MAX_KEY_LEN            64      /* max key length */
#endif

#ifndef ISEC_MAX_IV_LEN
#define ISEC_MAX_IV_LEN             64      /* max iv length */
#endif

/* SM2 key context */
typedef void* SM2_CONTEXT;

/**
 * @brief data format
 *
 */
typedef enum {
    ISEC_DATA_FORMAT_RAW = 0,   /* raw */
    ISEC_DATA_FORMAT_DER = 1,   /* asn1 */
}isec_data_format_enum;


/**
 * @brief Symmetric algorithm mode
 *
 */
typedef enum {
    ISEC_CIPHER_MODE_NONE   = 0,  /* undefine mode */
    ISEC_CIPHER_MODE_ECB    = 1,  /* ECB */
    ISEC_CIPHER_MODE_CBC    = 2,  /* CBC */
} isec_cipher_mode_enum;


/**
 * @brief Symmetric algorithm padding
 *
 */
typedef enum {
    ISEC_CIPHER_PADDING_NONE  = 0,  /* no-padding */
    ISEC_CIPHER_PADDING_PKCS7 = 1,  /* PKCS7-padding */
} isec_cipher_padding_enum;


#ifdef __cplusplus
}
#endif

#endif // __ISEC_CONFIG_H__
