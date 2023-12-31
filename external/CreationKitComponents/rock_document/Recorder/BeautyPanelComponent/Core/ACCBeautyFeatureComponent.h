//
//  ACCBeautyFeatureComponent.h
//  Pods
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitComponents/ACCBeautyFeatureComponentView.h>
//message
#import <CreativeKit/ACCFeatureComponent.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>

NS_ASSUME_NONNULL_BEGIN
@class RACTwoTuple<__covariant First, __covariant Second>;
@class RACSignal<__covariant ValueType>;
@class IESEffectModel;
@class ACCBeautyPanel;
@class ACCBeautyTrackerSender;
typedef RACTwoTuple<IESEffectModel *, NSNumber *> *ACCDidApplyEffectPack;

@interface ACCBeautyFeatureComponent : ACCFeatureComponent
// D&T
@property (nonatomic, strong) ACCBeautyFeatureComponentView *componentView;
// Plugin Visible
@property (nonatomic ,strong, readonly) ACCBeautyPanel *beautyPanel;

// D
// also see composerEffectObj
@property (nonatomic, strong) AWEComposerBeautyEffectViewModel *effectViewModel;
// Plugin Visible
@property (nonatomic, assign, readonly) BOOL isShowingBeautyPanel;
@property (nonatomic, strong, readonly) ACCBeautyTrackerSender *trackSender;

- (void)updateAvailabilityForEffects:(ACCDidApplyEffectPack _Nullable)pack;
- (void)applyEffectsWhenTurnOffPureMode;

@property (nonatomic, strong, readonly) __kindof RACSignal *modernBeautyButtonClickedSignal;
@property (nonatomic, strong, readonly) __kindof RACSignal *beautyPanelDismissSignal;
@property (nonatomic, strong, readonly) __kindof RACSignal *composerBeautyDidFinishSlidingSignal;

// T
@property (nonatomic, strong, readonly) ACCGroupedPredicate<id, id> *enableSwitchBeauty;

@end

NS_ASSUME_NONNULL_END
