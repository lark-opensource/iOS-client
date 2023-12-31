//
//  CJPayRechargeService.h
//  Pods
//
//  Created by wangxiaohong on 2020/12/5.
//

#ifndef CJPayRechargeService_h
#define CJPayRechargeService_h
#import "CJPaySDKDefine.h"

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayRechargeService <NSObject>

- (void)i_openH5RechargeDeskWithParams:(NSDictionary *)params delegate:(nullable id<CJPayAPIDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayRechargeService_h */
