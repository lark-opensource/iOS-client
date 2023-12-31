//
//  EMANetworkCipher.h
//  EEMicroAppSDK
//
//  Created by houjihu on 2019/9/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 用于加密网络响应参数的加密类
@interface EMANetworkCipher : NSObject

/// 用于生成加密密钥的key
@property(nonatomic, copy) NSString *key;
/// 用于生成加密密钥的iv
@property(nonatomic, copy) NSString *iv;
/// 加密密钥
@property(nonatomic, copy) NSString *encryptKey;

/// 生成新的加密密钥
+ (EMANetworkCipher *)cipher;

+ (instancetype)getCipher;

/**
 解密网络响应中的内容

 @param encryptedContent 加密内容
 @param cipher 加密密钥
 @return 返回解密后的内容
 */
+ (id)decryptDictForEncryptedContent:(NSString *)encryptedContent cipher:(EMANetworkCipher *)cipher;

@end

NS_ASSUME_NONNULL_END
