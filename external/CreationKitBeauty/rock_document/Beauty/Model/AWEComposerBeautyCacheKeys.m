//
//  AWEComposerBeautyCacheKeys.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/14.
//

#import <CreationKitBeauty/AWEComposerBeautyCacheKeys.h>

@interface AWEComposerBeautyCacheKeys()

@property (nonatomic, copy, readwrite) NSString *effectSetCachePrefix;
@property (nonatomic, copy, readwrite) NSString *categoryCachePrefix;
@property (nonatomic, copy, readwrite) NSString *selectedChildCategoryCachePrefix;
@property (nonatomic, copy, readwrite) NSString *effectConfigurationPrefix;
@property (nonatomic, copy, readwrite) NSString *effectAppliedEffectsCacheKey;
@property (nonatomic, copy, readwrite) NSString *categorySwitchOnKey;

@property (nonatomic, copy, readwrite) NSString *appliedFilterPlaceHolder;
@property (nonatomic, copy, readwrite) NSString *appliedFilterIDKey;
@property (nonatomic, copy, readwrite) NSString *consecutiveRecognizedAsFemaleCountKey;
@property (nonatomic, copy, readwrite) NSString *panelLastSelectedTabIDKey;

@property (nonatomic, copy, readwrite) NSString *businessName;

@end


@implementation AWEComposerBeautyCacheKeys

- (instancetype)initWithBusinessName:(NSString *)businessName
{
    self = [super init];
    if (self) {
        _businessName = businessName;
    }
    return self;
}

- (NSString *)p_cacheKey:(NSString *)key withPrefix:(NSString *)prefix
{
    NSString *defaultKey = key;
    if ([prefix length]) {
        NSMutableString *withPrefixKey = [NSMutableString stringWithString:prefix];
        [withPrefixKey appendString:@"-"];
        [withPrefixKey appendString:defaultKey];
        return withPrefixKey;
    }
    return defaultKey;
}

#pragma mark - getter

- (NSString *)effectSetCachePrefix
{
    if (!_effectSetCachePrefix) {
        _effectSetCachePrefix = [self p_cacheKey:@"kAWEComposerBeautyEffectSet." withPrefix:self.businessName];
    }
    return _effectSetCachePrefix;
}

- (NSString *)categoryCachePrefix
{
    if (!_categoryCachePrefix) {
        _categoryCachePrefix = [self p_cacheKey:@"kAWEComposerBeautyEffectCategory." withPrefix:self.businessName];
    }
    return _categoryCachePrefix;
}

- (NSString *)selectedChildCategoryCachePrefix
{
    if (!_selectedChildCategoryCachePrefix) {
        _selectedChildCategoryCachePrefix = [self p_cacheKey:@"kAWEComposerSelectedChildCategory." withPrefix:self.businessName];
    }
    return _selectedChildCategoryCachePrefix;
}

- (NSString *)effectConfigurationPrefix
{
    if (!_effectConfigurationPrefix) {
        _effectConfigurationPrefix = [self p_cacheKey:@"kAWEComposerBeautyEffect." withPrefix:self.businessName];
    }
    return _effectConfigurationPrefix;
}

- (NSString *)categorySwitchOnKey
{
    if (!_categorySwitchOnKey) {
        _categorySwitchOnKey = [self p_cacheKey:@"kAWEComposerCategorySwitchOn." withPrefix:self.businessName];
    }
    return _categorySwitchOnKey;
}

- (NSString *)effectAppliedEffectsCacheKey
{
    if (!_effectAppliedEffectsCacheKey) {
        _effectAppliedEffectsCacheKey = [self p_cacheKey:@"AWEComposerBeautyEffectAppliedEffectsCacheKey." withPrefix:self.businessName];
    }
    return _effectAppliedEffectsCacheKey;
}

- (NSString *)appliedFilterPlaceHolder
{
    if (!_appliedFilterPlaceHolder) {
        _appliedFilterPlaceHolder = [self p_cacheKey:@"AWEComposerBeautyAppliedFilterPlaceHolder" withPrefix:self.businessName];
    }
    return _appliedFilterPlaceHolder;
}

- (NSString *)appliedFilterIDKey
{
    if (!_appliedFilterIDKey) {
        _appliedFilterIDKey = [self p_cacheKey:@"AWEComposerBeautyAppliedFilterKey" withPrefix:self.businessName];
    }
    return _appliedFilterIDKey;
}

- (NSString *)consecutiveRecognizedAsFemaleCountKey
{
    if (!_consecutiveRecognizedAsFemaleCountKey) {
        _consecutiveRecognizedAsFemaleCountKey = [self p_cacheKey:@"AWEComposerBeautyConsecutiveRecognizedAsFemaleCountKey" withPrefix:self.businessName];
    }
    return _consecutiveRecognizedAsFemaleCountKey;
}

- (NSString *)panelLastSelectedTabIDKey
{
    if (!_panelLastSelectedTabIDKey) {
        _panelLastSelectedTabIDKey = [self p_cacheKey:@"com.composerBeauty.AWEComposerBeautyPanelLastSelectedTabIDKey" withPrefix:self.businessName];
    }
    return _panelLastSelectedTabIDKey;
}

- (NSString *)selectedTimeStampKey
{
    return [self p_cacheKey:@"AWEComposerBeautySelectedTimeStampKey" withPrefix:self.businessName];
}

@end
