//
//  HMDANRSDKMonitor.h
//  AWECloudCommand
//
//  Created by maniackk on 2020/7/6.
//

#import <Foundation/Foundation.h>


@protocol HMDANRSDKMonitorDelegate <NSObject>

- (void)didBlockWithDuration:(NSTimeInterval)duration;

@end

@interface HMDANRSDKMonitor : NSObject

/**
 * SDK timeoutInterval
 * main thread runloop block time exceed timeoutInterval，ANR occurred
 * default timeoutInterval 0.3s,  min timeoutInterval 0.1s
 */
@property(nonatomic, assign, readonly)NSTimeInterval timeoutInterval;

/**
 * ANR delegate
 */
@property(nonatomic, weak, readonly)id<HMDANRSDKMonitorDelegate> _Nullable delegate;


// default timeoutInterval 0.3s
- (instancetype _Nullable )initWithANRSDKMonitorDelegate:(id<HMDANRSDKMonitorDelegate> _Nullable)delegate;

- (instancetype _Nullable )initWithANRSDKMonitorDelegate:(id<HMDANRSDKMonitorDelegate> _Nullable)delegate timeInterval:(NSTimeInterval)timeoutInterval NS_DESIGNATED_INITIALIZER;

- (instancetype _Nullable )init NS_UNAVAILABLE;
+ (instancetype _Nullable )new NS_UNAVAILABLE;

/**
 * start SDK ANR Monitor（asynchronization）
 */
- (void)start;

/**
 * stop SDK ANR Monitor（asynchronization）
 */
- (void)stop;

@end

