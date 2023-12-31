//
//  BDXLazyLoadProxy.m
//  BulletX
//
//  Created by bytedance on 2021/5/25.
//

#import "BDXLazyLoadProxy.h"

@interface BDXLazyLoadProxy ()

@property(nonatomic,strong)NSMutableArray* methodsChain;
@property(nonatomic,strong)Class targetClass;
@property(nonatomic,copy)BOOL (^selectorFilter)(SEL);

@end

@implementation BDXLazyLoadProxy

-(id)initWithTargetClass:(Class)targetClass{
    
    return [self initWithTargetClass:targetClass filter:^BOOL(SEL sel) {
        return YES;
    }];
}

-(id)initWithTargetClass:(Class)targetClass filter:(BOOL(^)(SEL))filterSelector{
    
    if (nil == targetClass) {
        return nil;
    }
    
    _targetClass = targetClass;
    
    self.selectorFilter = filterSelector;
    
    return self;

}


-(void)forwardInvocation:(NSInvocation *)invocation{
    
    if (invocation && self.selectorFilter && self.selectorFilter(invocation.selector)) {
        
        [invocation retainArguments];
        [self.methodsChain addObject:invocation];
    }
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel{
    
    NSMethodSignature* result = [self.targetClass instanceMethodSignatureForSelector:sel];
    
    return result;
}

-(NSMutableArray*)methodsChain{
    if (!_methodsChain) {
        _methodsChain = [[NSMutableArray alloc] init];
    }
    return _methodsChain;
}


/// 把方法应用与object
/// @param target target
/// @param clean 清除所有方法，默认yes，如果为NO，可以多次调用此方法
-(void)applyToTarget:(NSObject*)target clean:(BOOL)clean{
    
    if (nil == target || nil == _targetClass) {
        return;
    }
    
    NSAssert([target isKindOfClass:_targetClass], ([NSString stringWithFormat:@"%@ is not instance of class:%@",target,NSStringFromClass(_targetClass)]));
    
    if (_methodsChain && _methodsChain.count>0) {
        @synchronized (self) {
            for (NSInvocation* invocation in _methodsChain) {
                [invocation invokeWithTarget:target];
            }
        }
    }
    if (clean) {
        [self clean];
    }
}

-(void)applyToTarget:(NSObject*)target{
    [self applyToTarget:target clean:YES];
}

-(void)clean{
    if(_methodsChain){
        @synchronized (self) {
            [_methodsChain removeAllObjects];
            _methodsChain = nil;
        }
    }
}

@end
