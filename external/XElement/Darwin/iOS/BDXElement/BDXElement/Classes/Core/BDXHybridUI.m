//
//  BDXHybridUI.m
//  BDXElement
//
//  Created by li keliang on 2020/11/23.
//

#import "BDXHybridUI.h"
#import <objc/runtime.h>

@implementation BDXHybridUI

+ (NSString *)tagName
{
    return @"";
}

- (nonnull UIView *)view
{
    UIView *view = objc_getAssociatedObject(self, _cmd);
    if (!view) {
        view = [self createView];
        objc_setAssociatedObject(self, _cmd, view, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return view;
}

- (nonnull UIView *)createView
{
    return [UIView new];
}

- (void)layoutDidFinished
{
    
}

- (void)updateAttribute:(NSString *)attribute value:(__nullable id)value requestReset:(BOOL)requestReset
{
    NSString *methodName = [NSString stringWithFormat:@"bdx_%@:requestReset:", attribute];
    SEL selector = NSSelectorFromString(methodName);
    // TODO: 类型转换
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    if ([self respondsToSelector:selector]) {
        [self performSelector:selector withObject:value withObject:requestReset ? @(YES) : nil];
    }
#pragma clang diagnostic pop
}

@end
