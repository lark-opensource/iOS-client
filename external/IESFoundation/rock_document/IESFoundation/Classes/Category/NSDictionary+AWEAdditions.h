//
//  NSDictionary+AWEAdditions.h
//  Pods
//
//  Created by Stan Shan on 2018/6/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (AWEAdditions)

- (id)awe_objectForKey:(NSString *)key;
- (id)awe_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)awe_intValueForKey:(NSString *)key;
- (NSInteger)awe_integerValueForKey:(NSString *)key;
- (NSUInteger)awe_unsignedIntegerValueForKey:(NSString *)key;
- (float)awe_floatValueForKey:(NSString *)key;
- (double)awe_doubleValueForKey:(NSString *)key;
- (long)awe_longValueForKey:(NSString *)key;
- (long long)awe_longlongValueForKey:(NSString *)key;
- (BOOL)awe_boolValueForKey:(NSString *)key;
- (NSString *)awe_stringValueForKey:(NSString *)key;
- (NSNumber *)awe_numberValueForKey:(NSString *)key;
- (NSArray *)awe_arrayValueForKey:(NSString *)key;
- (NSDictionary *)awe_dictionaryValueForKey:(NSString *)key;

- (NSString*)awe_dictionaryToJson;

@end

