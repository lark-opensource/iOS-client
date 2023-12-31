//
//  rust_encrypt.h
//  ByteView
//
//  Created by ZhangJi on 2023/4/19.
//

#ifndef rust_encrypt_h
#define rust_encrypt_h

#include <stdarg.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>

typedef enum ResourceEncryptAlgorithm {
  CHACHA20_POLY1305 = 1,
  AES_256_GCM = 2,
} ResourceEncryptAlgorithm;

typedef enum ResourceEncryptResult {
  /**
   * 正常返回
   */
  OK = 0,
  /**
   * 不是加密资源
   */
  NOT_ENCRYPT_FILE = 1,
  /**
   * 密钥或 nonce 不符合预期
   */
  BAD_KEY,
  /**
   * 元数据过大
   */
  METADATA_TOO_LARGE,
  /**
   * 元数据解析失败
   */
  METADATA_PARSE_FAIL,
  /**
   * 元数据解密失败
   */
  DECRYPT_METADATA_FAIL,
  /**
   * 资源解密失败
   */
  DECRYPT_FILE_FAIL,
  /**
   * IO 错误，可从 errno 取 system error
   */
  IO_ERROR,
  /**
   * IO 错误，但没有 errno
   */
  IO_UNKNOWN,
  /**
   * 路径不符合 utf8 要求
   */
  PATH_NO_UTF8,
  /**
   * 文件长度不符合预期
   */
  BAD_FILE_LENGTH,
  /**
   * 不支持的算法
   */
  NO_SUPPORT_ALGORITHM,
  /**
   * 未知错误
   */
  UNKNOWN = 255,
} ResourceEncryptResult;

#ifdef __cplusplus
extern "C" {
#endif // __cplusplus

/**
 * # read all
 *
 * 将已加密资源解密并全部读到内存
 *
 * # 参数
 *
 * * app_resource_key: 应用资源密钥字节
 * * app_resource_key_len: 应用资源密钥长度, 若长度不一致将会返回 BAD_KEY
 * * path: 加密资源路径, 要求是 utf8 字符串
 * * buf_ptr: buffer 指针的可变引用；若正常返回，则会修改为指向解密后内容的
 *   buffer 指针；
 * 该 buffer 使用结束后，需要调用 `lark_sdk_resource_encrypt_free_buf` 释放内存
 * * buf_len: buffer 长度的可变引用；若正常返回，则会修改为 buffer 的长度
 */
enum ResourceEncryptResult lark_sdk_resource_encrypt_read_all(const uint8_t *app_resource_key,
                                                              size_t app_resource_key_len,
                                                              const uint8_t *path,
                                                              size_t path_len,
                                                              uint8_t **buf_ptr,
                                                              size_t *buf_len);

/**
 * # free buf
 *
 * 释放使用 `lark_sdk_resource_encrypt_read_all` 分配的内存
 */
void lark_sdk_resource_encrypt_free_buf(uint8_t *buf_ptr, size_t buf_len);

/**
 * 根据 `ResourceEncryptAlgorithm` 取密钥长度
 */
size_t lark_sdk_resource_encrypt_aead_key_len(enum ResourceEncryptAlgorithm alg);

/**
 * 往 buf 里填充随机密钥
 */
void lark_sdk_resource_encrypt_key_fill(uint8_t *buf, size_t len);

/**
 * 使用指定的 aead 算法进行加密
 *
 * 要求 output buffer 比 input buffer 至少长 64bytes，
 * 当不满足时会返回 `ResourceEncryptResult::BAD_FILE_LENGTH`。
 * 密钥长度不正确时会返回 `ResourceEncryptResult::BAD_KEY`。
 * 不支持的算法将会返回 `ResourceEncryptResult::NO_SUPPORT_ALGORITHM`。
 *
 * 加密成功将会返回 `ResourceEncryptResult::OK`，
 * 并且会修改 `output_len` 指针的值成加密输出的长度。
 */
enum ResourceEncryptResult lark_sdk_resource_encrypt_aead_seal(enum ResourceEncryptAlgorithm alg,
                                                               const uint8_t *key_buf,
                                                               size_t key_len,
                                                               const uint8_t *input_buf,
                                                               size_t input_len,
                                                               uint8_t *output_buf,
                                                               size_t *output_len);

/**
 * 使用指定的 aead 算法进行解密
 *
 * 要求 output buffer 不比 input buffer 短，
 * 当不满足时会返回 `ResourceEncryptResult::BAD_FILE_LENGTH`。
 * 密钥长度不正确时会返回 `ResourceEncryptResult::BAD_KEY`。
 * 不支持的算法将会返回 `ResourceEncryptResult::NO_SUPPORT_ALGORITHM`。
 * 解密失败将会返回 `ResourceEncryptResult::DECRYPT_FILE_FAIL`。
 *
 * 解密成功将会返回 `ResourceEncryptResult::OK`，
 * 并且会修改 `output_len` 指针的值成解密输出的长度。
 */
enum ResourceEncryptResult lark_sdk_resource_encrypt_aead_open(enum ResourceEncryptAlgorithm alg,
                                                               const uint8_t *key_buf,
                                                               size_t key_len,
                                                               const uint8_t *input_buf,
                                                               size_t input_len,
                                                               uint8_t *output_buf,
                                                               size_t *output_len);

#ifdef __cplusplus
} // extern "C"
#endif // __cplusplus


#endif /* rust_encrypt_h */
