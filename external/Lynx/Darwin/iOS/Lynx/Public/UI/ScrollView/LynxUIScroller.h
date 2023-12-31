// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Foundation/Foundation.h>
#import "AbsLynxUIScroller.h"
#import "LynxUI.h"

NS_ASSUME_NONNULL_BEGIN

@class LynxScrollView;
@class LynxBounceView;

extern NSString *const LynxEventScroll;
extern NSString *const LynxEventScrollToUpper;
extern NSString *const LynxEventScrollToLower;
extern NSString *const LynxEventScrollEnd;

typedef NS_ENUM(NSInteger, HoverPosition) {
  HoverPositionTop = 0,
  HoverPositionBottom,
  HoverPositionCenter,
  HoverPositionLeft,
  HoverPositionRight
};

@protocol LynxBounceView <NSObject>

@optional
- (void)bdx_updateOverflowText:(nullable NSString *)text;

@end

@protocol LynxScrollViewUIDelegate <NSObject>

@optional
+ (UIView<LynxBounceView> *)LynxBounceView:(UIScrollView *)scrollView;

@end

@interface LynxUIScroller : AbsLynxUIScroller <UIScrollView *> <UIScrollViewDelegate>
@property(nonatomic) BOOL enableSticky;
@property(nonatomic) BOOL enableScrollY;
@property(class) Class<LynxScrollViewUIDelegate> UIDelegate;
// for bounceView
@property(nonatomic, strong) NSMutableArray<LynxBounceView *> *bounceUIArray;
// Controls scrollToBounce event. Set to true before users' dragging ends.
@property(nonatomic, assign) BOOL isTransferring;

- (float)scrollLeftLimit;
- (float)scrollRightLimit;
- (float)scrollUpLimit;
- (float)scrollDownLimit;

@end

NS_ASSUME_NONNULL_END
