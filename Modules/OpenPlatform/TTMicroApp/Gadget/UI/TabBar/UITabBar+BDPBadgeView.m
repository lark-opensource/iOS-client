//
//  UITabBar+BDPBadgeView.m
//  Timor
//
//  Created by owen on 2018/12/4.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "UITabBar+BDPBadgeView.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIView+BDPExtension.h>
#import "BDPTabBarPageController.h"
#import <OPFoundation/BDPStyleCategoryDefine.h>
#import <OPFoundation/UIView+BDPAppearance.h>
#import <ECOInfra/NSString+BDPExtension.h>
#import <OPFoundation/UIImage+BDPExtension.h>
#import <OPFoundation/BDPView.h>
#import <OPFoundation/BDPDeviceHelper.h>
#import <ECOInfra/BDPLog.h>

static NSString *const kEllipsisText = @"...";
static CGFloat const kTabBarRedDotBadgeHeight = 10;  // 不带数字的 Badge 高度
static CGFloat const kTabBarTextBadgeHeight = 16; // 带数字的 Badge 高度
static CGFloat const kTabBarTextBadgeTop = 2; // 带数字的 Badge Top

@implementation UITabBar (BDPBadgeView)

- (void)showTabBarRedDotWithIndex:(NSInteger)index {
    [self removeBadgeOnItemIndex:index];
    [self showBadgeOnItemIndex:index text:@""];
}

- (void)hideTabBarRedDotWithIndex:(NSInteger)index {
    [self removeBadgeOnItemIndex:index];
}

- (void)setTabBarBadgeWithIndex:(NSInteger)index text:(NSString *)text {
    [self removeBadgeOnItemIndex:index];
    [self showBadgeOnItemIndex:index text:text];
}

- (void)removeTabBarBadgeWithIndex:(NSInteger)index {
    [self removeBadgeOnItemIndex:index];
}

- (NSString *)trimmedText:(NSString *)text {
    if ([NSString bdp_isPureInt:text]) {
        NSInteger num = [text integerValue];
        if (num > 0) {
            if (num > 99) {
                return kEllipsisText;
            }
        }
    }

    NSUInteger textLength = [NSString bdp_textLength:text];
    if (textLength > 4) {
        return kEllipsisText;
    }
    return [text copy];
}

- (void)showBadgeOnItemIndex:(NSInteger)index text:(NSString *)text {
    BDPView *badgeView = [[BDPView alloc] init];
    badgeView.backgroundColor = [UIColor whiteColor];
    badgeView.tag = [self tagForItemIndex:index];
    BDPView *redView = [[BDPView alloc] init];
    redView.bdp_styleCategories = @[BDPStyleCategoryTabBarRedDot];
    [badgeView addSubview:redView];
    [self addSubview:badgeView];
    if (text.length > 0) {
        /**
         badge文本支持4个字符：
         1、数字：展示上限为双位数，超出数字数量统一展示为...
         2、文字：最大支持2个中文字符、4个英文字符，超出文字数量统一展示为 ...
         */
        text = [self trimmedText:text];

        UIView *contentView;
        if ([text isEqualToString:kEllipsisText]) {
            UIImage *ellipsisImg = [UIImage bdp_imageNamed:@"tabbar_badge_text_ellipsis"];
            UIImageView *ellipsisImageView = [[UIImageView alloc] initWithImage:ellipsisImg];
            ellipsisImageView.bdp_size = CGSizeMake(10, 10);
            contentView = ellipsisImageView;
        } else {
            UILabel *label = [[UILabel alloc] init];
            label.text = text;
            label.textColor = [UIColor whiteColor];
            label.font = [UIFont boldSystemFontOfSize:12];
            [label sizeToFit];
            contentView = label;
        }
        [badgeView addSubview:contentView];
        badgeView.bdp_size = CGSizeMake(contentView.bdp_width + 8, kTabBarTextBadgeHeight);
        // 如果宽比高小，做圆角之后会显示不正常
        if (badgeView.bdp_width < badgeView.bdp_height) {
            badgeView.bdp_width = badgeView.bdp_height;
        }
        contentView.center = CGPointMake(badgeView.bdp_width / 2, badgeView.bdp_height / 2);
    } else {
        badgeView.bdp_size = CGSizeMake(kTabBarRedDotBadgeHeight, kTabBarRedDotBadgeHeight);
    }
    [self updateBadgePositionOnItemIndex:index badgeView:badgeView];
    redView.bdp_size = CGSizeMake(badgeView.bdp_size.width, badgeView.bdp_size.height);
    redView.center = CGPointMake(badgeView.bdp_width / 2, badgeView.bdp_height / 2);
    badgeView.layer.cornerRadius = badgeView.bdp_height / 2;
    badgeView.layer.allowsEdgeAntialiasing = YES;   // 消除边缘锯齿
    redView.layer.cornerRadius = redView.bdp_height / 2;
    redView.layer.allowsEdgeAntialiasing = YES;     // 消除边缘锯齿
}

- (void)updateBadgePositionOnItemIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return;
    }
    UIView *badgeView = [self badgeViewForItemIndex:index];
    [self updateBadgePositionOnItemIndex:index badgeView:badgeView];
}

- (void)updateBadgePositionOnItemIndex:(NSInteger)index badgeView:(UIView *)badgeView {
    if (index < 0 || index >= self.items.count) {
        return;
    }
    if ([BDPDeviceHelper isPadDevice]) {
        // ipad badge策略：
        // 显示红点：badgeView右上角与icon对齐，红点
        // 显示非红点：badgeView占用icon右上角一个正方形，高出2，右边延伸

        // UITabbarItem发生变化，先Layout将UITabbarItem布局刷新，然后获取UITabbarItem里的布局来设置badgeview
        [self layoutIfNeeded];
        CGFloat outset = badgeView.bdp_height > kTabBarRedDotBadgeHeight ? 2 : 0;
        CGRect iconRect = [self getTabbarImageRectOnItemIndex:index];
        badgeView.bdp_left = iconRect.origin.x + iconRect.size.width - (badgeView.bdp_height - outset);
        badgeView.bdp_top = iconRect.origin.y - outset;
    } else {
        CGFloat tabItemIconTop = 5;
        CGFloat percentX = (index + 0.5) / self.items.count;
        CGFloat mobileTabItemIconRight = percentX * self.frame.size.width + CGSizeFromString(BDPTabBarImageSizeString).width / 2;
        if (badgeView.bdp_height > kTabBarRedDotBadgeHeight) {
            badgeView.bdp_left = mobileTabItemIconRight - (kTabBarTextBadgeHeight / 2);
            badgeView.bdp_top = kTabBarTextBadgeTop;
        } else {
            badgeView.bdp_right = mobileTabItemIconRight;
            badgeView.bdp_top = tabItemIconTop;
        }
    }
    
    // 需要置顶, 否则一些情况会被icon盖住
    [badgeView.superview bringSubviewToFront:badgeView];
}

//移除小红点
- (void)removeBadgeOnItemIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return;
    }
    //按照tag值移除小红点
    for (UIView *subView in self.subviews) {
        if (subView.tag == [self tagForItemIndex:index]) {
            [subView removeFromSuperview];
        }
    }
}

- (UIView *)badgeViewForItemIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        return nil;
    }
    for (UIView *subView in self.subviews) {
        if (subView.tag == [self tagForItemIndex:index]) {
            return subView;
        }
    }
    return nil;
}

- (NSInteger)tagForItemIndex:(NSInteger)index {
    return 100 + index;
}

// 适配iPad分屏/转屏宽度变化，需要将badgeView位置设对
- (void)bdp_layoutBadgeIfNeeded {
    if ([BDPDeviceHelper isPadDevice]) {
        [self.items enumerateObjectsUsingBlock:^(UITabBarItem * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self updateBadgePositionOnItemIndex:idx];
        }];
    }
}

// 获取UITabbarItem里的icon对应的rect
- (CGRect)getTabbarImageRectOnItemIndex:(NSInteger)index {
    if (index < 0 || index >= self.items.count) {
        BDPLogWarn(@"get tabbar image rect index out of range, index=%@, items.count=%@", @(index), @(self.items.count));
        return CGRectZero;
    }
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        return [evaluatedObject isKindOfClass:[UIControl class]];
    }];
    NSArray<UIView *> *tabbarBtns = [self.subviews filteredArrayUsingPredicate:predicate];
    if (index >= tabbarBtns.count) {
        BDPLogWarn(@"get tabbar image rect from tababrBtns out of range, index=%@, tabbarBtns.count=%@", @(index), @(tabbarBtns.count));
        return CGRectZero;
    }
    UIView *tabbarItem = tabbarBtns[index];
    __block CGRect imageViewRect = CGRectZero;
    [tabbarItem.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[UIImageView class]]) {
            imageViewRect = [tabbarItem convertRect:obj.frame toView:self];
            *stop = YES;
        }
    }];
    return imageViewRect;
}

@end
