//
//  DVEAudioWaveViewModel.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/28.
//

#import <Foundation/Foundation.h>
#import <NLEPlatform/NLEModel+iOS.h>
#import "DVEMediaContext.h"

NS_ASSUME_NONNULL_BEGIN

@class RACSignal;
@interface DVEAudioWaveViewModel : NSObject

@property (nonatomic, weak, nullable) DVEMediaContext *context;
@property (nonatomic, strong, readonly) NLESegmentAudio_OC *segmentAudio;
@property (nonatomic, assign) CMTimeRange sourceTimeRange;
@property (nonatomic, assign) CMTimeRange targetTimeRange;
@property (nonatomic, assign) CGFloat speed;
@property (nonatomic, strong) UIColor *fillColor;
//是否一次性显示绘制全部的音频波纹
@property (nonatomic, assign) BOOL isShowAllWave;

- (NSArray<NSNumber *> *)wavePointsCache;

- (RACSignal *)wavePoints;

- (instancetype)initWithContext:(DVEMediaContext *)context
                        segment:(NLESegmentAudio_OC *)segment
                sourceTimeRange:(CMTimeRange)sourceTimeRange
                targetTimeRange:(CMTimeRange)targetTimeRange
                          speed:(CGFloat)speed
                      fillColor:(UIColor *)fillColor
                  isShowAllWave:(BOOL)isShowAllWave;

@end

NS_ASSUME_NONNULL_END
