//
//  ACCKaraokeTimeSlice.h
//  CameraClient-Pods-Aweme
//
//  Created by xiafeiyu on 2021/4/12.
//

#import <Foundation/Foundation.h>

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCKaraokeTimeSlice : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSTimeInterval intervalStart;
@property (nonatomic, assign, readonly) NSTimeInterval intervalEnd;

- (instancetype)initWithIntervalStart:(NSTimeInterval)start intervalEnd:(NSTimeInterval)end;

@end

@interface ACCKaraokeTimeSwitchPoint : NSObject

@property (nonatomic, assign, readonly) BOOL originalSoundOpened;
@property (nonatomic, assign, readonly) NSTimeInterval timestamp;

+ (instancetype)switchPointWithTimestamp:(NSTimeInterval)stamp originalSoundOpened:(BOOL)opened;

@end

NS_ASSUME_NONNULL_END
