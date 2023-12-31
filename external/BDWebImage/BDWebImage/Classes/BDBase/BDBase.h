//
//  BDBase.h
//  BDWebImage
//
//  Created by wby on 2021/2/9.
//

#import <Foundation/Foundation.h>
#import "BDImagePerformanceRecoder.h"
#import "BDWebImageStartUpConfig.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BDBaseImpl) {
    BDBaseImplInternal = 0,
    BDBaseImplToB
};

/**
 该协议用于指定tob和internal的公共函数
*/
@protocol BDBase <NSObject>

// ttmonitor
- (void)setMonitorEvent:(NSDictionary *)attributes recorder:(BDImagePerformanceRecoder *)recorder;

/**
 是否支持超分。
 internal中返回值始终为YES，tob中返回值根据tob中所添加的组件是否包含sr来确定
 */
- (BOOL)isSupportSuperResolution;

- (NSString *)adaptiveDecodePolicy;

/**
 tob版本下，拉取配置和授权码
 内部版本下，仅需要拉取配置
 */
- (void)startUpWithConfig:(BDWebImageStartUpConfig *)config;

@end

NS_ASSUME_NONNULL_END
