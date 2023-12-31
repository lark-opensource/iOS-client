//
//  NSObject+Utilities.m
//  HDPro
//
//  Created by Stephen Liu on 12-10-18.
//  Copyright (c) 2012年 Stephen Liu. All rights reserved.
//

#import "NSObject+HMDUtilities.h"
#import <objc/runtime.h>
#import "NSDictionary+HMDSafe.h"

@interface GHNSObjectProperty ()

- (instancetype _Nullable)initWithProperty:(objc_property_t _Nonnull)property class:(Class _Nonnull)cls;

@end

@implementation GHNSObjectProperty

- (instancetype)initWithProperty:(objc_property_t)property class:(Class)cls {
    // Check property name
    const char *name = property_getName(property);
    if (!name) {
        return nil;
    }
    NSString *propertyName = [NSString stringWithUTF8String:name];
    
    // Check property attributes
    const char *attributes = property_getAttributes(property);
    if (!attributes) {
        return nil;
    }
    // Ignore readonly property
    NSString *propertyAttributes = [NSString stringWithUTF8String:attributes];
    NSArray<NSString *> *attributeItems = [propertyAttributes componentsSeparatedByString:@","];
    if ([attributeItems containsObject:@"R"]) {
        return nil;
    }
    
    if (self = [super init]) {
        _name = propertyName;
        unsigned int outCount;
        objc_property_attribute_t *attributeList = property_copyAttributeList(property, &outCount);
        if (attributeList) {
            for (unsigned int i = 0; i < outCount; i++) {
                objc_property_attribute_t attribute = attributeList[i];
                
                // https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtPropertyIntrospection.html
                // Table 7-1 Declared property type encodings
                switch (attribute.name[0]) {
                    case 'T':
                        if (attribute.value) {
                            [self _setupType:attribute.value];
                        }
                        break;
                    case 'G':
                        if (attribute.value) {
                            _getter = sel_getUid(attribute.value);
                        }
                        break;
                    case 'S':
                        if (attribute.value) {
                            _setter = sel_getUid(attribute.value);
                        }
                        break;
                    case 'D':
                        _dynamic = YES;
                        break;
                    default:
                        break;
                }
            }
            
            free(attributeList);
            attributes = NULL;
        }
        if (!_getter) {
            _getter = sel_getUid(name);
        }
        if (!_setter) {
            // Manual splicing setter
            NSString *setterName = [NSString stringWithFormat:@"set%@%@:", [_name substringToIndex:1].uppercaseString, [_name substringFromIndex:1]];
            _setter = NSSelectorFromString(setterName);
        }
        if (_getter) {
            _getterImpl = class_getMethodImplementation(cls, _getter);
        }
        if (_setter) {
            _setterImpl = class_getMethodImplementation(cls, _setter);
        }
    }
    return self;
}

- (void)_setupType:(const char *)typeEncoding {
    // Set default value
    _type = NSPropertyTypeUnknown;
    
    // Check available
    char *type = (char *)typeEncoding;
    if (!type) {
        return;
    }
    size_t length = strlen(type);
    if (length <= 0) {
        return;
    }
    
    // Remove prefix
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r': /* _C_CONST */
            case 'n': /* _C_IN */
            case 'N': /* _C_INOUT */
            case 'o': /* _C_OUT */
            case 'O': /* _C_BYCOPY */
            case 'R': /* _C_BYREF */
            case 'V': /* _C_ONEWAY */
                type++;
                break;
            default:
                prefix = false;
                break;
        }
    }
    
    length = strlen(type);
    if (length <= 0) {
        return;
    }
    
    switch (*type) {
        case _C_UCHR:
        case _C_CHR:
        case _C_BOOL:
        case _C_BFLD:
            self.type = NSPropertyTypeBOOL;
            break;
        case _C_INT:
        case _C_UINT:
            self.type = NSPropertyTypeInteger;
            break;
        case _C_LNG:
        case _C_ULNG:
            self.type = NSPropertyTypeLong;
            break;
        case _C_LNG_LNG:
        case _C_ULNG_LNG:
            self.type = NSPropertyTypeLongLong;
            break;
        case _C_FLT:
            self.type = NSPropertyTypeFloat;
            break;
        case _C_DBL:
            self.type = NSPropertyTypeDouble;
            break;
        case '@':
        {
            // Example: @"NSString"
            if (*(type + 1) == '"' && length > 3) {
                char className[length - 2];
                className[length - 3] = '\0';
                memcpy(className, type + 2, length - 3);
                self.cls = objc_getClass(className);
                self.type = NSPropertyTypeClass;
            }
            break;
        }
        default:
            break;
    }
}

@end

@implementation NSObject (HMDPropertyAccess)

+ (NSDictionary<NSString *,GHNSObjectProperty *> *)hmd_properties {
    // Initialize cache
    static dispatch_once_t onceToken;
    static NSMutableDictionary<NSString *, NSDictionary<NSString *, GHNSObjectProperty *> *> *cache;
    dispatch_once(&onceToken, ^{
        cache = [NSMutableDictionary dictionary];
    });
    
    // Get cache properties
    NSString *clsName = NSStringFromClass(self);
    NSDictionary<NSString *, GHNSObjectProperty *> *cachedProperties = nil;
    @synchronized (cache) {
        cachedProperties = [cache hmd_objectForKey:clsName class:NSDictionary.class];
    }
    if (cachedProperties) {
        return cachedProperties;
    }
    
    // Copy property list
    unsigned int outCount;
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    if (outCount <= 0) {
        free(properties);
        return nil;
    }
    
    // Generate GHNSObjectProperty by property attributes
    NSMutableDictionary *ps = [NSMutableDictionary dictionary];
    for (unsigned int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        
        GHNSObjectProperty *ghProperty = [[GHNSObjectProperty alloc] initWithProperty:property class:self];
        if (ghProperty == nil) {
            continue;
        }
        [ps setObject:ghProperty forKey:ghProperty.name];
    }
    free(properties);
    
    // Save properties for reuse
    cachedProperties = [ps copy];
    @synchronized (cache) {
        [cache hmd_setObject:cachedProperties forKey:clsName];
    }
    
    return cachedProperties;
}

@end
