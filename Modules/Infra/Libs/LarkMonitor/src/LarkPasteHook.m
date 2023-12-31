//
//  LarkPasteHook.m
//  LarkMonitor
//
//  Created by sniperj on 2021/10/18.
//

#import "LarkPasteHook.h"
#import <LarkMonitor/LarkMonitor-swift.h>
#import <LKLoadable/Loadable.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LarkMonitor.h"

LoadableRunloopIdleFuncBegin(LarkPasteHook)

[LarkPasteHook swizzleMethod:NSClassFromString(@"UICalloutBar") withSel:NSSelectorFromString(@"_updateVisibleItemsAnimated:") exchangeClass:[LarkPasteHook class] newSel:@selector(my_updateVisibleItemsAnimated:)];
[LarkPasteHook swizzleMethod:NSClassFromString(@"UICalloutBar") withSel:NSSelectorFromString(@"appear") exchangeClass:[LarkPasteHook class] newSel:@selector(myappear)];

LoadableRunloopIdleFuncEnd(LarkPasteHook)

@implementation LarkPasteHook

+ (void)swizzleMethod:(Class)_originClass withSel:(SEL)_originSelector exchangeClass:(Class)_newClass newSel:(SEL)_newSelector {
    Method oriMethod = class_getInstanceMethod(_originClass, _originSelector);
    Method newMethod = class_getInstanceMethod(_newClass, _newSelector);
    class_addMethod(_originClass, _newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    BOOL isAddedMethod = class_addMethod(_originClass, _originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    if (isAddedMethod) {
        class_replaceMethod(_originClass, _newSelector, method_getImplementation(oriMethod), method_getTypeEncoding(oriMethod));
    } else {
        method_exchangeImplementations(oriMethod, newMethod);
    }
}

- (int)my_updateVisibleItemsAnimated:(id)ani {
    int res = [self my_updateVisibleItemsAnimated:ani];
    [LarkAllActionLoggerLoad logNarmalInfoWithInfo:[NSString stringWithFormat:@"paste meun track updateVisibleItemAnimated %d", res]];
    if (res == 0) {
        // lint:disable:next lark_storage_check
        if ([[NSUserDefaults standardUserDefaults] boolForKey:@"lark.menu.forbid.force.show"]) {
            [LarkPasteHook logMenuBarInfo: (UIView *)self];
            return res;
        } else {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
                [LarkMonitor trackService:@"ios_menu_hidden" metric:@{@"itms": @"0"} category:nil extra:nil];
            });
            int updateRes = [LarkPasteHook shouldShowMenuForView:(UIView *)self];
            [LarkAllActionLoggerLoad logNarmalErrorWithError: [NSString stringWithFormat:@"paste meun track hide.invalid.items: updateVisibleItemAnimated: %d", updateRes]];
            return updateRes;
        }
    }
    return res;
}

- (void)myappear {
    [LarkAllActionLoggerLoad logNarmalInfoWithInfo:@"paste menu track appear"];
    [self myappear];
}

+ (int)shouldShowMenuForView:(UIView *) bar {
    /// 如果FG关闭 由原有的逻辑
    // lint:disable:next lark_storage_check
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"lark.menu.hide.invalid.items"] == NO) {
        return 1;
    }
    if ([bar isKindOfClass:NSClassFromString([LarkPasteHook MenuBarNameStr])]) {
        if (![LarkPasteHook hasEffectiveMenuItemsForCallOutBar:bar]) {
            return 0;
        }
    }
    return 1;
}

+ (BOOL)hasEffectiveMenuItemsForCallOutBar:(UIView *)bar {
    UIView *callOutBarContentView = bar.subviews.lastObject;
    BOOL hasMenuItem = NO;
    NSString* buttonStr = [LarkPasteHook MenuBarButtonNameStr];
    for (int i = 0; i < callOutBarContentView.subviews.count; i++) {
        UIView *item = callOutBarContentView.subviews[i];
        if ([item isKindOfClass:NSClassFromString(buttonStr)] && !item.isHidden && item.frame.size.width > 0 && item.frame.size.height > 0) {
            hasMenuItem = YES;
            break;
        }
    }
    return  hasMenuItem;
}

+ (void)logMenuBarInfo:(UIView *)bar {
    if ([bar isKindOfClass:NSClassFromString([LarkPasteHook MenuBarNameStr])]) {
        BOOL hasMenuItem = [LarkPasteHook hasEffectiveMenuItemsForCallOutBar:bar];
        /// 这里取UI属性不能放在异步线程
        NSMutableDictionary * category = [[NSMutableDictionary alloc]init];
        category[@"hasSuperview"] = @(bar.superview != nil);
        category[@"isHidden"] = @(bar.isHidden);
        category[@"hasItems"] = @(hasMenuItem);
        /// 检测矩形是否长度或者宽度为0
        category[@"frame"] = CGRectIsEmpty(bar.frame) ? @"empty": @(bar.frame.size.width).stringValue;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
            /// 上报一下不展示时候的埋点
            [LarkMonitor trackService:@"menu_update_Items_hide" metric: nil category: category extra:nil];
        });
        [LarkAllActionLoggerLoad logNarmalInfoWithInfo:
         [NSString stringWithFormat:@"paste meun track info superView: %d isHidden: %d frame: %@ hasMenuItem: %d",bar.superview != nil, bar.isHidden, NSStringFromCGRect(bar.frame), hasMenuItem]];
    } else {
        [LarkAllActionLoggerLoad logNarmalErrorWithError:@"paste meun track forbid.force.show: error bar type"];
    }
}

+ (NSString*)MenuBarNameStr {
    return @"UICalloutBar";
}

+ (NSString*)MenuBarButtonNameStr {
    return @"UICalloutBarButton";
}
@end
