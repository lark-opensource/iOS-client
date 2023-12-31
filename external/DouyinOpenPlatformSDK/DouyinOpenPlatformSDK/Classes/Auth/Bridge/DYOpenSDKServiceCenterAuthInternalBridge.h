//
//  DYOpenSDKServiceCenterAuthInternalBridge.h
//  DouyinOpenPlatformSDK
//
//  Created by ByteDance on 2022/8/25.
//

#import <Foundation/Foundation.h>
#import "DouyinOpenSDKAuth.h"

NS_ASSUME_NONNULL_BEGIN

@class DouyinOpenSDKAuthRequest;

/// --- Auth 相关
@protocol DYOpenSDKServiceCenterAuthInternalBridge <NSObject>
@optional
/// @brief 发送手机授权请求
/// @param req 请求 model
/// @param vc 从哪个 vc present 手机授权页面
/// @param useHalf 是否使用半屏展示
/// @param complete 授权完成回调
- (void)internal_sendPhoneAuthRequest:(nonnull DouyinOpenSDKAuthRequest *)req
                              useHalf:(BOOL)useHalf
                             isSkipUI:(BOOL)isSkipUI
                                scene:(nullable NSString *)scene
                                 atVC:(nonnull UIViewController *)vc
                            completed:(nullable DouyinOpenSDKAuthCompleteBlock)complete;

@end

NS_ASSUME_NONNULL_END
