//
//  TTAdSplashSocketUtil.h
//  TTAdSplashSDK
//
//  Created by resober on 2018/11/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface TTAdSplashSocketUtil : NSObject
+ (instancetype)shared;
/** 将数值转成字节。编码方式：低位在前，高位在后 */
+ (NSData *)bytesFromUInt8:(uint8_t)val;
+ (NSData *)bytesFromUInt16:(uint16_t)val;
+ (NSData *)bytesFromUInt32:(uint32_t)val;
+ (NSData *)bytesFromUInt64:(uint64_t)val;
+ (uint8_t)uint8FromBytes:(NSData *)fData;
+ (uint16_t)uint16FromBytes:(NSData *)fData;
+ (uint32_t)uint32FromBytes:(NSData *)fData;
+ (uint64_t)uint64FromBytes:(NSData *)fData;
+ (NSData *)dataWithReverse:(NSData *)srcData;
+ (NSData *)bytesFromString:(NSString *)val;
+ (NSString *)hexStringFromData:(NSData *)data;
+ (NSString *)asciiStringFromHexString:(NSString *)hexString;
+ (NSString *)hexStringFromASCIIString:(NSString *)asciiString;
+ (NSString *)decimalStringFromHexString:(NSString *)hexString;
/**
 *  依据密码安全学生成的伪随机数
 *  @return 伪随机数 4字节 失败返回0
 */
+ (uint32_t)cryptographicallySecurePseudoRandomNumber;
- (uint)randomSequenceOfUnique;
@end

NS_ASSUME_NONNULL_END
