//
//  DouyinOpenSDKPhoneAuthManager.h
//  DouyinOpenPlatformSDK-6252ab7f-DYOpenPhone
//
//  Created by ByteDance on 2023/6/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NSString * _Nullable DYOpenPhoneFallbackType NS_TYPED_ENUM;
FOUNDATION_EXTERN NSString * _Nonnull const DYOpenPhoneFallbackTypeDouyin; // 抖音
FOUNDATION_EXTERN NSString * _Nonnull const DYOpenPhoneFallbackTypeDouyinLite; // 抖极
FOUNDATION_EXTERN NSString * _Nonnull const DYOpenPhoneFallbackTypeH5; // h5

// 降级原因
typedef NS_ENUM(NSInteger, DYOpenPhoneFallbackWhen) {
    DYOpenPhoneFallbackWhenUnknown = 0,
    DYOpenPhoneFallbackWhenClick            = -1, // 用户手动点击按钮
    DYOpenPhoneFallbackWhenCheat            = 7, // 反作弊（少量情况是策略误伤）
    DYOpenPhoneFallbackWhenNewNotRegister   = 1011, // 新用户&不允许注册
    DYOpenPhoneFallbackWhenNoPhoneNum       = 1060, // 获取绑定手机号失败(可能没绑定手机号)
    DYOpenPhoneFallbackWhenReuseServiceErr  = 12008, // 二次号服务降级
    DYOpenPhoneFallbackWhenRisk             = 12009, // 风控
    DYOpenPhoneFallbackWhenReuseTel         = 12010, // 二次号
};

@class DouyinOpenSDKAuthRequest, UIViewController, DouyinOpenSDKAuthResponse, DouyinOpenSDKPhoneAuthTrackManager;
@interface DouyinOpenSDKPhoneAuthManager : NSObject

@property (nonatomic, strong) NSDictionary *currentAuthInfo;
@property (nonatomic, strong) DouyinOpenSDKPhoneAuthTrackManager *trackManager;

- (instancetype)init;

// 二次号配置平台: https://cloud.bytedance.net/tcc-open-platform/project/detail/952
// 风控配置平台: https://bytedance.feishu.cn/wiki/wikcncgQpJzJO3tMCJ7Joiy6LWc#Sq60SC
- (void)requestOneAuthForNewUser:(BOOL)isNewUser
                             req:(DouyinOpenSDKAuthRequest *)req
                           scope:(NSString *)scope
                    inController:(UIViewController *)controller
                        isSkipUI:(BOOL)isSkipUI
                      completion:(void(^_Nullable)(DouyinOpenSDKAuthResponse * _Nullable authRsp))completion;

+ (DYOpenPhoneFallbackType)fallbackType;

/// key: 需要走降级标准授权的错误码，value: 埋点值
+ (NSDictionary<NSNumber *,NSString *> *)fallbackDict;

+ (void)sendStandardAuthReq:(DouyinOpenSDKAuthRequest *)req
                       when:(DYOpenPhoneFallbackWhen)when
               inController:(UIViewController *)controller
                 completion:(void(^)(DouyinOpenSDKAuthResponse * _Nonnull resp))completion;

@end

NS_ASSUME_NONNULL_END
