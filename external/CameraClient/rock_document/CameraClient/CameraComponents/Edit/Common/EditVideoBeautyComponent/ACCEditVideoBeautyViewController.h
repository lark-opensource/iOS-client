//
//  ACCEditVideoBeautyViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/17.
//

#import <UIKit/UIKit.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyDelegate.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <CreationKitBeauty/ACCBeautyUIConfigProtocol.h>
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import "ACCEditTransitionServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>

@protocol ACCEditVideoBeautyViewControllerDelegate <AWEComposerBeautyDelegate>

- (void)didClickSaveButton;
- (void)didClickCancelButton;

@end

@interface ACCEditVideoBeautyViewController : UIViewController<AWEMediaSmallAnimationProtocol, ACCEditTransitionViewControllerProtocol>

@property (nonatomic, copy) void(^dissmissBlock)(void);
@property (nonatomic, copy) void(^externalDismissBlock)(void); // use external dismiss action
@property (nonatomic, weak) id<ACCEditVideoBeautyViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) AWEComposerBeautyViewModel *viewModel;
@property (nonatomic, strong, readonly) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
                      editService:(id<ACCEditServiceProtocol>)editService
             stickerContainerView:(nullable ACCStickerContainerView *)stickerContainerView;

- (void)clearSelection;

- (void)reloadPanel;

- (void)refreshSliderDefaultIndicatorPosition:(CGFloat)position;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config;

@end

