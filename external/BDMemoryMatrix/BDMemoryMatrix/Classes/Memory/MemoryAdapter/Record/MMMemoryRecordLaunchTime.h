//
//  MMMemoryRecordLaunchTime.h
//  Pods-IESDetection_Example
//
//  Created by zhufeng on 2021/8/25.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MMMemoryRecordLaunchTime : NSObject

@property (nonatomic, assign, readonly) uint64_t lastSessionLaunchTime;
@property (nonatomic, assign, readonly) uint64_t currentSessionLaunchTime;

+ (instancetype)shared;

- (void)onAppLaunch;

@end

NS_ASSUME_NONNULL_END
