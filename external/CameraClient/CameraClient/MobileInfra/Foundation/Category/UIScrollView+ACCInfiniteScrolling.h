//
//  UIScrollView+ACCInfiniteScrolling.h
//  CameraClient
//
//  Created by gongandy on 2018/1/16.
//  Copyright © 2018年 Bytedance. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, ACCInfiniteScrollingState) {
    ACCInfiniteScrollingStateStopped = 0,
    ACCInfiniteScrollingStateTriggered,
    ACCInfiniteScrollingStateLoading,
    ACCInfiniteScrollingStateAll = 10
};

@interface ACCInfiniteScrollingView : UIView

@property (nonatomic, readwrite) BOOL enabled;
@property (nonatomic, readonly) ACCInfiniteScrollingState state;

- (void)startAnimating;
- (void)stopAnimating;
- (void)resetOriginalContentSize;

@end

typedef NS_ENUM(NSInteger, ACCInfiniteScrollPosition) {
    ACCInfiniteScrollPositionFarFromBottom,
    ACCInfiniteScrollPositionNearBottom,
    ACCInfiniteScrollPositionAtAbsoluteBottom
};

@interface UIScrollView (ACCInfiniteScrolling)

- (void)acc_addInfiniteScrollingWithActionHandler:(void (^)(void))actionHandler;
- (void)acc_addInfiniteScrollingWithViewHeight:(CGFloat)viewHeight actionHandler:(void (^)(void))actionHandler;
// 支持横向滚动无限加载，支持自定义宽度
- (void)acc_addInfiniteHorizontalScrollingWithViewWidth:(CGFloat)viewWidth actionHandler:(void (^)(void))actionHandler;

- (void)acc_triggerInfiniteScrolling;

@property (nonatomic, assign) BOOL acc_showsInfiniteScrolling;
@property (nonatomic, assign) ACCInfiniteScrollPosition acc_infiniteScrollPosition;
@property (nonatomic, strong, readonly) ACCInfiniteScrollingView *acc_infiniteScrollingView;

@end
