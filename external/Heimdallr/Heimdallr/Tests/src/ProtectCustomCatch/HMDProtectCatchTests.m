//
//  HMDProtectCatchTests.m
//  HMDProtectCatchTests
//
//  Created by bytedance on 2020/8/4.
//  Copyright © 2020 bytedance. All rights reserved.
//

#include <objc/objc.h>
#include <objc/runtime.h>
#include <objc/message.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDDynamicCall.h"
#import "HMDProtectCatch.h"

// fix-up for missing symbol long double
#ifndef _C_LNG_DBL
#define _C_LNG_DBL 'D'
#endif

static uint8_t objc_type_coding[] = {
    _C_ID, _C_CLASS, _C_SEL, _C_CHR, _C_UCHR, _C_SHT, _C_USHT, _C_INT, _C_UINT, _C_LNG, _C_ULNG, _C_LNG_LNG, _C_ULNG_LNG, _C_INT128, _C_UINT128, _C_FLT, _C_DBL, _C_LNG_DBL, _C_BFLD, _C_BOOL, _C_VOID, _C_UNDEF, _C_PTR, _C_CHARPTR, _C_ATOM, _C_ARY_B, _C_ARY_E, _C_UNION_B, _C_UNION_E, _C_STRUCT_B, _C_STRUCT_E, _C_VECTOR
};

static uint8_t objc_modifier_coding[] = {
    _C_COMPLEX, _C_ATOMIC, _C_CONST, _C_IN, _C_INOUT, _C_OUT, _C_BYCOPY, _C_BYREF, _C_ONEWAY, _C_GNUREGISTER
};

static uint8_t objc_name_scope_coding[] = {
    '"'
};

static bool is_objc_type_coding(uint8_t code) {
    size_t count = sizeof(objc_type_coding)/sizeof(objc_type_coding[0]);
    for(size_t index = 0; index < count; index++)
        if(objc_type_coding[index] == code)
            return true;
    return false;
}

static bool is_objc_modifier_coding(uint8_t code) {
    size_t count = sizeof(objc_modifier_coding)/sizeof(objc_modifier_coding[0]);
    for(size_t index = 0; index < count; index++)
        if(objc_modifier_coding[index] == code)
            return true;
    return false;
}

static bool is_objc_name_scope_coding(uint8_t code) {
    size_t count = sizeof(objc_name_scope_coding)/sizeof(objc_name_scope_coding[0]);
    for(size_t index = 0; index < count; index++)
        if(objc_name_scope_coding[index] == code)
            return true;
    return false;
}

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl);
static const char * _Nonnull skipTypeModifierEncoding(const char *_Nonnull encoding);

@interface HMDProtectCatch (Test)
- (id)blockWithSignature:(const char *)signature key:(NSString *)key;
@end

@interface HMDProtectCatchTests : XCTestCase

@end

@implementation HMDProtectCatchTests

+ (void)setUp    { /* 在所有测试前调用一次 */ }
+ (void)tearDown { /* 在所有测试后调用一次 */ }
- (void)setUp    { /* 在每次 -[ test_xxx] 方法前调用 */ }
- (void)tearDown { /* 在每次 -[ test_xxx] 方法后调用 */ }

- (void)tools_used_when_test {
    // Expectation
    XCTestExpectation *expectation = [self expectationWithDescription:@"description"];
    [expectation fulfill];
    [self waitForExpectationsWithTimeout:3 handler:nil];
    
    // Assert
    XCTAssert(nil, @"NSLog format:%@", nil);
}

- (void)test_typeEncodingWithModifier_method {
    Class aClass = objc_getClass("NSFileManager");
    SEL aSEL = @selector(fileSystemRepresentationWithPath:);
    Method method = class_getInstanceMethod(aClass, aSEL);
    const char *typeEncoding = method_getTypeEncoding(method);
    XCTAssert(typeEncoding != nil);
    id _Nullable block = [HMDProtectCatch.sharedInstance blockWithSignature:typeEncoding key:@"我爱你中国"];
    XCTAssert(block != nil);
}

- (void)test_HMDDCSkipMethodEncodings {
    unsigned int classCount;
    Class _Nonnull * _Nullable classList = objc_copyClassList(&classCount);
    if(classList == NULL) return;
    
    for(unsigned int classIndex = 0; classIndex < classCount; classIndex++) {
        Class aClass = classList[classIndex];
        
        [self HMDDCSkipMethodEncodings_forClass:aClass];
        
        if(!class_isMetaClass(aClass))
            [self HMDDCSkipMethodEncodings_forClass:object_getClass(aClass)];
    }
    
    free(classList);
}

- (void)HMDDCSkipMethodEncodings_forClass:(Class)aClass {
    unsigned int methodCount;
    Method _Nonnull * _Nullable methodList = class_copyMethodList(aClass, &methodCount);
    if(methodList == NULL) return;
    
    for(unsigned int methodIndex = 0; methodIndex < methodCount; methodIndex++) {
        const char * _Nullable typeEncoding = method_getTypeEncoding(methodList[methodIndex]);
        if(typeEncoding == NULL) continue;
        if(typeEncoding[0] == '\0') continue;
        
        const char *className = class_getName(aClass);
        bool is_metaClass = class_isMetaClass(aClass);
        SEL method_SEL = method_getName(methodList[methodIndex]);
        const char *method_SEL_name = sel_getName(method_SEL);
        
        const char *firstTypeCoding = HMDDCSkipMethodEncodings(typeEncoding);
        const char *sameTypeCoding = skipTypeModifierEncoding(typeEncoding);
        
        XCTAssert(firstTypeCoding == sameTypeCoding);
        
        {
            NSMethodSignature *signature = nil;
            @try {
                NSMethodSignature *temp_signature = [NSMethodSignature signatureWithObjCTypes:typeEncoding];
                if(temp_signature != nil) signature = temp_signature;
            } @catch (NSException *exception) {
                DEBUG_LOG("[TEST][FAILED] method:%s[%s %s] typeEncoding:%s", class_isMetaClass(aClass)?"+":"-", class_getName(aClass), sel_getName(method_getName(methodList[methodIndex])), typeEncoding);
                signature = nil;
            }
            
            if(signature != nil) {
                const char *returnType = signature.methodReturnType;
                if(returnType != NULL) {
                    const char *s1 = HMDDCSkipMethodEncodings(returnType);
                    const char *s2 = skipTypeModifierEncoding(returnType);
                    XCTAssert(s1 == s2);
                    
                    XCTAssert(s1[0] != '\0', @"returnType %s", returnType);
                    
                    XCTAssert(!is_objc_modifier_coding(s1[0]), @"returnType %s", returnType);
                    XCTAssert(!is_objc_name_scope_coding(s1[0]), @"returnType %s", returnType);
                }
                
                NSUInteger argumentsCount = signature.numberOfArguments;
                for(NSUInteger index = 0; index < argumentsCount; index++) {
                    const char *argumentType = [signature getArgumentTypeAtIndex:index];
                    if(argumentType == NULL) continue;
                    
                    const char *s1 = HMDDCSkipMethodEncodings(argumentType);
                    const char *s2 = skipTypeModifierEncoding(argumentType);
                    XCTAssert(s1 == s2);
                    
                    XCTAssert(s1[0] != '\0', @"argumentType %s", argumentType);
                    
                    XCTAssert(!is_objc_modifier_coding(s1[0]), @"argumentType %s", argumentType);
                    XCTAssert(!is_objc_name_scope_coding(s1[0]), @"argumentType %s", argumentType);
                }
            }
        }
        
        XCTAssert(firstTypeCoding[0] != '\0', @"%s[%s %s] typeEncoding %s", is_metaClass?"+":"-", className, method_SEL_name, typeEncoding);
        
        XCTAssert(!is_objc_modifier_coding(firstTypeCoding[0]), @"typeEncoding %s", typeEncoding);
        XCTAssert(!is_objc_name_scope_coding(firstTypeCoding[0]), @"typeEncoding %s", typeEncoding);
        if(!is_objc_type_coding(firstTypeCoding[0])) {
            
            if(typeEncoding != firstTypeCoding || !isnumber(firstTypeCoding[0])) {
                XCTAssert(NO, @"typeEncoding %s", typeEncoding);
            }
        }
    }
    
    free(methodList);
}

@end

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl) {
    static const char *qualifiersAndComments = "nNoOrRV\"";
    while (*decl != '\0' && strchr(qualifiersAndComments, *decl)) {
        if (*decl == '"') {
            decl++;
            while (*decl++ != '"');
        }
        else decl++;
    }
    return decl;
}

static const char * _Nonnull skipTypeModifierEncoding(const char *_Nonnull encoding) {
    
    XCTAssert(encoding != NULL);
    
    static const char *qualifiersAndComments = "nNoOrRV\"";
    while (encoding[0] != '\0' && strchr(qualifiersAndComments, encoding[0])) {
        if (encoding[0] == '"') {
            encoding++;
            
            while(encoding[0] != '\0' && encoding[0] != '"')
                encoding++;
        }
        else encoding++;
    }
    return encoding;
}
