//
//  BDPowerLogURLSessionMonitor.h
//  Jato
//
//  Created by ByteDance on 2022/10/14.
//

#import <Foundation/Foundation.h>
@class BDPowerLogNetEvent;
NS_ASSUME_NONNULL_BEGIN
@protocol BDPowerLogURLSessionMonitorDelegate <NSObject>

- (void)netEventGenerate:(BDPowerLogNetEvent *)netEvent;

@end

@interface BDPowerLogURLSessionMonitor : NSObject

+ (BDPowerLogURLSessionMonitor *)sharedInstance;

@property (nonatomic, assign) BOOL enableURLSessionMetrics;

@property (nonatomic, weak) id<BDPowerLogURLSessionMonitorDelegate> delegate;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
