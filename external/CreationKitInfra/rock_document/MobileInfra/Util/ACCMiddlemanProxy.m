//
//  ACCMiddlemanProxy.m
//  CameraClient-Pods-Aweme
//
//  Created by qiuhang on 2020/8/14.
//

#import "ACCMiddlemanProxy.h"

@implementation ACCMiddlemanProxy

- (BOOL)conformsToProtocol:(Protocol *)aProtocol {
    
    return ([self.originalDelegate conformsToProtocol:aProtocol] ||
            [self.middlemanDelegate conformsToProtocol:aProtocol]);
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    
    return ([self.originalDelegate respondsToSelector:aSelector] ||
            [self.middlemanDelegate respondsToSelector:aSelector]);
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    
    id methodSignature = [self.originalDelegate methodSignatureForSelector:sel];
    
    if (!methodSignature) {
        methodSignature = [self.middlemanDelegate methodSignatureForSelector:sel];
    }
    
    return methodSignature;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    
    if ([self.middlemanDelegate respondsToSelector:invocation.selector]) {
        
        [invocation invokeWithTarget:self.middlemanDelegate];
        
    } else if ([self.originalDelegate respondsToSelector:invocation.selector]) {
        
        [invocation invokeWithTarget:self.originalDelegate];
    }
}

- (NSString *)debugDescription {
    
    return [NSString stringWithFormat:@"originalDelegate is:%@\nmiddlemanDelegate is:%@\n",
            self.originalDelegate, self.middlemanDelegate];
}

@end
