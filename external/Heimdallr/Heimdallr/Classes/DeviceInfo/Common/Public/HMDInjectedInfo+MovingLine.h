//
//  HMDInjectedInfo+movingLine.h
//  Heimdallr
//
//  Created by liuhan on 2023/10/23.
//

#import "HMDInjectedInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDInjectedInfo (MovingLine)

@property (nonatomic, assign) NSUInteger performanceLocalMaxStoreSize; /**性能和埋点未命中采样日志磁盘缓存阈值，默认5M**/

@property (nonatomic, assign) NSUInteger traceLocalMaxStoreSize; /**用户动线未命中采样日志磁盘缓存阈值，默认1M**/

@end

NS_ASSUME_NONNULL_END
