//
//  BDPPhoneNumberPermissionContentView.m
//  Timor
//
//  Created by liuxiangxin on 2019/6/19.
//

#import "BDPPhoneNumberPermissionContentView.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/UIFont+BDPExtension.h>
#import <OPFoundation/UIView+BDPBorders.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPResponderHelper.h>

static const CGFloat kTitleLabelOffsetTop = 24.f;
static const CGFloat kContainerOffsetTop = 7.f;
static const CGFloat kContainerOffsetBottom = 0.f;
static const CGFloat kImageViewWidth = 44.f;
static const CGFloat kImageViewHeight = kImageViewWidth;
static const CGFloat kImageViewOffsetTop = 13.f;
static const CGFloat kImageViewOffsetBottom = 36.f;
static const CGFloat kBorderWidth = 0.5f;
static const CGFloat kPhoneNumberTitleOffsetLeft = 12.f;
static const CGFloat kContentHeight = 152.f;

@interface BDPPhoneNumberPermissionContentView ()

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong, readwrite) UILabel *titleLabel;
@property (nonatomic, strong, readwrite) UIImageView *phoneIconView;
@property (nonatomic, strong, readwrite) UILabel *phoneNumberLabel;
@property (nonatomic, strong) UIView *topBorder;
@property (nonatomic, strong) UIView *bottomBorder;

@property (nonatomic, weak) UIWindow *targetWindow;

@end

@implementation BDPPhoneNumberPermissionContentView

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame window:(nonnull UIWindow *)window
{
    self = [super initWithFrame:frame];
    if (self) {
        self.targetWindow = window;
        [self setupUI];
    }
    
    return self;
}


#pragma mark - UI

_Pragma("clang diagnostic push")
_Pragma("clang diagnostic ignored \"-Wunguarded-availability\"")

- (void)setupUI
{
    [self setupTitleLabel];
    [self setupContainer];
    [self setupPhoneNumberIcon];
    [self setupPhoneNumberTitle];
    [self setupBorders];
}

- (void)setupTitleLabel
{
    UILabel *label = [UILabel new];
    [self addSubview:label];
    self.titleLabel = label;
    
    label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightMedium size:18.f];
    label.textColor = [UIColor bdp_BlackColor1];
    
    label.text = BDPI18n.bound_phone_number;

    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label.topAnchor constraintEqualToAnchor:self.topAnchor constant:kTitleLabelOffsetTop].active = YES;
    [label.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
}

- (void)setupContainer
{
    UIView *view = [UIView new];
    [self addSubview:view];
    self.containerView = view;
    
    view.translatesAutoresizingMaskIntoConstraints = NO;
    [view.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor
                                   constant:kContainerOffsetTop].active = YES;
    [view.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
    [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor
                                      constant:-kContainerOffsetBottom].active = YES;
    [view.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
}

- (void)setupPhoneNumberIcon
{
    UIImage *img = [UIImage imageNamed:@"phone_number_auth" inBundle:BDPBundle.mainBundle compatibleWithTraitCollection:nil];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:img];
    [self.containerView addSubview:imageView];
    self.phoneIconView = imageView;
    
    imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [imageView.leftAnchor constraintEqualToAnchor:self.containerView.leftAnchor].active = YES;
    [imageView.topAnchor constraintEqualToAnchor:self.containerView.topAnchor
                                        constant:kImageViewOffsetTop].active = YES;
    [imageView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor
                                        constant:-kImageViewOffsetBottom].active = YES;
    [imageView.widthAnchor constraintEqualToConstant:kImageViewWidth].active = YES;
    [imageView.heightAnchor constraintEqualToConstant:kImageViewHeight].active = YES;
}

- (void)setupPhoneNumberTitle
{
    UILabel *label = [UILabel new];
    [self.containerView addSubview:label];
    self.phoneNumberLabel = label;
    
    label.font = [UIFont bdp_pingFongSCWithWeight:UIFontWeightRegular size:16.f];
    label.textColor = [UIColor bdp_BlackColor1];
    
#if DEBUG
    label.text = @"***********";
#endif
    
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [label.centerYAnchor constraintEqualToAnchor:self.phoneIconView.centerYAnchor].active = YES;
    [label.leftAnchor constraintEqualToAnchor:self.phoneIconView.rightAnchor constant:kPhoneNumberTitleOffsetLeft].active = YES;
}

- (void)setupBorders
{
    [self.containerView bdp_addBorderForEdges:UIRectEdgeTop
                                        width:kBorderWidth
                                        color:UIColor.bdp_BlackColor7];
    self.topBorder = self.bdp_topBorder;
    self.bottomBorder = self.bdp_bottomBorder;
}

- (CGSize)intrinsicContentSize
{
    // 原始逻辑为取[[UIScreen mainScreen] bounds].size.width
    // 适配iPad时解除屏幕依赖，统一换成用[BDPResponderHelper windowSize]取window的width
    return CGSizeMake([BDPResponderHelper windowSize:self.window?:self.targetWindow].width, kContentHeight);
}

_Pragma("clang diagnostic pop")

#pragma mark - Getter && Setter

- (void)setPhoneNumer:(NSString *)phoneNumer
{
    _phoneNumer = [phoneNumer copy];
    self.phoneNumberLabel.text = phoneNumer;
}

@end
