//
//  BDApplicationStat.h
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/6/11.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDApplicationStat : NSObject

+ (void)startCollectUpdatedClick;

+ (NSDate *)getLatestClickDate;

+ (long)getLatestClickTimestamp;

@end

NS_ASSUME_NONNULL_END
