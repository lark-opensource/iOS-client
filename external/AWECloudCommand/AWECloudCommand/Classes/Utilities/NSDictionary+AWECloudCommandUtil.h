//
//  NSDictionary+AWECloudCommandUtil.h
//  AWECloudCommand
//
//  Created by songxiangwu on 2018/1/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (AWECloudCommandUtil)

- (id)awe_cc_objectForKey:(NSString *)key;
- (id)awe_cc_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)awe_cc_intValueForKey:(NSString *)key;
- (NSInteger)awe_cc_integerValueForKey:(NSString *)key;
- (NSUInteger)awe_cc_unsignedIntegerValueForKey:(NSString *)key;
- (float)awe_cc_floatValueForKey:(NSString *)key;
- (double)awe_cc_doubleValueForKey:(NSString *)key;
- (long)awe_cc_longValueForKey:(NSString *)key;
- (long long)awe_cc_longlongValueForKey:(NSString *)key;
- (BOOL)awe_cc_boolValueForKey:(NSString *)key;
- (NSString *)awe_cc_stringValueForKey:(NSString *)key;
- (NSArray *)awe_cc_arrayValueForKey:(NSString *)key;
- (NSDictionary *)awe_cc_dictionaryValueForKey:(NSString *)key;
- (NSString *)awe_cc_dictionaryToJson;
+ (id)awe_cc_dictionaryWithJSONString:(NSString *)inJSON error:(NSError **)outError;
- (id)awe_cc_objectForInsensitiveKey:(NSString *)key;

@end

NS_ASSUME_NONNULL_END
