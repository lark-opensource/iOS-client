//
//  ACCSerialization.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/12/17.
//

#import "ACCSerialization.h"
#import <CreationKitInfra/ACCRACWrapper.h>

#import <Mantle/Mantle.h>
#import <Mantle/EXTRuntimeExtensions.h>
#import <objc/runtime.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCMacros.h>

static void *ACCSCachedPropertyKeysKey = &ACCSCachedPropertyKeysKey;


@interface NSObject (ACCSerializationPrivate)

// Enumerates all properties of the receiver's class hierarchy, starting at the
// receiver, and continuing up until (but not including) MTLModel.
//
// The given block will be invoked multiple times for any properties declared on
// multiple classes in the hierarchy.
+ (void)accs_enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block;

+ (NSSet<NSString *> *)accs_propertyKeys;

+ (Class)accs_classForKeyPath:(NSString *)propertyKeyPath;

- (BOOL)accs_checkExistKeyPath:(NSString *)propertyKeyPath;

@end

// Validates a value for an object and sets it if necessary.
//
// obj         - The object for which the value is being validated. This value
//               must not be nil.
// key         - The name of one of `obj`s properties. This value must not be
//               nil.
// value       - The new value for the property identified by `key`.
// forceUpdate - If set to `YES`, the value is being updated even if validating
//               it did not change it.
// error       - If not NULL, this may be set to any error that occurs during
//               validation
//
// Returns YES if `value` could be validated and set, or NO if an error
// occurred.
static BOOL ACCSValidateAndSetValue(id obj, NSString *keyPath, id value, BOOL forceUpdate, NSError **error) {
    // Mark this as being autoreleased, because validateValue may return
    // a new object to be stored in this variable (and we don't want ARC to
    // double-free or leak the old or new values).
    __autoreleasing id validatedValue = value;

    @try {
        if (![obj validateValue:&validatedValue forKeyPath:keyPath error:error]) return NO;

        if (forceUpdate || value != validatedValue) {
            [obj setValue:validatedValue forKeyPath:keyPath];
        }

        return YES;
    } @catch (NSException *ex) {

        return NO;
    }
}

@implementation NSObject (ACCSerializationPrivate)

#pragma mark Reflection

+ (void)accs_enumeratePropertiesUsingBlock:(void (^)(objc_property_t property, BOOL *stop))block {
    Class cls = self;
    BOOL stop = NO;

    while (!stop && ![cls isEqual:NSObject.class]) {
        unsigned count = 0;
        objc_property_t *properties = class_copyPropertyList(cls, &count);

        cls = cls.superclass;
        if (properties == NULL) continue;

        @onExit {
            free(properties);
        };

        for (unsigned i = 0; i < count; i++) {
            block(properties[i], &stop);
            if (stop) break;
        }
    }
}

+ (NSSet<NSString *> *)accs_propertyKeys {
    NSSet *cachedKeys = objc_getAssociatedObject(self, ACCSCachedPropertyKeysKey);
    if (cachedKeys != nil) return cachedKeys;

    NSMutableSet *keys = [NSMutableSet set];

    [self accs_enumeratePropertiesUsingBlock:^(objc_property_t property, BOOL *stop) {
        NSString *key = @(property_getName(property));

        if ([self accs_storageBehaviorForPropertyWithKey:key] != MTLPropertyStorageNone) {
             [keys addObject:key];
        }
    }];

    // It doesn't really matter if we replace another thread's work, since we do
    // it atomically and the result should be the same.
    objc_setAssociatedObject(self, ACCSCachedPropertyKeysKey, keys, OBJC_ASSOCIATION_COPY);

    return keys;
}

+ (MTLPropertyStorage)accs_storageBehaviorForPropertyWithKey:(NSString *)propertyKey {
    objc_property_t property = class_getProperty(self.class, propertyKey.UTF8String);

    if (property == NULL) return MTLPropertyStorageNone;

    mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
    @onExit {
        free(attributes);
    };
    
    BOOL hasGetter = [self instancesRespondToSelector:attributes->getter];
    BOOL hasSetter = [self instancesRespondToSelector:attributes->setter];
    if (!attributes->dynamic && attributes->ivar == NULL && !hasGetter && !hasSetter) {
        return MTLPropertyStorageNone;
    } else if (attributes->readonly && attributes->ivar == NULL) {
        return MTLPropertyStorageNone;
    } else {
        return MTLPropertyStoragePermanent;
    }
}

+ (Class)accs_classForKeyPath:(NSString *)propertyKeyPath
{
    NSArray *pathArray = [propertyKeyPath componentsSeparatedByString:@"."];
    
    id result = self;
    for (NSString *propertyKey in pathArray) {
        objc_property_t property = class_getProperty(result, propertyKey.UTF8String);

        if (property == NULL) return Nil;

        mtl_propertyAttributes *attributes = mtl_copyPropertyAttributes(property);
        @onExit {
            free(attributes);
        };
        
        if (*(attributes->type) == *(@encode(id))) {
            Class propertyClass = attributes->objectClass;
            result = propertyClass;
        } else {
            result = Nil;
            break;
        }
    }
    
    return result;
}

- (BOOL)accs_checkExistKeyPath:(NSString *)propertyKeyPath
{
    BOOL checkFlag = YES;
    Class theClass = self.class;
    id theObj = self;
    NSArray *paths = [propertyKeyPath componentsSeparatedByString:@"."];
    for (NSString *key in paths) {
        if ([[theClass accs_propertyKeys] containsObject:key] == NO) {
            checkFlag = NO;
            break;
        }
        
        theObj = [theObj valueForKey:key];
        if (theObj) {
            theClass = [theObj class];
        } else {
            theClass = [theClass accs_classForKeyPath:key];
        }
    }
    
    return checkFlag;
}

@end

@interface ACCSerialization ()

@end

@implementation ACCSerialization

+ (__kindof NSObject<ACCSerializationProtocol> *)transformOriginalObj:(NSObject *)originObj to:(Class)toClass
{
    if (originObj == nil ||
        ![toClass conformsToProtocol:@protocol(ACCSerializationProtocol)]) {
        return nil;
    }
    
    NSObject<ACCSerializationProtocol> *target = nil;
    if ([toClass respondsToSelector:@selector(accs_customSaveByOriginObj:)]) {
        target = [toClass accs_customSaveByOriginObj:originObj];
    }
    
    if (target == nil) {
        target = [[toClass alloc] init];
    }
    
    if ([target respondsToSelector:@selector(accs_customCheckAcceptClass:isTransform:)]) {
        if ([target accs_customCheckAcceptClass:originObj.class isTransform:YES] == NO) {
            return nil;
        }
    }
    
    if ([toClass respondsToSelector:@selector(accs_acceptClasses:)]) {
        NSSet<Class> *checkSet = [toClass accs_acceptClasses:YES];
        if (checkSet && ![checkSet containsObject:originObj.class]) {
            return nil;
        }
    }
    
    NSDictionary *relationKeys = nil;
    if ([toClass respondsToSelector:@selector(accs_covertRelations:)]) {
        relationKeys = [toClass accs_covertRelations:originObj.class];
        if ([relationKeys.allValues.firstObject isKindOfClass:NSDictionary.class]) {
            relationKeys = ACCDynamicCast(relationKeys[NSStringFromClass(originObj.class)], NSDictionary);
        }
    }
    
    NSError __block *error;
    void (^processBlock)(NSString *, BOOL *) = ^(NSString *key, BOOL *stop) {
        NSString *transitionKey = ACCDynamicCast(relationKeys[key], NSString);
        if (transitionKey == nil) {
            transitionKey = key;
        }
        
        if ([originObj accs_checkExistKeyPath:transitionKey]) {
            id originValue = [originObj valueForKeyPath:transitionKey];
            id theValue = originValue;
            Class targetClass = [toClass accs_classForKeyPath:key];
            if ([targetClass conformsToProtocol:@protocol(ACCSerializationProtocol)] &&
                ![targetClass isEqual:[originValue class]]) {
                theValue = [ACCSerialization transformOriginalObj:originValue to:targetClass];
            }
            
            
            ACCSValidateAndSetValue(target, key, theValue, YES, &error);
            if (error) {
                *stop = YES;
                AWELogToolError(AWELogToolTagEdit, @"%s--error:%@", __func__, error);
            }
        }
    };
    
    BOOL checkFlag = NO;
    if ([toClass respondsToSelector:@selector(accs_includeKeys:)]) {
        id checkType = [toClass accs_includeKeys:YES];
        NSArray<NSString *> *includeKeys = nil;
        
        if ([checkType isKindOfClass:NSArray.class]) {
            includeKeys = checkType;
        } else if ([checkType isKindOfClass:NSDictionary.class]) {
            includeKeys = [checkType valueForKey:NSStringFromClass(originObj.class)];
        }
        
        if (includeKeys.count > 0) {
            checkFlag = YES;
            [includeKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                processBlock(key, stop);
            }];
        }
        
    }
    
    if (checkFlag == NO &&
        [toClass respondsToSelector:@selector(accs_excludeKeys:)]) {
        id checkType = [toClass accs_excludeKeys:YES];
        NSArray<NSString *> *excludeKeys = nil;
        
        if ([checkType isKindOfClass:NSArray.class]) {
            excludeKeys = checkType;
        } else if ([checkType isKindOfClass:NSDictionary.class]) {
            excludeKeys = [checkType valueForKey:NSStringFromClass(originObj.class)];
        }
        
        if (excludeKeys.count > 0) {
            checkFlag = YES;
            NSSet<NSString *> *excludeSet = [[NSSet alloc] initWithArray:excludeKeys];
            [[toClass accs_propertyKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull key, BOOL * _Nonnull stop) {
                if (![excludeSet containsObject:key]) {
                    processBlock(key, stop);
                }
            }];
        }
    }
    
    if (checkFlag == NO) {
        [[toClass accs_propertyKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull key, BOOL * _Nonnull stop) {
            processBlock(key, stop);
        }];
    }
    
    if (error) {
        AWELogToolError(AWELogToolTagEdit, @"%s--error:%@",__func__, error);
    } else if ([target respondsToSelector:@selector(accs_extraFinishTransform:)]) {
        [target accs_extraFinishTransform:originObj];
    }
    
    return target;
}

+ (__kindof NSObject *)restoreFromObj:(NSObject<ACCSerializationProtocol> *)fromObj to:(Class)originClass
{
    if (originClass == Nil ||
        ![fromObj conformsToProtocol:@protocol(ACCSerializationProtocol)]) {
        return nil;
    }
    
    if ([fromObj respondsToSelector:@selector(accs_customCheckAcceptClass:isTransform:)]) {
        if ([fromObj accs_customCheckAcceptClass:originClass isTransform:NO] == NO) {
            return nil;
        }
    }
    
    if ([fromObj.class respondsToSelector:@selector(accs_acceptClasses:)]) {
        NSSet<Class> *checkSet = [fromObj.class accs_acceptClasses:NO];
        if (checkSet && ![checkSet containsObject:originClass]) {
            return nil;
        }
    }
    
    NSObject *originObj = nil;
    if ([fromObj respondsToSelector:@selector(accs_customRestoreOriginObj:)]) {
        originObj = [fromObj accs_customRestoreOriginObj:originClass];
    }
    
    if (originObj == nil) {
        originObj = [[originClass alloc] init];
    }
    
    NSDictionary *relationKeys = nil;
    if ([fromObj.class respondsToSelector:@selector(accs_covertRelations:)]) {
        relationKeys = [fromObj.class accs_covertRelations:originClass];
        if ([relationKeys.allValues.firstObject isKindOfClass:NSDictionary.class]) {
            relationKeys = ACCDynamicCast(relationKeys[NSStringFromClass(originClass)], NSDictionary);
        }
    }
    
    NSError __block *error;
    void (^processBlock)(NSString *, BOOL *) = ^(NSString *key, BOOL *stop) {
        NSString *transitionKey = ACCDynamicCast(relationKeys[key], NSString);
        if (transitionKey == nil) {
            transitionKey = key;
        }
        
        if ([originObj accs_checkExistKeyPath:transitionKey]) {
            id targetValue = [fromObj valueForKeyPath:key];
            id theValue = targetValue;
            Class originValueClass = [originClass accs_classForKeyPath:transitionKey];
            Class targetValueClass = [targetValue class];
            if ([targetValueClass conformsToProtocol:@protocol(ACCSerializationProtocol)] &&
                ![targetValueClass isEqual:originValueClass]) {
                theValue = [ACCSerialization restoreFromObj:theValue to:originValueClass];
            }
            
            ACCSValidateAndSetValue(originObj, transitionKey, theValue, YES, &error);
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"%s--error:%@", __func__, error);
                *stop = YES;
            }
        }
    };
    
    BOOL checkFlag = NO;
    if ([fromObj.class respondsToSelector:@selector(accs_includeKeys:)]) {
        id checkType = [fromObj.class accs_includeKeys:NO];
        NSArray<NSString *> *includeKeys = nil;
        
        if ([checkType isKindOfClass:NSArray.class]) {
            includeKeys = checkType;
        } else if ([checkType isKindOfClass:NSDictionary.class]) {
            includeKeys = [checkType valueForKey:NSStringFromClass(originObj.class)];
        }
        
        if (includeKeys.count > 0) {
            checkFlag = YES;
            [includeKeys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
                processBlock(key, stop);
            }];
        }
    }
    
    if ([fromObj.class respondsToSelector:@selector(accs_excludeKeys:)]) {
        id checkType = [fromObj.class accs_excludeKeys:NO];
        NSArray<NSString *> *excludeKeys = nil;
        
        if ([checkType isKindOfClass:NSArray.class]) {
            excludeKeys = checkType;
        } else if ([checkType isKindOfClass:NSDictionary.class]) {
            excludeKeys = [checkType valueForKey:NSStringFromClass(originObj.class)];
        }
        
        if (excludeKeys.count > 0) {
            checkFlag = YES;
            NSSet<NSString *> *excludeSet = [[NSSet alloc] initWithArray:excludeKeys];
            [[fromObj.class accs_propertyKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull key, BOOL * _Nonnull stop) {
                if (![excludeSet containsObject:key]) {
                    processBlock(key, stop);
                }
            }];
        }
    }
    
    if (checkFlag == NO) {
        [[fromObj.class accs_propertyKeys] enumerateObjectsUsingBlock:^(NSString * _Nonnull key, BOOL * _Nonnull stop) {
            processBlock(key, stop);
        }];
    }
    
    if (error) {
        AWELogToolError(AWELogToolTagEdit, @"%s--error:%@", __func__, error);
    } else if ([fromObj respondsToSelector:@selector(accs_extraFinishRestore:)]) {
        [fromObj accs_extraFinishRestore:originObj];
    }
    
    return originObj;
}

+ (NSArray<__kindof NSObject<ACCSerializationProtocol> *> *)transformOriginalObjArray:(NSArray *)originObjArray to:(Class)toClass
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [originObjArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id newObj = [ACCSerialization transformOriginalObj:obj to:toClass];
        if (newObj) {
            [result addObject:newObj];
        }
    }];
    
    return result;
}

+ (NSArray *)restoreFromObjArray:(NSArray<NSObject<ACCSerializationProtocol> *> *)fromObjArray to:(Class)originClass
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    [fromObjArray enumerateObjectsUsingBlock:^(NSObject<ACCSerializationProtocol> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id newObj = [ACCSerialization restoreFromObj:obj to:originClass];
        if (newObj) {
            [result addObject:newObj];
        }
    }];
    
    return result;
}

@end
