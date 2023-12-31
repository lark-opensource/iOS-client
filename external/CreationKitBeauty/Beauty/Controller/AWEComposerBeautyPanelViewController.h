//
//  AWEComposerBeautyPanelViewController.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/10/31.
//

#import <UIKit/UIKit.h>
#import "AWEComposerBeautyEffectCategoryWrapper.h"
#import "AWEComposerBeautyEffectViewModel.h"
#import "AWEComposerBeautyViewModel.h"
#import "ACCBeautyUIConfigProtocol.h"

@class AWEComposerBeautyTopBarViewController;
@protocol AWEComposerBeautyPanelViewControllerDelegate <NSObject>

@required

// category change
- (void)composerBeautyPanelDidChangeToCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;

// select effect
- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                 oldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
                              fromDownload:(BOOL)fromDownload;
// select effect
- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper forParentObject:(NSObject *)parentItem;
// back
- (void)composerBeautyPanelDidGoBackToCategoryPanel;
// reset
- (void)composerBeautyPanelDidTapResetButtonWithCompletion:(void (^)(void))completion;
// switch
- (void)composerBeautyPanelDidSwitch:(BOOL)isOn isManually:(BOOL)isManually;
// finish download
- (void)composerBeautyPanelDidFinishDownloadingAllEffects;
// download effect
- (void)composerBeautyPanelDidUpdateCandidateEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper forParentItem:(NSString *)parentItemID;

@optional
// use for track
- (void)composerBeautyPanelDidSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                lastEffect:(AWEComposerBeautyEffectWrapper *)lastEffectWrapper;

// primary select category
- (void)composerBeautyPanelDidSelectPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                                       lastCategory:(AWEComposerBeautyEffectCategoryWrapper *)lastCategoryWrapper
                                     parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper;
// primary enter category
- (void)composerBeautyPanelDidEnterCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                            parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper;

// primary reset category
- (void)composerBeautyPanelDidTapResetPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;

@end

@interface AWEComposerBeautyPanelViewController : UIViewController

@property (nonatomic, weak) id<AWEComposerBeautyPanelViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) id<ACCBeautyUIConfigProtocol> uiConfig;
@property (nonatomic, strong, readonly) AWEComposerBeautyTopBarViewController *topBarViewController;
@property (nonatomic, strong, readonly) UIView *headerView;

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel;

- (instancetype)initWithViewModelAndOptimizedUI:(AWEComposerBeautyViewModel *)viewModel;

- (void)updateCurrentSelectedEffectWithStrength:(CGFloat)strength;

- (BOOL)isShowingChildItems;
- (BOOL)isShowingEffectsItems;
- (BOOL)isShowingPrimayItems;

- (void)reloadPanel;

- (void)updateResetButtonToDisabled:(BOOL)disabled;

- (void)updateBeautySubItemsViewIfIsOn:(BOOL)isOn;

- (void)updateBeautySwitchIsOn:(BOOL)isOn isManually:(BOOL)isManually;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)config;

- (void)updateResetModeButton;
@end
