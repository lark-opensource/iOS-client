//
//  ACCMemoryMonitor.mm
//  CameraClient
//
//  Created by Liu Deping on 2020/5/24.
//

#import "ACCMemoryMonitor.h"
#import "ACCWeakObjectWrapper.h"
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static NSMutableDictionary *_monitorDictionary;
static NSMutableDictionary *_monitorCountDictionary;
static NSMutableSet *_allMonitorClasses;
static NSInteger _countCleanTimeInterval = 30;
static dispatch_queue_t _serialQueue;
static __weak UIAlertController *_alertController;
static NSMutableSet *_ignoredContexts;

@interface ACCMemoryCountDictionary : NSObject

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableArray*> *countDic;

@end

@implementation ACCMemoryCountDictionary

- (instancetype)init
{
    if (self = [super init]) {
        _countDic = [NSMutableDictionary dictionary];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_countCleanTimeInterval * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self startCleanMemory];
        });
    }
    return self;
}

- (void)startCleanMemory
{
    dispatch_async(_serialQueue, ^{
        NSMutableArray *cleanClasses = [NSMutableArray array];
        [self.countDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray * _Nonnull obj, BOOL * _Nonnull stop) {
            NSMutableIndexSet *idxs = [[NSMutableIndexSet alloc] init];
            [obj enumerateObjectsUsingBlock:^(ACCWeakObjectWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (!obj.weakObject) {
                    [idxs addIndex:idx];
                }
            }];
            [obj removeObjectsAtIndexes:idxs];
            if (!obj.count) {
                [cleanClasses addObject:key];
            }
        }];
        [cleanClasses enumerateObjectsUsingBlock:^(NSString * _Nonnull classKey, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.countDic removeObjectForKey:classKey];
        }];
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_countCleanTimeInterval * NSEC_PER_SEC)), _serialQueue, ^{
        [self startCleanMemory];
    });
}

- (void)addObject:(id)object forKey:(Class)key
{
    dispatch_async(_serialQueue, ^{
        if (![self.countDic objectForKey:NSStringFromClass(key)]) {
            self.countDic[NSStringFromClass(key)] = [NSMutableArray array];
        }
        [self.countDic[NSStringFromClass(key)] addObject:object];
        NSMutableArray *instances = [NSMutableArray array];
        [instances addObjectsFromArray:[self.countDic objectForKey:NSStringFromClass(key)] ?: @[]];
        NSMutableIndexSet *idxs = [[NSMutableIndexSet alloc] init];
        [instances enumerateObjectsUsingBlock:^(ACCWeakObjectWrapper *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (!obj.weakObject) {
                [idxs addIndex:idx];
            }
        }];
        [instances removeObjectsAtIndexes:idxs];
        
        NSUInteger instanceCount = 0;
        for (NSString *monitorKey in _monitorDictionary.allKeys) {
            NSMutableSet *set = _monitorDictionary[monitorKey];
            NSNumber *MaxCount = _monitorCountDictionary[monitorKey];
            for (Class cls in set) {
                if (cls == key) {
                    instanceCount += MaxCount.integerValue;
                }
            }
        }
        if (instances.count > instanceCount) {
            NSString *memoryLeakClass = NSStringFromClass(key);
            NSAssert(NO, @"A memory leak occurred in the %@ class", memoryLeakClass);
        }
    });
}

@end

static ACCMemoryCountDictionary *_countDictionary;

@interface NSObject (ACCMemoryMonitor)

+ (instancetype)acc_allocWithZone:(struct _NSZone *)zone;
+ (void)acc_swizzleClass:(Class)cls SEL:(nonnull SEL)origSEL withSEL:(nonnull SEL)swizzledSEL;

@end

@implementation NSObject (ACCMemoryMonitor)

+ (instancetype)acc_allocWithZone:(struct _NSZone *)zone
{
    id instance = [self acc_allocWithZone:zone];
    if (instance) {
        ACCWeakObjectWrapper *wrapper = [[ACCWeakObjectWrapper alloc] init];
        wrapper.weakObject = instance;
        Class targetClass = nil;
        NSSet *allMonitorClasses = nil;
        @synchronized (_allMonitorClasses) {
            allMonitorClasses = [_allMonitorClasses copy];
        }
        
        for (Class cls in allMonitorClasses) {
            if ([instance isKindOfClass:cls]) {
                targetClass = cls;
            }
        }
        [_countDictionary addObject:wrapper forKey:targetClass ? : [self class]];
    }
    return instance;
}

+ (void)acc_swizzleClass:(Class)cls SEL:(SEL)origSEL withSEL:(SEL)swizzledSEL
{
    Method originalMethod = class_getInstanceMethod(cls, origSEL);
    Method swizzledMethod = class_getInstanceMethod(cls, swizzledSEL);
    
    BOOL didAddMethod =
    class_addMethod(cls,
                    origSEL,
                    method_getImplementation(swizzledMethod),
                    method_getTypeEncoding(swizzledMethod));
    if (didAddMethod) {
        class_replaceMethod(cls,
                            swizzledSEL,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end

@implementation ACCMemoryMonitor

+ (void)startCheckMemoryLeaks:(id)object
{
#if DEBUG
    ACCWeakObjectWrapper *weakWrapper = [[ACCWeakObjectWrapper alloc] init];
    weakWrapper.weakObject = object;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (weakWrapper.weakObject) {
            if (_alertController) {
                return;
            }
            _alertController = [UIAlertController alertControllerWithTitle:@"Memory Leak" message:[NSString stringWithFormat:@"%@ object should be dealloc", weakWrapper.weakObject] preferredStyle:UIAlertControllerStyleAlert];
            [_alertController addAction:[UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                _alertController = nil;
            }]];
            UIViewController *presentationVC = [self alertPresentationController];
            if (presentationVC) {
                [presentationVC presentViewController:_alertController animated:YES completion:nil];
            }
        }
    });
#endif
}

+ (UIViewController *)alertPresentationController
{
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    if ([rootVC isKindOfClass:[UITabBarController class]]) {
        rootVC = ((UITabBarController *)rootVC).selectedViewController;
    }
    if ([rootVC isKindOfClass:[UINavigationController class]]) {
        rootVC = ((UINavigationController *)rootVC).visibleViewController;
    }
    return rootVC;
}

+ (void)setup
{
#if DEBUG
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _monitorDictionary = [NSMutableDictionary dictionary];
        _monitorCountDictionary = [NSMutableDictionary dictionary];
        _allMonitorClasses = [NSMutableSet set];
        _serialQueue = dispatch_queue_create("com.cameraclient.memorymonitor.queue", DISPATCH_QUEUE_SERIAL);
        _ignoredContexts = [NSMutableSet set];
    });
#endif
}

+ (void)startMemoryMonitorForContext:(NSString *)context tartgetClasses:(NSArray<Class> *)classes maxInstanceCount:(NSUInteger)count
{
#if DEBUG
    NSAssert([NSThread isMainThread], @"Must be called by the main thread");
    [self setup];
    NSAssert(context != nil, @"Must be set monitorObject key");
    NSAssert(classes != nil, @"Must be set monitorObject monitorClasses");
    __block NSUInteger maxCount = count;
    dispatch_async(_serialQueue, ^{
        if (context && [_ignoredContexts containsObject:context]) {
            return;
        }
        NSSet<Class> *set = [_allMonitorClasses copy];
        _countDictionary = [[ACCMemoryCountDictionary alloc] init];
        [_allMonitorClasses addObjectsFromArray:classes];
        
        NSMutableSet *monitorClasees = [_monitorDictionary objectForKey:context];
        
        if (!monitorClasees) {
            monitorClasees = [NSMutableSet set];
            [_monitorDictionary setObject:monitorClasees forKey:context];
                    
            if (maxCount <= 0) {
                maxCount = 1;
            }
            
            [_monitorCountDictionary setObject:@(maxCount) forKey:context];
        }
        [monitorClasees addObjectsFromArray:classes];
        
        for (Class cls in classes) {
            if (![set containsObject:cls]) {
                [NSObject acc_swizzleClass:object_getClass(cls)
                                       SEL:@selector(allocWithZone:)
                                   withSEL:@selector(acc_allocWithZone:)];
            }
        }
    });
#endif
}

+ (void)addObject:(id)obj forContext:(NSString *)context
{
#if DEBUG
    dispatch_async(_serialQueue, ^{
        if (context && [_ignoredContexts containsObject:context]) {
            return;
        }
        Class clazz = [obj class];
        NSMutableSet *monitorClasses = [_monitorDictionary objectForKey:context];
        NSAssert(monitorClasses != nil, @"You must call startMemoryMonitorForContext method before addObject");
        [monitorClasses addObject:clazz];
        if ([_allMonitorClasses containsObject:clazz]) {
            NSAssert(NO, @"obj class must be added dynamically");
        }
        ACCWeakObjectWrapper *weakObjectWrapper = [[ACCWeakObjectWrapper alloc] init];
        weakObjectWrapper.weakObject = obj;
        [_countDictionary addObject:weakObjectWrapper forKey:clazz];
    });
#endif
}

+ (void)stopMemoryMonitorForContext:(NSString *)context
{
#if DEBUG
    dispatch_async(_serialQueue, ^{
        if (context && [_ignoredContexts containsObject:context]) {
            return;
        }
        if ([_monitorDictionary objectForKey:context]) {
            [_monitorDictionary removeObjectForKey:context];
            [_monitorCountDictionary removeObjectForKey:context];
        } else {
            NSAssert(NO, @"You must first start monitoring in ViewController to stop monitoring");
        }
    });
#endif
}

+ (void)ignoreContext:(NSString *)context
{
#if DEBUG
    [self setup];
    dispatch_async(_serialQueue, ^{
        if (context) {
            [_ignoredContexts addObject:context];
        }
    });
#endif
}

@end
