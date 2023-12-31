//
//  ACCEditTagStickerView.m
//  CameraClient-Pods-AwemeCore
//
//  Created by 卜旭阳 on 2021/10/6.
//

#import "ACCEditTagStickerView.h"

#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>

#import <ByteDanceKit/UIImage+BTDAdditions.h>

static CGFloat const kACCEditTagStickerViewTagPointPadding = 6.f;

@interface ACCEditTagStickerView()

@property (nonatomic, strong) CALayer *animationLayer;
@property (nonatomic, strong) UIView *pointView; // 小圆点

@property (nonatomic, strong) UIView *tagBackgroundView;
@property (nonatomic, strong) UIImageView *iconView; // 图标的View
@property (nonatomic, strong) UILabel *titleLabel;

@property (nonatomic, strong) UIImageView *rightArrowImageView;

@end

@implementation ACCEditTagStickerView

@synthesize coordinateDidChange;
@synthesize stickerId;
@synthesize transparent = _transparent;
@synthesize stickerContainer;

- (id)copyForContext:(id)contextId
{
    AWEInteractionEditTagStickerModel *interactionStickerModel = [self.interactionStickerModel copy];
    return [[[self class] alloc] initWithStickerModel:interactionStickerModel];
}

static CGFloat kTextWidthLimit = 180.f + 5;

- (instancetype)initWithStickerModel:(AWEInteractionStickerModel *)model
{
    self = [super init];
    if (self) {
        if ([model isKindOfClass:AWEInteractionEditTagStickerModel.class]) {
            _maxTextWidth = kTextWidthLimit;
            [self setupUI];
            self.interactionStickerModel = (AWEInteractionEditTagStickerModel *)model;
        }
    }
    self.userInteractionEnabled = NO;
    return self;
}

- (void)setInteractionStickerModel:(AWEInteractionEditTagStickerModel *)interactionStickerModel
{
    _interactionStickerModel = interactionStickerModel;
    @weakify(self);
    [[[[RACObserve(_interactionStickerModel.editTagInfo, orientation) skip:1] takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateUI];
    }];
    [self updateUI];
}

static CGFloat const kDefaultTextHeight = 18.f;
static CGFloat const kVerticalMargin = 5.f;

- (void)setupUI
{
    UIView *pointView = [[UIView alloc] init];
    pointView.frame = CGRectMake(0.f, 9.f, 6.f, 6.f);
    
    UIImage *cropImage = [UIImage btd_imageWithSize:CGSizeMake(10.f, 10.f) cornerRadius:5.f backgroundColor:ACCResourceColor(ACCColorSDTertiary)];
    CALayer *animationLayer = [[CALayer alloc] init];
    animationLayer.contents = (__bridge id)cropImage.CGImage;
    animationLayer.frame = CGRectMake(-2.f, -2.f, 10.f, 10.f);
    animationLayer.position = CGPointMake(3.f, 3.f);
    [pointView.layer addSublayer:animationLayer];
    self.animationLayer = animationLayer;
    
    UIView *whitePointView = [[UIView alloc] init];
    whitePointView.backgroundColor = [UIColor whiteColor];
    whitePointView.layer.cornerRadius = 3.f;
    whitePointView.frame = CGRectMake(0.f, 0.f, 6.f, 6.f);
    [pointView addSubview:whitePointView];
    [self addSubview:pointView];
    self.pointView = pointView;

    UIView *tagBackgroundView = [[UIView alloc] init];
    tagBackgroundView.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
    tagBackgroundView.layer.cornerRadius = 14.f;
    tagBackgroundView.layer.borderWidth = 1.f;
    tagBackgroundView.layer.borderColor = ACCResourceColor(ACCColorConstLineInverse).CGColor;
    tagBackgroundView.frame = CGRectMake(0.f, 0.f, 84.f, kDefaultTextHeight + 2 * kVerticalMargin);
    [self addSubview:tagBackgroundView];
    self.tagBackgroundView = tagBackgroundView;
    
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.frame = CGRectMake(8.f, 8.f, 12.f, 12.f);
    [tagBackgroundView addSubview:iconView];
    self.iconView = iconView;
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont acc_systemFontOfSize:12.f weight:ACCFontWeightMedium];
    titleLabel.frame = CGRectMake(iconView.acc_right + 4, kVerticalMargin, 0.f, kDefaultTextHeight);
    [tagBackgroundView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    UIImageView *rightArrowImageView = [[UIImageView alloc] init];
    rightArrowImageView.image = ACCResourceImage(@"right_arrow_12x12");
    rightArrowImageView.frame = CGRectMake(8.f, 7.f, 12.f, 12.f);
    [tagBackgroundView addSubview:rightArrowImageView];
    self.rightArrowImageView = rightArrowImageView;
}

- (void)setNumberOfLines:(NSUInteger)numberOfLines
{
    _numberOfLines = numberOfLines;
    self.titleLabel.numberOfLines = numberOfLines;
    [self updateUI];
}

- (void)updateUI
{
    [self p_updateIconImage];
    
    BOOL showIconImage = [self showIconImage];
    self.iconView.hidden = !showIconImage;
    
    // 点的占用空间
    CGFloat pointWidth = kACCEditTagStickerViewTagPointPadding + 6.f;
    // icon和文字边距距离
    CGFloat beforeTextWidth = showIconImage ? (8.f + 12.f + 4.f) : 12.f;
    CGFloat afterTextWidth = [[self editTagInfo] interactional]? (2.f + 6.f + 12.f) : 12.f;

    // 纯文字内容宽度
    self.titleLabel.text = [self editTagInfo].text;
    CGSize textSize = [self.titleLabel sizeThatFits:CGSizeMake(self.maxTextWidth, self.titleLabel.font.lineHeight * self.numberOfLines)];
    CGFloat actualTextWidth = MIN(self.maxTextWidth, textSize.width) ;

    CGFloat contentWidth = pointWidth + beforeTextWidth + actualTextWidth + afterTextWidth; // 实际占用宽度
    CGFloat contentHeight = MAX(kDefaultTextHeight, textSize.height) + 2 * kVerticalMargin;
    
    self.titleLabel.acc_width = actualTextWidth;
    self.titleLabel.acc_height = MAX(kDefaultTextHeight, textSize.height);
    self.titleLabel.acc_left = showIconImage ? (self.iconView.acc_right + 4) : 12;
    self.tagBackgroundView.acc_width = beforeTextWidth + actualTextWidth + afterTextWidth;
    
    if ([self editTagInfo].orientation == ACCEditTagOrientationRight) {
        self.tagBackgroundView.acc_left = 0.f;
        self.pointView.acc_right = contentWidth;
    } else {
        self.pointView.acc_left = 0.f;
        self.tagBackgroundView.acc_right = contentWidth;
    }
    self.tagBackgroundView.acc_height = contentHeight;
    self.pointView.acc_centerY = contentHeight / 2.f;
    
    if ([[self editTagInfo] interactional]) {
        self.rightArrowImageView.hidden = NO;
        self.rightArrowImageView.acc_right = self.tagBackgroundView.acc_width - 6;
        self.rightArrowImageView.acc_centerY = contentHeight / 2.f;
    } else {
        self.rightArrowImageView.hidden = YES;
    }
    
    self.bounds = CGRectMake(0.f, 0.f, contentWidth, contentHeight);
    ACCBLOCK_INVOKE(self.coordinateDidChange);
}

- (AWEInteractionEditTagStickerInfoModel *)editTagInfo
{
    return self.interactionStickerModel.editTagInfo;
}

#pragma mark - private
- (void)p_updateIconImage
{
    switch ([self editTagInfo].type) {
        case ACCEditTagTypeUser:
            self.iconView.image = ACCResourceImage(@"edittag_icon_person");
            break;
        case ACCEditTagTypePOI:
            self.iconView.image = ACCResourceImage(@"edittag_icon_location");
            break;
        case ACCEditTagTypeCommodity:
            self.iconView.image = ACCResourceImage(@"edittag_icon_goods");
            break;
        case ACCEditTagTypeBrand:
            self.iconView.image = ACCResourceImage(@"edittag_icon_brand");
            break;
        default:
            self.iconView.image = nil;
            break;
    }
}

- (void)updateInteractionModel:(AWEInteractionEditTagStickerModel *)interactionStickerModel
{
    self.interactionStickerModel = interactionStickerModel;
}

- (void)showHeartAnimation
{
    CABasicAnimation *scaleAni = [CABasicAnimation animation];
    scaleAni.keyPath = @"transform.scale";
    scaleAni.toValue = @(1.4);
    scaleAni.repeatCount = CGFLOAT_MAX;
    scaleAni.duration = 0.5;
    scaleAni.autoreverses = YES;
    scaleAni.removedOnCompletion = NO;
    scaleAni.timingFunction = [CAMediaTimingFunction functionWithControlPoints:0.46 :0 :0.18 :1];
    
    [self.animationLayer addAnimation:scaleAni forKey:@"heart_scale"];
}

- (void)setTransparent:(BOOL)transparent
{
    _transparent = transparent;
    self.alpha = transparent? 0.5: 1.0;
}

- (void)setMaxContentWidth:(CGFloat)maxContentWidth
{
    _maxContentWidth = maxContentWidth;
    // 点的占用空间
    CGFloat pointWidth = kACCEditTagStickerViewTagPointPadding + 6.f;
    // icon和文字边距距离
    CGFloat beforeTextWidth = [self showIconImage] ? (8.f + 12.f + 4.f) : 12.f;
    CGFloat afterTextWidth = [[self editTagInfo] interactional]? (2.f + 6.f + 12.f) : 12.f;
    self.maxTextWidth = maxContentWidth - pointWidth - beforeTextWidth - afterTextWidth;
}

- (void)setMaxTextWidth:(CGFloat)maxTextWidth
{
    if (maxTextWidth < kTextWidthLimit) {
        _maxTextWidth = maxTextWidth;
    }
    [self updateUI];
}

#pragma mark - Utils

- (BOOL)showIconImage
{
    return [self editTagInfo].type != ACCEditTagTypeNone && [self editTagInfo].type != ACCEditTagTypeSelfDefine;
}

- (CGPoint)normalizedTagCenterPoint
{
    return CGPointMake(self.pointView.center.x / self.frame.size.width, self.pointView.center.y / self.frame.size.height);
}

@end
