//
//  AWEComposerBeautyPrimaryItemsViewController.h
//  CreationKitBeauty-Pods-Aweme
//
//  Created by bytedance on 2021/8/18.
//

#import <UIKit/UIKit.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import <CreationKitBeauty/ACCBeautyUIConfigProtocol.h>
#import "AWEComposerBeautyViewModel.h"



NS_ASSUME_NONNULL_BEGIN


extern NSString * const AWEComposerBeautyPrimaryItemsCellIdentifier;

@class AWEComposerBeautyPrimaryItemsViewController;

@protocol AWEComposerBeautyPrimaryItemsViewControllerDelegate <NSObject>

// select
- (void)composerPrimaryItemsViewController:(AWEComposerBeautyPrimaryItemsViewController *)viewController
                         didSelectCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                            parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper;
// enter
- (void)composerPrimaryItemsViewController:(AWEComposerBeautyPrimaryItemsViewController *)viewController
                          didEnterCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                            parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper;

@end


@interface AWEComposerBeautyPrimaryItemsViewController : UIViewController

@property(nonatomic, weak)id<AWEComposerBeautyPrimaryItemsViewControllerDelegate> delegate;

- (instancetype)initWithViewModel:(AWEComposerBeautyViewModel *)viewModel
                  PrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
            selectedChildCategory:(nullable AWEComposerBeautyEffectCategoryWrapper *)selectedChildCategory;

- (void)updateWithViewModel:(AWEComposerBeautyViewModel *)viewModel
            PrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
      selectedChildCategory:(nullable AWEComposerBeautyEffectCategoryWrapper *)selectedChildCategory;

- (void)updateUIConfig:(id<ACCBeautyUIConfigProtocol>)uiConfig;

- (void)reloadPanel;

@end

NS_ASSUME_NONNULL_END
