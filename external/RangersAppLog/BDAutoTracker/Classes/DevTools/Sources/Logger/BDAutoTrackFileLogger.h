//
//  BDAutoTrackFileLogger.h
//  RangersAppLog
//
//  Created by bytedance on 7/5/22.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrack;
@interface BDAutoTrackFileLogger : NSObject

@property (nonatomic, weak) BDAutoTrack *tracker;

- (NSString *)dump;

@end

NS_ASSUME_NONNULL_END
