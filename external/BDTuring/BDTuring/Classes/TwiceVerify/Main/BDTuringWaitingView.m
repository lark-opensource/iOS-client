//
//  BDTuringWaitingView.m
//  AFgzipRequestSerializer
//
//  Created by xunianqiang on 2020/3/15.
//

#import "BDTuringWaitingView.h"

static CGFloat const waitingItemSize = 24.f;

@implementation BDTuringWaitingView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self buildImageView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self buildImageView];
    }
    return self;
}

- (void)buildImageView
{
    self.imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
//    self.imageView.imageName = @"refreshicon_loading";
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageView];
    [self sizeToFit];
}

- (void)startAnimating {
    [self.imageView.layer removeAllAnimations];
    CABasicAnimation *rotateAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotateAnimation.duration = 1.0f;
    rotateAnimation.repeatCount = HUGE_VAL;
    rotateAnimation.toValue = @(M_PI * 2);
    [self.imageView.layer addAnimation:rotateAnimation forKey:@"rotateAnimation"];
    self.hidden = NO;
}

- (void)stopAnimating {
    [self.imageView.layer removeAllAnimations];
    self.hidden = YES;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    if (newSuperview) {
        [self startAnimating];
    } else {
        [self stopAnimating];
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    return CGSizeMake(waitingItemSize, waitingItemSize);
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(waitingItemSize, waitingItemSize);
}

@end
