//
//  BDCTInsetImageView.m
//  byted_cert-Pods-AwemeCore
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/12.
//

#import "BDCTInsetImageView.h"
#import "UIImage+BDCTAdditions.h"


@interface BDCTInsetImageView ()

@property (nonatomic, strong) UIImageView *innerView;

@end


@implementation BDCTInsetImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _innerView = [[UIImageView alloc] initWithImage:[UIImage bdct_holdSampleImage]];
        [self addSubview:_innerView];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(230, 147 + 20);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat width = 230;
    CGFloat height = 147;
    CGRect frame = CGRectMake(0, 0, width, height);
    frame.origin.x = (self.frame.size.width - width) / 2;
    frame.origin.y = 0;
    self.innerView.frame = frame;
}

@end
