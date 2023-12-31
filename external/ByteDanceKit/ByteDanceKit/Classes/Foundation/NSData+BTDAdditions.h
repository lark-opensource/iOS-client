//
//  NSData+BTDAdditions.h
//  ByteDanceKit
//
//  Created by wangdi on 2018/2/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSData (BTDAdditions)
/**
 @return md5字符串
 */
- (nonnull NSString *)btd_md5String;
/**
 @return 返回一个sha1的字符串
 */
- (nonnull NSString *)btd_sha1String;
/**

 @return 返回一个sha256的字符串
 */
- (nonnull NSString *)btd_sha256String;

- (nullable NSData *)btd_aes256EncryptWithKey:(nonnull NSData *)key iv:(nullable NSData *)iv __attribute__((deprecated("Please use the API from BDDataDecorator AES")));
- (nullable NSData *)btd_aes256DecryptWithkey:(nonnull NSData *)key iv:(nullable NSData *)iv __attribute__((deprecated("Please use the API from BDDataDecorator AES")));

/**
 将NSData数据转换成十六进制字符串
 
 @return 转换后的字符串
 */
- (NSString *)btd_hexString;

/**
 NSData生成一个NSArray或者NSDictionary

 @return 返回一个NSArray或者NSDictionary，如果出错返回空
 */
- (nullable id)btd_jsonValueDecoded;
- (nullable id)btd_jsonValueDecoded:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable NSArray *)btd_jsonArray;
- (nullable NSDictionary *)btd_jsonDictionary;

- (nullable NSArray *)btd_jsonArray:(NSError * _Nullable __autoreleasing * _Nullable)error;
- (nullable NSDictionary *)btd_jsonDictionary:(NSError * _Nullable __autoreleasing * _Nullable)error;

@end

NS_ASSUME_NONNULL_END
