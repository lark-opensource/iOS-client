//
//  AWEWorksPreviewVideoEditView.h
//  AWEStudio-Pods-Aweme
//
//  Created by Pinka on 2020/3/20.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ACCCutSameWorksPreviewBottomViewProtocol.h"
#import "ACCCutSameStyleCropEditManagerProtocol.h"

typedef NS_ENUM(NSInteger, ACCWorksPreviewVideoEditViewType) {
    ACCWorksPreviewVideoEditViewType_Photo,
    ACCWorksPreviewVideoEditViewType_Video
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^ACCWorksPreviewVideoEditViewChangeRangeBlock)(CMTime newTimeRange);
typedef void(^ACCWorksPreviewVideoEditViewScrollBlock)(CGFloat percent);

@interface ACCWorksPreviewVideoEditView : UIView<ACCCutSameWorksPreviewBottomViewProtocol>

@property (nonatomic, weak  ) id<ACCCutSameStyleCropEditManagerProtocol> editManager;

@property (nonatomic, assign) ACCWorksPreviewVideoEditViewType curType;

@property (nonatomic, copy  ) NSURL *imageFileURL;

@property (nonatomic, strong) AVURLAsset *videoAsset;

@property (nonatomic, assign) CMTimeRange timeRange;

@property (nonatomic, assign) CGFloat prepareWidth;

@property (nonatomic, copy  ) dispatch_block_t pauseCallback;

@property (nonatomic, copy  ) dispatch_block_t resumeCallback;

@property (nonatomic, copy  ) ACCWorksPreviewVideoEditViewChangeRangeBlock changeRangeCallback;

@property (nonatomic, copy  ) dispatch_block_t changeMaterialCallback;

@property (nonatomic, copy  ) dispatch_block_t okCallback;

@property (nonatomic, copy  ) dispatch_block_t closeCallback;

@property (nonatomic, copy  ) ACCWorksPreviewVideoEditViewScrollBlock scrollCallback;

- (void)reset;

- (void)updatePlayTime:(CMTime)time;

- (instancetype)initWithFrame:(CGRect)frame type:(ACCWorksPreviewVideoEditViewType)type;

- (void)AnimationForShowCropView;

- (void)AnimationForHideCropView;

@end

NS_ASSUME_NONNULL_END
