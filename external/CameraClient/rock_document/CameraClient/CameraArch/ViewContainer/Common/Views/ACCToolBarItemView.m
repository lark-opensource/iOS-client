//
//  ACCToolBarItemView.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/6/2.
//

#import "ACCToolBarItemView.h"

#import "ACCEditBarItemLottieExtraData.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreationKitInfra/UILabel+ACCAdditions.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>

static const CGFloat kRedPointRadius = 2.0f;

@interface ACCToolBarItemView ()
@property (nonatomic, assign) BOOL hideRedPointCache;
@property (nonatomic, assign) BOOL hasShownRedPoint;
@property (nonatomic, assign) BOOL hideRedPoint;
@property (nonatomic, strong) UIView *redPointView;
@property (nonatomic, assign) ACCToolBarItemViewDirection direction;
@property (nonatomic, assign) CGSize buttonSize;
@property (nonatomic, strong) LOTAnimationView *lottieView;
@end

@implementation ACCToolBarItemView

@synthesize imageName = _imageName;
@synthesize selectedImageName = _selectedImageName;
@synthesize needShow;
@synthesize barItemButton;
@synthesize itemViewDidClicked;
@synthesize enabled = _enabled;

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return self;
}

- (void)configWithItem:(ACCBarItem *)item direction:(ACCToolBarItemViewDirection)direction hideRedPoint:(BOOL)hideRedPoint buttonSize:(CGSize)size
{
    self.shownFirstTime = YES;
    self.hasShownRedPoint = NO;
    self.hideRedPoint = hideRedPoint;

    self.itemId = item.itemId;
    self.direction = direction;
    self.buttonSize = size;
    if (item.customView != nil) {
        // 为了适配原本的AWECameraContainerToolButtonWrapView, 只好把label.text和button拿过来了，button可能已经绑定了action
        self.button = item.customView.barItemButton;
        item.title = item.customView.title;
        self.label = [self p_createBarItemLabel:item];
        self.lottieView = [self p_createBarItemLottieView:item];
    } else {
        self.button = [self p_createBarItemButton:item];
        self.label = [self p_createBarItemLabel:item];
        self.lottieView = [self p_createBarItemLottieView:item];
    }

    // red point
    [self checkAndShowRedPoint];

    [self setupUI];
}

- (void)setupUI
{
    self.clipsToBounds = YES;
    self.barItemButton = self.button;

    [self addSubview:self.button];
    [self.button addSubview:self.lottieView];
    [self addSubview:self.label];
    [self addSubview:self.redPointView];
    [self bringSubviewToFront:self.button];

    [self.button addTarget:self action:@selector(onButtonClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self makeLayout];
    [self layoutIfNeeded];
}

- (void)makeLayout
{
    if (self.direction == ACCToolBarItemViewDirectionVertical) {
        ACCMasMaker(self.button, {
            make.top.equalTo(self);
            make.centerX.equalTo(self);
            make.width.mas_equalTo(self.buttonSize.width);
            make.height.mas_equalTo(self.buttonSize.height);
            make.width.lessThanOrEqualTo(self);
        });
        ACCMasMaker(self.label, {
            make.top.equalTo(self.button.mas_bottom).offset(2);
            make.centerX.equalTo(self);
            make.bottom.equalTo(self);
            make.width.lessThanOrEqualTo(self);
        });
    } else if (self.direction == ACCToolBarItemViewDirectionHorizontal) {
        ACCMasMaker(self.button, {
            make.right.equalTo(self);
            make.centerY.equalTo(self);
            make.width.mas_equalTo(self.buttonSize.width);
            make.height.mas_equalTo(self.buttonSize.height);
            make.height.lessThanOrEqualTo(self);
        });
        ACCMasMaker(self.label, {
            make.right.equalTo(self.button.mas_left).offset(-8);
            make.centerY.equalTo(self);
            make.left.greaterThanOrEqualTo(self);
            make.height.lessThanOrEqualTo(self);
        });
        ACCMasMaker(self.redPointView, {
            make.right.equalTo(self.label.mas_left).offset(-3);
            make.centerY.equalTo(self);
            make.left.greaterThanOrEqualTo(self);
            make.size.mas_equalTo(2 * kRedPointRadius);
        });
    }
    
    ACCMasMaker(self.lottieView, {
        CGFloat offset = 20.f;
        make.leading.top.equalTo(self.button).offset(- offset / 2.0);
        make.width.height.equalTo(self.button).offset(offset);
    });
}

- (void)showRedPoint
{
    self.hideRedPointCache = NO;
    self.hasShownRedPoint = YES;
    self.hideRedPoint = NO;

}

- (BOOL)shouldShowRedPoint
{
    BOOL shouldShow = YES;
    if (self.hideRedPointCache) {
        shouldShow = NO;
    }

    if (self.hideRedPoint) {
        shouldShow = NO;
    }
    return shouldShow;
}

- (void)setImageName:(NSString *)imageName
{
    _imageName = [imageName copy];
    [self.button setImage:ACCResourceImage(imageName) forState:UIControlStateNormal];
}

- (void)setSelectedImageName:(NSString *)selectedImageName
{
    _selectedImageName = [selectedImageName copy];
    [self.button setImage:ACCResourceImage(selectedImageName) forState:UIControlStateSelected];
}

- (NSString *)imageName
{
    return _imageName;
}

- (NSString *)selectedImageName
{
    return _selectedImageName;
}

- (void)setTitle:(NSString *)title
{
    if (self.label) {
        self.label.text = title;
    }
}

- (NSString *)title
{
    return self.label.text;
}

- (void)setEnabled:(BOOL)enabled
{
    _enabled = enabled;
    self.button.alpha = enabled ? 1 : 0.5;
    self.label.alpha = enabled ? 1 : 0.5;
}

- (BOOL)enabled
{
    return _enabled;
}

// attention: 适配AWEEditActionItemView的enable
- (void)setEnable:(BOOL)enable
{
    self.enabled = enable;
    self.button.alpha = enable ? 1 : 0.5;
    self.label.alpha = enable ? 1 : 0.5;
}

- (BOOL)enable
{
    return self.enabled;
}

- (void)setAlpha:(CGFloat)alpha
{
    if (!self.enabled) {
        return;
    }
    self.button.alpha = alpha;
    self.label.alpha = alpha;
}

- (CGFloat)alpha
{
    return self.button.alpha;
}

- (UIButton *)p_createBarItemButton:(ACCBarItem *)barItem
{
    UIButton *barItemButton = nil;
    
    if (barItem.useAnimatedButton) {
        barItemButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
    } else {
        barItemButton = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    
    ACCEditBarItemLottieExtraData *extraData = ACCDynamicCast(barItem.extraData, ACCEditBarItemLottieExtraData);
    if (extraData.isLottie && [extraData.lottieResourceName hasSuffix:@".json"]) {
        barItemButton.backgroundColor = UIColor.clearColor;
    } else {
        [barItemButton setImage:ACCResourceImage(barItem.imageName) forState:UIControlStateNormal];
        if (barItem.selectedImageName) {
            [barItemButton setImage:ACCResourceImage(barItem.selectedImageName) forState:UIControlStateSelected];
        }
    }
    barItemButton.isAccessibilityElement = YES;
    barItemButton.accessibilityTraits = UIAccessibilityTraitButton;
    barItemButton.accessibilityLabel = barItem.title;
    barItemButton.adjustsImageWhenHighlighted = NO;
    return barItemButton;
}

- (LOTAnimationView *)p_createBarItemLottieView:(ACCBarItem *)barItem {
    ACCEditBarItemLottieExtraData *extraData = ACCDynamicCast(barItem.extraData, ACCEditBarItemLottieExtraData);
    if (extraData.isLottie && [extraData.lottieResourceName hasSuffix:@".json"]) {
        LOTAnimationView *lottieView = [LOTAnimationView animationWithFilePath:ACCResourceFile(extraData.lottieResourceName)];
        @weakify(self);
        [lottieView playWithCompletion:^(BOOL animationFinished) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.lottieCompletionBlock, animationFinished);
        }];
        return lottieView;
    } else {
        LOTAnimationView *lottieView = [LOTAnimationView new];
        lottieView.hidden = YES;
        return lottieView;
    }
}

- (UILabel *)p_createBarItemLabel:(ACCBarItem *)barItem
{
    if (ACC_isEmptyString(barItem.title)) {
        return nil;
    }

    CGFloat fontSzie = self.direction == ACCToolBarItemViewDirectionVertical ? 10 : 12;
    UILabel *label = [[UILabel alloc] acc_initWithFontSize:fontSzie isBold:YES textColor:ACCResourceColor(ACCUIColorConstTextInverse) text:barItem.title];
    label.textAlignment = NSTextAlignmentCenter;
    label.numberOfLines = 2;
    [label acc_addShadowWithShadowColor:ACCResourceColor(ACCUIColorConstLinePrimary) shadowOffset:CGSizeMake(0, 1) shadowRadius:2];
    label.isAccessibilityElement = NO;
    return label;
}

- (UIView *)redPointView
{
    if (!_redPointView) {
        UIView *redView = [[UIView alloc] init];
        redView.backgroundColor = [UIColor redColor];
        redView.layer.cornerRadius = kRedPointRadius;
        redView.clipsToBounds = YES;
        redView.hidden = NO;
        _redPointView = redView;
    }
    return _redPointView;
}

- (NSString *)p_redPointCacheKey
{
    NSString *itemIdValue = self.title;
    NSString *key = [[NSString alloc] initWithFormat:@"ACCToolBarItemRedPointHidden-%@", itemIdValue];
    if ([@[@"更多", @"收起", @"关闭"] containsObject: self.title]) {
        key = @"ACCToolBarItemRedPointHidden-More";
    }
    return key;
}

- (BOOL)p_getHideRedPointCache
{
    BOOL cache = NO;
    NSString *key = [self p_redPointCacheKey];
    cache = [ACCCache() boolForKey:key];
    return cache;
}

#pragma mark - Action

- (void)checkAndShowRedPoint
{
    if ([self shouldShowRedPoint]) {
        self.redPointView.hidden = NO;
        self.hasShownRedPoint = YES;
    } else {
        self.redPointView.hidden = YES;
    }
}

- (void)checkAndHideRedPoint
{
    if ([self shouldShowRedPoint] && self.hasShownRedPoint) {
        self.redPointView.hidden = YES;
        self.hideRedPointCache = YES;
    }
}

- (void)onButtonClicked:(UIButton *)button {
    [self checkAndHideRedPoint];
    ACCBLOCK_INVOKE(self.itemViewDidClicked, self.button);
}

- (BOOL)hideRedPointCache
{
    BOOL cache = NO;
    NSString *key = [self p_redPointCacheKey];
    cache = [ACCCache() boolForKey:key];
    return cache;
}

- (void)setHideRedPointCache:(BOOL)hideRedPointCache
{
    [ACCCache() setBool:hideRedPointCache forKey:[self p_redPointCacheKey]];
}

- (void)clearHideRedPointCache
{
    NSString *key = [self p_redPointCacheKey];
    if ([ACCCache() objectForKey:key] != nil) {
        [ACCCache() removeObjectForKey:key];
    }
    self.hideRedPointCache = NO;
}

- (void)showLabelWithDuration:(NSTimeInterval)duration
{
    [UIView animateWithDuration:duration animations:^{
        self.label.alpha = self.alpha;
    } completion:^(BOOL finished) {
        self.label.hidden = NO;
        if ([self shouldShowRedPoint]) {
            self.redPointView.hidden = NO;
        }
    }];
}

- (void)hideLabelWithDuration:(NSTimeInterval)duration
{
    if (duration <= 0) {
        self.redPointView.hidden = YES;
        self.label.hidden = YES;
        self.label.alpha = 0;
        return;
    }
    self.redPointView.hidden = YES;
    [UIView animateWithDuration:duration animations:^{
        self.label.alpha = 0;
    } completion:^(BOOL finished) {
        self.label.hidden = YES;
    }];
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *res = [super hitTest:point withEvent:event];
    if ((res == self || res == _lottieView) && _button.isUserInteractionEnabled && !_button.isHidden && _button.isEnabled && _button.alpha > 0.01) {
        return _button;
    }
    return res;
}

@end
