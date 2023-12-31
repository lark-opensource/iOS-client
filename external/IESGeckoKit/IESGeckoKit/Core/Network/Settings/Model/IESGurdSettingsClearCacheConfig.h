#import <Foundation/Foundation.h>

#import "IESGeckoDefines.h"

NS_ASSUME_NONNULL_BEGIN

@interface IESGurdSettingsClearCacheConfig : NSObject

@property (nonatomic, copy) NSDictionary<NSString *, NSArray<NSString *> *> *targetChannelDictionary;

+ (instancetype)configWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
