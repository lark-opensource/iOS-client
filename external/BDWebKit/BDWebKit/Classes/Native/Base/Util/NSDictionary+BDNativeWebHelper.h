//
//  NSDictionary+BDNativeWebHelper.h
//  BDNativeWebView
//
//  Created by liuyunxuan on 2019/6/16.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSDictionary (BDNativeHelper)

- (id)bdNative_objectForKey:(NSString *)key;
- (id)bdNative_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)bdNative_intValueForKey:(NSString *)key;
- (NSInteger)bdNative_integerValueForKey:(NSString *)key;
- (NSUInteger)bdNative_unsignedIntegerValueForKey:(NSString *)key;
- (float)bdNative_floatValueForKey:(NSString *)key;
- (double)bdNative_doubleValueForKey:(NSString *)key;
- (long)bdNative_longValueForKey:(NSString *)key;
- (long long)bdNative_longlongValueForKey:(NSString *)key;
- (BOOL)bdNative_boolValueForKey:(NSString *)key;
- (NSString *)bdNative_stringValueForKey:(NSString *)key;
- (NSArray *)bdNative_arrayValueForKey:(NSString *)key;
- (NSDictionary *)bdNative_dictionaryValueForKey:(NSString *)key;

- (NSString *)bdNative_JSONRepresentation;

@end

NS_ASSUME_NONNULL_END
