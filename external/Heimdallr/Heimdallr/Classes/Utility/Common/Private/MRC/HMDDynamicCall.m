//
//  HMDDynamicCall.m
//  CaptainAllred
//
//  Created by sunrunwang on 2019/4/26.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

#import <math.h>
#import <stdio.h>
#import <stdbool.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "HMDALogProtocol.h"
#include "HMDMacro.h"
#define HMDDynamicCallInternalImplementation
#import "HMDDynamicCall.h"

#if __has_feature(objc_arc)
#error HMDDynamicCall must compiler in MRC
#endif

#define SET_ARGUMENT_FORPARAM(x)                                    \
    do{                                                             \
        x param = va_arg(ap, x);                                    \
        [invocation setArgument:&param atIndex:index];              \
    }while(0);                                                      \
    break;

#define RETURN_DATA(x,y,z)                                          \
    do{                                                             \
        x store;                                                    \
        [invocation getReturnValue:&store];                         \
        result = [y z:store];                                       \
    }while(0);                                                      \
    break;


extern bool HMDDynamicCallIsSelectorReturnsRetained(SEL _Nonnull aSEL);
static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl);
static inline bool HMDDynamicCallMatchSelectorFamily(const char * _Nonnull selector, const char * _Nonnull family);
static void HMDDCCheckPointerToObject(id object, SEL aSEL, const char *type, int index);

extern id _Nullable HMDDynamicCall(id _Nullable object, SEL _Nullable aSEL, ...) {
    /*构建NSInvocation的预处理操作*/
    Class aClass = nil;
    id result = nil;
    if(object == nil || aSEL == NULL) {
        return result;
    }
    aClass = object_getClass(object);
    if(![object respondsToSelector:aSEL]) {
        DEBUG_ERROR("%s[%s %s] calls an undefined method. Operation failed!",
                        (!(class_isMetaClass(aClass))?"-":"+"),
                        class_getName(aClass),
                        sel_getName(aSEL));
        return result;
    }
    
    SEL signatureSEL = sel_registerName("methodSignatureForSelector:");
    if(signatureSEL == NULL || !(class_respondsToSelector(aClass, signatureSEL))) {
        DEBUG_ERROR("Failed to register methodSignatureForSelector!");
        return result;
    }
    
    NSMethodSignature *signature = [object methodSignatureForSelector:aSEL];
    if(signature == nil) {
        DEBUG_ERROR("Failed to get methodSignature!");
        return result;
    }
    
    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    if(invocation == nil) {
        DEBUG_ERROR("Failed to init invocation!");
        return result;
    }
    
    NSUInteger parametersCount = signature.numberOfArguments;
    if(parametersCount < 2) {
        DEBUG_ERROR("Expected 2 parameters at least, got %lu", parametersCount);
        return result;
    }
    
    invocation.target = object;
    invocation.selector = aSEL;
    BOOL flag = YES;
    va_list ap;
    va_start(ap, aSEL);
    
    /*
     借助Type_Encoding判断参数类型，并循环向invocation放入参数
     Type_Encoding官方文档:
     https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Articles/ocrtTypeEncodings.html#//apple_ref/doc/uid/TP40008048-CH100-SW1
     */
    for(unsigned int index = 2; index < parametersCount; index++) {
        const char *type = [signature getArgumentTypeAtIndex:index];
        if (!type) {
            flag = NO;
            DEBUG_ERROR("The Type_Encoding of Parameter #%d is NULL!", index);
            break;
        }
        
        /*跳过MethodEncodings*/
        type = HMDDCSkipMethodEncodings(type);
        switch (*type) {
            case _C_CHARPTR:        SET_ARGUMENT_FORPARAM(char*);
            case _C_INT:            SET_ARGUMENT_FORPARAM(int);
            case _C_UINT:           SET_ARGUMENT_FORPARAM(unsigned int);
            case _C_LNG:            SET_ARGUMENT_FORPARAM(long);
            case _C_ULNG:           SET_ARGUMENT_FORPARAM(unsigned long);
            case _C_LNG_LNG:        SET_ARGUMENT_FORPARAM(long long);
            case _C_ULNG_LNG:       SET_ARGUMENT_FORPARAM(unsigned long long);
            case _C_DBL:            SET_ARGUMENT_FORPARAM(double);
            case _C_SEL:            SET_ARGUMENT_FORPARAM(SEL);
            case _C_ID:
            case _C_CLASS:          SET_ARGUMENT_FORPARAM(id);
            case _C_PTR: {
                void *convert = va_arg(ap, void*);
                HMDDCCheckPointerToObject(object, aSEL, type, index);
                [invocation setArgument:&convert atIndex:index];
                break;
            }
            case _C_BOOL: {
                uint64_t convert = va_arg(ap, uint64_t);
                BOOL value = (convert == 0) ? NO : YES;
                [invocation setArgument:&value atIndex:index];
                break;
            }
            case _C_CHR: {
                int convert = va_arg(ap, int);
                if(convert > CHAR_MAX || convert < CHAR_MIN) {
                    flag = NO;
                    DEBUG_ERROR("Parameter #%d is not of type \'char\'!", index);
                    break;
                }
                char value = convert;
                [invocation setArgument:&value atIndex:index];
                break;
            }
            case _C_UCHR: {
                int convert = va_arg(ap, int);
                if(convert > UCHAR_MAX) {
                    flag = NO;
                    DEBUG_ERROR("Parameter #%d is not of type \'unsigned char\'!", index);
                    break;
                }
                unsigned char value = convert;
                [invocation setArgument:&value atIndex:index];
                break;
            }
            case _C_SHT: {
                int convert = va_arg(ap, int);
                if(convert > SHRT_MAX || convert < SHRT_MIN) {
                    flag = NO;
                    DEBUG_ERROR("Parameter #%d is not of type \'short\'!", index);
                    break;
                }
                short value = convert;
                [invocation setArgument:&value atIndex:index];
                break;
            }
            case _C_USHT: {
                int convert = va_arg(ap, int);
                if(convert > USHRT_MAX) {
                    flag = NO;
                    DEBUG_ERROR("Parameter #%d is not of type \'unsigned short\'!", index);
                    break;
                }
                unsigned short value = convert;
                [invocation setArgument:&value atIndex:index];
                break;
            }
            case _C_FLT: {
                double convert = va_arg(ap, double);
                if(convert > FLT_MAX || convert < copysign(FLT_MAX, -1.0)) {
                    flag = NO;
                    DEBUG_ERROR("Parameter #%d is not of type \'float\'!", index);
                    break;
                }
                float value = convert;
                [invocation setArgument:&value atIndex:index];
                break;
            }
            case _C_STRUCT_B: {
                if (strcmp(type, @encode(NSRange)) == 0) {
                    NSRange range = va_arg(ap, NSRange);
                    [invocation setArgument:&range atIndex:index];
                }
                else if (strcmp(type, @encode(CGPoint)) == 0) {
                    CGPoint point = va_arg(ap, CGPoint);
                    [invocation setArgument:&point atIndex:index];
                }
                else if (strcmp(type, @encode(CGSize)) == 0) {
                    CGSize size = va_arg(ap, CGSize);
                    [invocation setArgument:&size atIndex:index];
                }
                else if (strcmp(type, @encode(CGRect)) == 0) {
                    CGRect rect = va_arg(ap, CGRect);
                    [invocation setArgument:&rect atIndex:index];
                }
                else {
                    flag = NO;
                    DEBUG_ERROR("The Type_Encoding of Parameter #%d is %s, which is not a supported c-struct type currently. Only NSRange, CGPoint, CGSize and CGRect are supported.", index, type);
                }
                break;
            }
            default:
                flag = NO;
                DEBUG_ERROR("The Type_Encoding of Parameter #%d is %s, which is not a supported type currently.", index, type);
        }
        if(!flag)
            break;
    }
    
    va_end(ap);
    if(!flag) {
        DEBUG_ERROR("Failed to set parameter!");
        return result;
    }
    
    [invocation invoke];
    
    /*获取返回值*/
    const char *type = signature.methodReturnType;
    if (!type) {
        DEBUG_ERROR("Return value type is NULL!");
        return result;
    }
    
    while(*type == _C_CONST) type++;
    switch (*type)
    {
        case _C_VOID:       break;
        case _C_BOOL:       RETURN_DATA(BOOL, NSNumber, numberWithBool);
        case _C_CHR:        RETURN_DATA(char, NSNumber, numberWithChar);
        case _C_UCHR:       RETURN_DATA(unsigned char, NSNumber, numberWithUnsignedChar);
        case _C_SHT:        RETURN_DATA(short, NSNumber, numberWithShort);
        case _C_USHT:       RETURN_DATA(unsigned short, NSNumber, numberWithUnsignedShort);
        case _C_INT:        RETURN_DATA(int, NSNumber, numberWithInt);
        case _C_UINT:       RETURN_DATA(unsigned int, NSNumber, numberWithUnsignedInt);
        case _C_LNG:        RETURN_DATA(long, NSNumber, numberWithLong);
        case _C_ULNG:       RETURN_DATA(unsigned long, NSNumber, numberWithUnsignedLong);
        case _C_LNG_LNG:    RETURN_DATA(long long, NSNumber, numberWithLongLong);
        case _C_ULNG_LNG:   RETURN_DATA(unsigned long long, NSNumber, numberWithUnsignedLongLong);
        case _C_FLT:        RETURN_DATA(float, NSNumber, numberWithFloat);
        case _C_DBL:        RETURN_DATA(double, NSNumber, numberWithDouble);
        case _C_CHARPTR:    RETURN_DATA(char*, NSValue, valueWithPointer);
        case _C_PTR:        RETURN_DATA(void*, NSValue, valueWithPointer);
        case _C_ID:
        case _C_CLASS: {
            void *store;
            [invocation getReturnValue:&store];
            result = (__bridge id)store;
            /*
             在只考虑调用者为ARC的前提下，MRC下的动态方法调用会根据方法名不同做出不同的操作：
             1.如果是new\alloc\copy\mutableCopy家族方法，不会对创建的对象进行autorelease操作，此时强引用计数为1，而且不人工干预的话，该引用返回调用方后无法被释放，
             故要在动态调用内部对该家族的方法提前进行autoreleasing操作
             2.非家族方法会被默认进行autorelease操作
             */
            if(HMDDynamicCallIsSelectorReturnsRetained(aSEL))
                [result autorelease];
            break;
        }
        case _C_SEL: {
            SEL store;
            [invocation getReturnValue:&store];
            result = [NSValue value:&store withObjCType:type];
            break;
        }
        case _C_STRUCT_B: {
            NSUInteger size = 0;
            @try {
                NSGetSizeAndAlignment(type, &size, NULL);
            } @catch (NSException *exception) {
                HMDALOG_PROTOCOL_ERROR_TAG(@"HMDDynamicCall", @"NSGetSizeAndAlignment crashed when struct return value was in construction!");
            }
            if(size == 0) {
                DEBUG_ERROR("Failed to preprocess the struct return value of Type_Encoding=%s", type);
                break;
            }
            void *buffer = (void *)malloc(size);
            [invocation getReturnValue:buffer];
            result = [NSValue value:buffer withObjCType:type];
            free(buffer);
            break;
        }
        default:
            DEBUG_ERROR("Return value type of Type_Encoding=%s is not supported!", type);
            break;
    }
    
    return result;
}

extern bool HMDDynamicCallIsSelectorReturnsRetained(SEL _Nonnull aSEL) {
    if(aSEL == NULL) DEBUG_RETURN(false);
    NSString *selector = nil;
    if((selector = NSStringFromSelector(aSEL)) != nil) {
        const char *rawSelectorString = selector.UTF8String;
        if(rawSelectorString != NULL) {
            if(HMDDynamicCallMatchSelectorFamily(rawSelectorString, "new") ||
               HMDDynamicCallMatchSelectorFamily(rawSelectorString, "copy") ||
               HMDDynamicCallMatchSelectorFamily(rawSelectorString, "alloc") ||
               HMDDynamicCallMatchSelectorFamily(rawSelectorString, "mutableCopy"))
                return true;
        }
    } DEBUG_ELSE
    return false;
}

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl)
{
    /*
     跳过method encodings(即nNoOrRV字符)以及被双引号”“包裹的字符。
     method encodings（详情见官方文档），关于method encodings的官方解释如下:
     Note that although the @encode() directive doesn’t return them, the runtime system uses the additional encodings listed in Table 6-2 for type qualifiers when they’re used to declare methods in a protocol.
     */
    static const char *qualifiersAndComments = "nNoOrRV\"";
    while (*decl != '\0' && strchr(qualifiersAndComments, *decl)) {
        if (*decl == '"') {
            decl++;
            while (*decl++ != '"');
        }
        else
            decl++;
    }
    return decl;
}

static inline bool HMDDynamicCallMatchSelectorFamily(const char * _Nonnull selector, const char * _Nonnull family) {
    DEBUG_ASSERT(selector != NULL);
    DEBUG_ASSERT(family != NULL);
    
    while(selector[0] == '_') selector++;
    size_t familyLength = strlen(family);
    
    if(strncmp(selector, family, familyLength) == 0) {
        if(!islower(selector[familyLength])) return true;
        else return false;
    }
    return false;
}

static void HMDDCCheckPointerToObject(id object, SEL aSEL, const char *type, int index) {
    /*检查该参数类型是否为引用传递*/
#ifdef DEBUG
    while(*type == _C_PTR)
        type = HMDDCSkipMethodEncodings(++type);
    if(*type == _C_ID || *type == _C_CLASS) {
        Class objectClass = object_getClass(object);
        const char *className = class_getName(objectClass);
        BOOL isMetal = class_isMetaClass(objectClass);
        const char *selectorName = sel_getName(aSEL);
        DEBUG_LOG("The parameter #%d of %s[%s %s] is passed by reference. Please check the passed parameter ownership modifiers(strong, autorelease, etc.) is consistent with the method declaration!", index-1, isMetal?"+":"-", className, selectorName);
    }
#endif
}
