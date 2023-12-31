//
//  DVEAudioBeatsPoint.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/27.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVEAudioBeatsPoint : NSObject

@property (nonatomic, assign) NSInteger threshold;
@property (nonatomic, assign) CMTime time;

- (instancetype)initWithThreshold:(NSInteger)threshold time:(CMTime)time;

@end

NS_ASSUME_NONNULL_END
