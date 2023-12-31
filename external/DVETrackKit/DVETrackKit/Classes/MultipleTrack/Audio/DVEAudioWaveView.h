//
//  DVEAudioWaveView.h
//  DVETrackKit
//
//  Created by bytedance on 2021/4/28.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class DVEAudioWaveViewModel;
@interface DVEAudioWaveView : UIView

@property (nonatomic, strong) DVEAudioWaveViewModel *waveModel;

- (void)showWithWaveModel:(DVEAudioWaveViewModel * _Nullable)waveModel
               wavePoints:(NSArray<NSNumber *> *)wavePoints
                timeScale:(CGFloat)timeScale
        showFeaturePoints:(BOOL)showFeaturePoints;

- (void)startPositionChanged:(CGFloat)diff;

- (void)endPositionChanged:(CGFloat)diff;

- (CGFloat)audioWaveLayerWidth;

@end

NS_ASSUME_NONNULL_END
