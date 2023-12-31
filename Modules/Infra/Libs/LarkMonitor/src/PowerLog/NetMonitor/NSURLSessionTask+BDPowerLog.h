//
//  NSURLSessionTask+BDPowerLog.h
//  LarkMonitor
//
//  Created by ByteDance on 2022/9/13.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSURLSessionTask (BDPowerLog)

@property (nonatomic, assign) long long bd_pl_initTime;

@property (nonatomic, assign) long long bd_pl_startTime;

@property (nonatomic, assign) long long bd_pl_endTime;

@end

NS_ASSUME_NONNULL_END
