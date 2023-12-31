//
//  AWEComposerBeautyEffectViewModel.h
//  AWEStudio
//
//  Created by Shen Chen on 2019/8/5.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <Mantle/MTLModel.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyCacheViewModel.h>
#import <CreationKitBeauty/AWEComposerBeautyDataHandleProtocol.h>
#import <CreationKitBeauty/AWEComposerBeautyMigrationProtocol.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const AWEComposerBeautyEffectPanelAdvanced;
FOUNDATION_EXTERN NSString *const AWEComposerBeautyEffectPanelDefault;

typedef void (^AWEComposerBeautyEffectLoadBlock)(NSArray <AWEComposerBeautyEffectCategoryWrapper *> * _Nullable, BOOL); // categories, seccess

@interface AWEComposerBeautyEffectViewModel : NSObject
@property (nonatomic, copy, readonly) NSArray *currentEffects;
@property (nonatomic, copy, readonly) NSArray<AWEComposerBeautyEffectWrapper *> *effectsBeforeFilter;
@property (nonatomic, copy, readonly) NSArray<AWEComposerBeautyEffectWrapper *> *effectsAfterFilter;
@property (nonatomic, copy, readonly) NSArray<AWEComposerBeautyEffectWrapper *> *availableEffects;
@property (nonatomic, strong, readonly) AWEComposerBeautyCacheViewModel *cacheObj;

@property (nonatomic, assign) BOOL didModifyStatus;
/// one AWEComposerBeautyEffectWrapper should has multiple
/// sliders for every AWEComposerBeautyEffectItem.
/// Now we support two slider or one slider.
@property (nonatomic, assign, getter=isMultiSlider) BOOL multiSlider;

- (instancetype)initWithCacheViewModel:(nullable AWEComposerBeautyCacheViewModel *)cacheObj
                             panelName:(nullable NSString *)panelName;
- (instancetype)initWithCacheViewModel:(nullable AWEComposerBeautyCacheViewModel *)cacheObj
                             panelName:(nullable NSString *)panelName
                      migrationHandler:(nullable id<AWEComposerBeautyMigrationProtocol>)migrationHandler
                           dataHandler:(nullable id<AWEComposerBeautyDataHandleProtocol>)dataHandler;

- (instancetype)init NS_UNAVAILABLE;

// Effect loading
- (NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)localCachedBeautyData;
- (void)loadCachedEffectsWithCompletion:(AWEComposerBeautyEffectLoadBlock)completion;
- (void)fetchUpdatedEffectsForce: (BOOL)forceUpdate
                      completion:(AWEComposerBeautyEffectLoadBlock)completion;
// cache appliedEffects
- (void)cacheAppliedEffects;
- (void)clearAppliedEffects;

- (void)filterCategories:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories
              withGender:(AWEComposerBeautyGender)gender
          cameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition
              completion:(AWEComposerBeautyEffectLoadBlock)completion;
- (void)filterCategories:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories
              completion:(AWEComposerBeautyEffectLoadBlock)completion;

- (void)updateAppliedEffectsWithCategories:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories;
- (void)updateAvailableEffectsWithCategories:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories;

- (AWEComposerBeautyGender)currentGender;
- (void)updateWithGender:(AWEComposerBeautyGender)gender;
- (void)updateWithGender:(AWEComposerBeautyGender)gender
          cameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition;
- (void)prepareDataSource;

// Status update
- (void)updateAppliedChildEffect:(AWEComposerBeautyEffectWrapper *)childEffectWrapper
                       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)updateAppliedChildEffect:(AWEComposerBeautyEffectWrapper *)childEffectWrapper
                       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                          gender:(AWEComposerBeautyGender)gender;

- (void)updateSelectedEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                 forCategory:(AWEComposerBeautyEffectCategoryWrapper *)category;
- (void)updateSelectedEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                 forCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
                      gender:(AWEComposerBeautyGender)gender;
- (void)updateAppliedFilter:(IESEffectModel *)filterModel;

- (void)bringEffectWrapperToEnd:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)bringFilterToFront;

- (void)removeEffectWrapperFromAppliedEffects:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)removeEffectsArrayFromAppliedEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectsArray;

- (void)updateEffectRatioFromCache:(AWEComposerBeautyEffectWrapper *)effectWrapper;

// primary
- (void)updateSelectedChildCateogry:(AWEComposerBeautyEffectCategoryWrapper *)childCategory
                  lastChildCategory:(nullable AWEComposerBeautyEffectCategoryWrapper *)lastChildCategory
                 forPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)primaryCatgory;

// Patenity
- (void)enablePaternity;

@end

NS_ASSUME_NONNULL_END
