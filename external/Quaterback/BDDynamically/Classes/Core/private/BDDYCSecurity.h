//
//  BDDYCSecurity.h
//  BDDynamically
//
//  Created by zuopengliu on 21/5/2018.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN


#define BDDYC_AES_IV_SIZE  16
#define BDDYC_AES_KEY_SIZE 32


#if BDAweme
__attribute__((objc_runtime_name("AWECFHalcyon")))
#elif BDNews
__attribute__((objc_runtime_name("TTDFower")))
#elif BDHotSoon
__attribute__((objc_runtime_name("HTSDLeopard")))
#elif BDDefault
__attribute__((objc_runtime_name("BDDMaterConvolvulus")))
#endif
@interface BDDYCSecurity : NSObject

@end

#pragma mark -

@interface BDDYCSecurity (BASE64)

+ (NSString *)base64Encode:(NSString *)text;

+ (NSString *)base64Decode:(NSString *)text;

@end

#pragma mark -

@interface BDDYCSecurity (MD5)

+ (NSString *)MD5File:(NSString *)filePath;

+ (NSString *)MD5Data:(id /* NSString or NSData */)data;

@end

#pragma mark -

@interface BDDYCSecurity (Symmetric)

+ (NSData *)paddedDataOfKey:(NSString *)keyString
              numberOfBytes:(size_t)numberOfBytes;

// 生成随机值
+ (NSData *)randomDataOfNumberOfBytes:(size_t)length;

+ (NSData *)randomIVData;
+ (NSData *)randomKeyData;
+ (NSString *)randomKeyString;

/**
 采用AES加密数据
 
 @param data    待加密的数据
 @param keyData 密钥数据 (32 bytes)
 @param ivData  初始化向量数据 (16 bytes)，nil表示使用ECB Mode加密，否则使用CBC Mode加密
 @return 返回加密数据
 */
+ (NSData *)AESEncryptData:(NSData *)data
                   keyData:(NSData *)keyData /** 密钥 */
                    ivData:(NSData * _Nullable)ivData; /** 初始化向量 (16 bytes) */

// return raw data
+ (NSData *)AESEncryptData:(NSData *)data
                 keyString:(NSString *)keyString /** 密钥 */
                  ivString:(NSString * _Nullable)ivString; /** 初始化向量 (16 bytes) */

/**
 采用AES加密数据，返回base64编码的数据
 
 @param dataText  待加密的数据
 @param keyString 密钥
 @param ivString  初始化向量数据，nil表示使用ECB Mode加密，否则使用CBC Mode加密
 @return 返回对加密数据进行Base64编码的字符串
 */
+ (NSString *)AESEncryptString:(NSString *)dataText
                     keyString:(NSString *)keyString /** 密钥 */
                      ivString:(NSString * _Nullable)ivString; /** 初始化向量 (16 bytes) */

+ (NSString *)AESEncryptString:(NSString *)dataText
                       keyData:(NSData *)keyData /** 密钥 (32 bytes) */
                        ivData:(NSData * _Nullable)ivData; /** 初始化向量 (16 bytes) */

#pragma mark -

/**
 采用AES解密数据
 
 @param data    待解密的数据
 @param keyData 密钥数据
 @param ivData  初始化向量数据，nil表示使用ECB Mode加密，否则使用CBC Mode加密
 @return 解密的数据
 */
+ (NSData *)AESDecryptData:(NSData *)data
                   keyData:(NSData *)keyData
                    ivData:(NSData * _Nullable)ivData;

// return decrypted raw data
+ (NSData *)AESDecryptData:(NSData *)data
                 keyString:(NSString *)keyString
                  ivString:(NSString * _Nullable)ivString;

/**
 将文本数据进行base64解码，然后使用AES解密数据，并将数据转化为UTF8字符串
 
 decrypt base64 encoded string, convert `data` to UTF8 string (not base64 encoded)
 
 @param dataText  待解密的数据
 @param keyString 密钥
 @param ivString  初始化向量数据，nil表示使用ECB Mode加密，否则使用CBC Mode加密
 @return 返回解密数据
 */
+ (NSString *)AESDecryptString:(NSString *)dataText
                     keyString:(NSString *)keyString /** 密钥 */
                      ivString:(NSString * _Nullable)ivString; /** nil 使用ECB Mode */

+ (NSString *)AESDecryptString:(NSString *)dataText
                       keyData:(NSData *)keyData /** 密钥 */
                        ivData:(NSData * _Nullable)ivData; /** nil 使用ECB Mode */

@end

#pragma mark -

@interface BDDYCSecurity (Asymmetric)

// return base64 encoded string
+ (NSString *)RSAEncryptString:(NSString *)str
                     publicKey:(NSString *)pubKey;

// return raw data
+ (NSData *)RSAEncryptData:(NSData *)data
                 publicKey:(NSString *)pubKey;

// decrypt base64 encoded string, convert `data` to string (not base64 encoded)
+ (NSString *)RSADecryptString:(NSString *)str
                     publicKey:(NSString *)pubKey;

// return decrypted raw data
+ (NSData *)RSADecryptData:(NSData *)data
                 publicKey:(NSString *)pubKey;

@end


NS_ASSUME_NONNULL_END
