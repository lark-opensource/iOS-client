//
//  AWEComposerBeautyEffectKeys.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/14.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectKeys.h>

NSString *const AWEComposerBeautyLastPanelNameKey = @"AWEComposerBeautyLastPanelNameKey";

@interface  AWEComposerBeautyEffectKeys()

@property (nonatomic, copy, readwrite) NSString *dataReadyKey;
@property (nonatomic, copy, readwrite) NSString *lastPanelNameKey;
@property (nonatomic, copy, readwrite) NSString *lastABGroupKey;
@property (nonatomic, copy, readwrite) NSString *lastRegionKey;
@property (nonatomic, copy, readwrite) NSString *businessName;
@property (nonatomic, copy, readwrite) NSString *userHadModifiedKey;

@end


@implementation AWEComposerBeautyEffectKeys

- (instancetype)initWithBusinessName:(NSString *)businessName
{
    self = [super init];
    if (self) {
        _businessName = businessName;
    }
    return self;
}

- (NSString *)p_defaultKey:(NSString *)key withPrefix:(NSString *)prefix
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

- (NSString *)lastPanelNameKey
{
    if (!_lastPanelNameKey) {
        _lastPanelNameKey = [self p_defaultKey:AWEComposerBeautyLastPanelNameKey withPrefix:self.businessName];
    }
    return _lastPanelNameKey;
}

- (NSString *)lastABGroupKey
{
    if (!_lastABGroupKey) {
        _lastABGroupKey = [self p_defaultKey:@"AWEComposerBeautyLastABGroupKey" withPrefix:self.businessName];
    }
    return _lastABGroupKey;
}

- (NSString *)lastRegionKey
{
    if (!_lastRegionKey) {
        _lastRegionKey = [self p_defaultKey:@"AWEComposerBeautyLastRegionKey" withPrefix:self.businessName];
    }
    return _lastRegionKey;
}

- (NSString *)userHadModifiedKey
{
    if (!_userHadModifiedKey) {
        _userHadModifiedKey = [self p_defaultKey:@"AWEComposerBeautyEffectModified" withPrefix:self.businessName];
    }
    return _userHadModifiedKey;
}

@end
