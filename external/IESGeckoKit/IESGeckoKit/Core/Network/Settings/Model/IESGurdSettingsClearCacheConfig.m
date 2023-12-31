#import "IESGurdSettingsClearCacheConfig.h"
#import "NSDictionary+IESGurdKit.h"
#import "IESGeckoDefines+Private.h"


@implementation IESGurdSettingsClearCacheConfig

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary
{
    if (!GURD_CHECK_DICTIONARY(dictionary)) {
        return nil;
    }
    
    NSMutableDictionary<NSString *, NSArray<NSString *> *> *targetChannelDictionary = [NSMutableDictionary dictionary];
    [dictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        targetChannelDictionary[key] = [obj iesgurdkit_safeArrayWithKey:@"channels" itemClass:[NSString class]];
    }];
    
    IESGurdSettingsClearCacheConfig *config = [[self alloc] init];
    config.targetChannelDictionary = [targetChannelDictionary copy];
    return config;
}

@end
