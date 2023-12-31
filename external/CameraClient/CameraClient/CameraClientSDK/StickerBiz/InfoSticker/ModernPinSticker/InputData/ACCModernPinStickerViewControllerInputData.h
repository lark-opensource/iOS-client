//
//  ACCModernPinStickerViewControllerInputData.h
//  CameraClient
//
//  Created by Pinka.
//

#import <Foundation/Foundation.h>
#import <TTVideoEditor/HTSDefine.h>

NS_ASSUME_NONNULL_BEGIN
@class AWEVideoStickerEditCircleView, AWEStickerContainerView, IESInfoStickerProps, AWEVideoPublishViewModel;
@protocol ACCEditTransitionServiceProtocol, ACCStickerContainerProtocol, ACCEditServiceProtocol;

@interface ACCModernPinStickerViewControllerInputData : NSObject

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, strong) IESInfoStickerProps *stickerInfos;
@property (nonatomic, assign) NSInteger stickerId;

@property (nonatomic, strong) UIView<ACCStickerContainerProtocol> *stickerContainerView;

@property (nonatomic, assign) CGRect playerRect;

@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;

/// pin贴纸的开始时间
@property (nonatomic, assign) CGFloat startTime;
/// 时长，业务来限制seek的范围
@property (nonatomic, assign) CGFloat duration;
/// 当前进入pin页面对应的时间
@property (nonatomic, assign) CGFloat currTime;
/// 投票贴纸的截图，贴在视频上，不可交互
@property (nonatomic, strong) UIImageView *interactionImageView;

@property (nonatomic, assign) BOOL isCustomUploadSticker;

@property (nonatomic, copy) void (^willDismissBlock)(BOOL save);
@property (nonatomic, copy) void (^didDismissBlock)(BOOL save);
@property (nonatomic, copy) void (^didFailedBlock)(void);

@end

NS_ASSUME_NONNULL_END
