//
//  CFValidate.m
//  ASS_Editor
//
//  Created by sunrunwang on 2019/5/27.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

#ifdef DEBUG

#import "NSObject+HMDValidate.h"
#include <objc/runtime.h>
#import <Foundation/Foundation.h>

@implementation NSObject (CaptainAllred_Validate)

- (BOOL)hmd_performValidate:(CAValidateType)type saveResult:(NSMutableString * _Nullable)storage prefixBlank:(NSUInteger)prefixBlank increaseblank:(NSUInteger)increaseBlank {
    
    static Class stringClass;
    static Class arrayClass;
    static Class mutableArrayClass;
    static Class dictionaryClass;
    static Class mutableDictionaryClass;
    static Class numberClass;
    static Class KVO_DictionaryClass;
    static NSNull *null;
    static Class dataClass;
    static Class dateClass;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        stringClass = NSString.class;
        arrayClass = NSArray.class;
        mutableArrayClass = NSMutableArray.class;
        dictionaryClass = NSDictionary.class;
        mutableDictionaryClass = NSMutableDictionary.class;
        numberClass = NSNumber.class;
        KVO_DictionaryClass = objc_getClass("NSKeyValueChangeDictionary");
        null = [NSNull null];
        dataClass = NSData.class;
        dateClass = NSDate.class;
    });
    
    BOOL validate_immutable = type & CAValidateTypeImmutable;
    BOOL validate_immutableAllowNonStandard = type & CAValidateTypeImmutableAllowNonStandardClass;
    BOOL validate_JSON = type & CAValidateTypeJSON;
    BOOL validatePlist = type & CAValidateTypePlist;
    
    Class aClass = self.class;
    
    /* string */
    if([self isKindOfClass:stringClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++) {
                 [storage appendString:@" "];
            }
            [storage appendFormat:@"<%@> string\n", self];
        }
        return YES;
    }
    
    /* array */
    else if([self isKindOfClass:mutableArrayClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            if(validate_immutable)
                [storage appendFormat:@"mutableArray [ERROR] <%s %p>\n", class_getName(aClass), self];
            else
                [storage appendString:@"mutableArray\n"];
        }
        __block BOOL subValidate = YES;
        [(__kindof NSMutableArray *)self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(![obj hmd_performValidate:type saveResult:storage prefixBlank:prefixBlank + increaseBlank increaseblank:increaseBlank]) {
                subValidate = NO;
            }
        }];
        return !validate_immutable && subValidate;
    }
    else if([self isKindOfClass:arrayClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendFormat:@"array\n"];
        }
        __block BOOL subValidate = YES;
        [(__kindof NSArray *)self enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if(![obj hmd_performValidate:type saveResult:storage prefixBlank:prefixBlank + increaseBlank increaseblank:increaseBlank]) {
                subValidate = NO;
            }
        }];
        return subValidate;
    }
    
    /* dictionary */
    else if(KVO_DictionaryClass != nil && [self isKindOfClass:KVO_DictionaryClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendFormat:@"unsafeDictionary [ERROR] <%s %p>\n", class_getName(aClass), self];
        }
        [(__kindof NSDictionary *)self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if([key isKindOfClass:NSString.class]) {
                NSString *copied = [(__kindof NSString *)key copy];
                BOOL isMutable = !(key == copied);
                if(isMutable && validate_immutable) {
                    if(storage != nil) {
                        for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                            [storage appendString:@" "];
                        [storage appendFormat:@"<%@> mutableString [ERROR] <%s %p>\n", key, class_getName(((__kindof NSString *)key).class), key];
                    }
                }
                else if(storage != nil) {
                    for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                        [storage appendString:@" "];
                    if(isMutable)
                        [storage appendFormat:@"<%@> mutableString\n", key];
                    else
                        [storage appendFormat:@"<%@> string\n", key];
                }
            }
            else {
                if(storage != nil) {
                    for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                        [storage appendString:@" "];
                    [storage appendFormat:@"[ERROR] unknownKeyType <%s %p>\n", class_getName(((__kindof NSObject *)key).class), key];
                }
            }
            __unused BOOL result = [obj hmd_performValidate:type saveResult:storage prefixBlank:prefixBlank + increaseBlank increaseblank:increaseBlank];
        }];
        return NO;
    }
    else if([self isKindOfClass:mutableDictionaryClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            if(validate_immutable)
                [storage appendFormat:@"mutableDictionary [ERROR] <%s %p>\n", class_getName(aClass), self];
            else
                [storage appendString:@"mutableDictionary\n"];
        }
        __block BOOL subValidate = YES;
        [(__kindof NSMutableDictionary *)self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if([key isKindOfClass:NSString.class]) {
                NSString *copied = [(__kindof NSString *)key copy];
                BOOL isMutable = !(key == copied);
                if(isMutable && validate_immutable) {
                    if(storage != nil) {
                        for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                            [storage appendString:@" "];
                        [storage appendFormat:@"<%@> mutableString [ERROR] <%s %p>\n", key, class_getName(((__kindof NSString *)key).class), key];
                        subValidate = NO;
                    }
                }
                else if(storage != nil) {
                    for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                        [storage appendString:@" "];
                    if(isMutable)
                        [storage appendFormat:@"<%@> mutableString\n", key];
                    else
                        [storage appendFormat:@"<%@> string\n", key];
                }
            }
            else {
                if(storage != nil) {
                    for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                        [storage appendString:@" "];
                    [storage appendFormat:@"[ERROR] unknownKeyType <%s %p>\n", class_getName(((__kindof NSObject *)key).class), key];
                }
                subValidate = NO;
            }
            if(![(__kindof NSObject *)obj hmd_performValidate:type saveResult:storage prefixBlank:prefixBlank + increaseBlank * 2 increaseblank:increaseBlank]) {
                subValidate = NO;
            }
        }];
        return !validate_immutable && subValidate;
    }
    else if([self isKindOfClass:dictionaryClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendString:@"dictionary\n"];
        }
        __block BOOL subValidate = YES;
        [(__kindof NSDictionary *)self enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if([key isKindOfClass:NSString.class]) {
                NSString *copied = [(__kindof NSString *)key copy];
                BOOL isMutable = !(key == copied);
                if(isMutable && validate_immutable) {
                    if(storage != nil) {
                        for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                            [storage appendString:@" "];
                        [storage appendFormat:@"<%@> mutableString [ERROR] <%s %p>\n", key, class_getName(((__kindof NSString *)key).class), key];
                        subValidate = NO;
                    }
                }
                else if(storage != nil) {
                    for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                        [storage appendString:@" "];
                    if(isMutable)
                        [storage appendFormat:@"<%@> mutableString\n", key];
                    else
                        [storage appendFormat:@"<%@> string\n", key];
                }
            }
            else {
                if(storage != nil) {
                    for(NSUInteger index = 0; index < prefixBlank + increaseBlank; index++)
                        [storage appendString:@" "];
                    [storage appendFormat:@"[ERROR] unknownKeyType <%s %p>\n", class_getName(((__kindof NSObject *)key).class), key];
                }
                subValidate = NO;
            }
            if(![(__kindof NSObject *)obj hmd_performValidate:type saveResult:storage prefixBlank:prefixBlank + increaseBlank * 2 increaseblank:increaseBlank]) {
                subValidate = NO;
            }
        }];
        return subValidate;
    }
    
    /* number */
    else if([self isKindOfClass:numberClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendFormat:@"%@ number\n", self];
        }
        return YES;
    }
    
    /* null */
    else if(self == null) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendFormat:@"null\n"];
        }
        return !validatePlist;
    }
    
    /* data */
    else if ([self isKindOfClass:dataClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendFormat:@"%@ data\n", self];
        }
        return validatePlist;
    }
    
    /* date */
    else if ([self isKindOfClass:dateClass]) {
        if(storage != nil) {
            for(NSUInteger index = 0; index < prefixBlank; index++)
                [storage appendString:@" "];
            [storage appendFormat:@"%@ date\n", self];
        }
        return validatePlist;
    }
    
    /* other */
    else {
        if(validatePlist || validate_JSON || (validate_immutable & !validate_immutableAllowNonStandard)) {
            if(storage != nil) {
                for(NSUInteger index = 0; index < prefixBlank; index++)
                    [storage appendString:@" "];
                [storage appendFormat:@"[ERROR] unkownKeyType <%s %p>\n", class_getName(((__kindof NSMutableString *)self).class), self];
            }
            return NO;
        }
        else {
            if(storage != nil) {
                for(NSUInteger index = 0; index < prefixBlank; index++)
                    [storage appendString:@" "];
                [storage appendString:@"unkownKeyType\n"];
            }
            return YES;
        }
    }
}

@end

#endif
