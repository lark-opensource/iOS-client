//
//  AWEComposerBeautyEffectCategoryWrapper.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/5.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectCategoryWrapper.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <TTVideoEditor/IESMMEffectConfig.h>


@interface AWEComposerBeautyEffectItem()
@property (nonatomic, assign) float maxValue;
@property (nonatomic, assign) float minValue;
@property (nonatomic, assign) float defaultValue;
@property (nonatomic, assign) float maxPercent;
@property (nonatomic, assign) float minPercent;
@property (nonatomic, assign) float defaultPercent;
@property (nonatomic, assign) BOOL isDoubleDirection;
@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) NSString *resource;
@property (nonatomic, copy) NSString *effectID;
@property (nonatomic, copy) NSString *resourceID;
@end

@implementation AWEComposerBeautyEffectItem

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"maxPercent": @"max",
             @"minPercent": @"min",
             @"defaultPercent": @"value",
             @"isDoubleDirection": @"doubleDirection",
             @"tag": @"tag",
             @"name": @"name"
             };
}

- (float)maxValue
{
    return self.maxPercent / 100.0;
}

- (float)minValue
{
    return self.minPercent / 100.0;
}

- (float)defaultValue
{
    return self.defaultPercent / 100.0;
}

- (float)defaultPosition
{
    float result = 0.5;
    if (ACC_FLOAT_LESS_THAN(self.minValue, 0.f)) {
        if (ACC_FLOAT_LESS_THAN(self.defaultValue, 0.f)) {
            result = 0.5 - (self.defaultValue / self.minValue) / 2.0;
        } else {
            if (!ACC_FLOAT_EQUAL_TO(self.maxValue, 0.f)) {
                result = 0.5 + (self.defaultValue / self.maxValue) / 2.0;
            }
        }
    } else {
        if (!ACC_FLOAT_EQUAL_TO(self.minValue, self.maxValue)) {
            result = (self.defaultValue - self.minValue) / (self.maxValue - self.minValue);
        }
    }
    return result;
}

- (float)defaultRatio
{
    double result = self.defaultValue / self.maxValue;
    if (self.defaultValue < 0.f && self.minValue < 0.f) {
        result = fabs(self.defaultValue) / self.minValue;
    }
    return result;
}

- (NSString *)tagForCache
{
    return [NSString stringWithFormat:@"%@-%@", self.resourceID, self.tag];
}

- (float)effectValueForRatio:(CGFloat)ratio
{
    float value = ratio * self.maxValue;
    if (ratio < 0.f && self.minValue < 0.f) {
        value = fabs(ratio) * self.minValue;
    }
    return value;
}

@end

@implementation AWEComposerBeautyEffectWrapper

- (instancetype)initWithEffect:(IESEffectModel *)effect
{
    return [self initWithEffect:effect isFilter:NO];
}

- (instancetype)initWithEffect:(IESEffectModel *)effect isFilter:(BOOL)isFilter
{
    self = [super init];
    if (self) {
        _effect = effect;
        _isFilter = isFilter;
        _available = YES;
        _isSwitch = NO;
        if ([effect.extra length] > 0 ) {
            NSData *data = [effect.extra dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingAllowFragments error:nil];
            if ([dict isKindOfClass:NSDictionary.class]) {
                id _beautify = dict[@"beautify"];
                if (!_beautify) {
                    // compatible with live beauty
                    _beautify = dict[@"beautyConfig"];
                }
                if (_beautify) {
                    NSDictionary *beautyDict;
                    if ([_beautify isKindOfClass:NSDictionary.class]) {
                        beautyDict = _beautify;
                    } else if ([_beautify isKindOfClass:NSString.class]) {
                        beautyDict = [NSJSONSerialization JSONObjectWithData:[_beautify dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
                    }
                    _resource = [beautyDict acc_stringValueForKey:@"resource"];
                    if (beautyDict[@"items"] && [beautyDict[@"items"] isKindOfClass:NSArray.class]) {
                        _items = [MTLJSONAdapter modelsOfClass:AWEComposerBeautyEffectItem.class fromJSONArray:beautyDict[@"items"] error:nil];
                    }
                    if (_items == nil) {
                        _items = @[];
                    }
                    for (AWEComposerBeautyEffectItem *item in _items) {
                        item.effectID = effect.effectIdentifier;
                        item.resourceID = effect.resourceId;
                    }
                }
                _group = [dict[@"ab_group"] integerValue];
                _isForD = [dict[@"region_1"] boolValue];
                _isForT = [dict[@"region_2"] boolValue];
                _isForM = [dict[@"region_3"] boolValue];
                _isNone = [dict[@"is_none"] boolValue];
                _isDefault = [dict[@"default"] boolValue];
                _disableCache = [dict[@"disable_cache"] boolValue];
                _makeupType = [dict valueForKey:@"MakeupType"];
                _videoTag = [dict valueForKey:@"video_tag"];
            }
        }
    }
    NSMutableArray *childEffectWrappers = [NSMutableArray array];
    for (IESEffectModel *childEffect in effect.childrenEffects) {
        AWEComposerBeautyEffectWrapper *childEffectWraper = [[AWEComposerBeautyEffectWrapper alloc] initWithEffect:childEffect];
        childEffectWraper.parentEffect = self;
        [childEffectWrappers acc_addObject:childEffectWraper];
        if (childEffectWraper.isDefault) {
            self.appliedChildEffect = childEffectWraper;
        }
    }
    self.childEffects = [childEffectWrappers copy];
    return self;
}

- (BOOL)applied
{
    if ([self isEffectSet]) {
        if (!self.appliedChildEffect) {
            return NO;
        } else {
            return ACC_FLOAT_GREATER_THAN(fabs(self.appliedChildEffect.currentRatio), 0.01);
        }
    } else {
        // ratio in [-1, 1], and show value is in [-50, 50]
        // ratio in [0, 1], and show value is in [0, 100]
        // min gap value is 1 / 100 = 0.01
        return ACC_FLOAT_GREATER_THAN(fabs(self.currentRatio), 0.01);
    }
}

- (void)updateWithStrength:(CGFloat)strength
{
    if ([self isEffectSet]) {
        self.appliedChildEffect.currentRatio = strength;
    } else {
        self.currentRatio = strength;
    }
}

- (CGFloat)effectStrength
{
    if ([self isEffectSet]) {
        return self.appliedChildEffect.currentRatio;
    } else {
        return self.currentRatio;
    }
}

- (void)setCurrentRatio:(float)currentRatio
{
    for (AWEComposerBeautyEffectItem *item in self.items) {
        item.currentRatio = currentRatio;
    }
    _currentRatio = currentRatio;
}

- (CGFloat)currentIntensity
{
    return [self.items.firstObject effectValueForRatio:self.currentRatio];
}

- (BOOL)downloaded
{
    if (self.isLocalEffect) {
        return YES;
    } else {
        return self.effect.downloaded;
    }
}

- (BOOL)isEffectSet
{
    return !ACC_isEmptyArray(self.childEffects);
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
        AWEComposerBeautyEffectWrapper *anotherEffect = (AWEComposerBeautyEffectWrapper *)object;
        if (self.isFilter) {
            return anotherEffect.isFilter;
        }
        return [anotherEffect.effect.effectIdentifier isEqualToString:self.effect.effectIdentifier];
    }
    return NO;
}

- (NSString *)description
{
    if (self.makeupType != nil) {
        NSString *logInfo = @"[";
        for (AWEComposerBeautyEffectItem *item in self.items) {
            logInfo = [logInfo stringByAppendingFormat:@"%@:%@,", item.tag, @(item.currentRatio)];
        }
        return [logInfo stringByAppendingString:@"]"];
    }
    return [NSString stringWithFormat:@"%@-%@", self.effect.effectName, @([self effectStrength])];
}

- (BOOL)isInDefaultStatus
{
    if ([self isEffectSet]) {
        if (self.appliedChildEffect && ![self.appliedChildEffect isEqual:self.defaultChildEffect]) {
            return NO;
        }
        for (AWEComposerBeautyEffectWrapper *childEffect in self.childEffects) {
            if (![childEffect isInDefaultStatus]) {
                return NO;
            }
        }
        return YES;
    } else {
        // multiply by a factor to make it default when the display value is the same
        NSInteger factor = 100;
        if ([self.items firstObject].isDoubleDirection && self.items.firstObject.minValue < 0.f) {
            factor = 50;
        }
        NSInteger displayValue = round(self.currentRatio * factor);
        NSInteger defaultDisplayValue = round([self defaultRatio] * factor);
        return displayValue == defaultDisplayValue;
    }
}

- (double)defaultRatio
{
    AWEComposerBeautyEffectItem *item = [self.items firstObject];
    return item.defaultRatio;
}

- (AWEComposerBeautyEffectWrapper *)defaultChildEffect
{
    if (![self isEffectSet]) {
        return nil;
    }
    AWEComposerBeautyEffectWrapper *appliedChildEffectWrapper = nil;
    for (AWEComposerBeautyEffectWrapper *childEffect in self.childEffects) {
        if (childEffect.isDefault) {
            appliedChildEffectWrapper = childEffect;
            break;
        }
    }
    if (!appliedChildEffectWrapper) {
        appliedChildEffectWrapper = [self.childEffects firstObject];
    }
    return appliedChildEffectWrapper;
}

- (NSString *)tagForAppliedCache
{
    if (self.isFilter) {
        return @"com.composerBeauty.tagForFilter";
    }
    NSString *tag = [[self.items firstObject].tag lowercaseString];
    return tag;
}

- (NSArray *)nodes
{
    return [self nodesWithIntensity:YES];
}

- (NSArray *)nodesWithIntensity:(BOOL)withIntensity
{
    NSMutableArray *nodes = [NSMutableArray array];
    NSString *resourcePath = self.effect.resourcePath;
    if (ACC_isEmptyString(resourcePath)) {
        return [nodes copy];
    }
    if (ACC_isEmptyArray(self.items)) {
        VEComposerInfo *info = [[VEComposerInfo alloc] init];
        info.node = resourcePath;
        info.tag = self.effect.extra ?: @"";
        [nodes acc_addObject:info];
    } else {
        CGFloat intensity = self.currentIntensity;
        for (AWEComposerBeautyEffectItem *item in self.items) {
            NSString *pathTag = @"";
            if (withIntensity) {
                pathTag = [NSString stringWithFormat:@"%@;%@;%@", resourcePath, item.tag, @(intensity)];
            } else {
                pathTag = [NSString stringWithFormat:@"%@;%@", resourcePath, item.tag];
            }
            VEComposerInfo *info = [[VEComposerInfo alloc] init];
            info.node = pathTag;
            info.tag = self.effect.extra ?: @"";
            [nodes acc_addObject:info];
        }
    }
    return [nodes copy];
}

- (BOOL)isMakeUpForItem:(AWEComposerBeautyEffectItem *)item {
    if (_makeupType.integerValue == AWELiveBeautyMakeupTypeExclusive) {
        if ([item.tag containsString:@"Makeup"]) {
            return YES;
        }
        return NO;
    }
    return YES;
}

- (BOOL)hasNewRedDotTag
{
    return [self.effect showRedDotWithTag:@"new"];
}

- (CGFloat)currentSliderValue
{
    return self.currentRatio * [self sliderMaxValue];
}

- (void)updateRatioWithSliderValue:(CGFloat)sliderValue
{
    float ratio = sliderValue / [self sliderMaxValue];
    [self updateWithStrength:ratio];
}

- (CGFloat)sliderMaxValue
{
    AWEComposerBeautyEffectItem *item = self.items.firstObject;
    CGFloat sliderMaxValue = 100;
    if (ACC_FLOAT_LESS_THAN(item.minValue, 0)) {
        sliderMaxValue = 50.f;
    } else {
        sliderMaxValue = 100.f;
    }
    return sliderMaxValue;
}

@end

@implementation AWEComposerBeautyEffectCategoryWrapper

- (instancetype)initWithCategory:(IESCategoryModel *)category
{
    return [self initWithCategory:category responseModel:nil];
}

- (instancetype)initWithCategory:(IESCategoryModel *)category responseModel:(IESEffectPlatformResponseModel *)responseModel
{
    self = [super init];
    if (self) {
        _category = category;
        _categoryName = category.categoryName;
        _isDefault = category.isDefault;
        NSData *data = [category.extra dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData: data options:NSJSONReadingAllowFragments error:nil];
        if ([dict isKindOfClass:NSDictionary.class]) {
            _group = [dict[@"ab_group"] integerValue];
            _isForD = [dict[@"region_1"] boolValue];
            _isForT = [dict[@"region_2"] boolValue];
            _isForM = [dict[@"region_3"] boolValue];
            _gender = dict[@"panel_type"] ? [dict[@"panel_type"] integerValue] : [dict[@"gender"] integerValue];
            _exclusive = [dict[@"exclusive"] boolValue];
            _isDefault = [dict[@"default"] boolValue];
            _needShowTips = [dict[@"showTips"] boolValue];
            _isSwitchEnabled = [dict acc_boolValueForKey:@"showSwitch"];

            _parentId = [dict acc_stringValueForKey:@"parentid"];
            _parentId = (_parentId == nil || [_parentId isEqualToString:@"null"]) ? nil : _parentId;
            _categoryId = [dict acc_stringValueForKey:@"categoryid"];
            _childCategories = [NSArray array];
            _isChildCategoryExclusive = [dict[@"ifChildExclusive"] boolValue];
            _isDefaultChildCategory = [dict[@"category_default"] boolValue];
            _primaryCategoryName = [dict acc_stringValueForKey:@"Primary_panel_name"];
            if (!ACC_isEmptyString([dict acc_stringValueForKey:@"Primary_panel_icon"])) {
                NSMutableArray *urls = [NSMutableArray array];
                [[responseModel urlPrefix] enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    [urls acc_addObject:[obj stringByAppendingString:[dict acc_stringValueForKey:@"Primary_panel_icon"]]];
                }];
                _primaryCategoryIcons = [urls copy];
            }

        }
        NSMutableArray *effectWrappers = [NSMutableArray array];
        for (IESEffectModel *effect in category.effects) {
            AWEComposerBeautyEffectWrapper *effectWrapper = [[AWEComposerBeautyEffectWrapper alloc] initWithEffect:effect];
            if (effectWrapper) {
                [effectWrappers acc_addObject:effectWrapper];
            }
            if (effectWrapper.isDefault) {
                _selectedEffect = effectWrapper;
                _userSelectedEffect = _selectedEffect;
            }
            effectWrapper.categoryWrapper = self;
        }
        _effects = [effectWrappers copy];
    }
    return self;
}

- (void)setSelectedEffect:(AWEComposerBeautyEffectWrapper *)selectedEffect
{
    _selectedEffect = selectedEffect;
    _userSelectedEffect = selectedEffect;
}


@end


@implementation  AWEComposerBeautyEffectCategoryWrapper(Primary)

- (BOOL)isPrimaryCategory
{
    return !ACC_isEmptyArray(self.childCategories);
}

@end
