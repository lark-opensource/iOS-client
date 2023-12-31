//
//  CJPaySafeUtil.h
//  CJPay
//
//  Created by wangxinhua on 2018/10/25.
//

#import <Foundation/Foundation.h>
#import "CJPaySafeManager.h"
#import "CJPayCommonSafeHeader.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySafeUtil : NSObject

@property (nonatomic, copy) CJPaySafeManager *safeManager;

+ (NSString *)encryptPWD:(NSString *)pwd;

+ (NSString *)objEncryptPWD:(NSString *)pwd engimaEngine:(id<CJPayEngimaProtocol>)engimaEngine;

+ (NSString *)encryptPWD:(NSString *)pwd serialNumber:(NSString *) serialnum;

+ (NSString *)encryptField:(NSString *)field;

+ (NSString *)encryptContentFromH5:(NSString *)data;

+ (NSString *)encryptContentFromH5:(NSString *)data token:(NSString *)publicKey;

+ (NSString *)decryptContentFromH5:(NSString *)data;

+ (NSString *)objDecryptContentFromH5:(NSString *)data engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl;

+ (NSString *)objEncryptField:(NSString *)field engimaEngine:(id<CJPayEngimaProtocol>)engimaImpl;

@end

NS_ASSUME_NONNULL_END
