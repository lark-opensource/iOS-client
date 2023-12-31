//
//  CJPayCashierModule.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/12.
//

#ifndef CJPayCashierModuleService_h
#define CJPayCashierModuleService_h
#import "CJPayProtocolServiceHeader.h"
#import "CJPayDYPayBizDeskModel.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayNameModel;
@protocol CJPayCashierModule <CJPayWakeByUniversalPayDeskProtocol>

/**
 设置收银台页面显示的title MOdel

 @param nameModel titleModel
 */
- (void)i_setupTitlesModel:(CJPayNameModel *)nameModel;

/**
 * 打开收银台界面  bizParams是由商户传入的参数
 **/
- (void)i_openPayDeskWithConfig:(NSDictionary *)configDic params:(nonnull NSDictionary *)bizParams delegate:(id<CJPayAPIDelegate>)delegate;

// 聚合链路抖音支付收银台（唤端支付收银台）
- (void)i_openDYPayBizDeskWithDeskModel:(CJPayDYPayBizDeskModel *)deskModel delegate:(id<CJPayAPIDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayCashierModuleService_h */

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayEcommerceDeskService <CJPayWakeByUniversalPayDeskProtocol>

/// 打开电商收银台
/// @param params 参数
- (void)i_openEcommercePayDeskWithParams:(nonnull NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

/// 打开大额转账收银台
/// @param params 参数
- (void)i_openECLargePayDeskWithParams:(nonnull NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

@end

@protocol CJPayFastPayService <CJPayWakeByUniversalPayDeskProtocol>

- (void)i_openFastPayDeskWithConfig:(NSDictionary *)configDic params:(nonnull NSDictionary *)bizParams delegate:(id<CJPayAPIDelegate>)delegate;

@end

@protocol CJPaySuperPayService <CJPayWakeByUniversalPayDeskProtocol>

- (void)i_openSuperPayWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

@end

@protocol CJPayPayUpgradeService <CJPayWakeByUniversalPayDeskProtocol>

- (void)i_openPayUpgradeWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate;

- (void)i_getWalletUrlWithParams:(NSDictionary *)params completion:(void (^)(NSString * _Nonnull walletUrl))completionBlock;

@end

NS_ASSUME_NONNULL_END

