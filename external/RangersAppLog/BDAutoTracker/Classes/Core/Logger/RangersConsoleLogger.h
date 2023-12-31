//
//  RangersConsoleLogger.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/3/15.
//

#import <Foundation/Foundation.h>
#import "RangersLogManager.h"

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrack;
@interface RangersConsoleLogger : NSObject<RangersLogger>

@property (nonatomic, weak) BDAutoTrack *tracker;

+ (NSString *)logToString:(RangersLogObject *)log;

@end

NS_ASSUME_NONNULL_END
