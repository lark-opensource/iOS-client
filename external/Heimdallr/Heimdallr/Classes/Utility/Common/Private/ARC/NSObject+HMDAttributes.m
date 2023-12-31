//
//  NSObject+HMDAttributes.m
//  KKShopping
//
//  Created by 刘诗彬 on 14/12/9.
//  Copyright (c) 2014年 Nice. All rights reserved.
//

#import "NSObject+HMDAttributes.h"
#import <objc/message.h>
#include "pthread_extended.h"
#import "NSObject+HMDUtilities.h"
#import "HMDMacro.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"

@implementation NSObject (HMDAttributes)

#pragma mark - Basic

+ (NSString *)hmd_className {
    return NSStringFromClass([self class]);
}

+ (Class)hmd_ancestorClass {
    return [NSObject class];
}

#pragma mark - Initialize

+ (instancetype)hmd_objectWithDictionary:(NSDictionary *)dataDict {
    return [self hmd_objectWithDictionary:dataDict block:nil];
}

+ (NSArray *)hmd_objectsWithDictionaries:(NSArray<NSDictionary *> *)dataArray {
    return [self hmd_objectsWithDictionaries:dataArray block:nil];
}

+ (instancetype)hmd_objectWithDictionary:(NSDictionary *)dataDict block:(NS_NOESCAPE HMDAttributeExtraBlock)block {
    NSObject *object = [[self alloc] init];
    [object hmd_setAttributes:dataDict block:block];
    return object;
}

+ (NSArray *)hmd_objectsWithDictionaries:(NSArray<NSDictionary *> *)dataArray block:(NS_NOESCAPE HMDAttributeExtraBlock)block {
    if (HMDIsEmptyArray(dataArray)) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:dataArray.count];
    for (NSDictionary *dataDict in dataArray) {
        if (![dataDict isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSObject *object = [self hmd_objectWithDictionary:dataDict block:block];
        [array addObject:object];
    }
    if (array.count == 0) {
        return nil;
    }
    return [array copy];
}

#pragma mark - Aggregation

+ (NSDictionary *)_hmd_attributeMapCacheForKey:(NSString *)key packagedBlock:(NSDictionary * _Nullable (NS_NOESCAPE ^)(Class _Nonnull cls))block {
    static pthread_mutex_t map_mtx = PTHREAD_MUTEX_INITIALIZER;
    static NSMutableDictionary *cache;
    if (cache == nil) {
        cache = [NSMutableDictionary dictionary];
    }
    pthread_mutex_lock(&map_mtx);
    NSDictionary *cachedObj = [cache hmd_objectForKey:key class:NSDictionary.class];
    pthread_mutex_unlock(&map_mtx);
    if (cachedObj) {
        return cachedObj;
    }
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    for (Class cls = self; cls != [self hmd_ancestorClass]; cls = [cls superclass]) {
        NSDictionary *map = block(cls);
        if (map) {
            [dict addEntriesFromDictionary:map];
        }
    }
    cachedObj = [dict copy];
    pthread_mutex_lock(&map_mtx);
    [cache setObject:cachedObj forKey:key];
    pthread_mutex_unlock(&map_mtx);
    return cachedObj;
}

+ (NSDictionary *)hmd_allAttributeMapDictionary {
    NSString *key = [NSStringFromClass(self) stringByAppendingString:@".attribute"];
    return [self _hmd_attributeMapCacheForKey:key packagedBlock:^NSDictionary * _Nullable(Class _Nonnull __unsafe_unretained cls) {
        return [cls hmd_attributeMapDictionary];
    }];
}

+ (NSDictionary *)hmd_managedProperties {
    NSString *key = [NSStringFromClass(self) stringByAppendingString:@".property"];
    return [self _hmd_attributeMapCacheForKey:key packagedBlock:^NSDictionary * _Nullable(Class _Nonnull __unsafe_unretained cls) {
        return [cls hmd_properties];
    }];
}

#pragma mark - Dictionary to Attributes

- (void)_hmd_gh_setValue:(id)value forProperty:(GHNSObjectProperty *)property {
    void *function = objc_msgSend;
    if (!property.dynamic && property.setterImpl) {
        function = (void *)property.setterImpl;
    }
    if (!property.cls) { // 基础类型 / 未知类型 / 类类型(无法正确识别到类)
        // 仅对基础类型进行处理
        if (property.type == NSPropertyTypeBOOL) {
            if ([value respondsToSelector:@selector(boolValue)]) {
                ((void (*)(id, SEL, bool))function)(self, property.setter, [value boolValue]);
            }
        } else if (property.type == NSPropertyTypeInteger || property.type == NSPropertyTypeLong) {
            if ([value respondsToSelector:@selector(integerValue)]) {
                ((void (*)(id, SEL, NSInteger))function)(self, property.setter, [value integerValue]);
            }
        } else if (property.type == NSPropertyTypeLongLong) {
            if ([value respondsToSelector:@selector(longLongValue)]) {
                ((void (*)(id, SEL, long long))function)(self, property.setter, [value longLongValue]);
            }
        } else if (property.type == NSPropertyTypeFloat) {
            if ([value respondsToSelector:@selector(floatValue)]) {
                ((void (*)(id, SEL, float))function)(self, property.setter, [value floatValue]);
            }
        } else if (property.type == NSPropertyTypeDouble) {
            if ([value respondsToSelector:@selector(doubleValue)]) {
                ((void (*)(id, SEL, double))function)(self, property.setter, [value doubleValue]);
            }
        }
    } else if (![value isKindOfClass:property.cls]) { // 类类型(数据类型不匹配)
        // 特殊处理部分类型
        if (property.cls == [NSString class]) {
            if ([value respondsToSelector:@selector(stringValue)]) {
                ((void (*)(id, SEL, NSString *))function)(self, property.setter, [value stringValue]);
            }
        } else if (property.cls == [NSNumber class]) {
            if ([value respondsToSelector:@selector(floatValue)]) {
                ((void (*)(id, SEL, NSNumber *))function)(self, property.setter, @([value floatValue]));
            }
        } else if (property.cls == [NSDate class]) {
            if ([value respondsToSelector:@selector(doubleValue)]) {
                ((void (*)(id, SEL, NSDate *))function)(self, property.setter, [NSDate dateWithTimeIntervalSince1970:[value doubleValue]]);
            }
        }
    } else { // 类类型(数据类型匹配)
        ((void (*)(id, SEL, id))function)(self, property.setter, value);
    }
}

- (id)_hmd_gh_valueForProperty:(GHNSObjectProperty *)property {
    return [self valueForKey:property.name];
}

- (BOOL)_hmd_isMutableClassProperty:(Class)cls {
    if (!cls) {
        return NO;
    }
    // https://developer.apple.com/library/archive/documentation/General/Conceptual/CocoaEncyclopedia/ObjectMutability/ObjectMutability.html
    if (cls == [NSMutableArray class] ||
        cls == [NSMutableDictionary class] ||
        cls == [NSMutableSet class] ||
        cls == [NSMutableIndexSet class] ||
        cls == [NSMutableCharacterSet class] ||
        cls == [NSMutableData class] ||
        cls == [NSMutableString class] ||
        cls == [NSMutableAttributedString class] ||
        cls == [NSMutableURLRequest class]) {
        return YES;
    }
    return NO;
}

- (void)hmd_setAttributes:(NSDictionary *)dataDict {
    [self hmd_setAttributes:dataDict block:nil];
}

- (void)hmd_setAttributes:(NSDictionary *)dataDict block:(NS_NOESCAPE HMDAttributeExtraBlock)block {
    // 确保 dataDict 为空时，也能设置默认值
    if (HMDIsEmptyDictionary(dataDict)) {
        dataDict = @{};
    }
    
    NSDictionary *attrMap = [[self class] hmd_allAttributeMapDictionary];
    NSDictionary *propMap = [[self class] hmd_managedProperties];
    
    [attrMap enumerateKeysAndObjectsUsingBlock:^(id _Nonnull attributeName, id _Nonnull mapKey, BOOL * _Nonnull stop) {
        GHNSObjectProperty *property = [propMap objectForKey:attributeName];
        NSString *dataDictKey = nil;
        id defaultValue = nil;
        
        if ([mapKey isKindOfClass:[NSDictionary class]]) {
            // `HMD_ATTR_MAP_CLASS`
            dataDictKey = [[mapKey allKeys] firstObject];
            Class objCls = [mapKey objectForKey:dataDictKey];
            if (property.cls == [NSArray class]) {
                NSArray *dataArray = [dataDict valueForKeyPath:dataDictKey];
                if ([dataArray isKindOfClass:[NSArray class]]) {
                    NSArray *objects = [objCls hmd_objectsWithDictionaries:dataArray];
                    [self _hmd_gh_setValue:objects forProperty:property];
                }
            } else if (property.cls == objCls) {
                NSDictionary *data = [dataDict valueForKeyPath:dataDictKey];
                if (data == nil || [data isKindOfClass:[NSDictionary class]]) {
                    NSObject *object = [objCls hmd_objectWithDictionary:data];
                    [self _hmd_gh_setValue:object forProperty:property];
                }
            }
            return;
        } else if ([mapKey isKindOfClass:[NSArray class]]) {
            // `HMD_ATTR_MAP_DEFAULT` / `HMD_ATTR_MAP_DEFAULT2`
            dataDictKey = [mapKey firstObject];
            defaultValue = [mapKey lastObject];
        } else {
            // `HMD_ATTR_MAP`
            dataDictKey = mapKey;
        }
        
        id value = [dataDict valueForKeyPath:dataDictKey] ?: defaultValue;
        if (value) {
            if ([self _hmd_isMutableClassProperty:property.cls]) {
                value = [value mutableCopy];
            }
            [self _hmd_gh_setValue:value forProperty:property];
        }
    }];
    
    if (block) {
        block(self, dataDict);
    }
}

#pragma mark - Attributes to Dictionary

- (NSDictionary *)hmd_dataDictionary {
    NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
    
    NSDictionary *attrMap = [[self class] hmd_allAttributeMapDictionary];
    [attrMap enumerateKeysAndObjectsUsingBlock:^(id _Nonnull attributeName, id _Nonnull mapKey, BOOL * _Nonnull stop) {
        NSObject *object = [self valueForKey:attributeName];
        NSString *key = nil;
        
        if ([mapKey isKindOfClass:[NSDictionary class]]) {
            // `HMD_ATTR_MAP_CLASS`
            key = [[mapKey allKeys] firstObject];
            if ([object isKindOfClass:[NSArray class]]) {
                object = [object valueForKeyPath:@"hmd_dataDictionary"];
            } else {
                object = [object hmd_dataDictionary];
            }
        } else if ([mapKey isKindOfClass:[NSArray class]]) {
            // `HMD_ATTR_MAP_DEFAULT` / `HMD_ATTR_MAP_DEFAULT2`
            key = [mapKey firstObject];
        } else {
            // `HMD_ATTR_MAP`
            key = mapKey;
        }
        
        if (object && key) {
            [dataDict setObject:object forKey:key];
        }
    }];
    return [dataDict copy];
}

#pragma mark - HMDAttributes

+ (NSDictionary *)hmd_attributeMapDictionary {
    return nil;
}

@end
