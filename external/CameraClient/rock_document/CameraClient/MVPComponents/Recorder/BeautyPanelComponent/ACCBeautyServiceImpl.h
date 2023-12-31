//
//  ACCBeautyServiceImpl.h
//  Pods
//
//  Created by liyingpeng on 2020/5/27.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCRecorderViewModel.h>
#import <CreationKitComponents/ACCBeautyService.h>

NS_ASSUME_NONNULL_BEGIN

@class ACCBeautyPanelViewModel;

@interface ACCBeautyServiceImpl : ACCRecorderViewModel<ACCBeautyService>

@property (nonatomic, assign) BOOL beautyOn;
@property (nonatomic, strong, readonly) ACCBeautyPanelViewModel *beautyPanelViewModel;
@property (nonatomic, strong, readonly) AWEComposerBeautyEffectViewModel *effectViewModel;

/// beauty switch on or use composer beauty and has at least one beauty item value not equal to 0
- (BOOL)isUsingBeauty;
- (BOOL)isUsingLocalBeautyResource;
- (void)clearAllComposerBeautyEffects;
- (void)clearComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers;
- (void)applyComposerBeautyEffects:(NSArray <AWEComposerBeautyEffectWrapper *> *)effectWrappers;
- (void)updateAvailabilityForEffectsInCategories:(NSArray *)categories;
- (void)addSkeletonAlgorithmCallback;
- (void)addAlgorithmCallbackForBeauty:(AWEComposerBeautyEffectWrapper *)beautyWrapper;

@end

NS_ASSUME_NONNULL_END
