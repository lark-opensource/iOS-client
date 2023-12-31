//
//  AWEVideoEffectChooseViewController.h
//  Aweme
//
//  Created by hanxu on 2017/4/9.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import "AWEStoryTextContainerViewProtocol.h"
#import "ACCEditTransitionServiceProtocol.h"

@class AWEVideoPublishViewModel, ACCStickerContainerView;

@protocol ACCEditServiceProtocol, ACCChallengeModelProtocol;

FOUNDATION_EXPORT CGFloat kAWEVideoEffectChooseMidMargin;

@interface AWEVideoEffectChooseViewController : UIViewController <AWEMediaSmallAnimationProtocol, ACCEditTransitionViewControllerProtocol>

@property (nonatomic, copy) void (^didDismissBlock)(void);
@property (nonatomic, copy) void (^willDismissBlock)(UIImage *snapImage);
@property (nonatomic, strong) UIImageView *interactionImageView;//贴在视频上展示
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)model
                  editService:(id<ACCEditServiceProtocol>)editService
         stickerContainerView:(ACCStickerContainerView *)stickerContainerView
           originalPlayerRect:(CGRect)playerRect;

@end
