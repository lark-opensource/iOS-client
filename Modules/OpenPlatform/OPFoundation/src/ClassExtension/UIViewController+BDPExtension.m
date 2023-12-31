//
//  UIViewController+BDPExtension.m
//  Timor
//
//  Created by liuxiangxin on 2019/9/26.
//

#import "UIViewController+BDPExtension.h"
#import <objc/runtime.h>
#import <ECOInfra/OPMacroUtils.h>

typedef void(^_BDPPresentAction)(UIViewController *fromController);

@implementation UIViewController (BDPExtension)

- (void)bdp_presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(dispatch_block_t)completion
{
    
    if (self.bdp_excutePresenting) {
        WeakSelf;
        _BDPPresentAction presentTask = ^(UIViewController *fromController){
            StrongSelfIfNilReturn;
            
            [fromController bdp_presentViewController:controller animated:animated completion:completion];
        };
        
        [[self bdp_presentQueue] addObject:presentTask];
        
        return;
    }
    
    self.bdp_excutePresenting = YES;
    [self presentViewController:controller animated:animated completion:^{
        if (completion) {
            completion();
        }
        self.bdp_excutePresenting = NO;
        
        for (_BDPPresentAction action in [self bdp_presentQueue]) {
            action(controller);
        }
        [[self bdp_presentQueue] removeAllObjects];
    }];
    
    return;


}

#pragma mark - Getter && Setter

- (NSMutableArray<_BDPPresentAction> *)bdp_presentQueue
{
    NSMutableArray<_BDPPresentAction> *queue = objc_getAssociatedObject(self, @selector(bdp_presentQueue));
    if (!queue) {
        queue = [NSMutableArray array];
        objc_setAssociatedObject(self, @selector(bdp_presentQueue), queue, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return queue;
}

- (BOOL)bdp_isExcutePresenting
{
    return [self bdp_excutePresenting];
}

- (BOOL)bdp_excutePresenting
{
    return [objc_getAssociatedObject(self, @selector(bdp_excutePresenting)) boolValue];
}

- (void)setBdp_excutePresenting:(BOOL)bdp_excutePresenting
{
    objc_setAssociatedObject(self, @selector(bdp_excutePresenting), @(bdp_excutePresenting), OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
