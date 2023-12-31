//
//  AWEMusicNameInfoView.m
//  AWEStudio
//
//  Created by Liu Deping on 2019/10/24.
//

#import "AWEMusicNameInfoView.h"
#import <CreationKitArch/AWEScrollStringLabel.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/ACCMacros.h>

@interface AWEMusicNameInfoView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *loopContainerView;
@property (nonatomic, strong) UIView *musicContainerView;
@property (nonatomic, strong) CAGradientLayer *gradientLayer;

@property (nonatomic, strong) UIImageView *musicLogoView;
@property (nonatomic, copy) NSString *musicLoopString;

@property (nonatomic, assign) CGFloat containerViewWidth;
@property (nonatomic, assign) CGFloat containerViewHeight;
@property (nonatomic, assign) CGFloat subviewWidth;
@property (nonatomic, assign) NSInteger subviewCount;

@end

@implementation AWEMusicNameInfoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        self.userInteractionEnabled = YES;
        self.isAccessibilityElement = YES;

        _musicContainerView = [UIView new];
        [self addSubview:_musicContainerView];

        _containerView = [UIView new];
        _containerView.clipsToBounds = YES;
        [_musicContainerView addSubview:_containerView];
        
        _loopContainerView = [UIView new];
        [_containerView addSubview:_loopContainerView];
        // icon
        _musicLogoView = [[UIImageView alloc] init];
        _musicLogoView.contentMode = UIViewContentModeScaleAspectFit;
        [self addSubview:_musicLogoView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (!self.musicLoopString) {
        return;
    }
    self.containerViewWidth = 195 / 750.0f * ACC_SCREEN_WIDTH + 195 / 2.0f;
    self.containerViewHeight = 18;
    self.subviewWidth = [self widthWithLabelString:self.musicLoopString];
    self.subviewCount = ceil(self.containerViewWidth / self.subviewWidth) + 1;
    CGFloat containerViewX;
    self.musicLogoView.frame = CGRectMake(0, 3, 13, 13);
    containerViewX = CGRectGetMaxX(self.musicLogoView.frame) + 4;
    self.musicContainerView.frame = CGRectMake(containerViewX, 0, CGRectGetWidth(self.frame) - containerViewX, self.containerViewHeight);
    self.gradientLayer.frame = _musicContainerView.bounds;
    CGFloat fadeInRatio = 6.0 / CGRectGetWidth(self.musicContainerView.frame);
    self.gradientLayer.locations = @[@(0), @(fadeInRatio), @(1-fadeInRatio)];
    self.containerView.frame = CGRectMake(0, 0, self.subviewWidth * self.subviewCount, self.containerViewHeight);
    self.loopContainerView.frame = CGRectMake(0, 0, self.subviewWidth * self.subviewCount, self.containerViewHeight);
    
    for (int i = 0; i < self.loopContainerView.subviews.count; ++i) {
        UIView *extraSubview = self.loopContainerView.subviews[i];
        extraSubview.frame = CGRectMake(i * self.subviewWidth, 0, self.subviewWidth, self.containerViewHeight);
    }
}

- (void)configRollingAnimationWithLabelString:(NSString *)musicLabelString
{
    self.musicLoopString = musicLabelString;
    self.accessibilityLabel = self.musicLoopString;
    // 清除旧有的subview
    [self.loopContainerView.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj removeFromSuperview];
    }];
    
    self.musicLogoView.image = ACCResourceImage(@"icon_music_info_logo");
    
    if (self.isDisableStyle) {
        self.musicLogoView.tintColor = ACCResourceColor(ACCColorConstTextInverse4);
        self.musicLogoView.image = [self.musicLogoView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
    
    // 计算蒙版的宽度
    self.containerViewWidth = 195 / 750.0f * ACC_SCREEN_WIDTH + 195 / 2.0f;
    self.containerViewHeight = 18;
    // 计算subview的宽度
    self.subviewWidth = [self widthWithLabelString:self.musicLoopString];
    // 填充subview
    self.subviewCount = ceil(self.containerViewWidth / self.subviewWidth) + 1;
    
    for (int i = 0; i < self.subviewCount; ++i) {
        UIView *extrasubview = [self subviewItemWithLabelString:musicLabelString];
        [self.loopContainerView addSubview:extrasubview];
    }
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

- (void)addViewTapTarget:(id)target action:(SEL)action
{
    UITapGestureRecognizer *t = [UITapGestureRecognizer new];
    [t addTarget:target action:action];
    [self addGestureRecognizer:t];
}

- (UIView *)subviewItemWithLabelString:(NSString *)musicLabelString
{
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.subviewWidth, 18)];
   
    // label
    AWEScrollStringLabel *musicLabel = [[AWEScrollStringLabel alloc] initWithHeight:18.f];
    [musicLabel configWithTitle:musicLabelString titleColor:self.isDisableStyle?ACCResourceColor(ACCColorConstTextInverse4) : ACCResourceColor(ACCUIColorConstTextInverse) fontSize:15.f isBold:NO];
    musicLabel.frame = CGRectMake(0, 0, self.subviewWidth - 15, 18);
    [containerView addSubview:musicLabel];
    if (musicLabel.labelWidth > self.frame.size.width - 17.f) {
        [musicLabel startAnimation];
    } else {
        [musicLabel stopAnimation];
    }
    return containerView;
}

- (CGFloat)widthWithLabelString:(NSString *)musicLabelString
{
    CGRect rect = [musicLabelString boundingRectWithSize:CGSizeMake(MAXFLOAT, 18)
                                                 options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                              attributes:@{ NSFontAttributeName : [ACCFont() systemFontOfSize:15] }
                                                 context:nil];
    return 15 + ceil(rect.size.width);
}

- (CAGradientLayer *)gradientLayer
{
    if (!_gradientLayer) {
        _gradientLayer = [[CAGradientLayer alloc] init];
        _gradientLayer.backgroundColor = UIColor.clearColor.CGColor;

        _gradientLayer.colors = @[(id)[UIColor colorWithWhite:1 alpha:0].CGColor,
                                  (id)UIColor.whiteColor.CGColor,
                                  (id)UIColor.whiteColor.CGColor,
                                  (id)[UIColor colorWithWhite:1 alpha:0].CGColor];
        _gradientLayer.startPoint = CGPointMake(0, 0.5);
        _gradientLayer.endPoint = CGPointMake(1, 0.5);
    }
    return _gradientLayer;
}

- (void)setIsDisableStyle:(BOOL)isDisableStyle
{
    _isDisableStyle = isDisableStyle;
    if (!ACC_isEmptyString(self.musicLoopString)) {
        [self configRollingAnimationWithLabelString:self.musicLoopString];
    }
}

@end
