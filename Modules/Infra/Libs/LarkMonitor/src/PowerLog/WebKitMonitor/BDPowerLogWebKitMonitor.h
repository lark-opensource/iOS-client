//
//  BDPowerLogWebKitMonitor.h
//  Jato
//
//  Created by ByteDance on 2023/4/10.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>
#import "BDPowerLogCPUMetrics.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDPowerLogWebKitMonitor : NSObject

+ (BDPowerLogWebKitMonitor *)sharedInstance;

- (void)start;

- (void)stop;

- (void)addMemoryEvent:(NSDictionary *)memoryEvent;

- (long long)currentWebKitCPUTime;

- (long long)currentWebKitTime;

- (double)currentWebKitMemory;

- (void)updateAppState:(BOOL)foreground;

@end

NS_ASSUME_NONNULL_END
