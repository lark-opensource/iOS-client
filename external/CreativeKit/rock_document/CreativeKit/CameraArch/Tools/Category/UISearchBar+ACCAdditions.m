//
//  UISearchBar+ACCAdditions.m
//  Pods
//
// Created by Wang Xiao on June 24, 2019
//

#import "UISearchBar+ACCAdditions.h"
#import <objc/runtime.h>

@implementation UISearchBar (ACCAdditions)

- (void)setAcc_textField:(UITextField *)acc_textField
{
    objc_setAssociatedObject(self, _cmd, acc_textField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UITextField *)acc_textField
{
    UITextField *searchField;
#ifdef __IPHONE_13_0
    if (@available(iOS 13.0, *)) {
        searchField = self.searchTextField;
    } else {
        searchField = [self valueForKey:@"_searchField"];
    }
#else
    if ([[[UIDevice currentDevice] systemVersion] compare:@"13.0" options:NSNumericSearch] != NSOrderedAscending) {
        searchField = objc_getAssociatedObject(self, @selector(setAcc_textField:));
        if (!searchField) {
            searchField = [self findTextField];
            self.acc_textField = searchField;
        }
    } else {
        searchField = [self valueForKey:@"_searchField"];
    }
#endif
    return searchField;
}

- (UITextField *)findTextField
{
    NSMutableArray *subViewQueue = [NSMutableArray array];
    [subViewQueue addObjectsFromArray:self.subviews];
    while (subViewQueue.count > 0) {
        UIView *view = subViewQueue[0];
        [subViewQueue removeObjectAtIndex:0];
        if ([view isKindOfClass:[UITextField class]]) {
            return (UITextField *)view;
        } else {
            [subViewQueue addObjectsFromArray:view.subviews];
        }
    }
    return nil;
}

@end
