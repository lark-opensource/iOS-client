//
//  NSObject+LKAttributes.m
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import "NSObject+LKAttributes.h"
#import <objc/message.h>
#include "pthread_extend.h"

static pthread_mutex_t map_mtx = PTHREAD_MUTEX_INITIALIZER;

@implementation NSObject (LKAttributes)

+ (NSMutableDictionary *)attributeMapCache_noLock  // access ONLY within map_mtx LOCK [WARNING]
{
    static NSMutableDictionary *cache;
    if(cache == nil) cache = [NSMutableDictionary dictionary];
    return cache;
}

+ (NSString *)lk_className
{
    return NSStringFromClass([self class]);
}

+ (Class)lk_anstorClass
{
    return [NSObject class];
}

+ (NSDictionary *)lk_managedProperties
{
    NSString *cacheName = [NSStringFromClass(self) stringByAppendingString:@".property"];
    pthread_mutex_lock(&map_mtx);
    NSDictionary *cachedProperties = [[self attributeMapCache_noLock] objectForKey:cacheName];
    pthread_mutex_unlock(&map_mtx);
    if (cachedProperties) {
        return cachedProperties;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (Class class = self; class != [self lk_anstorClass]; class = [class superclass]) {
        [dic addEntriesFromDictionary:[class lk_properties]];
    }
    pthread_mutex_lock(&map_mtx);
    [[self attributeMapCache_noLock] setObject:dic forKey:cacheName];
    pthread_mutex_unlock(&map_mtx);
    return dic;
}

+ (NSString *)lk_primaryKey
{
    return nil;
}

+ (id)lk_objectWithDictionary:(NSDictionary *)dataDic
{
    return [self lk_objectWithDictionary:dataDic block:NULL];
}

+ (NSArray *)lk_objectsWithDictionaries:(NSArray *)data
{
    return [self lk_objectsWithDictionaries:data block:NULL];
}

+ (instancetype)lk_objectWithDictionary:(NSDictionary *)dataDic block:(void (^)(id, NSDictionary *))block
{
    NSObject *object = [[self alloc] init];
    [object lk_setAttributes:dataDic block:block];
    return object;
}

+ (NSArray *)lk_objectsWithDictionaries:(NSArray *)dataDics block:(void (^)(id object,NSDictionary *dataDic))block
{
    if (!dataDics) {
        return nil;
    }
    NSMutableArray *array = [NSMutableArray array];
    for (NSDictionary *data in dataDics) {
        if ([data isKindOfClass:[NSDictionary class]]) {
            id object = [self lk_objectWithDictionary:data block:block];
            if (object) {
                [array addObject:object];
            }
        }
    }
    return array;
}


- (BOOL)lk_validate
{
    return YES;
}

+ (NSDictionary *)lk_attributeMapDictionary
{
    return nil;
}

+ (NSDictionary *)lk_allAttributeMapDictionary
{
    pthread_mutex_lock(&map_mtx);
    NSDictionary *cachedMap = [[self attributeMapCache_noLock] objectForKey:NSStringFromClass(self)];
    pthread_mutex_unlock(&map_mtx);
    if (cachedMap) {
        return cachedMap;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    for (Class class = self; class != [self lk_anstorClass]; class = [class superclass])
    {
        [dic addEntriesFromDictionary:[class lk_attributeMapDictionary]];
    }
    pthread_mutex_lock(&map_mtx);
    [[self attributeMapCache_noLock] setObject:dic forKey:NSStringFromClass(self)];
    pthread_mutex_unlock(&map_mtx);
    return dic;
}

- (void)lk_setAttributes:(NSDictionary*)dataDic
{
    [self lk_setAttributes:dataDic block:NULL];
}

- (void)gh_setValue:(id)value forProperty:(LKObjectProperty *)property
{
    void *function = objc_msgSend;
    if (!property.dynamic && property.setterImp) {
        function = (void *)property.setterImp;
    }
    if (!property.clazz)
    {
        if (property.type == NSPropertyTypeBOOL && [value respondsToSelector:@selector(boolValue)]) {
            ((void (*)(id, SEL, bool))function)(self, property.setter, [value boolValue]);
        } else if ((property.type == NSPropertyTypeInteger || property.type == NSPropertyTypeLong) && [value respondsToSelector:@selector(integerValue)]) {
            ((void (*)(id, SEL, NSInteger))function)(self, property.setter, [value integerValue]);
        } else if (property.type == NSPropertyTypeLongLong && [value respondsToSelector:@selector(longLongValue)]) {
            ((void (*)(id, SEL, long long))function)(self, property.setter, [value longLongValue]);
        } else if (property.type == NSPropertyTypeFloat && [value respondsToSelector:@selector(floatValue)]) {
            ((void (*)(id, SEL, float))function)(self, property.setter, [value floatValue]);
        } else if (property.type == NSPropertyTypeDouble && [value respondsToSelector:@selector(doubleValue)]) {
            ((void (*)(id, SEL, double))function)(self, property.setter, [value doubleValue]);
        }
    } else if (![value isKindOfClass:property.clazz]) {
        if (property.clazz == [NSString class] && [value respondsToSelector:@selector(stringValue)]) {
            ((void (*)(id, SEL, NSString *))function)(self, property.setter, [value stringValue]);
        } else if(property.clazz == [NSNumber class] && [value respondsToSelector:@selector(floatValue)]){
            ((void (*)(id, SEL, NSNumber *))function)(self, property.setter, @([value floatValue]));
        } else if (property.clazz == [NSDate class] && [value respondsToSelector:@selector(doubleValue)]){
            ((void (*)(id, SEL, NSDate *))function)(self, property.setter,
                                                    [NSDate dateWithTimeIntervalSince1970:[value doubleValue]]);
        }
    } else {
        ((void (*)(id, SEL, id))function)(self, property.setter, value);
    }
}

- (id)gh_valueForProperty:(LKObjectProperty *)property
{
    return [self valueForKey:property.propertyName];
}

- (void)lk_setAttributes:(NSDictionary *)dataDic block:(void (^)(NSObject *, NSDictionary *))block
{
    if (![dataDic isKindOfClass:[NSDictionary class]]) {
        dataDic = @{}; //去掉之前的return，解决default value丢失的问题
    }
    
    NSDictionary *attrMap = [self.class lk_allAttributeMapDictionary];
    
    NSDictionary *properties = [[self class] lk_managedProperties];
    
    [attrMap enumerateKeysAndObjectsUsingBlock:^(id attributeName, id obj, BOOL *stop) {
        
        LKObjectProperty *property = [properties objectForKey:attributeName];
        id mapKey = obj;
        NSString *defaultValue = nil;
        
        if ([attributeName rangeOfString:@"_:_"].location != NSNotFound) {
            NSArray *attributes = [attributeName componentsSeparatedByString:@"_:_"];
            attributeName = [attributes firstObject];
            property = [properties objectForKey:attributeName];
            defaultValue = [attributes lastObject];
        }
        
        NSString *dataDicKey = nil;
        
        if ([mapKey isKindOfClass:[NSDictionary class]]) {
            dataDicKey = [[mapKey allKeys] firstObject];
            id object = [mapKey objectForKey:dataDicKey];
            if (property.clazz == [NSArray class] && [object isKindOfClass:[NSArray class]]) {
                Class objectClass = [object firstObject];
                NSArray *datas = [dataDic valueForKeyPath:dataDicKey];
                if ([datas isKindOfClass:[NSArray class]]) {
                    NSArray *objects = [objectClass lk_objectsWithDictionaries:datas];
                    [self gh_setValue:objects forProperty:property];
                }
                return;
            } else if([object class] == property.clazz){
                NSDictionary *data = [dataDic valueForKeyPath:dataDicKey];
                if ([data isKindOfClass:[NSDictionary class]]) {
                    id oldValue = [self gh_valueForProperty:property];
                    if (oldValue && [oldValue isKindOfClass:property.clazz]) {
                        NSString *primaryKey = [property.clazz lk_primaryKey];
                        id newPrimaryValue = nil;
                        id primaryValue = nil;
                        if (primaryKey) {
                            primaryValue = [oldValue valueForKey:primaryKey];
                            newPrimaryValue = [data objectForKey:[[property.clazz lk_allAttributeMapDictionary] objectForKey:primaryKey]];
                            if ([newPrimaryValue isKindOfClass:[NSNumber class]]) {
                                newPrimaryValue = [newPrimaryValue stringValue];
                            }
                        }
                        
                        if (!primaryValue || [primaryValue isEqual:newPrimaryValue]) {
                            [oldValue lk_setAttributes:data];
                        } else {
                            NSObject *value = [property.clazz lk_objectWithDictionary:data];
                            [self gh_setValue:value forProperty:property];
                        }
                    } else {
                        NSObject *value = [property.clazz lk_objectWithDictionary:data];
                        [self gh_setValue:value forProperty:property];
                    }
                }
                return;
            }
        }
        else if ([mapKey isKindOfClass:[NSArray class]]) {
            dataDicKey = [mapKey firstObject];
            defaultValue = [mapKey lastObject];
        }
        else
        {
            dataDicKey = mapKey;
        }
        
        id value = [dataDic valueForKeyPath:dataDicKey];
        if (value) {
            [self gh_setValue:value forProperty:property];
        } else if (defaultValue) {
            [self gh_setValue:defaultValue forProperty:property];
        }
    }];
    
    if (block)
    {
        block(self,dataDic);
    }
}

- (NSDictionary *)lk_dataDictionary
{
    NSMutableDictionary *dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary *attrMap = [self.class lk_allAttributeMapDictionary];
    NSEnumerator *keyEnum = [attrMap keyEnumerator];
    id attributeName;
    while ((attributeName = [keyEnum nextObject]))
    {
        NSRange indicatorRange = [attributeName rangeOfString:@":"];
        if (indicatorRange.location != NSNotFound) {
            attributeName = [attributeName substringToIndex:indicatorRange.location];
        }
        NSObject *valueObj = [self valueForKey:attributeName];
        id mapKey = [attrMap objectForKey:attributeName];
        if ([mapKey isKindOfClass:[NSDictionary class]]) {
            mapKey = [[(NSDictionary *)mapKey allKeys] firstObject];
            if ([valueObj isKindOfClass:[NSArray class]]) {
                valueObj = [valueObj valueForKey:@"dataDictionary"];
            } else {
                valueObj = [valueObj lk_dataDictionary];
            }
        } else if ([mapKey isKindOfClass:[NSArray class]]) {
            mapKey = [mapKey firstObject];
        }
        
        if (valueObj && mapKey)
        {
            [dataDictionary setObject:valueObj forKey:mapKey];
        }
    }
    return dataDictionary;
}

- (NSString *)lk_customDescription
{
    return nil;
}

@end
