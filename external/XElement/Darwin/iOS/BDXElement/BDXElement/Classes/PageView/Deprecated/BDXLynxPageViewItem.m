//
//  BDXLynxPageViewItem.m
//  BDXElement
//
//  Created by AKing on 2020/9/21.
//

#import "BDXLynxPageViewItem.h"
#import <Lynx/LynxComponentRegistry.h>
#import <Lynx/LynxPropsProcessor.h>
#import <Lynx/LynxUI.h>
#import "BDXLynxRefreshView.h"
#import "NSObject+BDXPageKVO.h"

@implementation BDXPageItemView

@end

@interface BDXLynxPageViewItem ()

@property (nonatomic, copy) NSString *tag;

@property (nonatomic, weak) UIScrollView *scrollView;

@end

@implementation BDXLynxPageViewItem

static void *KVOContext = &KVOContext;

- (void)dealloc {
//    [self.scrollView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:KVOContext];
//    [self.view removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) context:KVOContext];
    [self.scrollView bdx_removeObserverBlocksForKeyPath:NSStringFromSelector(@selector(contentSize))];
    [self.view bdx_removeObserverBlocksForKeyPath:NSStringFromSelector(@selector(frame))];
}

- (nullable UIScrollView *)childScrollView {
    if (self.scrollView) {
        return self.scrollView;
    }
    [self traverseAllSubviews:self.view];
    return _scrollView;
}

#if LYNX_LAZY_LOAD
LYNX_LAZY_REGISTER_UI("x-viewpager-item")
#else
LYNX_REGISTER_UI("x-viewpager-item")
#endif

- (UIView*)createView {
    BDXPageItemView* view = [[BDXPageItemView alloc] init];
    [view setBackgroundColor:[UIColor clearColor]];
    view.clipsToBounds = YES;
    __weak typeof(self) wself = self;
    [view bdx_addObserverBlockForKeyPath:NSStringFromSelector(@selector(frame)) block:^(id  _Nonnull obj, id  _Nullable oldVal, id  _Nullable newVal) {
        UIView *subview = obj;
        CGRect oldFrame = [oldVal CGRectValue];
        CGRect newFrame = subview.frame;
        if (!CGRectEqualToRect(newFrame, oldFrame)) {
            [wself.sizeDelegate pageItemViewDidChangeFrame:subview];
        }
    }];
//    [view addObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) options:NSKeyValueObservingOptionOld context:KVOContext];
    return view;
}

- (void)insertChild:(LynxUI *)child atIndex:(NSInteger)index {
    [super insertChild:child atIndex:index];
    [self traverseAllSubviews:child.view];
}

- (void)traverseAllSubviews:(UIView *)view {
    for (UIView *subView in view.subviews) {
        if ([subView isKindOfClass:[UIScrollView class]]) {
            self.scrollView = (UIScrollView *)subView;
            __weak typeof(self) wself = self;
            [self.scrollView bdx_addObserverBlockForKeyPath:NSStringFromSelector(@selector(contentSize)) block:^(id  _Nonnull obj, id  _Nullable oldVal, id  _Nullable newVal) {
                UIScrollView *scrollView = obj;
                CGSize oldContentSize = [oldVal CGSizeValue];
                CGSize newContentSize = scrollView.contentSize;
                if (!CGSizeEqualToSize(newContentSize, oldContentSize)) {
                    [wself.sizeDelegate pageItemViewDidChangeContentSize:scrollView];
                }
            }];
//            [self.scrollView addObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) options:NSKeyValueObservingOptionOld context:KVOContext];
            return;
        }
        if (subView.subviews.count) {
            [self traverseAllSubviews:subView];
        }
    }
    return;
}

//- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
//{
//    if (context == KVOContext) {
//        // Initiate a layout recalculation only when a subviewʼs frame or contentSize has changed
//        if ([keyPath isEqualToString:NSStringFromSelector(@selector(contentSize))]) {
//            UIScrollView *scrollView = object;
//            CGSize oldContentSize = [change[NSKeyValueChangeOldKey] CGSizeValue];
//            CGSize newContentSize = scrollView.contentSize;
//            if (!CGSizeEqualToSize(newContentSize, oldContentSize)) {
//                [_sizeDelegate pageItemViewDidChangeContentSize:scrollView];
//            }
//        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(frame))] ||
//                   [keyPath isEqualToString:NSStringFromSelector(@selector(bounds))]) {
//            UIView *subview = object;
//            CGRect oldFrame = [change[NSKeyValueChangeOldKey] CGRectValue];
//            CGRect newFrame = subview.frame;
//            if (!CGRectEqualToRect(newFrame, oldFrame)) {
//                [_sizeDelegate pageItemViewDidChangeFrame:subview];
//            }
//        }
//    }
//}

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

@end
