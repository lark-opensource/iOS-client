//
//  IESGurdDelegateDispatcher.m
//  IESGeckoKit
//
//  Created by chenyuchuan on 2019/6/5.
//

#import "IESGurdDelegateDispatcher.h"

#import <objc/runtime.h>
#import <pthread/pthread.h>

static pthread_rwlock_t delegates_rwlock = PTHREAD_RWLOCK_INITIALIZER;

@interface IESGurdDelegateDispatcher ()

@property (nonatomic, strong) Protocol *protocol;

@property (nonatomic, strong) NSHashTable *delegatesHashTable;

@end

@implementation IESGurdDelegateDispatcher

+ (instancetype)dispatcherWithProtocol:(Protocol *)protocol
{
    if (!protocol) {
        return nil;
    }
    IESGurdDelegateDispatcher *dispatcher = [[IESGurdDelegateDispatcher alloc] init];
    dispatcher.protocol = protocol;
    return dispatcher;
}

- (void)dealloc
{
    pthread_rwlock_destroy(&delegates_rwlock);
}

#pragma mark - Public

- (void)registerDelegate:(id)delegate
{
    pthread_rwlock_wrlock(&delegates_rwlock);
    [self.delegatesHashTable addObject:delegate];
    pthread_rwlock_unlock(&delegates_rwlock);
}

- (void)unregisterDelegate:(id)delegate
{
    pthread_rwlock_wrlock(&delegates_rwlock);
    [self.delegatesHashTable removeObject:delegate];
    pthread_rwlock_unlock(&delegates_rwlock);
}

#pragma mark - Message forard

- (BOOL)respondsToSelector:(SEL)aSelector
{
    BOOL canResponds = NO;
    pthread_rwlock_rdlock(&delegates_rwlock);
    for (id delegate in self.delegatesHashTable) {
        if ([delegate respondsToSelector:aSelector]) {
            canResponds = YES;
            break;
        }
    }
    pthread_rwlock_unlock(&delegates_rwlock);
    return canResponds;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    NSMethodSignature *methodSignature = [super methodSignatureForSelector:aSelector];
    if (methodSignature) {
        return methodSignature;
    }
    Protocol *protocol = self.protocol;
    struct objc_method_description description = protocol_getMethodDescription(protocol, aSelector, YES, YES);
    if (description.types == NULL) {
        description = protocol_getMethodDescription(protocol, aSelector, NO, YES);
    }
    if (description.types != NULL) {
        return [NSMethodSignature signatureWithObjCTypes:description.types];
    }
    //防Crash
    return [NSMethodSignature signatureWithObjCTypes:"v@:"];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    pthread_rwlock_rdlock(&delegates_rwlock);
    NSArray *delegates = self.delegatesHashTable.allObjects;
    pthread_rwlock_unlock(&delegates_rwlock);
    
    for (id delegate in delegates) {
        if ([delegate respondsToSelector:anInvocation.selector]) {
            [anInvocation invokeWithTarget:delegate];
        }
    }
}

#pragma mark - Getter

- (NSHashTable *)delegatesHashTable
{
    if (!_delegatesHashTable) {
        _delegatesHashTable = [NSHashTable weakObjectsHashTable];
    }
    return _delegatesHashTable;
}

@end
