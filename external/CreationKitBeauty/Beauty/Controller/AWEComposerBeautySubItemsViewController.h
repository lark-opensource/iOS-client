//
//  AWEComposerBeautySubItemsViewController.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/10/30.
//

#import <UIKit/UIKit.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import <CreationKitBeauty/ACCBeautyUIConfigProtocol.h>
#import "AWEComposerBeautyViewModel.h"

extern NSString * const AWEComposerBeautySubItemsCellIdentifier;

@class AWEComposerBeautySubItemsViewController;
@protocol AWEComposerBeautySubItemsViewControllerDelegate <NSObject>

- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                       didSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                        canceledEffect:(AWEComposerBeautyEffectWrapper *)canceledEffect
                          fromDownload:(BOOL)fromDownload;

- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                    didSelectEffectSet:(AWEComposerBeautyEffectWrapper *)effectWrapper;

- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                       didSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         forParentItem:(NSString *)parentItemID;

- (void)composerSubItemsViewControllerDidFinishDownloadingAllEffects;

@optional
- (BOOL)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
              handleClickDisableEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;

- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                    didTapOnToggleView:(BOOL)isOn
                            isManually:(BOOL)isManually;

/// reset button in primary category effects
- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                   didTapResetCategory:(AWEComposerBeautyEffectCategoryWrapper *)resetCategoryWrapper;

/// reset button enable or disable
- (BOOL)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
  shouldResetButtonEnabledWithCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;

/// use for track
- (void)composerSubItemsViewController:(AWEComposerBeautySubItemsViewController *)viewController
                       didSelectEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                            lastEffect:(AWEComposerBeautyEffectWrapper *)lastEffectWrapper;
@end

@interface AWEComposerBeautySubItemsViewController : UIViewController<UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic, weak) id<AWEComposerBeautySubItemsViewControllerDelegate> delegate;
@property (nonatomic, strong, readonly) UICollectionView *collectionView;
@property (nonatomic, assign) BOOL exclusive;
@property (nonatomic, strong, readonly) id<ACCBeautyUIConfigProtocol> uiConfig;

// deprecated
- (instancetype)initWithEffectWrappers:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers
                             viewModel:(AWEComposerBeautyViewModel *)viewModel
                          parentItemID:(NSString *)parentItemID
                        selectedEffect:(AWEComposerBeautyEffectWrapper *)selectedEffect
                             exclusive:(BOOL)exclusive;
// deprecated
- (void)updateWithEffectWrappers:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers
                    parentItemID:(NSString *)parentItemID
                  selectedEffect:(AWEComposerBeautyEffectWrapper *)selectedEffect
                       exclusive:(BOOL)exclusive;

// parent is suppport to be category or effectSet
- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
                   parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory
                   OrParentEffect:(AWEComposerBeautyEffectWrapper *)parentEffect;

- (void)updateWithParentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory
                  OrParentEffect:(AWEComposerBeautyEffectWrapper *)parentEffect;

- (void)reloadCurrentItem;

- (void)reloadPanel;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)uiConfig;

- (CGFloat)itemWidth;

- (void)reloadBeautySubItemsViewIfIsOn:(BOOL)isOn changedByUser:(BOOL)isChangedByUser;

- (void)setShouldShowAppliedIndicatorForAllCells:(BOOL)shouldShow;

- (void)updateResetModeButton;

@end
