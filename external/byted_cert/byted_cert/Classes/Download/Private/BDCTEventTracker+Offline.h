//
//  BDCTEventTracker+Offline.h
//  AFgzipRequestSerializer
//
//  Created by chenzhendong.ok@bytedance.com on 2020/11/27.
//

#import "BDCTEventTracker.h"
@class BytedCertError;

NS_ASSUME_NONNULL_BEGIN


@interface BDCTEventTracker (Offline)

/// 本地模型情况
+ (void)trackLocalModelAvailable:(NSString *)channel error:(BytedCertError *)error;

/// 资源下载或更新结果
+ (void)trackGeckoResourceSyncResult:(NSDictionary *)result;

/// 模型下载 cert_model_update
/// @param result 结果, 1 成功 0 失败 2 获取不到资源
/// @param errorMsg 错误信息
+ (void)trackCertModelUpdateEventWithResult:(NSInteger)result errorMsg:(NSString *_Nullable)errorMsg;

///  模型预加载开始 cert_model_preload_start
+ (void)trackcertModelPreloadStartEvent;

///  模型预加载 cert_model_preload
/// @param result 结果, 1 成功 0 失败 2 获取不到资源
/// @param errorMsg 错误信息
+ (void)trackCertModelPreloadEventWithResult:(NSInteger)result errorMsg:(NSString *_Nullable)errorMsg;

/// 静默 cert_do_still_liveness
/// @param error 错误
- (void)trackCertDoStillLivenessEventWithError:(BytedCertError *_Nullable)error;

/// 离线比对 cert_offline_face_verify
/// @param error 错误
- (void)trackCertOfflineFaceVerifyEventWithError:(BytedCertError *_Nullable)error;

@end

NS_ASSUME_NONNULL_END
