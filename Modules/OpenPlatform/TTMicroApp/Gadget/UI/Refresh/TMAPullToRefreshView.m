//
//  TMAPullToRefreshView.m
//  Timor
//
//  Created by muhuai on 2018/1/18.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString *const kBackgroundTextStyleLight = @"light";
static NSString *const kBackgroundTextStyleDark = @"dark";

#import "TMAPullToRefreshView.h"
#import "BDPLoadingAnimationView.h"

#define animateCircleRadius 6

@interface TMAPullToRefreshView ()

@property (nonatomic, strong) BDPLoadingAnimationView *animateView;

@end

@implementation TMAPullToRefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _animateView = [[BDPLoadingAnimationView alloc] initWithFrame:self.frame];
        [self addSubview:_animateView];
    }
    return self;
}

- (void)startLoading {
    [_animateView startLoading];
}

- (void)stopLoading {
    [_animateView stopLoading];
}

- (void)updateAnimationWithScrollOffset:(CGFloat)offset {
    CGFloat animateCircleCenterY = [_animateView getAnimateCenterY];
    CGFloat percent = MIN(1, MAX(ABS(offset) - animateCircleCenterY, 0) / (kTMAPullRefreshHeight - animateCircleCenterY));
    [_animateView setCirclesDistanceWithPercent:percent];
}

- (void)updateViewWithPullState:(TMAPullState)state
{
    
}

- (void)configurePullRefreshLoadingHeight:(CGFloat)pullRefreshLoadingHeight
{
    
}

- (void)setBackgroundTextStyle:(NSString *)backgroundTextStyle
{
    BDPLoadingAnimationViewStyle style = BDPLoadingAnimationViewStyleDark;
    if ([backgroundTextStyle isEqualToString:kBackgroundTextStyleLight]) {
        style = BDPLoadingAnimationViewStyleLight;
    }
    
    _animateView.circleStyle = style;
}

- (NSString *)backgroundTextStyle
{
    NSString *textStyle = kBackgroundTextStyleDark;
    if (_animateView.circleStyle == BDPLoadingAnimationViewStyleLight) {
        textStyle = kBackgroundTextStyleLight;
    }
    
    return [textStyle copy];
}

@end
