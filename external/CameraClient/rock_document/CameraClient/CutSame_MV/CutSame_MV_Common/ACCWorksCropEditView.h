//
//  ACCWorksCropEditView.h
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/4/3.
//

#import <UIKit/UIKit.h>
//#import <VideoTemplate/LVTemplateDataManager+Fetcher.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCCutSameStylePreviewFragmentProtocol.h"

@class AVURLAsset;

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCWorksCropEditViewPlayTimeBlock)(CMTime time);

@interface ACCWorksCropEditView : UIView

- (instancetype)initWithFrame:(CGRect)frame fragment:(id<ACCCutSameStylePreviewFragmentProtocol>)fragment canScale:(BOOL)canScale;

@property (nonatomic, copy) NSURL *imageFileURL;

@property (nonatomic, strong) AVURLAsset *videoAsset;

@property (nonatomic, copy  ) ACCWorksCropEditViewPlayTimeBlock playTimeCallback;

@property (nonatomic, copy  ) dispatch_block_t changeMaterialCallback;

@property (nonatomic, assign) CGSize preferredSize;

@property (nonatomic, assign, readonly) BOOL didModified;

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, assign) NSInteger curIdx;

- (void)play;

- (void)pause;

- (void)playIfPauseBySlide;

- (void)pauseBySlide;

- (void)playIfPauseByDisappear;

- (void)pauseByDisappear;

- (void)seekToTime:(CMTime)time;

- (void)reset;

- (void)changeTimeOffest:(CMTime)time;

- (CMTimeRange)currentTimeRange;

- (void)refreshFrame;

- (nullable NSArray<NSValue *> *)currentCrops;

- (void)makeViewCenterInEditView;

@end

NS_ASSUME_NONNULL_END
