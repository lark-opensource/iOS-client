//
//  HMDTTMonitorTagHelper.h
//  Heimdallr-6ca2cf9f
//
//  Created by 崔晓兵 on 2/8/2022.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 被标记为tag的数据是否应该上报
typedef BOOL(^TagVerifyBlock)(NSInteger tag);

@interface HMDTTMonitorTagHelper : NSObject

/// 设置TAG校验BLOCK，用以验证被标记为某个TAG的数据是否应该上报
/// @param tagVerifyBlock 校验闭包
+ (void)setMonitorTagVerifyBlock:(TagVerifyBlock _Nonnull)tagVerifyBlock;

/// 设置当前全局TAG，用以给事件埋点数据打标签（注：tag必须大于0，0和负值内部使用）
/// @param tag tag
+ (void)setMonitorTag:(NSInteger)tag;

/// 获取当前TAG
+ (NSInteger)getMonitorTag;

/// 对被标记的TAG数据进行决议，是否应该上报
/// @param tag tag
+ (BOOL)verifyMonitorTag:(NSInteger)tag;

@end

NS_ASSUME_NONNULL_END
