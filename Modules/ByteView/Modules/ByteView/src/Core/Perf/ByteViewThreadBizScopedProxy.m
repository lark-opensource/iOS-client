//
//  ByteViewThreadBizScopedProxy.m
//  ByteView
//
//  Created by liujianlong on 2023/4/11.
//

#import "ByteViewThreadBizScopedProxy.h"

@interface ByteViewThreadBizScopedProxy()

@property(strong, nonatomic) id target;

@end

@implementation ByteViewThreadBizScopedProxy

- (instancetype)initWithScope:(ByteViewThreadBizScope)scope target:(id)target {
    _scope = scope;
    _target = target;
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    return [self.target methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation setTarget:self.target];
    ByteViewThreadBizScope oldScope = byteview_set_current_biz_scope(self.scope);
    [invocation invoke];
    byteview_set_current_biz_scope(oldScope);
    return;
}

- (BOOL)respondsToSelector:(SEL)aSelector {
    return [self.target respondsToSelector:aSelector];
}

@end
