//
//  NSDictionary+BDLynxAdditions.h
//  BDLynx
//
//  Created by bill on 2020/2/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (BDLynxAdditions)

- (id)bdlynx_objectForKey:(NSString *)key;
- (id)bdlynx_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)bdlynx_intValueForKey:(NSString *)key;
- (NSInteger)bdlynx_integerValueForKey:(NSString *)key;
- (NSUInteger)bdlynx_unsignedIntegerValueForKey:(NSString *)key;
- (float)bdlynx_floatValueForKey:(NSString *)key;
- (double)bdlynx_doubleValueForKey:(NSString *)key;
- (long)bdlynx_longValueForKey:(NSString *)key;
- (long long)bdlynx_longlongValueForKey:(NSString *)key;
- (BOOL)bdlynx_boolValueForKey:(NSString *)key;
- (NSString *)bdlynx_stringValueForKey:(NSString *)key;
- (NSArray *)bdlynx_arrayValueForKey:(NSString *)key;
- (NSDictionary *)bdlynx_dictionaryValueForKey:(NSString *)key;

- (NSString *)bdlynx_dictionaryToJson;

@end

NS_ASSUME_NONNULL_END
