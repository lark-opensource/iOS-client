//
//  MailDeallocHookAble.m
//  MailSDK
//
//  Created by tefeng liu on 2021/3/18.
//

#import "MailDeallocHookAble.h"
#import "NSObject+Runtime.h"
#import <objc/runtime.h>

@implementation MailDeallocHookAble

-(void)setLk_deallocAction:(MailDeallocBlock)deallocAction
{
    objc_setAssociatedObject(self, @selector(lk_deallocAction), deallocAction, OBJC_ASSOCIATION_COPY);
    [self mail_swizzleInstanceClassIsa:NSSelectorFromString(@"dealloc") withHookInstanceMethod:@selector(lk_native_render_dealloc)];
}

-(MailDeallocBlock)lk_deallocAction
{
    return objc_getAssociatedObject(self, @selector(lk_deallocAction));
}

- (void)lk_native_render_dealloc
{
    // 如果有先调用闭包
    if (self.lk_deallocAction) {
        self.lk_deallocAction(self);
    }
    [self lk_native_render_dealloc];
}

@end
