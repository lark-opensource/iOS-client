//
//  UITableView+crashProtect.m
//  LarkCrashSanitizer
//
//  Created by 李晨 on 2021/2/26.
//

#import "UITableView+crashProtect.h"
#import "LKHookUtil.h"
#import <LKLoadable/Loadable.h>
#import <UIKit/UIKit.h>

/// 用于持有当前第一响应者
@interface FirstResponderWrapper : NSObject
@property(nonatomic, weak) UIResponder* value;
@end
@implementation FirstResponderWrapper
+ (instancetype)shared{
    static FirstResponderWrapper *wrapper = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        wrapper = [[self alloc] init];
    });
    return wrapper;
}
@end

@interface UIResponder (FindFirstResponder)
@end

@implementation UIResponder (FindFirstResponder)

/// 获取当前第一响应者
+(UIResponder *)safe_findFirstResponder {
    [FirstResponderWrapper shared].value = NULL;
    [[UIApplication sharedApplication] sendAction:@selector(safe_findFirstResponder:) to:NULL from:NULL forEvent:NULL];
    return [FirstResponderWrapper shared].value;
}

- (void)safe_findFirstResponder:(UIResponder *) responder {
    [FirstResponderWrapper shared].value = self;
}

@end

@implementation UITableView (crashProtect)

- (void)safe_deleteSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [self safe_tableAnimationForSections: sections];
    [self safe_deleteSections: sections withRowAnimation: animation];
}

- (void)safe_deleteRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [self safe_tableAnimationForIndexPaths: indexPaths];
    [self safe_endEditingForIndexPaths: indexPaths];
    [self safe_deleteRowsAtIndexPaths: indexPaths withRowAnimation: animation];
}

- (void)safe_reloadSections:(NSIndexSet *)sections withRowAnimation:(UITableViewRowAnimation)animation {
    [self safe_tableAnimationForSections: sections];
    [self safe_reloadSections: sections withRowAnimation: animation];
}

- (void)safe_reloadRowsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths withRowAnimation:(UITableViewRowAnimation)animation {
    [self safe_tableAnimationForIndexPaths: indexPaths];
    [self safe_endEditingForIndexPaths: indexPaths];
    [self safe_reloadRowsAtIndexPaths: indexPaths withRowAnimation: animation];
}

/// 以安全的方式刷新 table sections，如果需要刷新的 cell 存在第一响应者，则调用 endEditing
- (void)safe_tableAnimationForSections:(NSIndexSet *)sections {
    UITableViewCell* cell = [self findFirstResponderCell];
    if (cell == NULL) {
        return;
    }
    NSIndexPath* index = [self indexPathForCell:cell];
    if ([sections containsIndex:index.section]) {
        [cell endEditing: YES];
    }
}

/// 以安全的方式刷新 table indexPaths，如果需要刷新的 cell 存在第一响应者，则调用 endEditing
- (void)safe_tableAnimationForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    UITableViewCell* cell = [self findFirstResponderCell];
    if (cell == NULL) {
        return;
    }
    NSIndexPath* index = [self indexPathForCell:cell];
    if ([indexPaths containsObject:index]) {
        [cell endEditing: YES];
    }
}

- (void)safe_endEditingForIndexPaths:(NSArray<NSIndexPath *> *)indexPaths {
    [indexPaths enumerateObjectsUsingBlock:^(NSIndexPath * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        UITableViewCell* cell = [self cellForRowAtIndexPath:obj];
        [cell endEditing: true];
    }];
}

/// 找到包含的第一响应者的 cell，如果不存在 返回 nil
- (UITableViewCell *)findFirstResponderCell {
    UIResponder* first = [UIResponder safe_findFirstResponder];
    UIResponder* nextResponder = first;
    UIResponder* beforeResponder;
    while (nextResponder != NULL) {
        if (nextResponder == self &&
            [beforeResponder isKindOfClass:[UITableViewCell class]]) {
            return (UITableViewCell *)beforeResponder;
        }
        beforeResponder = nextResponder;
        nextResponder = nextResponder.nextResponder;
    }
    return NULL;
}

@end

/*
 UITableView 动画刷新过程中 如果 cell 上存在 firstResponder 会导致崩溃
 通过 hook 的方式保证先 endEditing, 再执行刷新动画
 */
LoadableRunloopIdleFuncBegin(LarkCrashSanitizer_tableView_crashProtect)
SwizzleMethod([UITableView class], NSSelectorFromString(@"deleteSections:withRowAnimation:"), [UITableView class], @selector(safe_deleteSections:withRowAnimation:));
SwizzleMethod([UITableView class], NSSelectorFromString(@"deleteRowsAtIndexPaths:withRowAnimation:"), [UITableView class], @selector(safe_deleteRowsAtIndexPaths:withRowAnimation:));
SwizzleMethod([UITableView class], NSSelectorFromString(@"reloadSections:withRowAnimation:"), [UITableView class] , @selector(safe_reloadSections:withRowAnimation:));
SwizzleMethod([UITableView class], NSSelectorFromString(@"reloadRowsAtIndexPaths:withRowAnimation:"), [UITableView class], @selector(safe_reloadRowsAtIndexPaths:withRowAnimation:));
LoadableRunloopIdleFuncEnd(LarkCrashSanitizer_tableView_crashProtect)
