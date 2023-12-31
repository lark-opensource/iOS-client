//
//  TMAQueuingScrollView.h
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/15.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TMAReusablePage.h"

@class TMAQueuingScrollView;

@protocol TMAQueuingScrollViewDelegate <UIScrollViewDelegate>

@required

- (UIView<TMAReusablePage> *)queuingScrollView:(TMAQueuingScrollView *)queuingScrollView viewBeforeView:(UIView *)view;
- (UIView<TMAReusablePage> *)queuingScrollView:(TMAQueuingScrollView *)queuingScrollView viewAfterView:(UIView *)view;

@optional

- (void)queuingScrollViewChangedFocusView:(TMAQueuingScrollView *)queuingScrollView previousFocusView:(UIView *)previousFocusView;

@end

@interface TMAQueuingScrollView : UIScrollView

@property (nonatomic, weak) id<TMAQueuingScrollViewDelegate> delegate;

@property (nonatomic) CGFloat pagePadding;

@property (nonatomic, readonly) CGPoint targetContentOffset;

- (id)reusableViewWithIdentifer:(NSString *)identifier;

- (void)displayView:(UIView<TMAReusablePage> *)view;

@property (nonatomic, readonly) UIView *focusView;

- (NSArray *)allViews;

- (void)scrollToNextPageAnimated:(BOOL)animated;

- (void)scrollToPreviousPageAnimated:(BOOL)animated;

- (void)locateTargetContentOffset;

- (BOOL)contentOffsetIsValid;

- (CGRect)contentBounds;

@end
