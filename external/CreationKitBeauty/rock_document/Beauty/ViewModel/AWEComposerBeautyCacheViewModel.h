//
//  AWEComposerBeautyCacheViewModel.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/4.
//

#import <Foundation/Foundation.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreationKitBeauty/AWEComposerBeautyCacheKeys.h>

@interface AWEComposerBeautyCacheViewModel : NSObject
@property (nonatomic,   copy, readonly) NSString *businessName;
@property (nonatomic, strong, readonly) AWEComposerBeautyCacheKeys *cacheKeysObj;

// XS and DMT do not share the cache key, DMT is empty by default, other product settings
- (instancetype)initWithBusinessName:(NSString *)businessName;

- (void)updateCurrentGender:(AWEComposerBeautyGender)gender
             cameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition;

- (void)setCategory:(AWEComposerBeautyEffectCategoryWrapper *)category switchOn:(BOOL)isOn;

- (BOOL)isCategorySwitchOn:(AWEComposerBeautyEffectCategoryWrapper *)category;

// Preload related
- (void)updateCandidateChildEffect:(AWEComposerBeautyEffectWrapper *)childEffectWrapper
                   forParentItemID:(NSString *)parentItemID;
- (NSString *)cachedCandidateChildEffectIDForParentItemID:(NSString *)parentItemID;

// Ratio
- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                 gender:(AWEComposerBeautyGender)gender;
- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                    tag:(NSString *)tag;
- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                    tag:(NSString *)tag
                 gender:(AWEComposerBeautyGender)gender;
- (float)ratioForEffectItem:(AWEComposerBeautyEffectItem *)item;
- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
          gender:(AWEComposerBeautyGender)gender;
- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
             tag:(NSString *)tag;
- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
             tag:(NSString *)tag
          gender:(AWEComposerBeautyGender)gender;
- (void)setRatio:(float)ratio
   forEffectItem:(AWEComposerBeautyEffectItem *)item;
- (void)setRatio:(float)ratio
   forEffectItem:(AWEComposerBeautyEffectItem *)item
          gender:(AWEComposerBeautyGender)gender;

// category
- (void)updateCategoryFromCache:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                    multiSlider:(BOOL)isMultiSlider;
- (void)updateCategoryFromCache:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                    multiSlider:(BOOL)isMultiSlider
                         gender:(AWEComposerBeautyGender)gender;
- (void)updateEffectWithCachedStrength:(AWEComposerBeautyEffectWrapper *)effectWrapper;

// primary category

- (void)cacheSelectedChildCategoryId:(NSString *)childCategoryId forParentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory;
- (NSString *)cachedSelectedCategoryIdForParentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory;
// Beauty in use

/// Clear the cache of boys and girls under the gender of the corresponding application list
- (void)clearCachedAppliedEffects;
- (void)cacheAppliedEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)appliedEffects;
- (void)cacheAppliedEffectsResourceIds:(NSArray<NSString *> *)resourceIds
                             forGender:(AWEComposerBeautyGender)gender;
- (NSArray <NSString *> *)appliedEffectsFromCache;
- (NSArray <NSString *> *)appliedEffectsFromCacheForGender:(AWEComposerBeautyGender)gender;
- (NSString *)appliedChildResourceIdForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                       gender:(AWEComposerBeautyGender)gender;
- (NSString *)appliedChildResourceIdForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)updateAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)updateAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                forGender:(AWEComposerBeautyGender)gender;
- (void)updateAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;
- (void)updateAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                                gender:(AWEComposerBeautyGender)gender;
- (void)clearAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)clearAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper;

// Filter used
- (void)cacheSelectedFilter:(NSString *)filterID;
- (void)cacheSelectedFilter:(NSString *)filterID
         withCameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition;
- (NSString *)cachedFilterID;

// Selected tab
- (void)cacheSelectedCategory:(NSString *)categoryIdentifier;
- (NSString *)cachedSelectedCategory;

// Gender identification
- (void)updateRecognizedGender:(AWEComposerBeautyGender)gender;
- (BOOL)shouldAlwaysRecognizeAsFemale;

// New flag
- (double)lastSelectedTimestamp:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)cacheSelectedTimestampForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
- (void)cacheSelectedTimestamp:(double)timestamp
                     forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper;
@end
