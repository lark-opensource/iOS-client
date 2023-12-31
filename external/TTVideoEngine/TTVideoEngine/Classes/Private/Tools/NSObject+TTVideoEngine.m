//
//  NSObject+TTVideoEngine.m
//  TTVideoEngine
//
//  Created by 黄清 on 2019/7/12.
//

#import "NSObject+TTVideoEngine.h"
#import <objc/runtime.h>
#import "TTVideoEngineUtilPrivate.h"


static __inline__ __attribute__((always_inline)) NSDateFormatter *_ttvideoengine_ISODateFormatter() {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";
    });
    return formatter;
}

@implementation NSObject (TTVideoEngine)

+ (NSDictionary<NSString *, Class> *)_ttvideoengine_codableProperties {
    unsigned int proCount;
    objc_property_t *properties = class_copyPropertyList(self, &proCount);
    __autoreleasing NSMutableDictionary *propertiyArray = [NSMutableDictionary dictionary];
    for (unsigned int i = 0; i < proCount; i++) {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        __autoreleasing NSString *key = @(propertyName);
        Class proCls = nil;
        char *typeEncde = property_copyAttributeValue(property, "T");
        switch (typeEncde[0]) {
            case '@': {
                if (strlen(typeEncde) >= 3) {
                    char *clsName = strndup(typeEncde + 2, strlen(typeEncde) - 3);
                    __autoreleasing NSString *name = @(clsName);
                    NSRange range = [name rangeOfString:@"<"];
                    if (range.location != NSNotFound) {
                        name = [name substringToIndex:range.location];
                    }
                    proCls = NSClassFromString(name) ?: [NSObject class];
                    free(clsName);
                }
                break;
            }
            case '{': {
                proCls = [NSValue class];
                break;
            }
            case 'c':
            case 's':
            case 'C':
            case 'q':
            case 'l':
            case 'i':
            case 'I':
            case 'S':
            case 'Q':
            case 'L':
            case 'f':
            case 'B':
            case 'd':{
                proCls = [NSNumber class];
                break;
            }
        }
        free(typeEncde);
        
        if (proCls) {
            char *ivar = property_copyAttributeValue(property, "V");
            if (ivar) {
                __autoreleasing NSString *ivarName = @(ivar);
                if ([ivarName isEqualToString:[@"_" stringByAppendingString:key]] || [ivarName isEqualToString:key]) {
                    propertiyArray[key] = proCls;
                }
                free(ivar);
            } else {
                char *readonly = property_copyAttributeValue(property, "R");
                char *dynamic = property_copyAttributeValue(property, "D");
                if (!readonly && dynamic) {
                    propertiyArray[key] = proCls;
                }
                free(readonly);
                free(dynamic);
            }
        }
    }
    free(properties);
    return propertiyArray;
}

- (NSDictionary<NSString *, Class> *)_ttvideoengine_codableProperties {
    __autoreleasing NSDictionary *codablePros = objc_getAssociatedObject([self class], _cmd);
    if (!codablePros) {
        Class subCls = [self class];
        codablePros = [NSMutableDictionary dictionary];
        while (subCls != [NSObject class]) {
            [(NSMutableDictionary *)codablePros addEntriesFromDictionary:[subCls _ttvideoengine_codableProperties]];
            subCls = [subCls superclass];
        }
        codablePros = [NSDictionary dictionaryWithDictionary:codablePros];
        objc_setAssociatedObject([self class], _cmd, codablePros, OBJC_ASSOCIATION_RETAIN);
    }
    return codablePros;
}

- (void)ttvideoengine_initWithCoder:(NSCoder *)aDecoder {
    BOOL secSupport = [[self class] supportsSecureCoding];
    BOOL secAvail = [aDecoder respondsToSelector:@selector(decodeObjectOfClass:forKey:)];
    NSDictionary *proes = self._ttvideoengine_codableProperties;
    for (NSString *key in proes) {
        Class proCls = proes[key];
        id object = nil;
        if (secAvail) {
            object = [aDecoder decodeObjectOfClass:proCls forKey:key];
        } else {
            object = [aDecoder decodeObjectForKey:key];
        }
        if (object) {
            if (secSupport && ![object isKindOfClass:proCls] && object != [NSNull null]) {
#ifdef DEBUG
                [NSException raise:@"TTVideoEngineCodingException" format:@"Expected '%@' to be a %@, but was actually a %@", key, proCls, [object class]];
#endif
            }
            [self setValue:object forKey:key];
        }
    }
}

- (void)ttvideoengine_encodeWithCoder:(NSCoder *)aCoder {
    for (NSString *key in self._ttvideoengine_codableProperties) {
        id object = [self valueForKey:key];
        if (object) [aCoder encodeObject:object forKey:key];
    }
}

static id _ModelToJSONObjectRecursive(NSObject *model) {
    if (!model || model == (id)kCFNull) return model;
    if ([model class] == model) return NSStringFromClass([model class]);
    if ([model isKindOfClass:[NSString class]]) return model;
    if ([model isKindOfClass:[NSNumber class]]) return model;
    if ([model isKindOfClass:[NSDictionary class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        NSMutableDictionary *newDic = [NSMutableDictionary new];
        [((NSDictionary *)model) enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            NSString *stringKey = [key isKindOfClass:[NSString class]] ? key : key.description;
            if (!stringKey) return;
            id jsonObj = _ModelToJSONObjectRecursive(obj);
            if (!jsonObj) jsonObj = (id)kCFNull;
            newDic[stringKey] = jsonObj;
        }];
        return newDic;
    }
    if ([model isKindOfClass:[NSSet class]]) {
        NSArray *array = ((NSSet *)model).allObjects;
        if ([NSJSONSerialization isValidJSONObject:array]) return array;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in array) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            } else {
                id jsonObj = _ModelToJSONObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }
    if ([model isKindOfClass:[NSArray class]]) {
        if ([NSJSONSerialization isValidJSONObject:model]) return model;
        NSMutableArray *newArray = [NSMutableArray new];
        for (id obj in (NSArray *)model) {
            if ([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]]) {
                [newArray addObject:obj];
            } else {
                id jsonObj = _ModelToJSONObjectRecursive(obj);
                if (jsonObj && jsonObj != (id)kCFNull) [newArray addObject:jsonObj];
            }
        }
        return newArray;
    }
    if ([model isKindOfClass:[NSURL class]]) return ((NSURL *)model).absoluteString;
    if ([model isKindOfClass:[NSAttributedString class]]) return ((NSAttributedString *)model).string;
    if ([model isKindOfClass:[NSDate class]]) return [_ttvideoengine_ISODateFormatter() stringFromDate:(id)model];
    if ([model isKindOfClass:[NSData class]]) return nil;
    if ([model isKindOfClass:[UIView class]]) return model;
    
    NSDictionary *propertiesInfo = [model _ttvideoengine_codableProperties];
    NSMutableDictionary *resultDict = [NSMutableDictionary dictionary];
    
    id object = nil;
    for (NSString *key in propertiesInfo) {
        object = [model valueForKey:key];
        if (object && [object _needTransformToJson]) {
            [resultDict setObject:_ModelToJSONObjectRecursive(object) ?: [NSNull null] forKey:key];
        } else {
            [resultDict setObject:(object) ?: [NSNull null] forKey:key];
        }
    }
    return resultDict;
}

- (BOOL)_needTransformToJson {
    if ([self isKindOfClass:[NSArray class]] ||
        [self isKindOfClass:[NSDictionary class]] ||
        [self isKindOfClass:[NSSet class]]) {
        return YES;
    }
    
    static NSArray *s_supportClass = nil;
    if (s_supportClass == nil) {
        s_supportClass = @[NSClassFromString(@"TTVideoEngineVideoInfo"),
                           NSClassFromString(@"TTVideoEngineThumbInfo"),
                           NSClassFromString(@"TTVideoEngineModel"),
                           NSClassFromString(@"TTVideoEngineInfoModel"),
                           NSClassFromString(@"TTVideoEngineURLInfoMap"),
                           NSClassFromString(@"TTVideoEngineURLInfo"),
                           NSClassFromString(@"TTVideoEnginePlayInfo"),
                           NSClassFromString(@"TTVideoEnginePlayItem"),
                           NSClassFromString(@"TTVideoEngineAdaptiveInfo"),
                           NSClassFromString(@"TTVideoEngineLiveURLInfo"),
                           NSClassFromString(@"TTVideoEngineLiveVideo"),
                           NSClassFromString(@"TTVideoEngineSeekTS"),
                           NSClassFromString(@"TTVideoEngineDynamicVideo")];
    }
    
    return [s_supportClass containsObject:[self class]];
}

- (NSString *)ttvideoengine_debugDescription {
    return [NSString stringWithFormat:@"%@",_ModelToJSONObjectRecursive(self)];
}

@end
