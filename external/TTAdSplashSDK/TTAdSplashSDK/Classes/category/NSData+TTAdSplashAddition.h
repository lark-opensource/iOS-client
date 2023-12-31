//
//  NSData+TTAdSplashAddition.h
//  TTAdSplashSDK
//
//  Created by resober on 2018/11/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (TTAdSplashAddition)
/**
 * @return 返回自身的MD5的16进制字串
 */
- (NSString *)ttad_MD5;
- (NSString *)ttad_SHA1;
- (NSString *)ttad_SHA256;
- (NSString *)ttad_SHA512;
- (NSString *)ttad_hexadecimalString;

/// 使用AES-256-GCM 解密, 前 12 字节为随机字符串，key 需要进行 hex 解码（64->32字节）
- (NSData *)BDASplashAes256Encrypt:(NSString *)key;

/// 使用AES-256-GCM 解密，取密文前12字节作为 nounce，key 需要进行 hex 解码（64->32字节）
- (NSData *)BDASplashAes256Decrypt:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
