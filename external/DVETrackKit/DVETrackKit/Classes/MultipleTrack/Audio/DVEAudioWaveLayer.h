//
//  DVEAudioWaveLayer.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/28.
//

#import <QuartzCore/QuartzCore.h>
#import "DVEMediaContext.h"
#import "DVEAudioPoint.h"

NS_ASSUME_NONNULL_BEGIN

@interface DVEAudioWaveLayer : CALayer

@property (nonatomic, weak) DVEMediaContext *context;
@property (nonatomic, assign) CGFloat timeScale;
@property (nonatomic, assign) CMTime payloadDuration;
@property (nonatomic, assign) CMTimeRange sourceTimeRange;
@property (nonatomic, assign) CMTimeRange targetTimeRange;
@property (nonatomic, assign) CGFloat audioSpeed;
@property (nonatomic, copy) NSArray<DVEAudioPoint *> *audioPoints;
@property (nonatomic, strong) UIColor *fillColor;
@property (nonatomic, assign) BOOL isShowAllWave;


+ (NSArray<DVEAudioPoint *> *)generateAudioPoints:(NSArray<NSNumber *> *)points
                                  payloadDuration:(CMTime)payloadDuration
                                            speed:(CGFloat)speed;

- (void)reloadData;

@end

NS_ASSUME_NONNULL_END
