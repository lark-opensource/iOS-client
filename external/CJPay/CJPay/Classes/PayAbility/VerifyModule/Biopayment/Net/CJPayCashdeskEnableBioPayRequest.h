//
//  CJPayCashdeskEnableBioPayRequest.h
//  Pods
//
//  Created by 利国卿 on 2021/7/28.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayCommonSafeHeader.h"
#import <JSONModel/JSONModel.h>
#import "CJPayBioPaymentBaseRequestModel.h"
#import "CJPayErrorButtonInfo.h"
#import "CJPayMemberEnableBioPayRequest.h"

NS_ASSUME_NONNULL_BEGIN

//  https://bytedance.feishu.cn/wiki/wikcnioOoUYde0H79iOEgt3RYEf

@interface CJPayCashdeskEnableBioPayResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *tokenFileStr;
@property (nonatomic, strong) CJPayErrorButtonInfo *buttonInfo;

@end

@interface CJPayCashdeskEnableBioPayRequest: CJPayBaseRequest

+ (void)startWithModel:(NSDictionary *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayCashdeskEnableBioPayResponse *response, BOOL result))completion;

@end

NS_ASSUME_NONNULL_END

