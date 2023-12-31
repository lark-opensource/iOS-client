//
//  AWEAutoCaptionsViewController.h
//  Pods
//
//  Created by li xingdong on 2019/8/23.
//

#import <UIKit/UIKit.h>
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import "ACCEditTransitionServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitRTProtocol/ACCEditPreviewProtocol.h>

@class AWEVideoPublishViewModel,
AWEStudioCaptionsManager,
AWEInteractionStickerLocationModel,
ACCStickerContainerView;

@class AWEVideoPublishViewModel;

@interface AWEAutoCaptionsViewController : UIViewController <AWEMediaSmallAnimationProtocol>

@property (nonatomic, copy) void (^willDismissBlock)(UIImage *snapImage, BOOL isCancel, BOOL isDeleted);
@property (nonatomic, copy) void (^didDismissBlock)(void);
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditPreviewProtocol> previewService;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, assign) CGFloat marginToContainerCenterY;

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository
                     containerView:(ACCStickerContainerView *)containerView
                originalPlayerRect:(CGRect)playerRect
                    captionManager:(AWEStudioCaptionsManager *)captionManager;

@end
