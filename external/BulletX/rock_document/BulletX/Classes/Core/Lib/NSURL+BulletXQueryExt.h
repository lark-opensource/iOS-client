//
//  NSURL+BulletQuery.h
//  AAWELaunchOptimization
//
//  Created by duanefaith on 2019/10/11.
//

NS_ASSUME_NONNULL_BEGIN

@interface NSURL (BulletXQueryExt)

@property(nonatomic, strong) NSDictionary<NSString *, NSString *> *bullet_queryParamDict;

- (NSString *)bullet_schemeAndHost;
- (nullable NSString *)bullet_findDecodedValueByKey:(NSString *)key;
- (NSURL *)bullet_urlByAppendingQueryItemWithDictionary:(NSDictionary *)queryItems;

@end

NS_ASSUME_NONNULL_END
