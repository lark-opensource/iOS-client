//
//  AWEComposerBeautyDelegate.h
//  Pods
//
//  Created by chengfei xiao on 2019/8/25.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>

NS_ASSUME_NONNULL_BEGIN


@protocol AWEComposerBeautyDelegate <NSObject>

@optional
// apply effect
- (void)applyComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effect ratio:(float)ratio;
- (void)selectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effect ratio:(float)ratio oldEffect:(nullable AWEComposerBeautyEffectWrapper *)oldEffectWrapper;
- (void)deselectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effect;
- (void)selectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effect forParentItem:(NSObject *)parentItem;

// slider
- (void)didFinishSlidingWithValue:(CGFloat)value forEffect:(AWEComposerBeautyEffectWrapper *)effect;

// apply category
- (void)selectCategory:(AWEComposerBeautyEffectCategoryWrapper *)category;

// reset
- (void)composerBeautyViewControllerDidReset;

// switch
- (void)composerBeautyViewControllerDidSwitch:(BOOL)isOn isManually:(BOOL)isManually;

// primary
- (void)composerBeautyPanelDidSelectPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                                       lastCategory:(AWEComposerBeautyEffectCategoryWrapper *)lastCategoryWrapper
                                     parentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategoryWrapper; // select
- (void)composerBeautyPanelDidTapResetPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper; // reset

// only used in RTV
- (void)composerBeautyViewControllerDidFinishDownloadingAllEffects;

// only used in ACCEditVideoBeautyComponent
- (void)composerBeautyViewControllerWillReset;

// nobody use
- (void)didResetWithValue:(CGFloat)value forEffect:(AWEComposerBeautyEffectWrapper *)effect;
- (void)updateCandidateComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effect forParentItem:(NSString *)parentItemID;
- (void)composerBeautyViewControllerWillDismiss;
- (void)composerBeautyViewControllerDidClickResetButton;
- (void)composerBeautyViewControllerDidModifyStatus;
- (void)composerBeautyDidClearRatioForCategory:(AWEComposerBeautyEffectCategoryWrapper *)category;

@end


NS_ASSUME_NONNULL_END
