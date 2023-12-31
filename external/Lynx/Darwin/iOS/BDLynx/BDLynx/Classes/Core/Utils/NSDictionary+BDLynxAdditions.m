//
//  NSDictionary+BDLynxAdditions.m
//  BDLynx
//
//  Created by bill on 2020/2/5.
//

#import "NSDictionary+BDLynxAdditions.h"

@implementation NSDictionary (BDLynxAdditions)

- (id)bdlynx_objectForKey:(NSString *)key {
  return [self bdlynx_objectForKey:key defalutObj:nil];
}

- (id)bdlynx_objectForKey:(id)aKey ofClass:(Class)aClass {
  return [self bdlynx_objectForKey:aKey ofClass:aClass defaultObj:nil];
}

- (int)bdlynx_intValueForKey:(NSString *)key {
  return [self bdlynx_intValueForKey:key defaultValue:0];
}

- (NSInteger)bdlynx_integerValueForKey:(NSString *)key {
  return [self bdlynx_integerValueForKey:key defaultValue:0];
}

- (NSUInteger)bdlynx_unsignedIntegerValueForKey:(NSString *)key {
  return [self bdlynx_unsignedIntegerValueForKey:key defaultValue:0];
}

- (float)bdlynx_floatValueForKey:(NSString *)key {
  return [self bdlynx_floatValueForKey:key defaultValue:0.f];
}

- (double)bdlynx_doubleValueForKey:(NSString *)key {
  return [self bdlynx_doubleValueForKey:key defaultValue:0.];
}

- (long)bdlynx_longValueForKey:(NSString *)key {
  return [self bdlynx_longValueForKey:key defaultValue:0];
}

- (long long)bdlynx_longlongValueForKey:(NSString *)key {
  return [self bdlynx_longlongValueForKey:key defaultValue:0];
}

- (BOOL)bdlynx_boolValueForKey:(NSString *)key {
  return [self bdlynx_integerValueForKey:key defaultValue:0] != 0;
}

- (NSString *)bdlynx_stringValueForKey:(NSString *)key {
  return [self bdlynx_stringValueForKey:key defaultValue:nil];
}

- (NSArray *)bdlynx_arrayValueForKey:(NSString *)key {
  return [self bdlynx_arrayValueForKey:key defaultValue:nil];
}

- (NSDictionary *)bdlynx_dictionaryValueForKey:(NSString *)key {
  return [self bdlynx_dictionaryValueForKey:key defalutValue:nil];
}

- (NSString *)bdlynx_dictionaryToJson {
  NSError *parseError = nil;

  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:self options:0 error:&parseError];

  return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
}

- (id)bdlynx_objectForKey:(NSString *)key defalutObj:(id)defaultObj {
  id obj = [self objectForKey:key];
  return obj ? obj : defaultObj;
}

- (id)bdlynx_objectForKey:(id)aKey ofClass:(Class)aClass defaultObj:(id)defaultObj {
  id obj = [self objectForKey:aKey];
  return (obj && [obj isKindOfClass:aClass]) ? obj : defaultObj;
}

- (int)bdlynx_intValueForKey:(NSString *)key defaultValue:(int)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return [(NSString *)value intValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value intValue] : defaultValue;
}

- (NSInteger)bdlynx_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return [(NSString *)value integerValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value integerValue] : defaultValue;
}

- (NSUInteger)bdlynx_unsignedIntegerValueForKey:(NSString *)key
                                   defaultValue:(NSUInteger)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return (NSUInteger)[(NSString *)value integerValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value unsignedIntegerValue]
                                                           : defaultValue;
}

- (double)bdlynx_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return [(NSString *)value doubleValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value doubleValue] : defaultValue;
}

- (float)bdlynx_floatValueForKey:(NSString *)key defaultValue:(float)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return [(NSString *)value floatValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value floatValue] : defaultValue;
}

- (long)bdlynx_longValueForKey:(NSString *)key defaultValue:(long)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return [(NSString *)value integerValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value longValue] : defaultValue;
}

- (long long)bdlynx_longlongValueForKey:(NSString *)key defaultValue:(long long)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return [(NSString *)value longLongValue];
  }
  return (value && [value isKindOfClass:[NSNumber class]]) ? [value longLongValue] : defaultValue;
}

- (NSString *)bdlynx_stringValueForKey:(NSString *)key defaultValue:(NSString *)defaultValue {
  id value = [self objectForKey:key];
  if (value && [value isKindOfClass:[NSString class]]) {
    return value;
  } else if (value && [value isKindOfClass:[NSNumber class]]) {
    return [value stringValue];
  } else {
    return defaultValue;
  }
}

- (NSArray *)bdlynx_arrayValueForKey:(NSString *)key defaultValue:(NSArray *)defaultValue {
  id value = [self objectForKey:key];
  return (value && [value isKindOfClass:[NSArray class]]) ? value : defaultValue;
}

- (NSDictionary *)bdlynx_dictionaryValueForKey:(NSString *)key
                                  defalutValue:(NSDictionary *)defaultValue {
  id value = [self objectForKey:key];
  return (value && [value isKindOfClass:[NSDictionary class]]) ? value : defaultValue;
}

@end
