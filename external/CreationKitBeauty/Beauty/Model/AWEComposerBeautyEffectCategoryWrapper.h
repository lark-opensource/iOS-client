//
//  AWEComposerBeautyEffectCategoryWrapper.h
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/5.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <Mantle/MTLModel.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>

@class AWEComposerBeautyEffectCategoryWrapper;

typedef NS_ENUM(NSInteger, AWEComposerBeautyCameraPosition) {
    AWEComposerBeautyCameraPositionFront = 0,
    AWEComposerBeautyCameraPositionBack = 1,
};


typedef NS_ENUM(NSUInteger, AWELiveBeautyMakeupType) {
    AWELiveBeautyMakeupTypeExclusive = 3, // Type a make-up, with filter special effect, mutually exclusive with conventional filter
    AWELiveBeautyMakeupTypeNonExclusive,  // B type beauty, can be superimposed with conventional filter
};

@interface AWEComposerBeautyEffectItem: MTLModel<MTLJSONSerializing>
@property (nonatomic, assign, readonly) float maxValue;
@property (nonatomic, assign, readonly) float minValue;
@property (nonatomic, assign, readonly) float defaultValue;
@property (nonatomic, assign, readonly) float defaultRatio;
@property (nonatomic, assign, readonly) float defaultPosition;
/// for live makeup, every effect item has it's own ratio
@property (nonatomic, assign) float currentRatio;
@property (nonatomic, assign, readonly) BOOL isDoubleDirection;
@property (nonatomic, copy, readonly) NSString *tag;
@property (nonatomic, copy, readonly) NSString *name;
+ (NSDictionary *)JSONKeyPathsByPropertyKey;
- (NSString *)tagForCache;
- (float)effectValueForRatio:(CGFloat)ratio;

@end

@interface AWEComposerBeautyEffectWrapper: NSObject
@property (nonatomic, strong) IESEffectModel *effect;
@property (nonatomic, copy) NSArray <AWEComposerBeautyEffectWrapper *> *childEffects;
@property (nonatomic, strong) NSArray<AWEComposerBeautyEffectItem *> *items;
@property (nonatomic, strong) NSString *resource;
@property (nonatomic, strong) NSString *videoTag; // for video and live beauty sync cache
@property (nonatomic, assign) NSInteger group; // ab_group
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) BOOL isForD;
@property (nonatomic, assign) BOOL isForT;
@property (nonatomic, assign) BOOL isForM;
@property (nonatomic, assign) BOOL isNone;
@property (nonatomic, assign) BOOL isFilter; // if is a filter placeholder
@property (nonatomic, assign) BOOL available; // if unavailable, make icon gray
@property (nonatomic, assign) BOOL disableCache;
@property (nonatomic, assign) BOOL isSwitch;

// [0,1] or [-1, 1]
// The proportion value of the current slide bar on the interface, the maximum value and minimum value of beauty item configuration may change
// But PM wants the position of the slider to be displayed to the user unchanged, so the proportion of the location of the slider will be saved internally
@property (nonatomic, assign) float currentRatio;

// The current ratio is converted to the strength value of the effect, and the internal default is to use the slider value of the first beauty item for conversion
// Because a beauty item may have multiple beauty items, that is, multiple parameters can be adjusted, but at present, they are adjusted uniformly.
@property (nonatomic, assign, readonly) CGFloat currentIntensity;
@property (nonatomic, strong) NSNumber *makeupType; // Beauty types, only beauty items
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *appliedChildEffect;
@property (nonatomic, weak) AWEComposerBeautyEffectWrapper *parentEffect;
@property (nonatomic, weak) AWEComposerBeautyEffectCategoryWrapper *categoryWrapper;
@property (nonatomic, assign) BOOL isLocalEffect;

/// is new effect, will show round dot in the right corner
@property (nonatomic, assign) BOOL isNew;

- (instancetype)initWithEffect:(IESEffectModel *)effect;
- (instancetype)initWithEffect:(IESEffectModel *)effect isFilter:(BOOL)isFilter;
- (BOOL)isEffectSet;
- (CGFloat)effectStrength;
- (void)updateWithStrength:(CGFloat)strength;
//(it's a beauty special effect of non album) & value= 0) | (at least one of the sub effects is applied & & value= 0) -> YES
- (BOOL)applied;
- (BOOL)downloaded;
- (BOOL)hasNewRedDotTag;

// Default status
- (BOOL)isInDefaultStatus;
- (double)defaultRatio;
- (AWEComposerBeautyEffectWrapper *)defaultChildEffect;

- (NSString *)tagForAppliedCache;
- (NSArray *)nodes;
- (NSArray *)nodesWithIntensity:(BOOL)withIntensity;
- (BOOL)isMakeUpForItem:(AWEComposerBeautyEffectItem *)item;
- (CGFloat)currentSliderValue;
- (void)updateRatioWithSliderValue:(CGFloat)sliderValue;

@end

@interface AWEComposerBeautyEffectCategoryWrapper : NSObject
@property (nonatomic, strong) IESCategoryModel *category;
@property (nonatomic, copy) NSString *categoryName;
@property (nonatomic, copy) NSArray <AWEComposerBeautyEffectWrapper *> *effects;
@property (nonatomic, assign) NSInteger group;
@property (nonatomic, assign) AWEComposerBeautyGender gender; // default is Women, algorithm detect
@property (nonatomic, assign) BOOL isDefault;
@property (nonatomic, assign) BOOL isForD;
@property (nonatomic, assign) BOOL isForT;
@property (nonatomic, assign) BOOL isForM;
@property (nonatomic, assign) BOOL exclusive; // is Child Effects exclusive
@property (nonatomic, assign) BOOL isLocalEffect; // is Location Resource
@property (nonatomic, assign) BOOL needShowTips; // use for skeleton
@property (nonatomic, assign, readonly) BOOL isSwitchEnabled;
// choosed, downloaded
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *selectedEffect;

// user selected, but not had choosed, is downloading
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *userSelectedEffect;

/// Primary Panel
@property (nonatomic, strong) NSString *categoryId;
@property (nonatomic, strong) NSString *parentId;
@property (nonatomic, strong) NSString *primaryCategoryName;
@property (nonatomic, strong) NSArray<NSString *> *primaryCategoryIcons;

@property (nonatomic, copy) NSArray <AWEComposerBeautyEffectCategoryWrapper *> *childCategories;
@property (nonatomic, assign) BOOL isChildCategoryExclusive; // childCategories
@property (nonatomic, strong) AWEComposerBeautyEffectCategoryWrapper *parentCategory;
@property (nonatomic, strong) AWEComposerBeautyEffectCategoryWrapper *selectedChildCategory;
@property (nonatomic, strong) AWEComposerBeautyEffectCategoryWrapper *userSelectedChildCategory;

@property (nonatomic, assign) BOOL isDefaultChildCategory;
@property (nonatomic, strong) AWEComposerBeautyEffectCategoryWrapper *defaultChildCategory;
@property (nonatomic, assign) BOOL isNoneCategory;
@property (nonatomic, readonly) BOOL isPrimaryCategory;
/// Primary Panel end

- (instancetype)initWithCategory:(IESCategoryModel *)category;
- (instancetype)initWithCategory:(IESCategoryModel *)category responseModel:(IESEffectPlatformResponseModel *)responseModel;

@end
