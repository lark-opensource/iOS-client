//
//  NLETrackSlot_OC+DVE.h
//  NLEPlatform
//
//  Created by bytedance on 2021/4/10.
//

#import <NLEPlatform/NLETrackSlot+iOS.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN

@interface NLETrackSlot_OC (DVE)

/// 轨道区的时间范围，包括变速
@property (nonatomic, assign) CMTimeRange dve_targetTimeRange;

/// 原始素材的使用范围，不包括变速
@property (nonatomic, assign) CMTimeRange dve_sourceTimeRange;
@property (nonatomic, assign, readonly) CGFloat dve_speed;

@property (nonatomic, strong, readonly, nullable) NLESegmentVideo_OC* dve_videoSegment;
@property (nonatomic, strong, readonly, nullable) NLESegmentAudio_OC* dve_audioSegment;
@property (nonatomic, strong, readonly, nullable) NLESegmentEffect_OC* dve_effectSegment;


- (void)dve_updateVideoAnimationValueIfNeed;
- (void)dve_updateTransition:(NLESegmentTransition_OC * _Nullable)transition;

/// 从文本贴纸slot中获取文本（包括文本贴纸和文本模板）
- (NSString *)contentText;

@end

NS_ASSUME_NONNULL_END
