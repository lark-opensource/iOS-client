//
//  CJPayEngimaProtocol.h
//  Pods
//
//  Created by 王新华 on 2022/7/6.
//

#ifndef CJPayEngimaProtocol_h
#define CJPayEngimaProtocol_h

NS_ASSUME_NONNULL_BEGIN
@protocol CJPayEngimaProtocol <NSObject>

+ (id<CJPayEngimaProtocol>)getEngimaProtocolBy:(NSString *)identify;
+ (id<CJPayEngimaProtocol>)getEngimaProtocolBy:(NSString *)identify useCert:(NSString *)cert;
- (NSString *)encryptWithData:(NSData *)data errorCode:(int *)errorCode;
- (NSString *)encryptWith:(NSString *)data errorCode:(int *)errorCode;
- (NSString *)decryptWith:(NSString *)data errorCode:(int *)errorCode;


/// 对称加解密
/// - Parameters:
///   - data: 加密数据
///   - key: 秘钥
///   - errorCode: 错误码
- (nullable NSString *)sm4Decrypt:(nonnull NSString *)data key:(nonnull NSString *)key
               errorCode:(int *)errorCode;
- (nullable NSString *)sm4Encrypt:(nonnull NSString *)data  key:(nonnull NSString *)key
               errorCode:(int *)errorCode;

@end
NS_ASSUME_NONNULL_END


#endif /* CJPayEngimaProtocol_h */
