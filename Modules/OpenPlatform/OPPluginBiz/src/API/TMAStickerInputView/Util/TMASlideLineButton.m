//
//  TMASlideLineButton.m
//  TMAStickerKeyboard
//
//  Created by houjihu on 2018/8/28.
//  Copyright © 2018年 houjihu. All rights reserved.
//

#import "TMASlideLineButton.h"
#import <OPFoundation/BDPDeviceHelper.h>

static CGFloat const TMASlideLineHeight = 22.0;

@interface TMASlideLineButton ()
@property (nonatomic, strong) NSArray<UIView *> *lineViews;
@end

@implementation TMASlideLineButton

- (instancetype)init {
    if (self = [super init]) {
        self.linePosition = TMASlideLineButtonPositionNone;
        self.lineColor = [UIColor blackColor];
    }
    return self;
}

- (void)setLineColor:(UIColor *)lineColor {
    if (_lineColor != lineColor) {
        _lineColor = lineColor;
        [self setNeedsLayout];
    }
}

- (void)setLinePosition:(TMASlideLineButtonPosition)linePosition {
    if (_linePosition != linePosition) {
        _linePosition = linePosition;
        [self setNeedsLayout];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];

    for (UIView *lineView in self.lineViews) {
        [lineView removeFromSuperview];
    }
    self.lineViews = nil;

    UIView *leftLine = [[UIView alloc] initWithFrame:CGRectMake(0, (CGRectGetHeight(self.bounds) - TMASlideLineHeight) / 2, BDPDeviceHelper.ssOnePixel, TMASlideLineHeight)];
    leftLine.backgroundColor = self.lineColor;
    UIView *rightLine = [[UIView alloc] initWithFrame:CGRectMake(CGRectGetWidth(self.bounds) - BDPDeviceHelper.ssOnePixel, (CGRectGetHeight(self.bounds) - TMASlideLineHeight) / 2, BDPDeviceHelper.ssOnePixel, TMASlideLineHeight)];
    rightLine.backgroundColor = self.lineColor;

    NSMutableArray *lineViews = [[NSMutableArray alloc] init];
    switch (self.linePosition) {
        case TMASlideLineButtonPositionNone:
            break;
        case TMASlideLineButtonPositionLeft:
            [lineViews addObject:leftLine];
            [self addSubview:leftLine];
            break;
        case TMASlideLineButtonPositionRight:
            [lineViews addObject:rightLine];
            [self addSubview:rightLine];
            break;
        case TMASlideLineButtonPositionBoth:
            [lineViews addObject:leftLine];
            [lineViews addObject:rightLine];
            [self addSubview:leftLine];
            [self addSubview:rightLine];
            break;
        default:
            break;
    }
    self.lineViews = lineViews;
}

@end
