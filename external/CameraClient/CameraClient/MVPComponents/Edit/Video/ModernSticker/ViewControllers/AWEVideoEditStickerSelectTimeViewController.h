//
//  AWEVideoEditStickerSelectTimeViewController.h
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/26.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreativeKitSticker/ACCStickerSelectTimeRangeProtocol.h>
#import <CameraClient/ACCEditTransitionServiceProtocol.h>

@class AWEVideoPublishViewModel, AWEStoryTextImageModel, AWEVideoStickerEditCircleView, AWEStoryBackgroundTextView, AWEStoryTextContainerView, AWEStickerEditBaseView;

@protocol ACCEditServiceProtocol;

@interface AWEVideoEditStickerSelectTimeViewController : UIViewController

@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;

@property (nonatomic, strong) NSArray *preLoadFramesArray;
@property (nonatomic, copy) void (^didDismissBlock)(AWEStoryTextContainerView *tempTextContainer, BOOL save);
@property (nonatomic, strong) UIImageView *interactionImageView;//贴在视频上展示

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)model
                  editService:(id<ACCEditServiceProtocol>)editService
                  stickerView:(UIView <ACCStickerSelectTimeRangeProtocol> *)stickerView
            textContainerView:(AWEStoryTextContainerView *)textContainerView
           originalPlayerRect:(CGRect)playerRect
              allStickerViews:(NSArray<AWEVideoStickerEditCircleView *> *)allStickerViews;

- (void)updateSelectedStickerView:(UIView <ACCStickerSelectTimeRangeProtocol>*)stickerView;
- (void)updateSelectedTextReadModel:(AWEStoryTextImageModel *)textModel;

@end
