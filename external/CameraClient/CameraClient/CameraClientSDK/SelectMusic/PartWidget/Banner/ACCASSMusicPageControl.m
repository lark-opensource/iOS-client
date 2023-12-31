//
//  ACCASSMusicPageControl.m
//  CameraClient
//
//  Created by 旭旭 on 2018/8/31.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "ACCASSMusicPageControl.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

static const CGFloat kDotW = 5;
static const CGFloat kPadding = 5;

@interface ACCASSMusicPageControl ()

@property (nonatomic, strong) NSMutableArray *dotArray;

@end

@implementation ACCASSMusicPageControl

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _dotArray = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - UI

- (void)p_setupUI
{
    for (UIView *view in _dotArray) {
        [view removeFromSuperview];
    }
    [_dotArray removeAllObjects];
    for (NSUInteger idx = 0; idx < _numberOfPages; idx++) {
        UIView *view = [[UIView alloc] init];
        view.layer.shadowColor = ACCUIColorFromRGBA(0x000000, 0.15).CGColor;
        view.layer.shadowOffset = CGSizeMake(0, 3);
        view.layer.cornerRadius = kDotW / 2;
        view.layer.masksToBounds = YES;
        [self addSubview:view];
        [_dotArray acc_addObject:view];
    }
    [self setNeedsLayout];
}

#pragma mark - layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat h = CGRectGetHeight(self.frame);
    CGFloat totalW = _numberOfPages * kDotW + (_numberOfPages - 1) * kPadding;
    __block CGFloat left = (w - totalW) / 2;
    CGFloat top = (h - kDotW) / 2;
    [_dotArray enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        view.frame = CGRectMake(left, top, kDotW, kDotW);
        left += kDotW + kPadding;
    }];
}

#pragma mark - getter & setter

- (void)setCurrentPage:(NSUInteger)currentPage {
    [_dotArray enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL * _Nonnull stop) {
        if (idx == currentPage) {
            view.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, 1.0);
        } else {
            view.backgroundColor = ACCUIColorFromRGBA(0xFFFFFF, 0.3);
        }
    }];
}

- (void)setNumberOfPages:(NSUInteger)numberOfPages
{
    if (_numberOfPages != numberOfPages) {
        _numberOfPages = numberOfPages;
        [self p_setupUI];
    }
}

@end
