//
//  BytedCertWrapper+Download.h
//  byted_cert
//
//  Created by chenzhendong.ok@bytedance.com on 2021/1/10.
//

#import "BytedCertWrapper.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSString *_Nonnull const GECKO_ACCESS_KEY;


@interface BytedCertWrapper (Download)

@property (nonatomic, strong, readonly, nonnull) NSMutableSet *geckoChannelList;

@property (nonatomic, strong, nonnull) NSString *appId;
@property (nonatomic, strong, nonnull) NSString *appVersion;
@property (nonatomic, strong, nonnull) NSString *mDownloadPath;
@property (nonatomic, strong, nonnull) NSString *mDeviceId;

///  @param params 参数，key定义如下，可以直接使用:
///    BytedCertParamAppName  :   业务app，必传；决定了下发资源；BytedCertParamTargetOffline：离线使用
///    BytedCertParamDeviceId  公司内部deviceid
///    BytedCertParamAppVersion : app 版本；用于gecko上报
///    BytedCertParamCacheRootDirectory  下载缓存目录 可选； 不传则默认使用Library/cache目录
///    BytedCertParamDeviceId  公司内部deviceid
- (void)setPreloadParams:(NSDictionary *_Nullable)params;
///  需要存储权限
///  检查当前模型状态是否可用
/// @param callback 回调，success的时候k表示可用
- (void)checkLoadStatus:(BytedCertResultBlock)callback;
///  需要存储权限
/// @param callback 回调
- (void)preload:(BytedCertResultBlock)callback;

///  需要存储权限,preload后检查模型是否可用。
////// @param callback 回调
- (void)checkAndPreload:(BytedCertResultBlock)callback;

// 提供给外部做本地模型检查
- (int)checkModelAvailable;

//内部接口
- (int)checkChannelAvailable:(NSArray *)filePre channel:(NSString *)channel;

- (int)checkModelAvailable:(NSArray *)modelPre path:(NSString *)channel;

- (int)checkResourceStatusWithChannel:(NSString *)channel;

@end

NS_ASSUME_NONNULL_END
