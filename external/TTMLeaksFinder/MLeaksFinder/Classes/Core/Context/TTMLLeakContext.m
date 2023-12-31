//
//  TTMLLeakContext.m
//  TTMLeaksFinder
//
//  Created by maruipu on 2020/11/3.
//

#import "TTMLLeakContext.h"
#import <objc/runtime.h>

@interface TTMLLeakContext ()

- (instancetype)initWithObject:(NSObject *)object;

@end

@implementation TTMLLeakContext

- (instancetype)initWithObject:(NSObject *)object {
    if (self = [super init]) {
        _viewStack = @[NSStringFromClass([object class])];
        _parentPtrs = [[NSSet alloc] initWithArray:@[@((uintptr_t)object)]];
    }
    return self;
}

@end


@interface TTMLLeakObject : NSObject
@property(nonatomic,weak) id obj;
@end

@implementation TTMLLeakObject

- (instancetype)initWith:(id)obj
{
    self = [super init];
    if (self) {
        _obj = obj;
    }
    return self;
}
- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[TTMLLeakObject class]]) {
        TTMLLeakObject *objcObject = object;
        return objcObject.obj == _obj;
    }
    return NO;
}

- (NSUInteger)hash
{
  return (size_t)_obj;
}

@end


@interface TTMLLeakContextMap ()
@property(nonatomic,strong)NSMapTable *LeakContextMap;
@property(nonatomic,strong)dispatch_semaphore_t semaphore;
@end

@implementation TTMLLeakContextMap

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    static TTMLLeakContextMap *instance = nil;
    dispatch_once(&onceToken, ^{
        instance = [[TTMLLeakContextMap alloc] init];
    });
    return instance;
}


- (id)init {
    self = [super init];
    if (self) {
        _LeakContextMap = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory
                                                        valueOptions:NSMapTableStrongMemory];
        _semaphore = dispatch_semaphore_create(1);
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return  self;
}


- (TTMLLeakContext *)ttml_leakContextOrNilOf:(id) obj{
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    TTMLLeakContext *context = [self.LeakContextMap objectForKey:[[TTMLLeakObject alloc] initWith:obj]];
    dispatch_semaphore_signal(_semaphore);
    return context;
}

- (TTMLLeakContext *)ttml_leakContextOf:(id) obj{
    if (!obj) {
        return nil;
    }
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    TTMLLeakContext *context = [self.LeakContextMap objectForKey:[[TTMLLeakObject alloc] initWith:obj]];
    if (context == nil) {
        context = [[TTMLLeakContext alloc] initWithObject:obj];
        [self.LeakContextMap setObject:context forKey:[[TTMLLeakObject alloc] initWith:obj]];
    }
    dispatch_semaphore_signal(_semaphore);
    return context;
}

- (BOOL)ttml_hasRetainCycleOf:(id)obj{
    if (!obj) {
        return NO;
    }
    TTMLLeakContext *context = [self ttml_leakContextOrNilOf:obj];
    if (context) {
        return context.cycles.count > 0;
    }
    return NO;
}

//进入后台清理map，防止map过大
- (void)appDidEnterBackground {
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    NSPointerArray *keyAry = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
    for (TTMLLeakObject *key in self.LeakContextMap) {
        if (!key.obj) {
            [keyAry addPointer:(__bridge void * _Nullable)(key)];
        }
    }
    for (id obj in keyAry) {
        if (obj) {
            [self.LeakContextMap removeObjectForKey:obj];
        }
    }
    dispatch_semaphore_signal(_semaphore);
}

@end
