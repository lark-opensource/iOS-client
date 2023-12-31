//
//  NSDictionary+TTAdSplashAddition.h
//  TTAdSplashSDK
//
//  Created by yin on 2017/8/2.
//  Copyright © 2017年 yin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (TTAdSplashAddition)

- (id)ttad_objectForKey:(NSString *)key;
- (id)ttad_objectForKey:(id)aKey ofClass:(Class)aClass;
- (int)ttad_intValueForKey:(NSString *)key;
- (int)ttad_intValueForKey:(NSString *)key defaultValue:(int)defaultValue;
- (NSInteger)ttad_integerValueForKey:(NSString *)key;
- (NSInteger)ttad_integerValueForKey:(NSString *)key defaultValue:(NSInteger)defaultValue;
- (NSUInteger)ttad_unsignedIntegerValueForKey:(NSString *)key;
- (float)ttad_floatValueForKey:(NSString *)key;
- (double)ttad_doubleValueForKey:(NSString *)key;
- (double)ttad_doubleValueForKey:(NSString *)key defaultValue:(double)defaultValue;
- (long)ttad_longValueForKey:(NSString *)key;
- (long long)ttad_longlongValueForKey:(NSString *)key;
- (BOOL)ttad_boolValueForKey:(NSString *)key;
- (NSString *)ttad_stringValueForKey:(NSString *)key;
- (NSArray *)ttad_arrayValueForKey:(NSString *)key;
- (NSDictionary *)ttad_dictionaryValueForKey:(NSString *)key;
    
- (NSString*)ttad_dictionaryToJson;

@end
