//
//  HMDStingerBlocker.m
//  Pods
//
//  Created by fengyadong on 2021/9/1.
//

#import "HMDStingerBlocker.h"
#import <objc/runtime.h>

static NSString *const kHMDProtectInstance = @"instance";
static NSString *const kHMDProtectClass = @"class";

@interface HMDStingerBlocker ()

@property(nonatomic, strong) NSMutableSet<NSString *>* catchBlockSet;/**key format:instance/class_className_selName**/

@end

@implementation HMDStingerBlocker

+ (instancetype)sharedInstance {
    static HMDStingerBlocker *blocker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        blocker = [[HMDStingerBlocker alloc] init];
    });
    
    return blocker;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _catchBlockSet = [[NSMutableSet alloc] init];
        [self setupBlockSet];
    }
    
    return self;
}

//all oc methods inside Stinger should be forbidden to be protected, not only the class itself, but also its super class
- (void)setupBlockSet {
    Class mArrayCls = [NSMutableArray class];
    [self excludeClassMethodForCls:mArrayCls selector:@selector(alloc)];
    [self excludeClassMethodForCls:mArrayCls selector:@selector(array)];
    [self excludeInstanceMethodForCls:mArrayCls selector:@selector(copy)];
    [self excludeInstanceMethodForCls:mArrayCls selector:@selector(initWithCapacity:)];
    [self excludeInstanceMethodForCls:mArrayCls selector:@selector(addObject:)];
    
    Class arrayCls = [NSArray class];
    [self excludeInstanceMethodForCls:arrayCls selector:@selector(objectAtIndex:)];
    [self excludeInstanceMethodForCls:arrayCls selector:@selector(count)];
    
    Class dataCls = [NSData class];
    [self excludeClassMethodForCls:dataCls selector:@selector(alloc)];
    [self excludeInstanceMethodForCls:dataCls selector:@selector(initWithBase64EncodedString:options:)];
    
    Class strCls = [NSString class];
    [self excludeClassMethodForCls:strCls selector:@selector(alloc)];
    [self excludeClassMethodForCls:strCls selector:@selector(stringWithUTF8String:)];
    [self excludeInstanceMethodForCls:strCls selector:@selector(initWithData:encoding:)];
    [self excludeInstanceMethodForCls:strCls selector:@selector(UTF8String)];
    
    Class invocationCls = [NSInvocation class];
    [self excludeClassMethodForCls:invocationCls selector:@selector(invocationWithMethodSignature:)];
    [self excludeInstanceMethodForCls:invocationCls selector:@selector(setArgument:atIndex:)];
    [self excludeInstanceMethodForCls:invocationCls selector:@selector(getReturnValue:)];
    [self excludeInstanceMethodForCls:invocationCls selector:@selector(methodSignature)];
    
    Class methodSignatureCls = [NSMethodSignature class];
    [self excludeClassMethodForCls:methodSignatureCls selector:@selector(signatureWithObjCTypes:)];
    [self excludeInstanceMethodForCls:methodSignatureCls selector:@selector(numberOfArguments)];
    [self excludeInstanceMethodForCls:methodSignatureCls selector:@selector(methodReturnLength)];
    [self excludeInstanceMethodForCls:methodSignatureCls selector:@selector(getArgumentTypeAtIndex:)];
    
    Class valueCls = [NSValue class];
    [self excludeClassMethodForCls:valueCls selector:@selector(valueWithBytes:objCType:)];
    
    Class nullCls = [NSNull class];
    [self excludeClassMethodForCls:nullCls selector:@selector(null)];
    
    Class stackBlockCls = NSClassFromString(@"__NSStackBlock__");
    [self excludeInstanceMethodForCls:stackBlockCls selector:@selector(copy)];
    
    Class heapBlockCls = NSClassFromString(@"__NSMallocBlock__");
    [self excludeInstanceMethodForCls:heapBlockCls selector:@selector(copy)];
}

- (void)excludeClassMethodForCls:(Class)cls selector:(SEL)sel {
    if (cls && sel) {
        Class currentClass = cls;
        do {
            if ([currentClass respondsToSelector:sel]) {
                [self checkBlockForCls:currentClass selector:sel isInstance:NO];
            } else {
                break;
            }
        } while ((currentClass = class_getSuperclass(currentClass)) != NULL && currentClass != cls);
    }
}

- (void)excludeInstanceMethodForCls:(Class)cls selector:(SEL)sel {
    if (cls && sel) {
        Class currentClass = cls;
        do {
            if ([currentClass instancesRespondToSelector:sel]) {
                [self checkBlockForCls:currentClass selector:sel isInstance:YES];
            } else {
                break;
            }
        } while ((currentClass = class_getSuperclass(currentClass)) != NULL && currentClass != cls);
    }
}

- (NSString *)blockKeyForCls:(Class)cls selector:(SEL)selector isInstance:(BOOL)isInstance {
    NSString *prefix = isInstance ? kHMDProtectInstance:kHMDProtectClass;
    NSString *blockKey = [NSString stringWithFormat:@"%@_%@_%@", prefix, NSStringFromClass(cls), NSStringFromSelector(selector)];
    
    return blockKey;
}

- (BOOL)checkBlockForCls:(Class)cls selector:(SEL)selector isInstance:(BOOL)isInstance {
    NSString *blockKey = [self blockKeyForCls:cls selector:selector isInstance:isInstance];
    if (blockKey && ![_catchBlockSet containsObject:blockKey]) {
        [_catchBlockSet addObject:blockKey];
        return YES;
    }
    
    return NO;
}

- (BOOL)hitBlockListForCls:(Class)cls selector:(SEL)selector isInstance:(BOOL)isInstance {
    NSString *blockKey = [self blockKeyForCls:cls selector:selector isInstance:isInstance];
    if (blockKey && [self.catchBlockSet containsObject:blockKey]) {
        return YES;
    }
    
    return NO;
}

@end
