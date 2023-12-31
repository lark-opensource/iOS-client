//
//  BDPPermissionView.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/13.
//

#import "BDPPermissionView.h"
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPButton.h>
#import <OPFoundation/BDPCommonManager.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPImageView.h>
#import <OPFoundation/BDPNetworking.h>
#import <OPFoundation/BDPStyleCategoryDefine.h>
#import <OPFoundation/BDPView.h>
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIFont+BDPExtension.h>
#import <OPFoundation/UIView+BDPAppearance.h>
#import <OPFoundation/UIView+BDPBorders.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>

static const CGFloat kActionLabelHeight = 20.f;
static const CGFloat kActionLabelHeightNewStyle = 24.f;
static const CGFloat kActionLabelOffsetLeft = 12.f;
static const CGFloat kActionLabelOffsetTop = 22.f;
static const CGFloat kActionLabelMarginLeftNewStyle = 20.f;
static const CGFloat kActionLabelMarginTopNewStyle = 20.f;
static const CGFloat kButtonHeight = 48.f;
static const CGFloat kButtonOffsetBottom = 15.f;
static const CGFloat kCancelButtonOffsetLeft = 16.f;
static const CGFloat kConfirmButtonOffsetLeft = 10.f;
static const CGFloat kConfirmButtonOffsetRight = kCancelButtonOffsetLeft;
static const CGFloat kContentViewOffsetLeft = 16.f;
static const CGFloat kContentViewOffsetRight = kContentViewOffsetLeft;
static const CGFloat kLogoBorderWidth = 2.f;
static const CGFloat kLogoOffsetLeft = 16.f;
static const CGFloat kLogoOffsetTop = 16.f;
static const CGFloat kLogoWidth = 60.f;
static const CGFloat kViewCornerRadius = 4.f;
static const CGFloat kViewExtraHeight = 41.f;
static const CGFloat kViewReduceHeightHorizontal = 9.f; // 刘海屏下横屏小游戏需减少的弹窗高度
static const CGFloat kViewReduceHeightVertical = 22.f; // 刘海屏下竖屏小游戏需减少的弹窗高度

@interface _BDPPermissionContainerView : UIView

@property (nonatomic, assign) CGSize cornerRadii;
@property (nonatomic, assign) UIRectCorner rectCorner;

@end

@implementation _BDPPermissionContainerView

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    UIBezierPath *rounded = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                  byRoundingCorners:self.rectCorner
                                                        cornerRadii:self.cornerRadii];
    CAShapeLayer *shape = [CAShapeLayer layer];
    shape.frame = self.bounds;
    shape.path = rounded.CGPath;
    self.layer.mask = shape;
}

@end

@interface BDPPermissionView ()

@property (nonatomic, strong) UIView *mainContainer;
@property (nonatomic, strong) UIImageView *appLogoView;
@property (nonatomic, strong) UIView *logoContainer;
@property (nonatomic, strong) UILabel *appActionLabel;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIButton *cancelButton;
@property (nonatomic, strong, readwrite) UIButton *confirmButton;
@property (nonatomic, strong) UIView *contentContainerView;
@property (nonatomic, strong, readwrite) UIView *contentView;
@property (nonatomic, copy) NSString *logo;
@property (nonatomic, strong) UIView *privacyPolicyView;
@property (nonatomic, strong, readwrite) UILabel *privacyPolicyLabel;
@property (nonatomic, strong) UIImageView *privaPolicyImageView;

@end

@implementation BDPPermissionView

#pragma mark - init

- (instancetype)initWithActionDescption:(NSString *)actionDescription
                        permissionTitle:(NSString *)permissionTitle
                                logo:(NSString *)logo
                            contentView:(UIView *)contentView
                                appName:(NSString *)appName
                               newStyle:(BOOL)enableNewStyle
                               uniqueID:(BDPUniqueID *)uniqueID
{
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _appActionDescription = [actionDescription copy];
        _permisstionTitle = [permissionTitle copy];
        _contentView = contentView;
        _logo = logo.copy;
        _appName = [appName copy];
        _enableNewStyle = enableNewStyle;
        _uniqueID = uniqueID;
        BDPCommon *common = [[BDPCommonManager sharedManager] getCommonWithUniqueID:_uniqueID];
        
        [self setupUI];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithActionDescption:@""
                         permissionTitle:@""
                                    logo:@""
                             contentView:[UIView new]
                                 appName:@""
                                newStyle:self.enableNewStyle
                                uniqueID:nil];
}

#pragma mark - UI

_Pragma("clang diagnostic push")
_Pragma("clang diagnostic ignored \"-Wunguarded-availability\"")

- (void)setupUI
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.backgroundColor = [UIColor clearColor];

    [self setupMainContainer];
    [self setupLogo];
    [self setupActionLabel];
    [self setupContentView];
    [self setupCancelButton];
    [self setupConfirmButton];
}

- (void)setupMainContainer
{
    _BDPPermissionContainerView *effectContainer = [_BDPPermissionContainerView new];
    [self addSubview:effectContainer];
    
    UIVisualEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:effect];
    [effectContainer addSubview:visualEffectView];
    
    UIView *view = [UIView new];
    [visualEffectView.contentView addSubview:view];
    self.mainContainer = effectContainer;
    
    effectContainer.backgroundColor = [UIColor clearColor];
    effectContainer.cornerRadii = CGSizeMake(kViewCornerRadius, kViewCornerRadius);
    effectContainer.rectCorner = (UIRectCornerTopLeft | UIRectCornerTopRight);
    view.backgroundColor = UDOCColor.bgFloat;

    effectContainer.translatesAutoresizingMaskIntoConstraints = NO;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    visualEffectView.translatesAutoresizingMaskIntoConstraints = NO;
    [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [view.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    [view.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
    
    [effectContainer.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
    [effectContainer.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
    [effectContainer.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    [effectContainer.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
    
    [visualEffectView.topAnchor constraintEqualToAnchor:effectContainer.topAnchor].active = YES;
    [visualEffectView.bottomAnchor constraintEqualToAnchor:effectContainer.bottomAnchor].active = YES;
    [visualEffectView.leftAnchor constraintEqualToAnchor:effectContainer.leftAnchor].active = YES;
    [visualEffectView.rightAnchor constraintEqualToAnchor:effectContainer.rightAnchor].active = YES;
}

- (void)setupLogo
{
    BDPImageView *imageView = [[BDPImageView alloc] init];
    [self addSubview:imageView];
    self.appLogoView = imageView;
    
    BDPView *borderView = [BDPView new];
    [self insertSubview:borderView belowSubview:imageView];
    self.logoContainer = borderView;
    
    UIColor *borderColor = UDOCColor.bgFloat;
    imageView.bdp_styleCategories = @[BDPStyleCategoryLogo];
    imageView.backgroundColor = UDOCColor.bgFloat;
    borderView.bdp_styleCategories = @[BDPStyleCategoryLogo];
    borderView.layer.allowsEdgeAntialiasing = YES;
    borderView.backgroundColor = borderColor;
    UIImage *img = [UIImage imageNamed:@"permission_default_icon" inBundle:BDPBundle.mainBundle compatibleWithTraitCollection:nil];
    [BDPNetworking setImageView:imageView url:[NSURL URLWithString:self.logo?:@""] placeholder:img];

    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    borderView.translatesAutoresizingMaskIntoConstraints = NO;
    CGFloat imgWidth = kLogoWidth - kLogoBorderWidth * 2;
    CGFloat imgOffsetTop = kLogoOffsetTop - kLogoBorderWidth;
    CGFloat imgOffsetLeft = kLogoOffsetLeft - kLogoBorderWidth;
    [imageView.widthAnchor constraintEqualToConstant:imgWidth].active = YES;
    [imageView.heightAnchor constraintEqualToConstant:imgWidth].active = YES;
    [imageView.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:imgOffsetLeft].active = YES;
    [imageView.topAnchor constraintEqualToAnchor:self.topAnchor constant:-imgOffsetTop].active = YES;
    
    [borderView.topAnchor constraintEqualToAnchor:imageView.topAnchor constant:-kLogoBorderWidth].active = YES;
    [borderView.leftAnchor constraintEqualToAnchor:imageView.leftAnchor constant:-kLogoBorderWidth].active = YES;
    [borderView.bottomAnchor constraintEqualToAnchor:imageView.bottomAnchor constant:kLogoBorderWidth].active = YES;
    [borderView.rightAnchor constraintEqualToAnchor:imageView.rightAnchor constant:kLogoBorderWidth].active = YES;
    self.appLogoView.hidden = _enableNewStyle;
    self.logoContainer.hidden = _enableNewStyle;
}

- (void)setupActionLabel
{
    UILabel *label = [UILabel new];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:label];
    self.appActionLabel = label;
    label.textAlignment = NSTextAlignmentLeft;
    label.text = self.appActionDescription?:@"";
    label.numberOfLines = 0;

    if(_enableNewStyle) {
        label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightBold size:17.f];
        label.textColor = UDOCColor.textTitle;
        [label.leftAnchor constraintEqualToAnchor:self.mainContainer.leftAnchor
                                         constant:kActionLabelMarginLeftNewStyle].active = YES;
        [label.rightAnchor constraintEqualToAnchor:self.mainContainer.rightAnchor
                                         constant:-kActionLabelMarginLeftNewStyle].active = YES;
        [label.topAnchor constraintEqualToAnchor:self.topAnchor
                                        constant:kActionLabelMarginTopNewStyle].active = YES;
    } else {
        label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightRegular size:16.f];
        label.textColor = UDOCColor.textTitle;
        [label.leftAnchor constraintEqualToAnchor:self.logoContainer.rightAnchor constant:kActionLabelOffsetLeft].active = YES;
        CGFloat width = [self.appActionDescription?:@"" boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, kActionLabelHeight) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName: [UIFont bdp_pingFongSCWithWeight:UIFontWeightRegular size:16.f]} context:nil].size.width;
        if (width > self.frame.size.width - kActionLabelOffsetLeft * 2 - kLogoWidth) {
            [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:kActionLabelOffsetTop - kActionLabelHeight].active = YES;
            [label.heightAnchor constraintEqualToConstant:kActionLabelHeight*2].active = YES;
        } else {
            [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:kActionLabelOffsetTop].active = YES;
            [label.heightAnchor constraintEqualToConstant:kActionLabelHeight].active = YES;
        }
        [label.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-kLogoOffsetLeft].active = YES;
    }
}

- (void)setupContentView
{
    UIView *view = [UIView new];
    [self.mainContainer addSubview:view];
    self.contentContainerView = view;
    if(_enableNewStyle) {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.topAnchor constraintEqualToAnchor:self.appActionLabel.bottomAnchor].active = YES;
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:kActionLabelMarginLeftNewStyle].active = YES;
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-kActionLabelMarginLeftNewStyle].active = YES;
    } else {
        view.translatesAutoresizingMaskIntoConstraints = NO;
        [view.topAnchor constraintEqualToAnchor:self.logoContainer.bottomAnchor].active = YES;
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:kContentViewOffsetLeft].active = YES;
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-kContentViewOffsetRight].active = YES;
    }

    self.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    [view addSubview:self.contentView];
    [self.contentView sizeToFit];
    [self.contentView.topAnchor constraintEqualToAnchor:view.topAnchor].active = YES;
    [self.contentView.leftAnchor constraintEqualToAnchor:view.leftAnchor].active = YES;
    [self.contentView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor].active = YES;
    [self.contentView.rightAnchor constraintEqualToAnchor:view.rightAnchor].active = YES;
}

- (void)setupCancelButton
{
    BDPButton *button = [BDPButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:button];
    self.cancelButton = button;
    [button setTitle:BDPI18n.cancel forState:UIControlStateNormal];
    [button setTitle:BDPI18n.cancel forState:UIControlStateHighlighted];
    [button setTitle:BDPI18n.cancel forState:UIControlStateSelected];
    [button addTarget:self action:@selector(onCancelButtonTaped:) forControlEvents:UIControlEventTouchUpInside];

    if(_enableNewStyle) {
        button.titleLabel.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightRegular size:17.f];
        [button setTitleColor:UDOCColor.textTitle forState:UIControlStateNormal];
        [button.topAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [button.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
        [button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [button.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
        [button bdp_addBorderForEdges:UIRectEdgeTop|UIRectEdgeRight
                                width:0.5
                                color:UDOCColor.lineDividerDefault];
        [button addBDPMorePanelPointerInteraction];
    } else {
        button.bdp_styleCategories = @[BDPStyleCategoryNegative, BDPStyleCategoryButton];
        button.titleLabel.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightRegular size:16.f];
        [button.topAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [button.leftAnchor constraintEqualToAnchor:self.leftAnchor constant:kCancelButtonOffsetLeft].active = YES;
        // 根据是否需要显示隐私政策调整高度
        CGFloat buttonOffsetBottom = kButtonOffsetBottom;
        [button.bottomAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor constant:-buttonOffsetBottom].active = YES;
        [button.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
    }
}

- (void)setupConfirmButton
{
    BDPButton *button = [BDPButton buttonWithType:UIButtonTypeCustom];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mainContainer addSubview:button];
    self.confirmButton = button;
    [button setTitle:BDPI18n.allow forState:UIControlStateNormal];
    [button setTitle:BDPI18n.allow forState:UIControlStateHighlighted];
    [button setTitle:BDPI18n.allow forState:UIControlStateSelected];
    [button addTarget:self action:@selector(onConfirmButtonTaped:) forControlEvents:UIControlEventTouchUpInside];

    if(_enableNewStyle) {
        button.titleLabel.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightMedium size:17.f];
        [button setTitleColor:UDOCColor.primaryPri500 forState:UIControlStateNormal];
        [button.topAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [button.leftAnchor constraintEqualToAnchor:self.cancelButton.rightAnchor].active = YES;
        CGFloat buttonOffsetBottom = kButtonOffsetBottom;
        [button.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [button.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
        [button.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
        [button.widthAnchor constraintEqualToAnchor:self.cancelButton.widthAnchor].active = YES;
        [button bdp_addBorderForEdges:UIRectEdgeTop|UIRectEdgeLeft
                                width:0.5
                                color:UDOCColor.lineDividerDefault];
        [button addBDPMorePanelPointerInteraction];
    } else {
        button.bdp_styleCategories = @[BDPStyleCategoryPositive, BDPStyleCategoryButton];

        button.titleLabel.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightMedium size:16.f];

        [button.topAnchor constraintEqualToAnchor:self.contentView.bottomAnchor].active = YES;
        [button.leftAnchor constraintEqualToAnchor:self.cancelButton.rightAnchor constant:kConfirmButtonOffsetLeft].active = YES;
        // 根据是否需要显示隐私政策调整高度
        CGFloat buttonOffsetBottom = kButtonOffsetBottom;
        [button.bottomAnchor constraintEqualToAnchor:self.safeAreaLayoutGuide.bottomAnchor constant:-buttonOffsetBottom].active = YES;
        [button.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-kConfirmButtonOffsetRight].active = YES;
        [button.heightAnchor constraintEqualToConstant:kButtonHeight].active = YES;
        [button.widthAnchor constraintEqualToAnchor:self.cancelButton.widthAnchor].active = YES;
    }
}

- (void)setupSeperator {
    
}

_Pragma("clang diagnostic pop")

#pragma mark - Action

- (void)onCancelButtonTaped:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(permissionViewDidCancel:)]) {
        [self.delegate permissionViewDidCancel:self];
    }
}

- (void)onConfirmButtonTaped:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(permissionViewDidConfirm:)]) {
        [self.delegate permissionViewDidConfirm:self];
    }
}

@end
