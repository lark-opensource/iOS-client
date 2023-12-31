//
//  BDPFPSMonitor.h
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// fps 的监控
@interface BDPFPSMonitor : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)start;
+ (void)stop;

/// 卡顿次数，距离你上次取值之间的数量
+ (CGFloat)fps; //
@end

NS_ASSUME_NONNULL_END
