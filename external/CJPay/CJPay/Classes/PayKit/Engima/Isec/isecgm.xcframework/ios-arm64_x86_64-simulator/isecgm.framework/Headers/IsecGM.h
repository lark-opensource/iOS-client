//
//  IsecGM.h
//  IsecGM
//
//  Created by infosec on 2022/7/3.
//  Copyright © 2022年 cn.com.infosec. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface IsecGM : NSObject

/* function */
#define isec_rtn_none                   0x00000000      /* success */
#define isec_rtn_fail                   0x0a000001      /* fail */
#define isec_rtn_internal               0x0a000002      /* internal error */
#define isec_rtn_param_null             0x0a000003      /* null parameter */
#define isec_rtn_param_invalid          0x0a000004      /* invalid parameter */
#define isec_rtn_buffer_too_small       0x0a000005      /* buffer too small */
#define isec_rtn_not_support            0x0a000006      /* not support */
#define isec_rtn_mac_different          0x0a000007      /* compare mac different */
/* system */
#define isec_rtn_file_not_exist         0x0a010001      /* file not exist */
#define isec_rtn_memory                 0x0a010002      /* memory error */
/* algorithm */
#define isec_rtn_key_invalid            0x0a020001      /* invalid key */
#define isec_rtn_iv_invalid             0x0a020002      /* invalid iv */
#define isec_rtn_aad_invalid            0x0a020003      /* invalid aad */
#define isec_rtn_tag_invalid            0x0a020004      /* invalid tag */
#define isec_rtn_encode_fail            0x0a020005      /* encode error */
#define isec_rtn_decode_fail            0x0a020006      /* decode error */
#define isec_rtn_hash_fail              0x0a020007      /* digest error */
#define isec_rtn_hmac_fail              0x0a020008      /* hmac error */
#define isec_rtn_cmac_fail              0x0a020009      /* cmac error */
#define isec_rtn_sign_fail              0x0a02000a      /* signature error */
#define isec_rtn_verify_fail            0x0a02000b      /* signature verify error */
#define isec_rtn_encrypt_fail           0x0a02000c      /* encrypt error */
#define isec_rtn_decrypt_fail           0x0a02000d      /* decrypt error */


/**
 * @brief 对称算法工作模式
 *
 */
typedef enum {
    CIPHER_ALG_MODE_ECB    = 1,  /* ECB */
    CIPHER_ALG_MODE_CBC    = 2,  /* CBC */
} ISEC_CIPHER_ALG_MODE;


/**
 * @brief 对称算法补位方式
 *
 */
typedef enum {
    CIPHER_PADDING_MODE_NONE  = 0,  /* no-padding */
    CIPHER_PADDING_MODE_PKCS7 = 1,  /* PKCS7-padding */
} ISEC_CIPHER_PADDING_MODE;

/**
 获取版本号
 @return NSString * 版本号字符串
 */
+ (NSString *)getVersion;

/**
 报文加密
 @param message   非空，待加密原文
 @param publicKey 非空，公钥，支持04||X||Y格式的65字节公钥或der编码公钥
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 密文数据包（HMAC + SM4密钥密文 + HMAC密钥密文 + 原文密文），失败返回nil
 */
- (NSData *)encryptMessage:(NSData *)message withPublicKey:(NSData *)publicKey withError:(NSInteger *)error;

/**
 报文解密
 @param message   非空，密文数据包（HMAC + 原文密文）
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 原文数据，失败返回nil
 */
- (NSData *)decryptMessage:(NSData *)message withError:(NSInteger *)error;

/**
 产生指定字节长度随机数
 @param length    正整数，输入指定字节长度，返回对应长度的随机数
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 随机数，失败返回nil
 */
- (NSData *)randomGenerateWithLength:(int)length withError:(NSInteger *)error;

/**
 SM2产生密钥对
 @param derEncode 输出密钥对格式，YES-DER编码，NO-原始密钥
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSDictionary * 密钥对(私钥["private"][NSData *]，公钥["public"][NSData *])，失败返回nil
 */
- (NSDictionary *)sm2GenerateKeyWithDerEncode:(BOOL)derEncode withError:(NSInteger *)error;

/**
 SM2加密
 @param message   非空，待加密原文
 @param publicKey 非空，公钥，支持04||X||Y格式的65字节公钥或der编码公钥
 @param derEncode 输出密文格式，YES-DER编码，NO-04||C1||C3||C2
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 密文，失败返回nil
 */
- (NSData *)sm2EncryptMessage:(NSData *)message withPublicKey:(NSData *)publicKey withDerEncode:(BOOL)derEncode withError:(NSInteger *)error;

/**
 SM2解密
 @param message    非空，待解密密文，支持DER编码格式或04||C1||C3||C2格式
 @param privateKey 非空，私钥，支持32字节或der编码私钥
 @param error      可空，返回错误码。0-成功，其他-失败
 @return NSData *  原文，失败返回nil
 */
- (NSData *)sm2DecryptMessage:(NSData *)message withPrivateKey:(NSData *)privateKey withError:(NSInteger *)error;

/**
 SM2签名
 @param message    非空，待签名原文
 @param privateKey 非空，私钥，支持32字节或der编码私钥
 @param derEncode  输出签名格式，YES-DER编码，NO-R||S
 @param error      可空，返回错误码。0-成功，其他-失败
 @return NSData *  签名，失败返回nil
 */
- (NSData *)sm2SignMessage:(NSData *)message withPrivateKey:(NSData *)privateKey withDerEncode:(BOOL)derEncode withError:(NSInteger *)error;

/**
 SM2验签
 @param message   非空，签名原文
 @param publicKey 非空，公钥，支持04||X||Y格式的65字节公钥或der编码公钥
 @param sign      非空，签名值，支持DER编码格式或R||S格式
 @param error     可空，返回错误码。0-成功，其他-失败
 @return BOOL     YES-成功，FALSE-失败
 */
- (BOOL)sm2VerifyMessage:(NSData *)message withPublicKey:(NSData *)publicKey withSign:(NSData *)sign withError:(NSInteger *)error;


/**
 SM3摘要
 @param message   非空，原文
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 摘要值，失败返回nil
 */
- (NSData *)sm3DigestMessage:(NSData *)message withError:(NSInteger *)error;

/**
 基于SM3的认证码
 @param message   非空，原文
 @param key       非空，密钥
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 消息认证码，失败返回nil
 */
- (NSData *)sm3HMACMessage:(NSData *)message withKey:(NSData *)key withError:(NSInteger *)error;


/**
 SM4密钥生成
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * SM4密钥，失败返回nil
 */
- (NSData *)sm4GenerateKeyWithError:(NSInteger *)error;

/**
 SM4加密
 @param message   非空，原文
 @param key       非空，密钥，必须16字节
 @param iv        初始向量，使用ECB时可空，必须16字节
 @param mode      算法工作模式，ECB/CBC
 @param padding   算法补位方式，NoPadding/PKCS7Padding，推荐使用PKCS7Paddin，如果使用NoPadding则原文长度必须是16的整数倍
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 密文，失败返回nil
 */
- (NSData *)sm4EncryptMessage:(NSData *)message withKey:(NSData *)key withIV:(NSData *)iv withMode:(ISEC_CIPHER_ALG_MODE)mode withPadding:(ISEC_CIPHER_PADDING_MODE)padding withError:(NSInteger *)error;

/**
 SM4加密
 @param message   非空，密文，密文长度必须是16的整数倍
 @param key       非空，密钥，必须16字节
 @param iv        初始向量，使用ECB时可空，必须16字节
 @param mode      算法工作模式，ECB/CBC
 @param padding   算法补位方式，NoPadding/PKCS5Padding，推荐使用PKCS7Paddin，如果使用NoPadding则原文长度必须是16的整数倍
 @param error     可空，返回错误码。0-成功，其他-失败
 @return NSData * 原文，失败返回nil
 */
- (NSData *)sm4DecryptMessage:(NSData *)message withKey:(NSData *)key withIV:(NSData *)iv withMode:(ISEC_CIPHER_ALG_MODE)mode withPadding:(ISEC_CIPHER_PADDING_MODE)padding withError:(NSInteger *)error;



@end
