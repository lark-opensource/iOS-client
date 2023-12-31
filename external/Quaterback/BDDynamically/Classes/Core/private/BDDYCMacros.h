//
//  BDDYCMacros.h
//  BDDynamically
//
//  Created by zuopengliu on 21/5/2018.
//

#ifndef BDDYCMacros_h
#define BDDYCMacros_h



/**
 * Make global functions usable in C++
 */
#if defined(__cplusplus)
#   define BDDYC_EXTERN extern "C" __attribute__((visibility("default")))
#   define BDDYC_EXTERN_C_BEGIN extern "C" {
#   define BDDYC_EXTERN_C_END }
#else
#   define BDDYC_EXTERN extern __attribute__((visibility("default")))
#   define BDDYC_EXTERN_C_BEGIN
#   define BDDYC_EXTERN_C_END
#endif



#pragma mark - Description

/**
 * Debug Description
 */
#if defined(DEBUG)

#import <objc/runtime.h>

#   define BDDYC_DEBUG_DESCRIPTION   \
- (NSString *)debugDescription  \
{   \
NSMutableDictionary *dictionary = [NSMutableDictionary dictionary]; \
NSArray *exceptNames = @[@"description"];   \
Class cls = [self class];   \
while (cls != [NSObject class]) {   \
uint count; \
objc_property_t *properties = class_copyPropertyList(cls, &count);  \
for (int i = 0; i < count; i++) {   \
objc_property_t property = properties[i];   \
NSString *name = @(property_getName(property)); \
if (name && [exceptNames containsObject:name]) continue;    \
id value = [self valueForKey:name] ? : @"nil";  \
[dictionary setObject:value forKey:name];   \
}   \
if (properties) free(properties);   \
cls = [cls superclass]; \
}   \
return [NSString stringWithFormat:@"<%@: %p> = \n%@", NSStringFromClass(self.class), self, dictionary]; \
}   \
\
- (NSString *)description   \
{   \
return [self debugDescription]; \
}   \

#else

#   define BDDYC_DEBUG_DESCRIPTION

#endif



#ifdef DEBUG
#   define BDDYCAssert      assert
#   define BDDYCCAssert     assert
#   define BDDYCNSAssert    NSAssert
#else
#   define BDDYCAssert
#   define BDDYCCAssert
#   define BDDYCNSAssert
#endif



#endif /* BDDYCMacros_h */
