//
//  BDPCascadeStyleNode.m
//  Timor
//
//  Created by 刘相鑫 on 2019/10/11.
//

#import "BDPCascadeStyleNode.h"
#import "BDPWeakProxy.h"

@interface BDPCascadeStyleNode ()

@property (nonatomic, strong) NSMutableArray<NSInvocation *> *invocations;
@property (nonatomic, strong) BDPWeakProxy *sharedProxy;

@end

@implementation BDPCascadeStyleNode

#pragma mark - init

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sharedProxy = [BDPWeakProxy weakProxy:nil];
    }
    return self;
}

#pragma mark - Cascade Manage

- (void)addChildNode:(BDPCascadeStyleNode *)node
{
    if (!node) {
        return;
    }
    
    [node removeFromParentNode];
    [self.childNodes addObject:node];
    node.parentNode = self;
}

- (void)removeFromParentNode
{
    BDPCascadeStyleNode *parent = self.parentNode;
    self.parentNode = nil;
    [parent.childNodes removeObject:self];
}

#pragma mark - forwarding

- (void)forwardInvocation:(NSInvocation *)anInvocation
{
    [anInvocation retainArguments];
    
    [self.invocations addObject:anInvocation];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
{
    return [self.cls instanceMethodSignatureForSelector:aSelector];
}

#pragma mark - Style

- (void)applyStyleForObject:(id)sender
{
    for (NSInvocation *invocation in self.invocations) {
        if ([sender respondsToSelector:invocation.selector]) {
            self.sharedProxy.object = sender;
            [invocation invokeWithTarget:self.sharedProxy];
        }
    }
}

#pragma mark - Getter && Setter

- (NSMutableArray<BDPCascadeStyleNode *> *)childNodes
{
    if (!_childNodes) {
        _childNodes = [NSMutableArray array];
    }
    return _childNodes;
}

- (NSMutableArray<NSInvocation *> *)invocations
{
    if (!_invocations) {
        _invocations = [NSMutableArray array];
    }
    return _invocations;
}

@end
