//
//  NSObject+BTDBlockObservation.m
//  Pods
//
//  Created by bytedance on 2021/6/4.
//

#import <objc/runtime.h>
#import <objc/message.h>
#import "NSObject+BTDBlockObservation.h"
#import "NSObject+BTDAdditions.h"
#import "NSArray+BTDAdditions.h"

#pragma mark - Key Value Observation

typedef NS_ENUM(int, BTDObserverContext) {
    BTDObserverContextKey,
    BTDObserverContextKeyWithChange,
    BTDObserverContextManyKeys,
    BTDObserverContextManyKeysWithChange
};

@interface _BTDObserver : NSObject {
    BOOL _isObserving;
}

@property (nonatomic, readonly, unsafe_unretained) id observee;
@property (nonatomic, readonly) NSMutableArray *keyPaths;
@property (nonatomic, readonly) id task;
@property (nonatomic, readonly) BTDObserverContext context;

- (id)initWithObservee:(id)observee keyPaths:(NSArray *)keyPaths context:(BTDObserverContext)context task:(id)task;

@end

static NSString *BTDObserverBlocksKey = @"BTDObserverBlocksKey";
static void *BTDBlockObservationContext = &BTDBlockObservationContext;

@implementation _BTDObserver

- (id)initWithObservee:(id)observee keyPaths:(NSArray *)keyPaths context:(BTDObserverContext)context task:(id)task
{
    if ((self = [super init])) {
        _observee = observee;
        _keyPaths = [keyPaths mutableCopy];
        _context = context;
        _task = [task copy];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context != BTDBlockObservationContext) return;

    @synchronized(self) {
        if (!self.task) return;
        switch (self.context) {
            case BTDObserverContextKey: {
                void (^task)(id) = self.task;
                task(object);
                break;
            }
            case BTDObserverContextKeyWithChange: {
                void (^task)(id, NSDictionary *) = self.task;
                task(object, change);
                break;
            }
            case BTDObserverContextManyKeys: {
                void (^task)(id, NSString *) = self.task;
                task(object, keyPath);
                break;
            }
            case BTDObserverContextManyKeysWithChange: {
                void (^task)(id, NSString *, NSDictionary *) = self.task;
                task(object, keyPath, change);
                break;
            }
        }
    }
}

- (void)startObservingWithOptions:(NSKeyValueObservingOptions)options
{
    @synchronized(self) {
        if (_isObserving) return;

        [self.keyPaths btd_forEach:^(NSString *keyPath) {
            [self.observee addObserver:self forKeyPath:keyPath options:options context:BTDBlockObservationContext];
        }];

        _isObserving = YES;
    }
}

- (void)stopObservingKeyPath:(NSString *)keyPath
{
    if (!keyPath.length) {
        return;
    }

    @synchronized (self) {
        if (!_isObserving) return;
        if (![self.keyPaths containsObject:keyPath]) return;

        NSObject *observee = self.observee;
        if (!observee) return;

        [self.keyPaths removeObject: keyPath];
        keyPath = [keyPath copy];

        if (!self.keyPaths.count) {
            _task = nil;
            _observee = nil;
            _keyPaths = nil;
        }

        [observee removeObserver:self forKeyPath:keyPath context:BTDBlockObservationContext];
    }
}

- (void)_stopObservingLocked
{
    if (!_isObserving) return;

    _task = nil;

    NSObject *observee = self.observee;
    NSArray *keyPaths = [self.keyPaths copy];

    _observee = nil;
    _keyPaths = nil;

    [keyPaths btd_forEach:^(NSString *keyPath) {
        [observee removeObserver:self forKeyPath:keyPath context:BTDBlockObservationContext];
    }];
}

- (void)stopObserving
{
    if (_observee == nil) return;

    @synchronized (self) {
        [self _stopObservingLocked];
    }
}

- (void)dealloc
{
    if (self.keyPaths) {
        [self _stopObservingLocked];
    }
}

@end


@implementation NSObject (BTDBlockObservation)

- (NSString *)btd_addObserverForKeyPath:(NSString *)keyPath task:(void (^)(id target))task
{
    NSString *token = [[NSProcessInfo processInfo] globallyUniqueString];
    [self _btd_addObserverForKeyPaths:(keyPath ? @[keyPath]: nil) identifier:token options:0 context:BTDObserverContextKey task:task];
    return token;
}

- (NSString *)btd_addObserverForKeyPaths:(NSArray *)keyPaths task:(void (^)(id obj, NSString *keyPath))task
{
    NSString *token = [[NSProcessInfo processInfo] globallyUniqueString];
    [self _btd_addObserverForKeyPaths:keyPaths identifier:token options:0 context:BTDObserverContextManyKeys task:task];
    return token;
}

- (NSString *)btd_addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSDictionary *change))task
{
    NSString *token = [[NSProcessInfo processInfo] globallyUniqueString];
    [self btd_addObserverForKeyPath:keyPath identifier:token options:options task:task];
    return token;
}

- (NSString *)btd_addObserverForKeyPaths:(NSArray *)keyPaths options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSString *keyPath, NSDictionary *change))task
{
    NSString *token = [[NSProcessInfo processInfo] globallyUniqueString];
    [self btd_addObserverForKeyPaths:keyPaths identifier:token options:options task:task];
    return token;
}

- (void)btd_addObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)identifier options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSDictionary *change))task
{
    BTDObserverContext context = (options == 0) ? BTDObserverContextKey : BTDObserverContextKeyWithChange;
    [self _btd_addObserverForKeyPaths:(keyPath ? @[keyPath]: nil) identifier:identifier options:options context:context task:task];
}

- (void)btd_addObserverForKeyPaths:(NSArray *)keyPaths identifier:(NSString *)identifier options:(NSKeyValueObservingOptions)options task:(void (^)(id obj, NSString *keyPath, NSDictionary *change))task
{
    BTDObserverContext context = (options == 0) ? BTDObserverContextManyKeys : BTDObserverContextManyKeysWithChange;
    [self _btd_addObserverForKeyPaths:keyPaths identifier:identifier options:options context:context task:task];
}

- (void)btd_removeObserverForKeyPath:(NSString *)keyPath identifier:(NSString *)token
{
    if (!keyPath.length || !token.length) {
        return;
    }

    NSMutableDictionary *dict = nil;

    @synchronized (self) {
        dict = [self _btd_observerBlocks];
        if (!dict) return;
        
        _BTDObserver *observer = dict[token];
        [observer stopObservingKeyPath:keyPath];

        if (observer.keyPaths.count == 0) {
            [dict removeObjectForKey:token];
        }

        if (dict.count == 0) [self _btd_setObserverBlocks:nil];
    }
}

- (void)btd_removeObserversWithIdentifier:(NSString *)token
{
    if (!token.length) {
        return;
    }

    NSMutableDictionary *dict = nil;

    @synchronized (self) {
        dict = [self _btd_observerBlocks];
        if (!dict) return;
        
        _BTDObserver *observer = dict[token];
        [observer stopObserving];

        [dict removeObjectForKey:token];

        if (dict.count == 0) [self _btd_setObserverBlocks:nil];
    }
}

- (void)btd_removeAllBlockObservers
{
    NSDictionary *dict = nil;

    @synchronized (self) {
        dict = [[self _btd_observerBlocks] copy];
        [self _btd_setObserverBlocks:nil];
    }

    [dict.allValues btd_forEach:^(_BTDObserver *trampoline) {
        [trampoline stopObserving];
    }];
}

+ (NSMutableSet *)_btd_observedClassesHash
{
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });

    return swizzledClasses;
}

- (void)_btd_addObserverForKeyPaths:(NSArray *)keyPaths identifier:(NSString *)identifier options:(NSKeyValueObservingOptions)options context:(BTDObserverContext)context task:(id)task
{
    if (!keyPaths.count || !identifier.length || !task) {
        return;
    }

    Class classToSwizzle = self.class;
    NSMutableSet *classes = self.class._btd_observedClassesHash;
    @synchronized (classes) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if (![classes containsObject:className]) {
            SEL deallocSelector = sel_registerName("dealloc");
            
            __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
            
            id newDealloc = ^(__unsafe_unretained id objSelf) {
                [objSelf btd_removeAllBlockObservers];
                
                if (originalDealloc == NULL) {
                    struct objc_super superInfo = {
                        .receiver = objSelf,
                        .super_class = class_getSuperclass(classToSwizzle)
                    };
                    
                    void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                    msgSend(&superInfo, deallocSelector);
                } else {
                    originalDealloc(objSelf, deallocSelector);
                }
            };
            
            IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
            
            if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
                // The class already contains a method implementation.
                Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
                
                // We need to store original implementation before setting new implementation
                // in case method is called at the time of setting.
                originalDealloc = (void(*)(__unsafe_unretained id, SEL))method_getImplementation(deallocMethod);
                
                // We need to store original implementation again, in case it just changed.
                originalDealloc = (void(*)(__unsafe_unretained id, SEL))method_setImplementation(deallocMethod, newDeallocIMP);
            }
            
            [classes addObject:className];
        }
    }

    NSMutableDictionary *dict = nil;
    _BTDObserver *observer = [[_BTDObserver alloc] initWithObservee:self keyPaths:keyPaths context:context task:task];
    [observer startObservingWithOptions:options];

    @synchronized (self) {
        dict = [self _btd_observerBlocks];

        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
            [self _btd_setObserverBlocks:dict];
        }
        
        dict[identifier] = observer;
    }
}

- (void)_btd_setObserverBlocks:(NSMutableDictionary *)dict
{
    [self btd_attachObject:dict forKey:BTDObserverBlocksKey];
}

- (NSMutableDictionary *)_btd_observerBlocks
{
    return [self btd_getAttachedObjectForKey:BTDObserverBlocksKey];
}

@end

#pragma mark - Notification Observation

@interface _BTDNotificationObserver : NSObject

@property (nonatomic, readonly) id observer;

- (id)initWithNotification:(NSNotificationName)notification object:(nullable id)obj queue:(nullable NSOperationQueue *)queue task:(void (^_Nullable)(NSNotification * _Nonnull note))task;

- (void)_btd_removeNotification:(nullable NSNotificationName)notification object:(nullable id)anObject;

@end

@implementation _BTDNotificationObserver

- (id)initWithNotification:(NSNotificationName)notification object:(nullable id)obj queue:(nullable NSOperationQueue *)queue task:(void (^)(NSNotification * _Nonnull))task {
    if ((self = [super init])) {
        _observer = [[NSNotificationCenter defaultCenter] addObserverForName:notification object:obj queue:queue usingBlock:task];
    }
    return self;
}

- (void)_btd_removeNotification:(nullable NSNotificationName)notification object:(nullable id)anObject {
    [[NSNotificationCenter defaultCenter] removeObserver:_observer name:notification object:anObject];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:_observer];
}

@end

static NSString *BTDNotificationObserversKey = @"BTDNotificationObserversKey";

@implementation NSObject (BTDBlockNotificationObservation)

- (NSString *)btd_addObserverForNotification:(NSNotificationName)notification object:(nullable id)obj queue:(NSOperationQueue *)queue task:(void (^)(NSNotification * _Nonnull))task {
    if (!task) {
        return nil;
    }
    
    Class classToSwizzle = self.class;
    NSMutableSet *classes = self.class._btd_observedNotificationClassesHash;
    @synchronized (classes) {
        NSString *className = NSStringFromClass(classToSwizzle);
        if (![classes containsObject:className]) {
            SEL deallocSelector = sel_registerName("dealloc");
            
            __block void (*originalDealloc)(__unsafe_unretained id, SEL) = NULL;
            
            id newDealloc = ^(__unsafe_unretained id objSelf) {
                [objSelf btd_removeAllNotificationObservers];
                
                if (originalDealloc == NULL) {
                    struct objc_super superInfo = {
                        .receiver = objSelf,
                        .super_class = class_getSuperclass(classToSwizzle)
                    };
                    
                    void (*msgSend)(struct objc_super *, SEL) = (__typeof__(msgSend))objc_msgSendSuper;
                    msgSend(&superInfo, deallocSelector);
                } else {
                    originalDealloc(objSelf, deallocSelector);
                }
            };
            
            IMP newDeallocIMP = imp_implementationWithBlock(newDealloc);
            
            if (!class_addMethod(classToSwizzle, deallocSelector, newDeallocIMP, "v@:")) {
                // The class already contains a method implementation.
                Method deallocMethod = class_getInstanceMethod(classToSwizzle, deallocSelector);
                
                // We need to store original implementation before setting new implementation
                // in case method is called at the time of setting.
                originalDealloc = (void(*)(__unsafe_unretained id, SEL))method_getImplementation(deallocMethod);
                
                // We need to store original implementation again, in case it just changed.
                originalDealloc = (void(*)(__unsafe_unretained id, SEL))method_setImplementation(deallocMethod, newDeallocIMP);
            }
            
            [classes addObject:className];
        }
    }

    NSMutableDictionary *dict = nil;
    _BTDNotificationObserver *observer = [[_BTDNotificationObserver alloc] initWithNotification:notification object:obj queue:queue task:task];
    
    NSString *token = [[NSProcessInfo processInfo] globallyUniqueString];

    @synchronized (self) {
        dict = [self _btd_notificationObservers];

        if (dict == nil) {
            dict = [NSMutableDictionary dictionary];
            [self _btd_setNotificationObservers:dict];
        }
        
        dict[token] = observer;
    }
    return token;
}

- (NSString *)btd_addObserverForNotification:(NSNotificationName)notification task:(void (^)(NSNotification * _Nonnull))task {
    return [self btd_addObserverForNotification:notification object:nil queue:nil task:task];
}

- (void)btd_removeNotificationObserverWithIdentifier:(NSString *)token {
    if (!token) return;
    NSMutableDictionary *dict = nil;
    @synchronized (self) {
        dict = [self _btd_notificationObservers];
        if (!dict) return;
        
        [dict removeObjectForKey:token];

        if (dict.count == 0) [self _btd_setObserverBlocks:nil];
    }
}

- (void)btd_removeNotificationObserverWithIdentifier:(NSString *)token name:(NSNotificationName)aName object:(id)anObject {
    if (!token) return;
    NSMutableDictionary *dict = nil;
    _BTDNotificationObserver *observer = nil;
    @synchronized (self) {
        dict = [self _btd_notificationObservers];
        if (!dict) return;
        
        observer = dict[token];
    }
    [observer _btd_removeNotification:aName object:anObject];
}

- (void)btd_removeAllNotificationObservers {
    NSMutableDictionary *dict = nil;

    @synchronized (self) {
        dict = [self _btd_notificationObservers];
        [dict removeAllObjects];
        
        [self _btd_setObserverBlocks:nil];
    }
}

+ (NSMutableSet *)_btd_observedNotificationClassesHash
{
    static dispatch_once_t onceToken;
    static NSMutableSet *swizzledClasses = nil;
    dispatch_once(&onceToken, ^{
        swizzledClasses = [[NSMutableSet alloc] init];
    });

    return swizzledClasses;
}

- (void)_btd_setNotificationObservers:(NSMutableDictionary *)dict
{
    [self btd_attachObject:dict forKey:BTDNotificationObserversKey];
}

- (NSMutableDictionary *)_btd_notificationObservers
{
    return [self btd_getAttachedObjectForKey:BTDNotificationObserversKey];
}

@end
