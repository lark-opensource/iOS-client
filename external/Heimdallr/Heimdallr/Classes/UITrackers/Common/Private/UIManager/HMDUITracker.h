//
//  HMDUITracker.h
//  HMDUITrackerRecreate
//
//  Created by sunrunwang on 2021/12/2.
//
// UITracker 的功能是 HOOK UIKit 各个模块，
// 然后通过 delegate 给返回信息


#import <UIKit/UIKit.h>
#import "HMDUITrackerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface HMDUITracker : NSObject

#pragma mark - 启动 UITracker

@property(class, readonly) __kindof HMDUITracker *sharedInstance;

@property (nonatomic, weak) id<HMDUITrackerDelegate> delegate;

- (void)start;

- (void)stop;

@end

NS_ASSUME_NONNULL_END
