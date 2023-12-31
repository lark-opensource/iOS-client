//
//  NSData+DecoratorAdditions.h
//  BDDataDecorator
//
//  Created by bob on 2020/1/9.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*! @abstract AES 加密 key size类型
 @discussion key size要和传入的key符合
*/
typedef NS_ENUM(NSInteger, BDDecoratorKeySize) {
    BDDecoratorKeySizeAES128 = 0x10, /// 对应key的byte是16字节
    BDDecoratorKeySizeAES192 = 0x18, /// 对应key的byte是24字节
    BDDecoratorKeySizeAES256 = 0x20, /// 对应key的byte是32字节
};

@interface NSData (DecoratorAdditions)

/*! @abstract AES 加密方法
 @param key 加密的key，这个需要和keySize对应的byte一致
 @param iv 如果 iv是nil，则使用EBC模式，不为nil则使用CBC模式
 @result 加密结果，失败则返回nil
 @discussion key的长度要是 16 、24、 32中的一种
 @discussion 此方法是copy <ByteDanceKit/NSData+BTDAdditions.h>，方法业务迁移适配
*/
- (nullable NSData *)bdd_aes256EncryptWithKey:(NSData *)key iv:(nullable NSData *)iv;

/*! @abstract AES 解密方法
 @param key 加密的key，这个需要和keySize对应的byte一致
 @param iv 如果 iv是nil，则使用EBC模式，不为nil则使用CBC模式
 @result 加密结果，失败则返回nil
 @discussion key的长度要是 16 、24、 32中的一种
 @discussion 此方法是copy <ByteDanceKit/NSData+BTDAdditions.h>，方法业务迁移适配
*/
- (nullable NSData *)bdd_aes256DecryptWithkey:(NSData *)key iv:(nullable NSData *)iv;





/*! @abstract AES 加密方法
 @param key 加密的key，这个需要和keySize对应的byte一致。如果过长，会截断；如果过短，默认用0填充
 @param keySize 参考枚举值BDDecoratorKeySize三种选项
 @param iv 如果 iv是nil，则使用EBC模式，不为nil则使用CBC模式
 @result 加密结果，失败则返回nil
 @discussion key和keySize要对应
*/
- (nullable NSData *)bdd_aesEncryptWithkey:(NSString *)key
                                   keySize:(BDDecoratorKeySize)keySize
                                        iv:(nullable NSString *)iv;

/*! @abstract AES 加密方法
 @param keyData 加密的key，这个需要和keySize对应的byte一致。如果过长，会截断；如果过短，默认用0填充
 @param keySize 参考枚举值BDDecoratorKeySize三种选项
 @param ivData 如果 iv是nil，则使用EBC模式，不为nil则使用CBC模式
 @result 加密结果，失败则返回nil
 @discussion key和keySize要对应
*/
- (nullable NSData *)bdd_aesEncryptWithkeyData:(NSData *)keyData
                                       keySize:(BDDecoratorKeySize)keySize
                                        ivData:(nullable NSData *)ivData;

/*! @abstract AES 解密方法
 @param key 加密的key，这个需要和keySize对应的byte一致。如果过长，会截断；如果过短，默认用0填充
 @param keySize 参考枚举值BDDecoratorKeySize三种选项
 @param iv 如果 iv是nil，则使用EBC模式，不为nil则使用CBC模式
 @result 解密结果，失败则返回nil
 @discussion key和keySize要对应
*/
- (nullable NSData *)bdd_aesDecryptwithKey:(NSString *)key
                                   keySize:(BDDecoratorKeySize)keySize
                                        iv:(nullable NSString *)iv;

/*! @abstract AES 解密方法
 @param keyData 加密的key，这个需要和keySize对应的byte一致。如果过长，会截断；如果过短，默认用0填充
 @param keySize 参考枚举值BDDecoratorKeySize三种选项
 @param ivData 如果 iv是nil，则使用EBC模式，不为nil则使用CBC模式
 @result 解密结果，失败则返回nil
 @discussion key和keySize要对应
*/
- (nullable NSData *)bdd_aesDecryptwithKeyData:(NSData *)keyData
                                       keySize:(BDDecoratorKeySize)keySize
                                        ivData:(nullable NSData *)ivData;
@end

NS_ASSUME_NONNULL_END
