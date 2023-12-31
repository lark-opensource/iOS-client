//
//  BaseDelegateProxy.m
//  LarkWebViewContainer
//
//  Created by houjihu on 2020/9/1.
//

#import "BaseDelegateProxy.h"

@implementation BaseDelegateProxy

- (instancetype)initWithDelegate:(id)delegate changeDelegateBlock:(os_block_t)changeDelegateBlock {
    if (self = [super init]) {
        _changeDelegateBlock = changeDelegateBlock;
        self.internDelegate = delegate;
    }
    return self;
}

- (void)dealloc {
    self.internDelegate = nil;
}

#pragma mark - Manage Delegate

- (void)setInternDelegate:(id)internDelegate {
    _internDelegate = internDelegate;
    if (self.changeDelegateBlock) {
        self.changeDelegateBlock();
    }
}

#pragma mark - Message Forwarding

- (BOOL)respondsToSelector:(SEL)aSelector {
    if ([super respondsToSelector:aSelector]) {
        return YES;
    }

    return [self.internDelegate respondsToSelector:aSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *methodSignature = [super methodSignatureForSelector:aSelector];
    if (methodSignature) {
        return methodSignature;
    }

    methodSignature = [self.internDelegate methodSignatureForSelector:aSelector];
    if (methodSignature) {
        return methodSignature;
    }

    // This causes a crash...
    // return [super methodSignatureForSelector:aSelector];

    // This also causes a crash...
    // return nil;

    return [self methodSignatureForSelector:@selector(description)];
}

- (void)forwardInvocation:(NSInvocation *)anInvocation {
    SEL aSelector = anInvocation.selector;
    // 检查是否能够响应消息
    if ([self.internDelegate respondsToSelector:aSelector]) {
        // 处理事件
        [anInvocation invokeWithTarget:self.internDelegate];
    }
}

/// Prevent NSInvalidArgumentException
- (void)doesNotRecognizeSelector:(SEL)aSelector { }

@end
