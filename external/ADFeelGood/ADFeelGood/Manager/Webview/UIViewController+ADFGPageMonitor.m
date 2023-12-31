//
//  UIViewController+ADFGPageMonitor.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/1/11.
//

#import "UIViewController+ADFGPageMonitor.h"
#import <objc/runtime.h>

@implementation UIViewController (ADFGPageMonitor)
@dynamic adfgViewDidDisappearBlock;

+ (void)setupSwizzleMethod
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self adfg_swizzleInstanceMethod:@selector(viewDidDisappear:) with:@selector(adfg_viewWillDisappear:)];
    });
}

+ (BOOL)adfg_swizzleInstanceMethod:(nonnull SEL)origSelector with:(nonnull SEL)newSelector
{
    Method originalMethod = class_getInstanceMethod(self, origSelector);
    Method swizzledMethod = class_getInstanceMethod(self, newSelector);
    if (!originalMethod || !swizzledMethod) {
        return NO;
    }
    if (class_addMethod(self,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(self,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        class_replaceMethod(self,
                            newSelector,
                            class_replaceMethod(self,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
    return YES;
}

- (void)adfg_viewWillDisappear:(BOOL)animated
{
    [self adfg_viewWillDisappear:animated];
    
    if (self.adfgViewDidDisappearBlock) {
        self.adfgViewDidDisappearBlock(animated);
    }
}

- (void)setAdfgViewDidDisappearBlock:(ADFGViewDidDisappear)adfgViewDidDisappearBlock
{
    objc_setAssociatedObject(self, @selector(adfgViewDidDisappearBlock), adfgViewDidDisappearBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (ADFGViewDidDisappear)adfgViewDidDisappearBlock
{
    return objc_getAssociatedObject(self, _cmd);
}

@end
