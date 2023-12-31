//
//  ACCKaraokeTimeSlice.m
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/4/12.
//

#import "ACCKaraokeTimeSlice.h"

@interface ACCKaraokeTimeSlice ()

@property (nonatomic, assign, readwrite) NSTimeInterval intervalStart;
@property (nonatomic, assign, readwrite) NSTimeInterval intervalEnd;

@end

@implementation ACCKaraokeTimeSlice

- (instancetype)initWithIntervalStart:(NSTimeInterval)start intervalEnd:(NSTimeInterval)end
{
    self = [super init];
    if (self) {
        _intervalStart = start;
        _intervalEnd = end;
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"intervalStart" : @"intervalStart",
        @"intervalEnd" : @"intervalEnd"
    };
}

@end

@interface ACCKaraokeTimeSwitchPoint ()

@property (nonatomic, assign, readwrite) BOOL originalSoundOpened;
@property (nonatomic, assign, readwrite) NSTimeInterval timestamp;

@end

@implementation ACCKaraokeTimeSwitchPoint

+ (instancetype)switchPointWithTimestamp:(NSTimeInterval)stamp originalSoundOpened:(BOOL)opened
{
    ACCKaraokeTimeSwitchPoint *point = [[ACCKaraokeTimeSwitchPoint alloc] init];
    point.originalSoundOpened = opened;
    point.timestamp = stamp;
    return point;
}

@end
