//
//  ACCRecorderTrackerTool.h
//  CameraClient-Pods-Aweme
//
//  Created by liumiao on 2020/10/27.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCTimeTraceUtil : NSObject

+ (void)startTraceTimeForKey:(id<NSCopying>)key;

+ (void)cancelTraceTimeForKey:(nonnull id<NSCopying>)key;

+ (NSTimeInterval)timeIntervalForKey:(nonnull id<NSCopying>)key;

+ (BOOL)alreadyTraceForKey:(id<NSCopying>)key;

@end

NS_ASSUME_NONNULL_END
