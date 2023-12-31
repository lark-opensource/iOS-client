//
//  AliyunEncryptor.h
//  AliyunIdentityPlatform
//
//  Created by nansong.zxc on 2021/7/28.
//  Copyright © 2021 aliyun.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AliyunEncryptorforTech : NSObject

/**
 * 国密sm4加解密
 */
+ (NSString *)sm4_encrypt_9_helper:(NSString *)plainText withKey:(NSString *)key;
+ (NSString *)sm4_decrypt_9_helper:(NSString *)plainText withKey:(NSString *)key;

/**
 * 计算NSData HASH值
 */
+ (NSData *)calc_data_hash:(NSData *)src;

/**
 * bytes转hex
 */
+ (NSString *)dataToHexString:(NSData *)src;
@end

NS_ASSUME_NONNULL_END
