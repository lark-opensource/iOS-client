//
//  HMDProtectCatch.m
//  Heimdallr
//
//

#import <stdatomic.h>
#import "HMDProtectCatch.h"
#import "pthread_extended.h"
#import "HMDThreadBacktrace.h"
#import "HMDMacro.h"
#import "HMDALogProtocol.h"
#import "HMDDynamicCall.h"
#import <objc/runtime.h>
#import <Stinger/Stinger.h>
#import "hmd_crash_safe_tool.h"
#include <dlfcn.h>
#import "HMDStingerBlocker.h"
#import "HMDInjectedInfo.h"
#import "HMDServiceContext.h"

// fix-up for missing symbol long double
#ifndef _C_LNG_DBL
#define _C_LNG_DBL 'D'
#endif

static NSString * const HMDCustomCatchMonitorKey = @"slardar_custom_catch";

#undef  DEBUG_LOG
#ifdef  DEBUG
#define DEBUG_LOG(format, ...) NSLog(@"[Heimdallr][ProtectCatch]"format, ##__VA_ARGS__);
#else
#define DEBUG_LOG(format, ...)
#endif

static pthread_mutex_t g_hook_lock = PTHREAD_MUTEX_INITIALIZER;
static pthread_rwlock_t g_callback_lock = PTHREAD_RWLOCK_INITIALIZER;
static pthread_rwlock_t g_protected_method_set_lock = PTHREAD_RWLOCK_INITIALIZER;
static void (^_internal_catch_captureBlock)(NSException * _Nonnull, NSDictionary * _Nonnull) = nil;
static NSMutableSet<NSString *>* crashKeySet = nil;
static NSMutableSet<NSString *>* swizzledMethodSet = nil;
static NSSet<NSString *>* protectedMethodSet = nil;
static NSString *mainBundlePath = nil;

@interface HMDProtectCatch()

@property(nonatomic, strong) NSMutableSet<NSString *>* catchBlockSet;/**key format:instance/class_className_selName**/

@end

@implementation HMDProtectCatch

+ (instancetype)sharedInstance {
    static HMDProtectCatch *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HMDProtectCatch alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        crashKeySet = [[NSMutableSet alloc] init];
        swizzledMethodSet = [[NSMutableSet alloc] init];
        protectedMethodSet = [[NSSet alloc] init];
        _catchBlockSet = [[NSMutableSet alloc] init];
        mainBundlePath = [NSBundle mainBundle].bundlePath;
    }
    
    return self;
}

- (void)registCallback:(void (^)(NSException * _Nonnull, NSDictionary * _Nonnull))callback {
    int lock_rst = pthread_rwlock_wrlock(&g_callback_lock);
    _internal_catch_captureBlock = callback;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_callback_lock);
    }
}

- (NSString *)catchClassMethod:(Class)cls selector:(SEL)sel {
    if (cls == NULL || sel == NULL) {
        return nil;
    }
    
    if ([[HMDStingerBlocker sharedInstance] hitBlockListForCls:cls selector:sel isInstance:NO]) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail for class:%@, selector:%@ due to it is a reserved system class method, otherwise it may cause recursive call problem", NSStringFromClass(cls), NSStringFromSelector(sel));
        return nil;
    }
    
    int lock_rst = pthread_mutex_lock(&g_hook_lock);
    NSString *key = [NSString stringWithFormat:@"+[%@ %@]", NSStringFromClass(cls), NSStringFromSelector(sel)];
    if ([swizzledMethodSet containsObject:key]) {
        if (lock_rst == 0) {
           pthread_mutex_unlock(&g_hook_lock);
        }
        
        return key;
    }
    
    Method targetMethod = class_getClassMethod(cls, sel);
    BOOL rst = (targetMethod != NULL);
    
    if (rst) {
        const char *signature = method_getTypeEncoding(targetMethod);
        id block = [self blockWithSignature:signature key:key];
        if (block) {
            NSError *error = nil;
            [cls st_hookClassMethod:sel withOptions:STOptionInstead|STOptionWeakCheckSignature usingBlock:block error:&error];
            rst = !error;
        }
        else {
            DEBUG_LOG(@"The type of the method's return value is not supported[%s]", signature);
            rst = NO;
        }
    }
    
    if (rst) {
        [swizzledMethodSet addObject:key];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"CustomProtect success for method:%@", key);
    }
    else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail for method:%@", key);
    }
    
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_hook_lock);
    }
    
    return rst ? key : nil;
}

- (NSString *)catchInstanceMethod:(Class)cls selector:(SEL)sel {
    if (cls == NULL || sel == NULL) {
        return nil;
    }
    
    if ([[HMDStingerBlocker sharedInstance] hitBlockListForCls:cls selector:sel isInstance:YES]) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail for class:%@, selector:%@ due to it is a reserved system instance method, otherwise it may cause recursive call problem", NSStringFromClass(cls), NSStringFromSelector(sel));
        return nil;
    }
    
    NSString *key = [NSString stringWithFormat:@"-[%@ %@]", NSStringFromClass(cls), NSStringFromSelector(sel)];
    int lock_rst = pthread_mutex_lock(&g_hook_lock);
    if ([swizzledMethodSet containsObject:key]) {
        if (lock_rst == 0) {
           pthread_mutex_unlock(&g_hook_lock);
        }
        
        return key;
    }
    
    Method targetMethod = class_getInstanceMethod(cls, sel);
    BOOL rst = (targetMethod != NULL);
    if (rst) {
        const char *signature = method_getTypeEncoding(targetMethod);
        id block = [self blockWithSignature:signature key:key];
        if (block) {
            NSError *error = nil;
            [cls st_hookInstanceMethod:sel withOptions:STOptionInstead|STOptionWeakCheckSignature usingBlock:block error:&error];
            rst = !error;
        }
        else {
            DEBUG_LOG(@"return type is not supported [%s]", signature);
            rst = NO;
        }
    }
    
    if (rst) {
        [swizzledMethodSet addObject:key];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"CustomProtect success for method:%@", key);
    }
    else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail for method:%@", key);
    }
    
    if (lock_rst == 0) {
        pthread_mutex_unlock(&g_hook_lock);
    }
    
    return rst ? key : nil;
}

- (void)catchMethodsWithNames:(NSArray<NSString *> *)names {
    NSMutableSet *protectedMethodSetTmp = [[NSMutableSet alloc] init];
    [names enumerateObjectsUsingBlock:^(NSString * _Nonnull name, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *validatedMethodName = [self catchMethodWithName:name];
        if (!HMDIsEmptyString(validatedMethodName)) {
            [protectedMethodSetTmp addObject:validatedMethodName];
        }
    }];
    int lock_rst = pthread_rwlock_wrlock(&g_protected_method_set_lock);
    protectedMethodSet = [protectedMethodSetTmp copy];
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_protected_method_set_lock);
    }
    [self trackCatchMethods];
}

- (void)trackCatchMethods {
    NSSet<NSString *> *protectedMethodSetTmp = nil;
    int lock_rst = pthread_rwlock_rdlock(&g_protected_method_set_lock);
    protectedMethodSetTmp = protectedMethodSet;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_protected_method_set_lock);
    }
    if ([protectedMethodSetTmp count] > 0) {
        NSString *currentCatchSetString = [[protectedMethodSetTmp allObjects] componentsJoinedByString:@", "];
        [[HMDInjectedInfo defaultInfo] setCustomContextValue:currentCatchSetString forKey:HMDCustomCatchMonitorKey];
        [[HMDInjectedInfo defaultInfo] setCustomFilterValue:currentCatchSetString forKey:HMDCustomCatchMonitorKey];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"protector enable custom catch: %@", currentCatchSetString);
    }
    else {
        [[HMDInjectedInfo defaultInfo] removeCustomContextKey:HMDCustomCatchMonitorKey];
        [[HMDInjectedInfo defaultInfo] removeCustomFilterKey:HMDCustomCatchMonitorKey];
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"protector enable custom catch: nil");
    }
    NSMutableDictionary *category = [[NSMutableDictionary alloc] init];
    [protectedMethodSetTmp enumerateObjectsUsingBlock:^(NSString * _Nonnull catchMethodName, BOOL * _Nonnull stop) {
        if ([catchMethodName isKindOfClass:[NSString class]]) {
            [category setValue:@(1) forKey:catchMethodName];
        }
    }];
    id<HMDTTMonitorServiceProtocol> ttmonitor = hmd_get_app_ttmonitor();
    [ttmonitor hmdTrackService:HMDCustomCatchMonitorKey metric:nil category:category extra:nil];
}

- (NSString *)catchMethodWithName:(NSString *)name {
    if (!(name && [name isKindOfClass:[NSString class]] && name.length > 0)) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail due to invalid name:%@", name);
        return nil;
    }
    
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    BOOL isClassMethod = NO;
    if ([name hasPrefix:@"+"]) {
        isClassMethod = YES;
    }
    else if ([name hasPrefix:@"-"]) {
        isClassMethod = NO;
    }
    else {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail due to invalid method prefix:%@", name);
        return nil;
    }
    
    name = [name substringFromIndex:1];
    name = [name stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (name.length > 2 && [name hasPrefix:@"["] && [name hasSuffix:@"]"]) {
        name = [name substringWithRange:NSMakeRange(1, name.length-2)];
    }
    
    NSArray<NSString *>*list = [name componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!(list && list.count == 2)) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail due to invalid method format:%@", name);
        return nil;
    }
    
    NSString *className = list[0];
    NSString *selectorName = list[1];
    if (!(className && className.length>0 && selectorName && selectorName.length>0)) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail due to invalidclass name:%@", name);
        return nil;
    }
    
    Class cls = NSClassFromString(className);
    if (cls == NULL) {
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"CustomProtect fail due to no such class:%@", name);
        return nil;
    }
    
    SEL sel = NSSelectorFromString(selectorName);
    if (isClassMethod) {
        return [self catchClassMethod:cls selector:sel];
    }
    else {
        return [self catchInstanceMethod:cls selector:sel];
    }
}

#pragma mark - Foundation

#define IFTryCatch

static void protect_method(id<StingerParams> params, void *rst, NSString *key) {
    NSSet<NSString *> *protectedMethodSetTmp = nil;
    int lock_rst = pthread_rwlock_rdlock(&g_protected_method_set_lock);
    protectedMethodSetTmp = protectedMethodSet;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_protected_method_set_lock);
    }
    if ([protectedMethodSetTmp containsObject:key]) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"CustomProtect is protecting method: %@", key);
        @try {
            [params invokeAndGetOriginalRetValue:rst];
        }
        @catch (NSException *exception) {
            catch_handle_exception(exception, key);
        }@catch (...) {
            catch_handle_exception(nil, key);
        }
    }
    else {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"CustomProtect is giving up to protect method: %@", key);
        [params invokeAndGetOriginalRetValue:rst];
    }
}

static const char *HMDDCSkipMethodEncodings(const char *_Nonnull decl);

- (id)blockWithSignature:(const char *)signature key:(NSString *)key {
    if(signature == NULL) DEBUG_RETURN(nil);
    
    signature = HMDDCSkipMethodEncodings(signature);
    
    id block = nil;
    switch (signature[0]) {
        case _C_ID:
        {
            block = ^id(id<StingerParams> params) {
                void *rst = NULL;
                protect_method(params, &rst, key);
                return (__bridge id)rst;
            };
            break;
        }
        case _C_CLASS:
        {
            block = ^Class(id<StingerParams> params) {
                Class rst = nil;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_SEL:
        {
            block = ^SEL(id<StingerParams> params) {
                SEL rst = nil;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_PTR:
        {
            block = ^void *(id<StingerParams> params) {
                void *rst = nil;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_CHARPTR:
        {
            block = ^char *(id<StingerParams> params) {
                char *rst = nil;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_CHR:
        {
            block = ^char(id<StingerParams> params) {
                char rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_UCHR:
        {
            block = ^unsigned char(id<StingerParams> params) {
                unsigned char rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_SHT:
        {
            block = ^short(id<StingerParams> params) {
                short rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_USHT:
        {
            block = ^unsigned short(id<StingerParams> params) {
                unsigned short rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_INT:
        {
            block = ^int(id<StingerParams> params) {
                int rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_UINT:
        {
            block = ^unsigned int(id<StingerParams> params) {
                unsigned int rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_LNG:
        {
            block = ^long(id<StingerParams> params) {
                long rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_ULNG:
        {
            block = ^unsigned long(id<StingerParams> params) {
                unsigned long rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_LNG_LNG:
        {
            block = ^long long(id<StingerParams> params) {
                long long rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_ULNG_LNG:
        {
            block = ^unsigned long long(id<StingerParams> params) {
                unsigned long long rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_FLT:
        {
            block = ^float(id<StingerParams> params) {
                float rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_DBL:
        {
            block = ^double(id<StingerParams> params) {
                double rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_LNG_DBL:
        {
            block = ^long double(id<StingerParams> params) {
                long double rst = 0;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_BOOL:
        {
            block = ^BOOL(id<StingerParams> params) {
                BOOL rst = NO;
                protect_method(params, &rst, key);
                return rst;
            };
            break;
        }
        case _C_VOID:
        {
            block = ^void(id<StingerParams> params) {
                protect_method(params, nil, key);
                GCC_FORCE_NO_OPTIMIZATION
            };
            break;
        }
        case _C_STRUCT_B:
        {
            if (hmd_reliable_has_prefix(signature, @encode(CGPoint))) {
                block = ^CGPoint(id<StingerParams> params) {
                    CGPoint rst = CGPointZero;
                    protect_method(params, &rst, key);
                    return rst;
                };
            }
            else if (hmd_reliable_has_prefix(signature, @encode(CGSize))) {
                block = ^CGSize(id<StingerParams> params) {
                    CGSize rst = CGSizeZero;
                    protect_method(params, &rst, key);
                    return rst;
                };
            }
            else if (hmd_reliable_has_prefix(signature, @encode(CGRect))) {
                block = ^CGRect(id<StingerParams> params) {
                    CGRect rst = CGRectZero;
                    protect_method(params, &rst, key);
                    return rst;
                };
            }
            else if (hmd_reliable_has_prefix(signature, @encode(NSRange))) {
                block = ^NSRange(id<StingerParams> params) {
                    NSRange rst = NSMakeRange(NSNotFound, 0);
                    protect_method(params, &rst, key);
                    return rst;
                };
            }
            break;
        }
        default:
            break;
    }
    
    return block;
}

static void HMD_NO_OPT_ATTRIBUTE catch_handle_exception(NSException * _Nullable exception, NSString *crashKey) {
    if(exception == nil) {
        exception = [NSException exceptionWithName:@"unknown" reason:nil userInfo:nil];
    }
    
    int lock_rst = pthread_rwlock_rdlock(&g_callback_lock);
    void (^captureBlock)(NSException * _Nonnull, NSDictionary * _Nonnull) = _internal_catch_captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_callback_lock);
    }

    NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
    if(captureBlock) {
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:8 suspend:NO];
        if (bt) {
            [info setValue:@[bt] forKey:@"backtraces"];
        }
        
        [info setValue:crashKey forKey:@"crashKey"];
        [info setValue:crashKeySet forKey:@"crashKeySet"];
        [info setValue:@(NO) forKey:@"filterWithTopStack"];
        captureBlock(exception, [info copy]);
    }
    
    GCC_FORCE_NO_OPTIMIZATION
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
