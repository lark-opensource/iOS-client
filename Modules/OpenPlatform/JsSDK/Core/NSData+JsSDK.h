//
//  NSData+JsSDK.h
//  LarkWeb
//
//  Created by 武嘉晟 on 2019/9/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (JsSDK)

/**
 *  RSA加密数据
 *
 *  @param data   待加密数据
 *  @param pubKey 公钥
 *  @param error  错误
 *
 *  @return 加密后的数据
 */
+ (nullable NSData *)web_encryptData:(NSData *)data publicKey:(NSString *)pubKey error:(NSError **)error;

/**
 *  使用RSA对数据进行认证
 *
 *  @param data   待认证的数据
 *  @param pubKey 公钥
 *  @param error  错误信息
 *
 *  @return 认证后的数据
 */
+ (nullable NSData *)web_decryptData:(NSData *)data publicKey:(NSString *)pubKey error:(NSError **)error;

/**
 *  将Base64格式的字符串转换成NSData
 *
 *  @param base64String Base64格式的字符串
 *
 *  @return 转换后的数据
 */
+ (nullable NSData *)web_dataWithBase64EncodedString:(NSString *)base64String;

/**
 *  将NSData转换成Base64格式字符串
 *
 *  @return 转换后的字符串
 */
- (nullable NSString *)web_base64EncodedString;


/**
 *  将NSData转换成MD5加密的字符串
 *
 *  @return 转换后的字符串
 */
- (nullable NSString *)web_md5String;

/**
 *  将NSData数据转换成十六进制字符串
 *
 *  @return 转换后的字符串
 */
- (NSString *)web_hexadecimalString;

@end

NS_ASSUME_NONNULL_END
