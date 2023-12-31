//
//  AWETimeRange.h
//  Aspects
//
// Created by Xuxu on September 13, 2018
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>
#import <CoreMedia/CoreMedia.h>

@interface AWETimeRange : MTLModel<MTLJSONSerializing>

@property (nonatomic, strong) NSNumber *start;
@property (nonatomic, strong) NSNumber *duration;

+ (AWETimeRange *)timeRangeWithCMTimeRange:(CMTimeRange)timeRange;
- (instancetype)initWithCMTimeRange:(CMTimeRange)timeRange;
- (CMTimeRange)CMTimeRangeValue;
@end
