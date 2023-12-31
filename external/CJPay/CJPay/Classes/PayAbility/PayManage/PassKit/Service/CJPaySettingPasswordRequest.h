//
//  CJPaySettingPasswordRequest.h
//  CJPay
//
//  Created by 王新华 on 2019/5/20.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPayPassKitBaseResponse.h"
#import "CJPayMemBankInfoModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPaySettingPasswordResponse : CJPayPassKitBaseResponse

@property (nonatomic, copy) NSString *token;
@property (nonatomic, strong) CJPayMemBankInfoModel *bankCardInfo;

@end

@interface CJPaySettingPasswordRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params
             completion:(void(^)(NSError *error, CJPaySettingPasswordResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
