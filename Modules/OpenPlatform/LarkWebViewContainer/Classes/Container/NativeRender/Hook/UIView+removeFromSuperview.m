//
//  UIView+removeFromSuperview.m
//  LarkWebViewContainer
//
//  Created by baojianjun on 2022/7/20.
//

#import "UIView+removeFromSuperview.h"
#import <objc/runtime.h>
#import "NSObject+RuntimeExtension.h"
#import <LarkWebViewContainer/LarkWebViewContainer-Swift.h>

@implementation UIView (LWRemoveFromSuperview)

- (void)hook_removeFromSuperview
{
    NSHashTable<RenderState *> *hashTable = [self lkw_renderObjects];
    if ((hashTable && [hashTable isKindOfClass:NSHashTable.class] && hashTable.count > 0)) {
        [hashTable.allObjects enumerateObjectsUsingBlock:^(RenderState * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.superviewWillBeRemoved = YES;
        }];
    }
    [self hook_removeFromSuperview];
}

- (void)addNativeRenderState:(RenderState *)state
{
    if (!(state && [state isKindOfClass:RenderState.class])) {
        return;
    }
    NSHashTable<RenderState *> *hashTable = [self lkw_renderObjects];
    if (!(hashTable && [hashTable isKindOfClass:NSHashTable.class] && hashTable.count > 0)) {
        hashTable = [NSHashTable hashTableWithOptions:NSPointerFunctionsWeakMemory];
    }
    [hashTable addObject:state];
    [self setLkw_renderObjects:hashTable];
}

- (void)setLkw_renderObjects:(NSHashTable<RenderState *> *)lkw_renderObjects
{
    objc_setAssociatedObject(self, @selector(lkw_renderObjects), lkw_renderObjects, OBJC_ASSOCIATION_RETAIN);
}

- (NSHashTable<RenderState *> *)lkw_renderObjects
{
    return objc_getAssociatedObject(self, @selector(lkw_renderObjects));
}

@end
