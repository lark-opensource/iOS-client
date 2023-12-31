//
//  DVETrackConfig.h
//  NLEEditor
//
//  Created by bytedance on 2021/4/10.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface DVETrackConfig : NSObject


@property (nonatomic, assign, class, readonly) CGFloat spacingBetweenSegments;

//  时间轴单位长度
@property (nonatomic, assign, class, readonly) CGFloat timelineWidthPerFrame;
@property (nonatomic, assign, class, readonly) CGFloat minSegmentDuration;
@property (nonatomic, assign, class, readonly) CGFloat maxTimeScale;
@property (nonatomic, assign, class, readonly) CGFloat minTimeScale;
@property (nonatomic, assign, class, readonly) CGFloat wavePerSecondsCount;
@property (nonatomic, assign, class, readonly) CGFloat keyframeWidth;
@property (nonatomic, assign, class, readonly) CGFloat keyframeHeight;
@property (nonatomic, assign, class, readonly) CMTime timePerFrame;

// 在某些场景下，时间线需要向前或者向后偏移一些，但是不能一帧的时间。
@property (nonatomic, assign, class, readonly) CMTime timelineErrorOffsetTime;

@end

NS_ASSUME_NONNULL_END
