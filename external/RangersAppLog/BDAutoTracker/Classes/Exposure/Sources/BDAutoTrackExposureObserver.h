//
//  BDAutoTrackExposureObserver.h
//  RangersAppLog
//
//  Created by SoulDiver on 2022/4/2.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BDAutoTrackExposureObserver : NSObject

+ (instancetype)sharedObserver;

- (void)start;

@end

NS_ASSUME_NONNULL_END
