//
//  NSObject+LKUtilities.m
//  LarkMonitor
//
//  Created by sniperj on 2020/11/8.
//

#import "NSObject+LKUtilities.h"
#import <objc/runtime.h>
#import "NSDictionary+safe.h"

@implementation LKObjectProperty
- (instancetype)initWithProperty:(objc_property_t)property class:(Class)class
{
    self = [super init];
    if (self) {
        const char *name = property_getName(property);
        if (!name) {
            return nil;
        }
        self.propertyName = [NSString stringWithUTF8String:name];
        unsigned int attrCount;
        objc_property_attribute_t *attrs = property_copyAttributeList(property, &attrCount);
        for (unsigned int i = 0; attrs != NULL && i < attrCount; i++) {
            objc_property_attribute_t attribute =  attrs[i];
            switch (attribute.name[0]) {
                case 'T': { // Type encoding
                    if (attribute.value) {
                        [self setupType:attribute.value];
                    }
                }   break;
                case 'G': {
                    if (attribute.value) {
                        self.getter = sel_getUid(attribute.value);
                    }
                }   break;
                case 'S': {
                    if (attribute.value) {
                        self.setter = sel_getUid(attribute.value);
                    }
                }   break;
                case 'D':{
                    self.dynamic = YES;
                }   break;
                default: break;
            }
        }
        if (attrs) {
            free(attrs);
            attrs = NULL;
        }
        
        if (!_getter) {
            _getter = sel_getUid(name);
        }
        if (!_setter) {
            _setter = NSSelectorFromString([NSString stringWithFormat:@"set%@%@:",[self.propertyName substringToIndex:1].uppercaseString,[self.propertyName substringFromIndex:1]]);
        }
        
        if (_getter) {
            _getterImp = class_getMethodImplementation(class, _getter);
        }
        if (_setter) {
            _setterImp = class_getMethodImplementation(class, _setter);
        }
    }
    return self;
}

- (void)setupType:(const char *)typeEncoding
{
    char *type = (char *)typeEncoding;
    if (!type) {
        self.type = NSPropertyTypeUnKnow;
        return;
    }
    size_t len = strlen(type);
    if (len == 0){
        self.type = NSPropertyTypeUnKnow;
        return;
    }
    
    bool prefix = true;
    while (prefix) {
        switch (*type) {
            case 'r':
            case 'n':
            case 'N':
            case 'o':
            case 'O':
            case 'R':
            case 'V':{
                type++;
            } break;
            default:{
                prefix = false;
            }
        }
    }
    
    len = strlen(type);
    if (len == 0) {
        self.type = NSPropertyTypeUnKnow;
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
            
        case '@': {
            if (*(type + 1) == '"')
            {
                if (len > 3) {
                    char className[len - 2];
                    className[len - 3] = '\0';
                    memcpy(className, type + 2, len - 3);
                    self.clazz = objc_getClass(className);
                    self.type = NSPropertyTypeClass;
                    break;
                }
            }
        }
        default: self.type = NSPropertyTypeUnKnow;
    }
}
@end

@implementation NSObject (LKUtilities)

static NSMutableDictionary *cache = nil;

+ (NSDictionary *)lk_properties
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache = [[NSMutableDictionary alloc] init];
    });
    NSString *className = NSStringFromClass(self);
    NSDictionary *cachedProperties = nil;
    @synchronized(cache) {
        cachedProperties = [cache objectForKey:className];
    }
    if (cachedProperties) {
        return cachedProperties;
    }
    unsigned int outCount, i;
    objc_property_t *properties = class_copyPropertyList(self, &outCount);
    if (outCount <= 0)
    {
        free(properties);
        return nil;
    }
    NSMutableDictionary *ps = [NSMutableDictionary dictionary];
    for(i = 0; i < outCount; i++)
    {
        objc_property_t property = properties[i];
        
        //get property attributes
        const char *attrs = property_getAttributes(property);
        NSString* propertyAttributes = [NSString stringWithUTF8String:attrs];
        NSArray* attributeItems = [propertyAttributes componentsSeparatedByString:@","];
        
        //ignore read-only properties
        if ([attributeItems containsObject:@"R"]) {
            continue; //to next property
        }
        
        const char *propName = property_getName(property);
        if(propName)
        {
            NSString *propertyName = [NSString stringWithCString:propName encoding:NSASCIIStringEncoding];
            LKObjectProperty *propertyType = [self ghPropertyWithProperty:property];
            if (propertyType) {
                [ps setObject:propertyType forKey:propertyName];
            }
        }
    }
    free(properties);
    NSDictionary *dictionary = [NSDictionary dictionaryWithDictionary:ps];
    @synchronized(cache) {
        [cache lk_setObject:dictionary forKey:className];
    }
    return dictionary;
}

+ (LKObjectProperty *)ghPropertyWithProperty:(objc_property_t)property
{
    return [[LKObjectProperty alloc] initWithProperty:property class:self];
}

@end
