//
//  LynxUI+BDXLynx.m
//  BDXElement
//
//  Created by li keliang on 2020/3/17.
//

#import "LynxUI+BDXLynx.h"
#import <Lynx/LynxLazyLoad.h>
#import <ByteDanceKit/NSObject+BTDAdditions.h>
#import <objc/runtime.h>

@implementation LynxUI (BDXLynx)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
LYNX_LOAD_LAZY(
    [self btd_swizzleInstanceMethod:@selector(insertChild:atIndex:) with:@selector(bdx_insertChild:atIndex:)];
               [self btd_swizzleInstanceMethod:@selector(super_insertChild:atIndex:) with:@selector(bdx_super_insertChild:atIndex:)];
    [self btd_swizzleInstanceMethod:@selector(removeChild:atIndex:) with:@selector(bdx_removeChild:atIndex:)];
)
#pragma clang diagnostic pop

- (void)bdx_insertChild:(LynxUI *)child atIndex:(NSInteger)index
{
    if ([child isKindOfClass:LynxUI.class] && child.bdx_inhibitParentLayout) {
        return;
    }
    [self bdx_insertChild:child atIndex:index];
}

- (void)bdx_super_insertChild:(LynxUI*)child atIndex:(NSInteger)index
{
    if ([child isKindOfClass:LynxUI.class] && child.bdx_inhibitParentLayout) {
        return;
    }
    [self bdx_super_insertChild:child atIndex:index];
}

- (void)bdx_removeChild:(LynxUI *)child atIndex:(NSInteger)index
{
    if ([child isKindOfClass:LynxUI.class] && child.bdx_inhibitParentLayout) {
        return;
    }
    [self bdx_removeChild:child atIndex:index];
}

- (BOOL)bdx_inhibitParentLayout
{
    return [objc_getAssociatedObject(self, _cmd) boolValue];
}

- (void)setBdx_inhibitParentLayout:(BOOL)bdx_inhibitParentLayout
{
    objc_setAssociatedObject(self, @selector(bdx_inhibitParentLayout), @(bdx_inhibitParentLayout), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
