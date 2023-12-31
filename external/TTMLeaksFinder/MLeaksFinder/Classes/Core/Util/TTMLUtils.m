//
//  TTMLUtils.c
//  TTMLeaksFinder-Pods-Aweme
//
//  Created by maruipu on 2020/11/11.
//

#import "TTMLUtils.h"
#import <objc/runtime.h>
#import <sys/sysctl.h>
#import <mach/mach_time.h>
#import <CommonCrypto/CommonDigest.h>

static const char * sMainBundlePath;
static size_t       sMainPathLength;

NSString *TTMLMD5String(NSString *srcStr) {
    const char *cStr = [srcStr UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5( cStr, (CC_LONG)strlen(cStr), result );
    
    return [NSString stringWithFormat:
            @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]
            ];
}

TTML_REGISTRATION {
    const char *p = [[[NSBundle mainBundle] bundlePath]
                            cStringUsingEncoding:NSUTF8StringEncoding];
    sMainBundlePath = strdup(p);
    sMainPathLength = strlen(p);
}

BOOL ttml_checkIsSystemClass(Class clazz) {
    if (clazz == nil) {
        return NO;
    }
    const char *imagePath = class_getImageName(clazz);
    if (imagePath == NULL) {  // In this situation, [NSBundle bundleForClass:]
        return NO;            // return main bundle object.
    }
    return strncmp(imagePath, sMainBundlePath, sMainPathLength) != 0;
}


uint64_t TTMLCurrentMachTime() {
    return mach_absolute_time();
}

double TTMLMachTimeToSecs(uint64_t time) {
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    return (double)time * (double)timebase.numer /
    (double)timebase.denom / NSEC_PER_SEC;
}

@implementation TTMLUtil

+ (BOOL)objectIsSystemClass:(id)object {
    Class clazz = object_getClass(object);
    if (clazz == nil) {
        return YES;
    }
    return [self isSystemClass:clazz];
}

+ (BOOL)isSystemClass:(Class)clazz {
    static dispatch_once_t onceToken;
    static NSMutableArray *systemClassArray = nil;
    static NSMutableArray *customizedClassArray = nil;
    static NSLock *lock;
    dispatch_once(&onceToken, ^{
        systemClassArray = [[NSMutableArray alloc] init];
        customizedClassArray = [[NSMutableArray alloc] init];
        lock = [[NSLock alloc] init];
    });
    
    [lock lock];
    
    if ([systemClassArray containsObject:clazz]) {
        [lock unlock];
        return YES;
    }
    if ([customizedClassArray containsObject:clazz]) {
        [lock unlock];
        return NO;
    }
    
    BOOL isSystemClass = ttml_checkIsSystemClass(clazz);
    
    if (!isSystemClass) {//临时写在这里，后续配置到服务端
        NSString *className = NSStringFromClass(clazz);
        if ([className containsString:@"RxSwift"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"Swinject"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"SQLite"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"RxCocoa"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"SnapKit"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"RxRelay"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"LOT"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"LarkRustClient"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"LarkRustHTTP"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"LarkRustClientAssembly"]) {
            [lock unlock];
            return  YES;
        }
        if ([className containsString:@"RustPB"]) {
            [lock unlock];
            return  YES;
        }
    }
    
    if (isSystemClass) {
        [systemClassArray addObject:clazz];
    }
    else {
        [customizedClassArray addObject:clazz];
    }
    
    [lock unlock];
    return isSystemClass;
}

// 用于memoryLeaks 检测相关功能
+ (void)tt_swizzleSEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL {
    [self tt_swizzleClass:[self class] SEL:originalSEL withSEL:swizzledSEL];
}
    
// 对外提供通用方法
+ (void)tt_swizzleClass:(Class)class SEL:(SEL)originalSEL withSEL:(SEL)swizzledSEL {
    Method originalMethod = class_getInstanceMethod(class, originalSEL);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSEL);
    
    BOOL didAddMethod =
    class_addMethod(class,
                    originalSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    
    if (didAddMethod) {
        class_replaceMethod(class,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end

