//
//  BDAutoTrackVisualLogger.h
//  RangersAppLog
//
//  Created by bytedance on 7/5/22.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
@class BDAutoTrack,RangersLogObject,BDAutoTrackDevLogger;
@interface BDAutoTrackVisualLogger : NSObject

@property (nonatomic, weak) BDAutoTrack *tracker;

@property (nonatomic, weak) BDAutoTrackDevLogger *visualController;

- (NSArray<RangersLogObject *> *)currentLogs;

- (NSArray<NSString *> *)currentModules;

@end

NS_ASSUME_NONNULL_END
