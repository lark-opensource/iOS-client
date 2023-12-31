//
//  BDXLynxPageViewItemPro.m
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUI.h>
#import <Lynx/UIView+Lynx.h>
#import "BDXLynxPageViewItemPro.h"
#import "NSObject+BDXPageKVO.h"
#import "BDXLynxPageViewPro.h"

@interface BDXPageItemViewPro ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, assign) UIEdgeInsets scrollViewPadding;

@end

@implementation BDXPageItemViewPro

- (void)layoutSubviews {
    [super layoutSubviews];
    self.scrollView.frame = UIEdgeInsetsInsetRect(self.bounds, self.scrollViewPadding);
}


- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (self.window && [self.delegate respondsToSelector:@selector(listWillMoveToWindow)]) {
        [self.delegate listWillMoveToWindow];
    }
}

@end

@interface BDXLynxPageViewItemPro () <BDXPagerViewListViewDelegate>

@property (nonatomic, copy) NSString *tag;
@property (nonatomic, copy) void(^scrollCallback)(UIScrollView *scrollView);
@property (nonatomic, weak) BDXPageBaseView *nestedPageView;

@end

@implementation BDXLynxPageViewItemPro

- (void)dealloc {
    [self.view.scrollView bdx_removeObserverBlocksForKeyPath:NSStringFromSelector(@selector(contentOffset))];
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-viewpager-item-pro")
#else
LYNX_REGISTER_UI("x-viewpager-item-pro")
#endif

- (UIView*)createView {
    BDXPageItemViewPro* view = [[BDXPageItemViewPro alloc] init];
    view.delegate = self;
    view.clipsToBounds = YES;
    return view;
}

- (void)layoutDidFinished {
    [super layoutDidFinished];
    self.view.scrollViewPadding = self.padding;
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
    if ([child.view isKindOfClass:[UIScrollView class]]) {
        [self setupScrollView:(UIScrollView *)child.view];
    } else {
        [self traverseAllSubviews:child.view];
    }
}

- (void)traverseAllSubviews:(UIView *)view {
    if (self.nestedPageView) {
        return;
    }
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[BDXPageBaseView class]]) {
            self.nestedPageView = (BDXPageBaseView *)subView;
            return;
        }
        if ([subView isKindOfClass:[UIScrollView class]] && subView.lynxSign) {
            [self setupScrollView:(UIScrollView *)subView];
            return;
        }
        if (subView.subviews.count) {
            [self traverseAllSubviews:subView];
        }
    }
    return;
}

- (void)setupScrollView:(UIScrollView *)scrollView {
    if (self.view.scrollView) {
        [self.view.scrollView bdx_removeObserverBlocksForKeyPath:NSStringFromSelector(@selector(contentOffset))];
    }
    self.view.scrollView = scrollView;
    __weak typeof(self) wself = self;
    [self.view.scrollView bdx_addObserverBlockForKeyPath:NSStringFromSelector(@selector(contentOffset)) block:^(id  _Nonnull obj, id  _Nullable oldVal, id  _Nullable newVal) {
        UIScrollView *scrollView = obj;
        CGPoint oldPoint = [oldVal CGPointValue];
        CGPoint newPoint = scrollView.contentOffset;
        if (!CGPointEqualToPoint(oldPoint, newPoint)) {
            [wself scrollViewDidScroll:scrollView];
        }

    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    !self.scrollCallback ?: self.scrollCallback(scrollView);
}

LYNX_PROP_SETTER("tag", tag, NSString *) {
    if ([value isKindOfClass:[NSNull class]]) {
        return;
    }
    if (_tag == nil ) {
        _tag = value;
        return;
    }
    if (![value isEqualToString:_tag]) {
        _tag = value;
        [self.tagDelegate tagDidChanged: self.view];
    }
}



- (UIScrollView *)listScrollView {
    if (self.nestedPageView) {
        UIScrollView *nestedScrollView = [self.nestedPageView.listContainerView currentScrollView];
        if (nestedScrollView && self.view.scrollView != nestedScrollView) {
            [self setupScrollView:nestedScrollView];
        }
    }
    if (!self.view.scrollView) {
        for (LynxUI *child in self.children) {
            if ([child.view isKindOfClass:[UIScrollView class]]) {
                self.view.scrollView = child.view;
            } else {
                [self traverseAllSubviews:child.view];
            }
            if (self.view.scrollView) {
                break;
            }
        }
    }
    return self.view.scrollView;
}

- (UIView *)listView {
    return self.view;
}

- (void)listViewDidScrollCallback:(void (^)(UIScrollView *))callback {
    self.scrollCallback = callback;
}

- (void)listWillMoveToWindow {
    [self resetAnimation];
    [self restartAnimation];
}

@end
