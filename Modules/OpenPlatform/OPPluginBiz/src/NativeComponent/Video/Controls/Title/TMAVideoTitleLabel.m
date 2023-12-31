//
//  TMAVideoTitleLabel.m
//  OPPluginBiz
//
//  Created by zhujingcheng on 2/8/23.
//

#import "TMAVideoTitleLabel.h"
#import <Masonry/Masonry.h>
#import <ByteDanceKit/NSString+BTDAdditions.h>
#import <ByteDanceKit/UIView+BTDAdditions.h>
#import <ByteDanceKit/UIColor+BTDAdditions.h>

@interface TMAVideoTitleLabel ()

@property (nonatomic, strong) UILabel *frontLabel;
@property (nonatomic, strong) UILabel *backLabel;

@property (nonatomic, assign) BOOL isAnimating;

@end

@implementation TMAVideoTitleLabel

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupViews];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self updateLayoutAndAnimation];
}

- (void)setupViews {
    self.clipsToBounds = YES;
    [self addSubview:self.frontLabel];
    [self.frontLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.mas_equalTo(self);
    }];
    [self addSubview:self.backLabel];
    [self.backLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.frontLabel.mas_trailing).mas_offset(16);
        make.centerY.mas_equalTo(self.frontLabel);
    }];
}

- (void)updateLayoutAndAnimation {
    self.frontLabel.text = self.content;
    self.backLabel.text = self.content;
    CGFloat width = [self.content btd_widthWithFont:self.frontLabel.font height:self.btd_height];
    BOOL shouldAnimate = width > self.btd_width;
    if (shouldAnimate == self.isAnimating) {
        return;
    }
    
    self.backLabel.hidden = !shouldAnimate;
    if (shouldAnimate) {
        [self startAnimationWithDistance:width + 16];
    } else {
        [self stopAnimation];
    }
    self.isAnimating = shouldAnimate;
}

- (void)startAnimationWithDistance:(CGFloat)distance {
    CABasicAnimation *transformAnim = [CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    transformAnim.fillMode = kCAFillModeForwards;
    transformAnim.removedOnCompletion = NO;
    transformAnim.beginTime = CACurrentMediaTime() + 2;
    transformAnim.duration = distance / 30;
    transformAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    transformAnim.fromValue = @0;
    transformAnim.toValue = @(-distance);
    transformAnim.repeatCount = HUGE_VALF;
    [self.frontLabel.layer addAnimation:transformAnim forKey:nil];
    [self.backLabel.layer addAnimation:transformAnim forKey:nil];
}

- (void)stopAnimation {
    [self.frontLabel.layer removeAllAnimations];
    [self.backLabel.layer removeAllAnimations];
}

- (void)setContent:(NSString *)content {
    _content = content;
    [self updateLayoutAndAnimation];
}

- (UILabel *)frontLabel {
    if (!_frontLabel) {
        _frontLabel = [[UILabel alloc] init];
        _frontLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        _frontLabel.textColor = [UIColor btd_colorWithHexString:@"#F0F0F0"];
    }
    return _frontLabel;
}

- (UILabel *)backLabel {
    if (!_backLabel) {
        _backLabel = [[UILabel alloc] init];
        _backLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
        _backLabel.textColor = [UIColor btd_colorWithHexString:@"#F0F0F0"];
        _backLabel.hidden = YES;
    }
    return _backLabel;
}

@end
