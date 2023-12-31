//
//  HMDTTMonitor+CustomTag.h
//  Heimdallr-6ca2cf9f
//
//  Created by 崔晓兵 on 2/8/2022.
//

#import "HMDTTMonitor.h"

NS_ASSUME_NONNULL_BEGIN

typedef BOOL(^TagVerifyBlock)(NSInteger tag);

@interface HMDTTMonitor (CustomTag)

/// 设置TAG校验BLOCK，用以验证被标记为某个TAG的数据是否应该上报
/// @param tagVerifyBlock 校验闭包
+ (void)setMonitorTagVerifyBlock:(TagVerifyBlock _Nonnull)tagVerifyBlock;

/// 设置当前全局TAG，用以给事件埋点数据打标签（注：tag必须大于0，0和负值内部使用）
/// @param tag tag
+ (void)setMonitorTag:(NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
