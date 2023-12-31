//
//  CJPayUserCenterModule.h
//  CJPay-655ba357
//
//  Created by wangxiaohong on 2020/8/20.
//

#ifndef BDPayNativeUserCenterService_h
#define BDPayNativeUserCenterService_h
#import "CJPaySDKDefine.h"
#import "CJPayProtocolServiceHeader.h"


NS_ASSUME_NONNULL_BEGIN

@protocol CJPayUserCenterModule <CJPayWakeBySchemeProtocol>

- (void)i_openNativeBalanceWithdrawDeskWithParams:(NSDictionary *)params delegate:(nullable id<CJPayAPIDelegate>)delegate;

- (void)i_openNativeBalanceRechargeDeskWithParams:(NSDictionary *)params delegate:(nullable id<CJPayAPIDelegate>)delegate;


@end

NS_ASSUME_NONNULL_END

#endif /* BDPayNativeUserCenterService_h */
