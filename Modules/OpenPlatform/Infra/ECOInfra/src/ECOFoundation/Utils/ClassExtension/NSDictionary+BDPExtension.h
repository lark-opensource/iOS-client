//
//  NSDictionary+BDPExtension.h
//  Timor
//
//  Created by muhuai on 2018/1/25.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface NSDictionary (BDPExtension)
+ (nullable NSDictionary *)bdp_dictionaryWithJsonString:(nonnull NSString *)jsonString;

- (NSDictionary *)decodeNativeBuffersIfNeed;
- (NSDictionary *)encodeNativeBuffersIfNeed;

- (id)objectForKey:(NSString *)key defalutObj:(id)defaultObj;
- (id)objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj;
- (int)intValueForKey:(NSString *)key defaultValue:(int)defaultValue;
- (NSInteger)integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (NSUInteger)unsignedIntegerValueForKey:(NSString *)key defaultValue:(NSUInteger)defaultValue;
- (float)floatValueForKey:(NSString *)key defaultValue:(float)defaultValue;
- (double)doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue;
- (long)longValueForKey:(NSString *)key defaultValue:(long)defaultValue;
- (long long)longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue;
- (BOOL)boolValueForKey:(NSString *)key defaultValue:(BOOL)defaultValue;
- (NSString *)stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue;
- (NSArray *)arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue;
- (NSDictionary *)dictionaryValueForKey:(NSString *)key defalutValue:(NSDictionary *)defaultValue;

- (id)bdp_objectForKey:(NSString *)key;
- (id)bdp_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)bdp_intValueForKey:(NSString *)key;
- (NSInteger)bdp_integerValueForKey:(NSString *)key;
- (NSUInteger)bdp_unsignedIntegerValueForKey:(NSString *)key;
- (float)bdp_floatValueForKey:(NSString *)key;
- (double)bdp_doubleValueForKey:(NSString *)key;
- (long)bdp_longValueForKey:(NSString *)key;
- (long long)bdp_longlongValueForKey:(NSString *)key;
- (BOOL)bdp_boolValueForKey:(NSString *)key DEPRECATED_MSG_ATTRIBUTE("deprecated, please use [NSDictionary bdp_boolValueForKey2:]");
- (BOOL)bdp_boolValueForKey2:(NSString *)key;
- (NSString *)bdp_stringValueForKey:(NSString *)key;
- (NSArray *)bdp_arrayValueForKey:(NSString *)key;
- (NSDictionary *)bdp_dictionaryValueForKey:(NSString *)key;

- (JSValue *)bdp_jsvalueInContext:(JSContext *)ctx;

- (NSDictionary *)bdp_dictionaryWithLowercaseKeys;
- (NSDictionary *)bdp_dictionaryWithCapitalizedKeys;

- (NSString *)bdp_URLQueryString;

- (nullable NSString *)bdp_jsonString;

+ (NSDictionary *)_dictWithString:(NSString *)string;


@end
