//
// Created by bai on 9/23/22.
//

#ifndef MYAPPLICATION_LIB_H
#define MYAPPLICATION_LIB_H

#include <openssl/bn.h>
#include <openssl/ec.h>
#include <openssl/ecdh.h>
#include <openssl/ecdsa.h>
#include <openssl/nid.h>
#include <openssl/sha.h>

extern const int Success;
extern const int HKDFError;
extern const int EVPEncryptError;
extern const int BufNotEnoughError;
extern const int InvalidKeyError;
extern const int InvalidMessageLength;
extern const int IVLength;
extern const int TagLength;
extern const int MagicLength;
extern const int SignatureMaxLength;
extern const int PrivateKeyLength;
extern const int PublicKeyLength;
extern const int UncompressPublicKeyLength;

/**
 * 使用aes_key对msg进行加密,结果保存在out中,调用者确保空间足够.
 * @param out 密文保存位置
 * @param out_len 密文空间长度
 * @param aes_key 加密密钥
 * @param msg 明文
 * @param msg_len 明文长度
 * @return 成功返回正数密文长度,失败返回负数错误码
 */
int d_encrypt(uint8_t *out, int out_len, uint8_t aes_key[PrivateKeyLength],
              uint8_t *msg, int msg_len);

/**
 * 生成临时生成的对称密钥
 * @param aes_key 生成密钥保存为准
 * @param other_public_Key 对方的公钥
 * @param self_private_key 自己的私钥
 * @return 成功返回0,否则返回负数的错误码
 */
int generate_aes_key(uint8_t aes_key[PrivateKeyLength],
                     EC_KEY *other_public_Key, EC_KEY *self_private_key);

///计算密文的长度
int get_encrypted_len(int msg_len);

///计算明文的长度
int get_decrypted_len(int msg_len);

/**
 * 使用aes_key进行解密
 * @param out 解密后的明文
 * @param out_len  不小于get_decrypted_len(encrypted_msg_len)
 * @param aes_key  协商出来的aes 密钥
 * @param encrypted_msg  密文
 * @param encrypted_msg_len  密文长度
 * @return 成功返回正数明文长度,失败返回负数错误码
 */
int decrypt(uint8_t *out, int out_len, uint8_t aes_key[PrivateKeyLength],
            uint8_t *encrypted_msg, int encrypted_msg_len);

///从字节序列生成EC_KEY,调用者负责释放
EC_KEY *
create_EC_KEY_from_private_key_bin(uint8_t priv_Key_bin[PrivateKeyLength]);

///从公钥字节序列生成EC_KEY,调用者负责释放,注意这里的EC_KEY仅能用于验签,里面不包含私钥
EC_KEY *create_EC_KEY_from_public_key_bin(uint8_t *pub_key_bin, int key_length);

///生成随机私钥,调用者负责释放
EC_KEY *generate_keypair();

/**
 * 随机生成一个私钥,格式为字节序列
 * @param priv_key_bin 保存私钥的字节序列
 */
int generate_private_key(uint8_t priv_key_bin[PrivateKeyLength]);

/**
 * 使用priv_key对msg进行签名,结果保存在out_sig中
 * @param out_sig 确保空间不小于SignatureMaxLength
 * @param priv_key 签名用私钥
 * @param msg 消息
 * @param msg_len 消息长度
 * @return 返回签名长度,因为长度可能会变化
 */
int sign(uint8_t out_sig[SignatureMaxLength], EC_KEY *priv_key, uint8_t *msg,
         int msg_len);

/**
 * 验证签名
 * @param msg 消息
 * @param msg_len 消息长度
 * @param pub_key 验签用公钥
 * @param sig 签名
 * @param sig_len 签名长度
 * @return 失败返回负数错误码,否则返回0
 */
int verify(uint8_t *msg, int msg_len, EC_KEY *pub_key, uint8_t *sig,
           int sig_len);

/**
 * 获取priv_key中的公钥,保存在
 * @param pub_key_bin
 * @param priv_key
 * @return
 */
int get_public_key(uint8_t pub_key_bin[PublicKeyLength], EC_KEY *priv_key);

void dbg_print(char *hint, uint8_t *buf, int len);

#endif // MYAPPLICATION_LIB_H
