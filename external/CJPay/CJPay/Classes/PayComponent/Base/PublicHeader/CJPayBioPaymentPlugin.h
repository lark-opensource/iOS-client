//
//  CJPayBioPaymentPlugin.h
//  CJPay-Example
//
//  Created by 王新华 on 2021/9/7.
//

#ifndef CJPayBioPaymentPlugin_h
#define CJPayBioPaymentPlugin_h

@class CJPayBaseVerifyManager;
@class CJPayBDOrderResultResponse;
@class CJPayBDCreateOrderResponse;


NS_ASSUME_NONNULL_BEGIN

@protocol CJPayBioPaymentPlugin

- (void)correctLocalTime;

- (BOOL)pluginHasInstalled;

- (BOOL)isValidForCurrentUid:(NSString *)uid;

- (BOOL)hasValidToken;

// 判断是否需要展示生物识别引导
- (BOOL)shouldShowGuideWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse;

/// 是否显示到系统设置开启生物权限引导
- (BOOL)shouldShowBioSystemSettingGuideWithResultResponse:(CJPayBDOrderResultResponse *)resultResponse;

/// 跳转指纹引导页
/// @param verifyManager 验证组件manager
/// @param completion 引导页完成/点击返回block，注意，此方法不会自动关闭引导页，需要自己处理
- (void)showGuidePageVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager completionBlock:(void (^)(void))completion;

/// 跳转指纹引导页
/// @param verifyManager 验证组件manager
/// @param extParams 额外参数（例如定制引导页转场逻辑等）
/// @param completion 引导页完成/点击返回block，注意，此方法不会自动关闭引导页，需要自己处理
- (void)showGuidePageVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager
                               extParams:(NSDictionary * _Nullable)extParams
                         completionBlock:(void (^)(void))completion;

///// 到系统设置开启生物权限引导
///// @param verifyManager 验证组件manager
///// @param completion 引导页完成/点击返回block，注意，此方法不会自动关闭引导页，需要自己处理
- (void)showBioSystemSettingVCWithVerifyManager:(CJPayBaseVerifyManager *)verifyManager completionBlock:(void (^)(void))completion;

/// 跳转指纹引导页
/// @param response query接口response
/// @param verifyManager 验证组件manager
/// @param backBlock 引导页点击返回block，注意，此方法不会自动关闭引导页，需要自己处理
- (BOOL)showGuidePageVCWithResultResponse:(CJPayBDOrderResultResponse *)response verifyManager:(CJPayBaseVerifyManager *)verifyManager cjbackBlock:(void (^)(void))backBlock;

- (NSDictionary *)getPreTradeCreateBioParamDic;

- (NSString *)biometricParams;

- (BOOL)isBioPayAvailableWithResponse:(CJPayBDCreateOrderResponse *)response;

//判断是否可展示生物识别引导
- (BOOL)isBioGuideAvailable;

- (BOOL)isBiometryNotAvailable;

- (BOOL)isBiometryLockout;

- (NSString *)bioType;//0-none, 1-finger, 2-face

- (void)callBioVerifyWithParams:(NSDictionary *)params completionBlock:(void(^)(NSDictionary *resultDic))completionBlock;

- (void)openBioPay:(NSDictionary *)requestModel
   withExtraParams:(NSDictionary *)extraParams
        completion:(void(^)(NSError *error, BOOL result))completion;

- (void)asyncOpenBioPayWithResponse:(CJPayBDCreateOrderResponse *)response
                            lastPWD:(NSString *)lastPWD;

- (NSDictionary *)buildPwdDicWithModel:(NSDictionary *)requestModel
                               lastPWD:(NSString *)lastPWD;

@end

NS_ASSUME_NONNULL_END


#endif /* CJPayBioPaymentPlugin_h */
