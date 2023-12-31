//
//  BDPTracingClientDurationExtension.h
//  Timor
//
//  Created by changrong on 2020/3/9.
//

#import <Foundation/Foundation.h>
#import "BDPTracingExtension.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * Client Duration: https://bytedance.feishu.cn/docs/doccn9biXNKrqn1jSe646GetkAb#THL3PA
 */
@interface BDPTracingClientDurationExtension : NSObject<BDPTracingExtension>

/**
 * 提供记录开始点
 */
- (void)start:(NSString *)key;

/**
 * 计算duration，并标记当前key已完成
 * startKey不成对出现时，返回<0
 */
- (NSInteger)end:(NSString *)startKey;

/**
 * 只计算duration，不标记当前key已完成
 * startKey不成对出现时，返回<0
 */
- (NSInteger)endDuration:(NSString *)startKey;

- (NSInteger)endDuration:(NSString *)startKey timestamp:(NSInteger)timestamp;


@end

NS_ASSUME_NONNULL_END
