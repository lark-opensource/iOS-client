//
//  BDPowerLogURLSessionMonitor+Private.h
//  Jato
//
//  Created by ByteDance on 2022/10/16.
//

#import "BDPowerLogURLSessionMonitor.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogURLSessionMonitor (Private)

- (void)_taskInit:(NSURLSessionTask *)task;

- (void)_taskStart:(NSURLSessionTask *)task;

- (void)_taskEnd:(NSURLSessionTask *)task;

@end

NS_ASSUME_NONNULL_END
