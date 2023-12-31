//
//  ACCEditVideoBeautyPanelViewController.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyPanelViewController.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <CreationKitBeauty/ACCBeautyUIConfigProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoBeautyPanelViewController : UIViewController

@property (nonatomic, weak) id<AWEComposerBeautyPanelViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, weak) UIButton *cancelBtn;
@property (nonatomic, weak) UIButton *saveBtn;
@property (nonatomic, weak) UIButton *stopAndPlayBtn;

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel;

- (CGFloat)composerPanelHeight;

- (void)setBottomBarHidden:(BOOL)hidden
                  animated:(BOOL)animated;

- (void)updateCurrentSelectedEffectWithStrength:(CGFloat)strength;

- (BOOL)isShowingChildItems;

- (void)reloadPanel;

- (void)updateResetButtonToDisabled:(BOOL)disabled;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config;

@end

NS_ASSUME_NONNULL_END
