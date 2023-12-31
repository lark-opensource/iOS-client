// Copyright 2019 The Lynx Authors. All rights reserved.

#import <UIKit/UIKit.h>

@class LynxView;

/// can be used for key in Dictionary, but must be clear before LynxView's dealloc, which means it's
/// lifecycle is smaller than LynxView's Lifecycle.
@interface LynxScrollInfo : NSObject <NSCopying>

@property(nonatomic, weak) LynxView *lynxView;

/// Tag name of LynxUI.
@property(nonatomic, copy) NSString *tagName;
/// Tag name  specified by web.
@property(nonatomic, copy) NSString *scrollMonitorTagName;

// lynxView is weak, so we need presistent URL to judge whether two ScrollInfo generate from same
// LynxView.
@property(nonatomic, readonly) NSString *lynxViewUrl;

@property(nonatomic, weak) UIScrollView *scrollView;

@property(nonatomic, assign) SEL selector;

// used only for selector `scrollerDidEndDragging:willDecelerate:`
@property(nonatomic, assign) BOOL decelerate;

+ (instancetype)infoWithScrollView:(UIScrollView *)scrollView
                           tagName:(NSString *)tagName
              scrollMonitorTagName:(NSString *)scrollMonitorTagName;

@end

@protocol LynxScrollListener <NSObject>

@optional
- (void)scrollerDidScroll:(LynxScrollInfo *)info;
- (void)scrollerWillBeginDragging:(LynxScrollInfo *)info;
- (void)scrollerDidEndDragging:(LynxScrollInfo *)info willDecelerate:(BOOL)decelerate;
- (void)scrollerDidEndDecelerating:(LynxScrollInfo *)info;
- (void)scrollerDidEndScrollingAnimation:(LynxScrollInfo *)info;

@end
