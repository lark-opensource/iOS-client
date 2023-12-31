//
//  CJPayMemberEnableBioPayRequest.h
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayCommonSafeHeader.h"
#import <JSONModel/JSONModel.h>
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayErrorButtonInfo.h"

NS_ASSUME_NONNULL_BEGIN

//  https://bytedance.feishu.cn/wiki/wikcnioOoUYde0H79iOEgt3RYEf
@interface CJPayBioSafeModel : NSObject

@property (nonatomic, copy) NSString *magicStr; // 用于解密后，识别密钥信息的标记。默认值约定为：caijing_pay
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *serialNum; // Token序列号
@property (nonatomic, copy) NSString *seedHexString; // 对密钥值进行16进制编码后的值
@property (nonatomic, copy) NSString *vendor; // 标示此Token使用的算法，由数字字母组成，如TOTP，HOTP等
@property (nonatomic, assign) NSInteger tokenLength;  // 动态口令长度，如d6，d8等
@property (nonatomic, copy) NSString *expireTime; // 过期时间
@property (nonatomic, assign) NSInteger timeStep; // 时间步长
@property (nonatomic, assign) NSInteger pwdType; // 用于解密后，识别密钥信息的标记。默认值约定为：caijing_pay

- (instancetype)initWithTokenFile:(NSString *)tokenFile;

- (BOOL)isValid;

@end

@interface CJPayMemberEnableBioPayResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *tokenFileStr;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

@interface CJPayMemberEnableBioPayRequest: CJPayBaseRequest

+ (void)startWithModel:(CJPayBioPaymentBaseRequestModel *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayMemberEnableBioPayResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
