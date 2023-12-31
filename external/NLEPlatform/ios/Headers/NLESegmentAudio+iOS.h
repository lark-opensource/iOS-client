//
//  NLESegmentAudio.h
//  NLEPlatform
//
//  Created by bytedance on 2020/12/8.
//

#import "NLESegment+iOS.h"
#import <CoreMedia/CoreMedia.h>
#import "NLEResourceAV+iOS.h"

NS_ASSUME_NONNULL_BEGIN

@interface NLESegmentAudio_OC : NLESegment_OC

/// 音频文件
@property (nonatomic, strong) NLEResourceAV_OC* audioFile;
@property (nonatomic, strong) NLEResourceAV_OC* reversedAVFile;
@property (nonatomic, assign, readonly) CMTime duration;

// 播放速率 变速参数；absSpeed = 2 表示2倍速快播；不可以设置为 0；
@property (nonatomic, assign) CGFloat absSpeed;

/// 倒播
@property (nonatomic, assign) BOOL rewind;

/// 倒播，兼容旧版本保留的方法
- (BOOL)getRewind;

/// 兼容旧版本保留的方法
- (CGFloat)getAbsSpeed;

/// 设置变速后音频是否维持原唱，true-维持，false-变速(默认),
- (void)setKeepTone:(bool)KeepTone;

/// 设置变速后音频是否维持原唱，true-维持，false-变速(默认),
- (bool)keepTone;

/*
 * repeatCount为-1时，音乐会进行循环播放，填充整个视频
 * repeatCount最小值为1
 */
- (void)setRepeatCount:(NSInteger)repeatCount;

/// 重复次数
- (NSInteger)repeatCount;

- (void)setTimeClipStart:(CMTime)timeClipStart;

/// Resource时间坐标-起始点
- (CMTime)timeClipStart;

- (void)setTimeClipEnd:(CMTime)timeClipEnd;

/// Resource时间坐标-终止点
- (CMTime)timeClipEnd;

- (void)setVolume:(float)volume;

/// 原音量=1.0f, 静音=0.0f
- (float)volume;

- (void)setFadeInLength:(CMTime)fadeInLength;

/// 淡入
- (CMTime)fadeInLength;

- (void)setFadeOutLength:(CMTime)fadeOutLength;

/// 淡出
- (CMTime)fadeOutLength;

- (CMTime)getDuration;

- (NLEResourceType)getType;

- (void)setSpeed:(CGFloat)speed;

/// 变速 直流分量；曲线变速的场景此变量也有作用；通过此变量计算EndTime; 1倍速倒放,speed=-1.0f；
/// Speed 是时间的概念，类似与空间的 Scale（变速） + Mirror（倒播）
- (CGFloat)speed;

- (void)addCurveSpeedPoint:(CGPoint)point;
// 设置变速点，x对应变速前时间
// 1. x数值范围为0-1，表示播放器的播放进度。y数值范围为0.1到10，表示速度的倍速。
// points为CGPoint转为NSValue后的数组
// points为nil时为清除变速点
- (void)setSegCurvePoints:(NSArray<NSValue *> *)points;
// 获取变速点，x对应变速前时间
- (NSArray<NSValue *> *)getSegCurvePoints;
// 获取变速后平均速度
- (CGFloat)avgCurveSpeed;
// 变速后速度常规变速*曲线变速
- (CGFloat)totalSpeed;
// 获取移除曲线变速的时长
- (int64_t)getDurationWithoutCurveSpeed;

/// NSValue wrapped CGPoint
- (NSArray<NSValue *> *)curveSpeedPoints;

- (void)removeAllCurveSpeedPoint;

- (void)setAudioChanger:(NLEAudioChanger)changer;

- (NLEAudioChanger)getAudioChanger;

/// 音频文件
- (NLEResourceAV_OC *)getResNode;

- (NLESegmentAudio_OC *)deepClone;


@end

NS_ASSUME_NONNULL_END
