//
//  NSData+Crypto.h
//  AAWELaunchOptimization-Pods
//
//  Created by ZhangYuanming on 2020/7/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (Crypto)

// 加密
- (NSData *)ep_aes256_encrypt:(NSString *)key;

// 解密
- (NSData *)ep_aes256_decrypt:(NSString *)key;

- (NSData *)ep_encryptAES128ECB:(NSString *)key;

//Call this to Decrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSData *)ep_decryptAES128ECB:(NSString *)key;

- (NSData *)ep_encryptAES128CBC:(NSString *)key iv:(NSString *)iv;

//Call this to Decrypt with CBC Cipher Transformation mode.
- (NSData *)ep_decryptAES128CBC:(NSString *)key iv:(NSString *)iv;

@end

NS_ASSUME_NONNULL_END
