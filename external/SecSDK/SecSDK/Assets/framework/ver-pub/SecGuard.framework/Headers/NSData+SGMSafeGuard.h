//
//  NSData+SGMSafeGuard.h
//  SecSDK
//
//  Created by renfeng.zhang on 2018/1/19.
//  Copyright © 2018年 Zhi Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (SGMSafeGuard)

#pragma mark - 哈希

/* 从16进制str返回data */
+ (NSData *)sgm_dataWithHexString:(NSString *)hexString;

/* 返回数据的MD5哈希字符串 */
- (NSString *)sgm_data_acquisition_md5String;

/* 返回数据的MD5哈希 */
- (NSData *)sgm_data_acquisition_md5;

/* crc32 哈希字符串 */
- (NSString *)sgm_data_acquisition_crc32String;

- (unsigned long)sgm_data_acquisition_crc32Code;

#pragma mark - 压缩/解压缩

/**
 *  以默认压缩级别(Z_DEFAULT_COMPRESSION)对数据进行gzip压缩
 *
 *  @return 经过gzip压缩后的数据.
 */
- (nullable NSData *)sgm_data_acquisition_gzipCompress;


/**
 * 对gzip压缩数据进行解压缩.
 *
 * @return gzip解压缩后的数据.
 */
- (nullable NSData *)sgm_data_acquisition_gzipDecompress;


#pragma mark - 加密/解密

/**
 * 使用AES算法、CFB模式, no-padding填充方式对数据进行加密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes加密后的数据, 发生错误时返回nil.
 */
- (nullable NSData *)sgm_data_acquisition_cfb_encryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;


/**
 * 使用AES算法、CFB模式, no-padding填充方式对数据进行解密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes解密后的数据, 发生错误时返回nil.
 */
- (nullable NSData *)sgm_data_acquisition_cfb_decryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;

/**
 * 使用AES算法、CFB8模式, no-padding填充方式对数据进行加密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes加密后的数据, 发生错误时返回nil.
 */
- (nullable NSData *)sgm_data_acquisition_cfb8_encryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;


/**
 * 使用AES算法、CFB8模式, no-padding填充方式对数据进行解密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes解密后的数据, 发生错误时返回nil.
 */
- (nullable NSData *)sgm_data_acquisition_cfb8_decryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;

@end //NSData (SGMSafeGuard)

NS_ASSUME_NONNULL_END
