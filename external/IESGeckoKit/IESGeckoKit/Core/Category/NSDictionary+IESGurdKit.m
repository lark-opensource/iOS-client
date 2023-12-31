//
//  NSDictionary+IESGurdKit.m
//  IESGeckoKit-ByteSync-Config_CN-Core-Downloader-Example
//
//  Created by 陈煜钏 on 2021/4/21.
//

#import "NSDictionary+IESGurdKit.h"

@implementation NSDictionary (IESGurdKit)

- (BOOL)iesgurdkit_safeBoolWithKey:(NSString *)key defaultValue:(BOOL)defaultValue
{
    NSNumber *value = self[key];
    return ([value isKindOfClass:[NSNumber class]]) ? value.boolValue : defaultValue;
}

- (NSInteger)iesgurdkit_safeIntegerWithKey:(NSString *)key defaultValue:(NSInteger)defaultValue
{
    NSNumber *value = self[key];
    return ([value isKindOfClass:[NSNumber class]]) ? value.integerValue : defaultValue;
}

- (NSString *)iesgurdkit_safeStringWithKey:(NSString *)key
{
    NSString *value = self[key];
    return ([value isKindOfClass:[NSString class]]) ? value : nil;
}

- (NSArray *)iesgurdkit_safeArrayWithKey:(NSString *)key itemClass:(Class)itemClass
{
    NSArray *array = self[key];
    if (![array isKindOfClass:[NSArray class]]) {
        return nil;
    }
    for (id item in array) {
        if (![item isKindOfClass:itemClass]) {
            return nil;
        }
    }
    return array;
}

- (NSDictionary *)iesgurdkit_safeDictionaryWithKey:(NSString *)key
                                          keyClass:(Class)keyClass
                                        valueClass:(Class)valueClass
{
    NSDictionary *dictionary = self[key];
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    for (id key in dictionary) {
        if (![key isKindOfClass:keyClass]) {
            return nil;
        }
        id value = dictionary[key];
        if (![value isKindOfClass:valueClass]) {
            return nil;
        }
    }
    return dictionary;
}

@end
