//
//  ACCEditVideoBeautyService.h
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/17.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewModel.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import "ACCEditVideoBeautyServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditVideoBeautyService : ACCEditViewModel<ACCEditVideoBeautyServiceProtocol>

@property (nonatomic, strong) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic, strong) AWEComposerBeautyViewModel *composerVM;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

- (void)fetchBeautyEffects;


/// 所有美颜小项滑竿值置为0，选中项恢复默认值，并移除所有美颜效果，同时还会修改草稿的数据
- (void)clearAllEffectAndReset;

/// 把所有小项的滑竿值置为0，并移除所有美颜效果，不会修改草稿数据
- (void)resetAllComposerBeautyEffectsValueAndRemoveAll;


/// 更新draft model 的 beauty repo model 数据，相当于更新草稿的内存数据
/// 会记录所有滑竿值、选中的小项、二级小项
- (void)updateDraftBeautyInfo;

/// 根据当前分类数据和草稿的数据，恢复小项的滑竿值，同时应用效果
- (void)resetAllEffectToCurrentDraftInfo;

- (void)updateAvailabilityForEffectsInCategories:(NSArray *)categories;

- (BOOL)hadChangeBeautyCompareDraft;
- (void)resumeBeautyEffectFromDraft;
- (void)removeComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)removeComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects;
- (void)updateEffectWithRatio:(float)ratio
                    forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
          autoRemoveZeroRatio:(BOOL)autoRemoveZeroRatio;
- (void)applyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
   replaceOldEffect:(nullable AWEComposerBeautyEffectWrapper *)oldEffectWrapper;

@end

NS_ASSUME_NONNULL_END
