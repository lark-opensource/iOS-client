//
//  HMDHeimdallrConfig+Legacy.h
//  Heimdallr
//
//  Created by bytedance on 2020/3/26.
//

#import "HMDHeimdallrConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDHeimdallrConfig (Legacy)

/// 当前是否是默认Config
@property (nonatomic, assign, readonly) BOOL isDefault;

/// 兼容默认配置的初始化方法
/// @param appId config的appId
/// @param dic 默认配置信息
- (instancetype)initWithAppId:(NSString *)appId defaultConfig:(NSDictionary *)dic;

@end

NS_ASSUME_NONNULL_END
