//
//  AWEEditStickerHintView.m
//  Pods
//
//  Created by 赖霄冰 on 2019/9/4.
//

#import "AWEEditStickerHintView.h"
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

NSString * const AWEEditStickerHintViewResignActiveNotification = @"AWEEditStickerHintViewResignActiveNotification";

@interface AWEEditStickerHintView ()

@property (nonatomic, strong) UILabel *textLabel;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;
@property (nonatomic, assign) AWEEditStickerHintType type;
@property (nonatomic, assign) BOOL shouldUseGradient;

@end

@implementation AWEEditStickerHintView

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self registerNotifications];
    }
    return self;
}

- (instancetype)initWithGradientAndFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUIWithGradient];
        [self registerNotifications];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.textLabel];
}

- (void)registerNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dismiss) name:AWEEditStickerHintViewResignActiveNotification object:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.frame = self.bounds;
    if (self.shouldUseGradient) {
        self.gradientLayer.frame = CGRectMake(0, 0, self.bounds.size.width * 2, self.bounds.size.height);
        [self p_animate];
    }
}

- (CGSize)intrinsicContentSize {
    return [self.textLabel sizeThatFits:CGSizeMake(ACC_SCREEN_WIDTH, 20.f)];
}

+ (void)setNoNeedShowForType:(AWEEditStickerHintType)type {
    [ACCCache() setBool:YES forKey:[self storageKeyForType:type]];
}

- (void)showHint:(NSString *)hint
{
    [self showHint:hint animated:YES autoDismiss:YES];
}

- (void)showHint:(NSString *)hint
        animated:(BOOL)animated
     autoDismiss:(BOOL)autoDismiss
{
    self.textLabel.text = hint;
    [self setNeedsLayout];
    [self layoutIfNeeded];
    [self setVisible:YES animated:animated];
    if (autoDismiss) {
        [self performSelector:@selector(autoDismiss) withObject:nil afterDelay:3.f];
    }
}

- (void)showHint:(NSString *)hint type:(AWEEditStickerHintType)type {
    if (![AWEEditStickerHintView isNeedShowHintViewForType:type]) return;
    self.type = type;
    [self showHint:hint];
}

- (void)dismiss
{
    [self dismissWithAnimation:YES];
}

- (void)dismissWithAnimation:(BOOL)animated {
    [self setVisible:NO animated:animated];
}

#pragma mark - Private

- (void)p_setupUIWithGradient
{
    self.shouldUseGradient = YES;
    
    [self addSubview:self.textLabel];
    self.maskView = self.textLabel;
    
    _gradientLayer = ({
        CAGradientLayer *layer = [CAGradientLayer layer];
        [self.layer addSublayer:layer];
        layer.startPoint = CGPointMake(0.0, 0.5);
        layer.endPoint = CGPointMake(1.0, 0.5);
        layer.colors = [NSArray arrayWithObjects:
                        (id)[[UIColor colorWithRed: 0.94 green: 0.78 blue: 1.00 alpha: 1.00] CGColor],
                        (id)[[UIColor colorWithRed: 1.00 green: 0.84 blue: 0.87 alpha: 1.00] CGColor],
                        (id)[[UIColor colorWithRed: 1.00 green: 0.92 blue: 0.86 alpha: 1.00] CGColor],
                        (id)[[UIColor colorWithRed: 0.79 green: 0.88 blue: 0.93 alpha: 1.00] CGColor],
                        (id)[[UIColor colorWithRed: 0.94 green: 0.78 blue: 1.00 alpha: 1.00] CGColor],
                        nil];
        layer.locations = @[
            @(0.0),
            @(0.2),
            @(0.48),
            @(0.75),
            @(1.0)
        ];
        
        layer;
    });
}

- (void)p_animate
{
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath = @"position";
    animation.fromValue = [NSValue valueWithCGPoint:CGPointMake(self.gradientLayer.position.x - self.gradientLayer.frame.size.width / 2.0,
                                                                self.gradientLayer.position.y)];
    animation.toValue = [NSValue valueWithCGPoint:CGPointMake(self.gradientLayer.position.x,
                                                              self.gradientLayer.position.y)];
    animation.duration = 1;
    animation.repeatCount = HUGE_VALF;
    animation.fillMode = kCAFillModeForwards;
    animation.autoreverses = YES;

    [self.gradientLayer addAnimation:animation forKey:@"basic"];
}

- (void)setVisible:(BOOL)visible animated:(BOOL)animated {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(autoDismiss) object:nil];
    CGFloat alpha = visible ? 1 : 0;
    if (animated) {
        [UIView animateWithDuration:.1 animations:^{
            self.alpha = alpha;
        } completion:^(BOOL finished) {
            self.alpha = alpha;
        }];
    } else {
        self.alpha = alpha;
    }
}

- (void)autoDismiss {
    [self setVisible:NO animated:YES];
}

+ (BOOL)isNeedShowHintViewForType:(AWEEditStickerHintType)type {
    return ![ACCCache() boolForKey:[self storageKeyForType:type]];
}

+ (NSString *)storageKeyForType:(AWEEditStickerHintType)type {
    switch (type) {
        case AWEEditStickerHintTypeInfo:
            return @"AWEEditStickerHintKey_Info";
        case AWEEditStickerHintTypeText:
            return @"AWEEditStickerHintKey_Text";
        case AWEEditStickerHintTypeInteractive:
            return @"AWEEditStickerHintKey_Interactive";
        case AWEEditStickerHintTypeInteractiveMultiPOI:
            return @"AWEEditStickerHintKey_Interactive_MultiPOI";
        case AWEEditStickerHintTypeTextReading:
            return @"AWEEditStickerHintKey_TextReading";
    }
}

- (UILabel *)textLabel {
    if (!_textLabel) {
        _textLabel = [UILabel new];
        _textLabel.font = [ACCFont() acc_boldSystemFontOfSize:14];
        _textLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _textLabel.numberOfLines = 1;
        _textLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _textLabel;
}

@end
