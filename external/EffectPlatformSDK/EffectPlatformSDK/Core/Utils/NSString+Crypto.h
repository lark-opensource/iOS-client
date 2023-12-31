//
//  NSString+Crypto.h
//  AAWELaunchOptimization-Pods
//
//  Created by ZhangYuanming on 2020/7/31.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Crypto)

- (NSString *)ep_aes256_encrypt:(NSString *)key;


// 解密
- (NSString *)ep_aes256_decrypt:(NSString *)key;

- (NSString *)ep_aes256DecryptFromBase64WithKey:(NSString *)key;

- (NSString *)ep_encryptAES128ECB:(NSString *)key;

//Call this to Decrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSString *)ep_decryptAES128ECB:(NSString *)key;

- (NSString *)ep_encryptAES128CBC:(NSString *)key;

//Call this to Decrypt with ECB Cipher Transformation mode. Iv is not required for ECB
- (NSString *)ep_decryptAES128CBC:(NSString *)key;

- (NSString *)ep_aes128CBCDecryptFromBase64WithKey:(NSString *)key iv:(NSString *)iv;

@end

NS_ASSUME_NONNULL_END
