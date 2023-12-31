//
//  NSString+SGMSafeGuard.h
//  SecSDK
//
//  Created by renfeng.zhang on 2018/1/19.
//  Copyright © 2018年 Zhi Lee. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (SGMSafeGuard)

/* crc32 哈希字符串 */
- (NSString *)sgm_data_acquisition_crc32String;

- (unsigned long)sgm_data_acquisition_crc32Code;

/* 将NSData转换为十六进制字符串 */
+ (NSString *)sgm_data_acquisition_dataToHexString:(NSData *)data;

/* 将十六进制字符串转换为NSData */
+ (NSData *)sgm_data_acquisition_hexStringToData:(NSString *)hexString;

#pragma mark - 加密/解密

/**
 * 使用AES算法、CFB模式, no-padding填充方式对数据进行加密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes加密后的数据, 发生错误时返回nil.
 */
- (nullable NSString *)sgm_data_acquisition_cfb_encryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;


/**
 * 使用AES算法、CFB模式, no-padding填充方式对数据进行解密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes加密后的数据, 发生错误时返回nil.
 */
- (nullable NSString *)sgm_data_acquisition_cfb_decryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;

/**
 * 使用AES算法、CFB8模式, no-padding填充方式对数据进行加密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes加密后的数据, 发生错误时返回nil.
 */
- (nullable NSString *)sgm_data_acquisition_cfb8_encryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;


/**
 * 使用AES算法、CFB8模式, no-padding填充方式对数据进行解密
 *
 * @param key 加密秘钥(长度为16、24、32,即128字节、192字节、256字节)
 * @param iv  初始向量(长度为16, 即128字节, 默认值全为0), 如果不需要使用的时候传入nil.
 *
 * @return aes加密后的数据, 发生错误时返回nil.
 */
- (nullable NSString *)sgm_data_acquisition_cfb8_decryptWithKey:(NSData *)key initializationVector:(nullable NSData *)iv;

@end //NSString (SGMSafeGuard)

NS_ASSUME_NONNULL_END
