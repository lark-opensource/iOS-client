//
//  BDPFreezeMonitor.h
//  Timor
//
//  Created by MacPu on 2018/10/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDPFreezeMonitorData : NSObject

@property (nonatomic, assign) NSUInteger freezeCount;
@property (nonatomic, assign) NSUInteger totalCount;

@end

/// 卡顿 的监控
@interface BDPFreezeMonitor : NSObject

- (instancetype)init NS_UNAVAILABLE;

+ (void)start;
+ (void)stop;

/// 卡顿次数，距离你上次取值之间的数量
+ (BDPFreezeMonitorData *)freeze; //

@end

NS_ASSUME_NONNULL_END
