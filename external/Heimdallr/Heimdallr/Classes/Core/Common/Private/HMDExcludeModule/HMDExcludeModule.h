//
//  HMDExcludeModule.h
//  Heimdallr
//
//  Created by sunrunwang on 2019/4/14.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol HMDExcludeModule <NSObject>

@property(atomic, readonly, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readonly, getter=isDetected) BOOL detected;

/// Notification object must be things return from excludedModule
- (NSString *)finishDetectionNotification;

+ (id<HMDExcludeModule>)excludedModule;

@end

NS_ASSUME_NONNULL_END
