//
//  RtcObjcProxy.m
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/23.
//

#import "RtcObjcProxy.h"

@interface RtcObjcProxy()

@property (strong, nonatomic) id target;
@property (copy, nonatomic) RtcObjcProxyHandler handler;

@end

@implementation RtcObjcProxy

- (instancetype)initWithTarget:(id)target handler:(RtcObjcProxyHandler)handler {
    _target = target;
    _handler = handler;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    self.handler(^{
        [invocation setTarget:self.target];
        [invocation invoke];
    });
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

@end
