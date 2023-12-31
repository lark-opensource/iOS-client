//
//  HMDKStingerHookPool.m
//  Indexer
//
//  Created by Martin Lyu on 2022/3/14.
//

#import "HMDKStingerHookPool.h"
#import "HMDStingerBlocker.h"
#import <objc/runtime.h>
#import <Stinger/Stinger.h>
#import "HMDMacro.h"
#import "HMDALogProtocol.h"
#import "hmd_crash_safe_tool.h"
#import "HMDWPDynamicSafeData.h"
#import "HMDWPDynamicSafeData+ThreadSynchronize.h"

@implementation HMDKStingerHookPool

+ (BOOL)hookOCMethod:(HMDOCMethod *)method
               block:(HMDStingerHookOperation)operationBlock {
    Class aClass = method.methodClass;
    SEL selector = method.selector;
    BOOL isClassMethod = method.classMethod;
    
    if(aClass == nil || selector == NULL) DEBUG_RETURN(NO);
    
    Method targetMethod = NULL;
    
    if (isClassMethod)
         targetMethod = class_getClassMethod(aClass, selector);
    else targetMethod = class_getInstanceMethod(aClass, selector);

    if(targetMethod == NULL) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDKStingerHookPool] failed to find method %s[%s %s]",
                                   isClassMethod ? "+":"-",
                                   class_getName(aClass),
                                   sel_getName(selector));
        return NO;
    }
    
    const char * _Nonnull methodEncoding = method_getTypeEncoding(targetMethod);
    id block = [self hookBlockWithMethodEncoding:methodEncoding replacedImplementation:operationBlock];
    if (block == nil) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDKStingerHookPool] unable to create block for %s[%s %s] encoding:%s",
                                   isClassMethod ? "+":"-",
                                   class_getName(aClass),
                                   sel_getName(selector), methodEncoding);
        return NO;
    }
    
    NSError *error = nil;
    if (isClassMethod) {
        [aClass st_hookClassMethod:selector
                       withOptions:STOptionInstead|STOptionWeakCheckSignature
                        usingBlock:block
                             error:&error];
        
    } else {
        [aClass st_hookInstanceMethod:selector
                          withOptions:STOptionInstead|STOptionWeakCheckSignature
                           usingBlock:block
                                error:&error];
    }
    return YES;
}

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl);

+ (id)hookBlockWithMethodEncoding:(const char *)signature
           replacedImplementation:(HMDStingerHookOperation)replacedImplementation {
    if (signature == NULL || replacedImplementation == nil) DEBUG_RETURN(nil);

    signature = HMDDCSkipMethodEncodings(signature);
    
    // generate block
    id block = nil;
    switch (signature[0]) {
        case _C_ID:
        {
            block = ^id(id<StingerParams> params) {
                // 创建异步数据存储对象 HMDWPDynamicSafeData
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataStoreObject];
                // CallerStatusWaiting 调用线程正在等待; 默认初始化为0; 无需额外赋值
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                // 创建异步线程;执行方法;同步等待方法执行成功返回
                replacedImplementation(params, returnStore, sizeof(id));
                
                // 获取返回对象的值
                id object = [returnStore getObject];
                
                // 无论获取成功与否; 标记调用线程已经没有再继续等待
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                
                return object;
            };
            break;
        }
        case _C_VOID:
        {
            block = ^void(id<StingerParams> params) {
                // 我们虽然不需要返回值，但是需要使用 atomicInfo 的值; 用于同步 HMDWPCallerStatusWaiting 信息
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:0];
                
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
    
                replacedImplementation(params, returnStore, 0);
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                GCC_FORCE_NO_OPTIMIZATION // 增加此行可以在 Slardar 上看到 HMDWPDynamicProtect 是 _C_VOID 这里的调用
            };
            break;
        }
        case _C_CLASS:
        {
            block = ^Class(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataStoreObject];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(Class));
                
                Class aClass = [returnStore getObject];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return aClass;
            };
            break;
        }
        case _C_SEL:
        {
            block = ^SEL(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(SEL)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(SEL));
                
                SEL defaultValue = NULL;   // 首先初始化默认值
                [returnStore getDataIfPossible:&defaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return defaultValue;
            };
            break;
        }
        case _C_PTR:
        {
            block = ^void *(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(void *)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(void *));
                
                void *defaultValue = NULL;
                [returnStore getDataIfPossible:&defaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return defaultValue;
            };
            break;
        }
        case _C_CHARPTR:
        {
            block = ^char *(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(char *)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(char *));
                
                void *defaultValue = NULL;
                [returnStore getDataIfPossible:&defaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return defaultValue;
            };
            break;
        }
        case _C_CHR:
        {
            block = ^char(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(char)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(char));
                
                char dafaultValue = '\0';
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_UCHR:
        {
            block = ^unsigned char(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(unsigned char)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(unsigned char));
                
                unsigned char dafaultValue = '\0';
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_SHT:
        {
            block = ^short(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(short)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(short));
                
                short dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_USHT:
        {
            block = ^unsigned short(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(unsigned short)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(unsigned short));
                
                unsigned short dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_INT:
        {
            block = ^int(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(int)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(int));
                
                int dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_UINT:
        {
            block = ^unsigned int(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(unsigned int)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(unsigned int));
                
                unsigned int dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_LNG:
        {
            block = ^long(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(long)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(long));
                
                long dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_ULNG:
        {
            block = ^unsigned long(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(unsigned long)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(unsigned long));
                
                unsigned long dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_LNG_LNG:
        {
            block = ^long long(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(long long)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(long long));
                
                long long dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_ULNG_LNG:
        {
            block = ^unsigned long long(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(unsigned long long)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(unsigned long long));
                
                unsigned long long dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_FLT:
        {
            block = ^float(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(float)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(float));
                
                float dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_DBL:
        {
            block = ^double(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(double)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(double));
                
                double dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_BOOL:
        {
            block = ^BOOL(id<StingerParams> params) {
                HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(BOOL)];
                DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                
                replacedImplementation(params, returnStore, sizeof(bool));
                
                BOOL dafaultValue = 0;
                [returnStore getDataIfPossible:&dafaultValue];
                
                returnStore.atomicInfo = HMDWPCallerStatusContinue;
                return dafaultValue;
            };
            break;
        }
        case _C_STRUCT_B:
        {
            if (hmd_reliable_has_prefix(signature, @encode(CGPoint))) {
                block = ^CGPoint(id<StingerParams> params) {
                    HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(CGPoint)];
                    DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                    
                    replacedImplementation(params, returnStore, sizeof(CGPoint));
                    
                    CGPoint dafaultValue = CGPointZero;
                    [returnStore getDataIfPossible:&dafaultValue];
                    
                    returnStore.atomicInfo = HMDWPCallerStatusContinue;
                    return dafaultValue;
                };
            }
            else if (hmd_reliable_has_prefix(signature, @encode(CGSize))) {
                block = ^CGSize(id<StingerParams> params) {
                    HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(CGSize)];
                    DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                    
                    replacedImplementation(params, returnStore, sizeof(CGSize));
                    
                    CGSize dafaultValue = CGSizeZero;
                    [returnStore getDataIfPossible:&dafaultValue];
                    
                    returnStore.atomicInfo = HMDWPCallerStatusContinue;
                    return dafaultValue;
                };
            }
            else if (hmd_reliable_has_prefix(signature, @encode(CGRect))) {
                block = ^CGRect(id<StingerParams> params) {
                    HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(CGRect)];
                    DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                    
                    replacedImplementation(params, returnStore, sizeof(CGRect));
                    
                    CGRect dafaultValue = CGRectZero;
                    [returnStore getDataIfPossible:&dafaultValue];
                    
                    returnStore.atomicInfo = HMDWPCallerStatusContinue;
                    return dafaultValue;
                };
            }
            else if (hmd_reliable_has_prefix(signature, @encode(NSRange))) {
                block = ^NSRange(id<StingerParams> params) {
                    HMDWPDynamicSafeData *returnStore = [HMDWPDynamicSafeData safeDataWithSize:sizeof(NSRange)];
                    DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
                    
                    replacedImplementation(params, returnStore, sizeof(NSRange));
                    
                    NSRange dafaultValue = NSMakeRange(NSNotFound, 0);
                    [returnStore getDataIfPossible:&dafaultValue];
                    
                    returnStore.atomicInfo = HMDWPCallerStatusContinue;
                    return dafaultValue;
                };
            }
            else {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDWP] DynamicProtect get block fail due to unknown _C_STRUCT_B: %s", signature);
            }
            break;
        }
        default:
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDWP] DynamicProtect get block fail due to unknown signature: %s", signature);
            break;
    }

    return block;
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
