//
//  CJPayH5DeskModule.h
//  CJPay
//
//  Created by wangxinhua on 2020/7/13.
//

#ifndef CJPayH5DeskService_h
#define CJPayH5DeskService_h

#import "CJPaySDKDefine.h"

typedef NS_ENUM(NSInteger, CJH5CashDeskStyle) {
    CJH5CashDeskStyleVertivalHalfScreen = 0, //竖屏半屏、无title、透明
    CJH5CashDeskStyleVertivalFullScreen = 1, //竖屏全屏、无title、暂不关注透明、需要closeWebview
    CJH5CashDeskStyleLandscapeHalfScreen = 2, //横屏半屏
};

typedef NS_ENUM(NSUInteger, CJPayH5SetPasswordDeskCallBackType) {
    CJPayH5SetPasswordDeskCallBackTypeCancel,
    CJPayH5SetPasswordDeskCallBackTypeSuccess,
};

NS_ASSUME_NONNULL_BEGIN

@protocol CJPayH5DeskModule <NSObject>

- (void)i_openH5PayDesk:(NSString *)url withDelegate:(id<CJPayAPIDelegate>)delegate;
// 
- (void)i_openH5PayDesk:(NSDictionary *)orderInfoDic deskStyle:(CJH5CashDeskStyle)deskStyle withDelegate:(id<CJPayAPIDelegate>)delegate;

// 打开H5支付管理
- (void)i_openH5PayManagerWithAppId:(NSString *)appId merchantId:(NSString *)merchantId;

// 打开H5交易记录页面
- (void)i_openH5TradeRecordWithAppId:(NSString *)appId merchantId:(NSString *)merchantId;

// 打开H5余额提现收银台
- (void)i_openH5BalanceWithdrawDeskWithParams:(NSDictionary *_Nullable)params
                                     delegate:(nullable id<CJPayAPIDelegate>)delegate;
// 打开H5支付收银台
- (void)i_openH5BDPayDesk:(NSDictionary *)orderInfoDic withDelegate:(id<CJPayAPIDelegate>)delegate;

// H5设置密码,webView中实现
- (void)i_openH5SetPasswordDeskWithParams:(nonnull NSDictionary *)params
                             withDelegate:(id<CJPayAPIDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END

#endif /* CJPayH5DeskService_h */
