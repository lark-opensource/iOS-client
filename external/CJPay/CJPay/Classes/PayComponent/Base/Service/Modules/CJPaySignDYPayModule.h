//
//  CJPaySignDYPayModel.h
//  Pods
//
//  Created by wangxiaohong on 2022/7/14.
//


#ifndef CJPaySignDYPayModule_h
#define CJPaySignDYPayModule_h
#import "CJPaySDKDefine.h"
#import "CJPayProtocolServiceHeader.h"
#import <JSONModel/JSONModel.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CJPaySignDYPayModule <CJPayWakeByUniversalPayDeskProtocol>

//签约并支付
- (void)i_signAndPayWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate;

//独立签约
- (void)i_signOnlyWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate;

- (void)i_requestSignAndPayInfoWithBizParams:(NSDictionary *)bizParams completion:(void(^)(BOOL isSuccess, JSONModel *response, NSDictionary *extraData))completionBlock;

- (void)i_requestSignOnlyInfoWithBizParams:(NSDictionary *)bizParams completion:(void(^)(BOOL isSuccess, JSONModel *response, NSDictionary *extraData))completionBlock;

@end

#endif /* CJPaySignDYPayModule_h */

NS_ASSUME_NONNULL_END
