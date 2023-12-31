//
//  BDPMultiDelegateProxy.m
//  Timor
//
//  Created by dingruoshan on 2019/4/3.
//

#import "BDPMultiDelegateProxy.h"

@interface BDPMultiDelegateProxy ()

@property (nonatomic, strong) NSPointerArray *delegates;

@end

@implementation BDPMultiDelegateProxy

- (id)init
{
    return [self initWithDelegates:nil];
}

- (id)initWithDelegate:(id)delegate
{
    if (delegate) {
        return [self initWithDelegates:@[delegate]];
    }
    return nil;
}

- (id)initWithDelegates:(nullable NSArray*)delegates
{
    self = [super init];
    if (self) {
        _delegates = [NSPointerArray weakObjectsPointerArray];
        for (id delegate in delegates) {
            [_delegates addPointer:(__bridge void *)delegate];
        }
    }
    return self;
}

- (NSUInteger)count
{
    return _delegates.count;
}

- (NSArray *)allObjects
{
    return _delegates.allObjects;
}

- (void)addDelegate:(id)delegate
{
    if (delegate) {
        [_delegates addPointer:(__bridge void *)delegate];
    }
}

- (NSUInteger)indexOfDelegate:(id)delegate
{
    for (NSUInteger i = 0; i < _delegates.count; i += 1) {
        if ([_delegates pointerAtIndex:i] == (__bridge void *)delegate) {
            return i;
        }
    }
    return NSNotFound;
}

- (void)addDelegate:(id)delegate beforeDelegate:(id)otherDelegate
{
    if (delegate) {
        NSUInteger index = [self indexOfDelegate:otherDelegate];
        if (index == NSNotFound)
            index = _delegates.count;
        [_delegates insertPointer:(__bridge void *)delegate atIndex:index];
    }
}

- (void)addDelegate:(id)delegate afterDelegate:(id)otherDelegate
{
    if (delegate) {
        NSUInteger index = [self indexOfDelegate:otherDelegate];
        if (index == NSNotFound)
            index = 0;
        else
            index += 1;
        [_delegates insertPointer:(__bridge void *)delegate atIndex:index];
    }
}

- (void)removeDelegate:(id)delegate
{
    NSUInteger index = [self indexOfDelegate:delegate];
    if (index != NSNotFound)
        [_delegates removePointerAtIndex:index];
    [self compactDelegates];
}

- (void)removeAllDelegates
{
    for (NSUInteger i = _delegates.count; i > 0; i -= 1)
        [_delegates removePointerAtIndex:i - 1];
}

- (BOOL)respondsToSelector:(SEL)selector
{
    if ([super respondsToSelector:selector])
        return YES;
    
    for (id delegate in _delegates) {
        if (delegate && [delegate respondsToSelector:selector])
            return YES;
    }
    
    return NO;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (signature)
        return signature;
    
    [self compactDelegates];
    if (self.silentWhenEmpty && _delegates.count == 0) {
        // return any method signature, it doesn't really matter
        return [self methodSignatureForSelector:@selector(description)];
    }
    
    for (id delegate in _delegates) {
        if (!delegate)
            continue;
        
        signature = [delegate methodSignatureForSelector:selector];
        if (signature)
            break;
    }

    if (signature == nil) {
          /// to avoid nil methodSignature caused crash
          return [self methodSignatureForSelector:@selector(description)];
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    SEL selector = [invocation selector];
    BOOL responded = NO;
    
    NSArray *copiedDelegates = [_delegates copy];
    for (id delegate in copiedDelegates) {
        if (delegate && [delegate respondsToSelector:selector]) {
            [invocation invokeWithTarget:delegate];
            responded = YES;
        }
    }
    
    if (!responded && !self.silentWhenEmpty)
        [self doesNotRecognizeSelector:selector];
}

- (void)compactDelegates
{
    // NSPointerArray.compact doesn't work..! Should remove null entries but doesn't!
    // workaround from https://gist.github.com/sberan/6342401d78674c3831ba
    for (NSInteger i = self.count - 1; i >= 0; i--) {
        id obj = [_delegates pointerAtIndex:(NSUInteger)i];
        if (!obj) {
            [_delegates removePointerAtIndex:(NSUInteger)i];
        }
    }
}

@end
