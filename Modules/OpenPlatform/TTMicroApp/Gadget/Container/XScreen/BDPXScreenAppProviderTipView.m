//
//  BDPXScreenAppProviderTipView.m
//  TTMicroApp
//
//  Created by qianhongqiang on 2022/8/10.
//

#import "BDPXScreenAppProviderTipView.h"
#import <BDWebImage/BDWebImage.h>
#import <OPFoundation/BDPBundle.h>
#import <OPFoundation/OPFoundation.h>
#import <UniverseDesignColor/UniverseDesignColor-Swift.h>
#import <TTMicroApp/TTMicroApp-Swift.h>
#import <OPFoundation/BDPI18n.h>

static NSString *const kTipViewContentColor = @"#EBEBEB";

@interface BDPXScreenAppProviderTipView()

@property (nonatomic, copy) NSString *appName;
@property (nonatomic, copy) NSString *iconURL;

/// 响应点击(比实际展示的区域要大)
@property (nonatomic, strong) UIButton *responseButton;
/// 蒙层背景
@property (nonatomic, strong) UIImageView *maskBG;
/// 应用图标
@property (nonatomic, strong) UIImageView *iconImageView;
/// 应用名称
@property (nonatomic, strong) UILabel *appNameLabel;
/// 展示固定文案'提供服务'
@property (nonatomic, strong) UILabel *tipLabel;
/// 箭头->
@property (nonatomic, strong) UIImageView *arrowImageView;

@end

@implementation BDPXScreenAppProviderTipView

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        _appName = @"";
        _iconURL = @"";
        [self setupSubviews];
    }
    return self;
}


- (void)setupSubviews{
    // 添加蒙层，其余展示的内容都添加到蒙层上
    [self addSubview:self.maskBG];
    
    [self.maskBG addSubview:self.iconImageView];
    [self.maskBG addSubview:self.appNameLabel];
    [self.maskBG addSubview:self.tipLabel];
    [self.maskBG addSubview:self.arrowImageView];
    
    [self addSubview:self.responseButton];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    // 内容由内部数据向外面撑，autolayout会有闪烁，所以采用绝对布局
    CGRect appNameAppropriatebounds = [self.appName boundingRectWithSize:CGSizeMake(160, CGFLOAT_MAX)
                                                   options:NSStringDrawingUsesFontLeading|NSStringDrawingTruncatesLastVisibleLine|NSStringDrawingUsesLineFragmentOrigin
                                                attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:14]}
                                                   context:nil];
    
    CGFloat appNameAppropriateWidth = appNameAppropriatebounds.size.width;
    
    CGFloat componentMaiginLeftRight = 4.f;
    CGFloat tipViewHeight = 28.f;
    CGFloat component12HeightMaiginTop = (tipViewHeight - 12.f) / 2;
    CGFloat component20HeightMaiginTop = (tipViewHeight - 20.f) / 2;
    
    // 图标
    CGFloat xOffset = componentMaiginLeftRight;
    CGFloat appIconWightHeight = 20.f;
    self.iconImageView.frame = CGRectMake(xOffset, component20HeightMaiginTop, appIconWightHeight, appIconWightHeight);
    
    // 应用名称
    xOffset += appIconWightHeight + componentMaiginLeftRight;
    CGFloat appTextHeight = 20.f;
    self.appNameLabel.frame = CGRectMake(xOffset, component20HeightMaiginTop, appNameAppropriateWidth, appTextHeight);
    
    // 固定文案"提供服务"
    xOffset += appNameAppropriateWidth + componentMaiginLeftRight;
    [self.tipLabel sizeToFit];
    self.tipLabel.frame = CGRectMake(xOffset, component20HeightMaiginTop, self.tipLabel.frame.size.width, appTextHeight);
    
    // 箭头
    xOffset += self.tipLabel.frame.size.width + componentMaiginLeftRight;
    CGFloat arrowIconWightHeight = 12.f;
    self.arrowImageView.frame = CGRectMake(xOffset, component12HeightMaiginTop, arrowIconWightHeight, arrowIconWightHeight);
    
    // 最终样式 图标 + 应用名称 + "提供服务" + 箭头>
    CGFloat maskBGPaddingLeftRight = 6.f;
    self.maskBG.frame = CGRectMake(16, maskBGPaddingLeftRight, xOffset + arrowIconWightHeight + componentMaiginLeftRight , tipViewHeight);
    
    self.responseButton.frame = CGRectMake(12, 0, xOffset + arrowIconWightHeight + componentMaiginLeftRight + maskBGPaddingLeftRight * 2, 40);
}

#pragma mark - private
- (void)onResponseButtonClicked:(UIButton *)btn {
    if (self.delegate && [self.delegate respondsToSelector:@selector(didClickAppProviderTipView:)]) {
        [self.delegate didClickAppProviderTipView:self];
    }
}

#pragma mark - public
- (void)updateAppName:(NSString *)appName iconURL:(NSString *)iconURL {
    _appName = appName;
    _iconURL = iconURL;
    
    BDPExecuteOnMainQueue(^{
        self.appNameLabel.text = appName;
        [self.iconImageView bd_setImageWithURL:[NSURL URLWithString:iconURL] placeholder:[UIImage op_imageNamed:@"mp_app_icon_default"]];
        [self setNeedsLayout];
        [self layoutIfNeeded];
    });
}

#pragma mark - getter

- (UIButton *)responseButton {
    if (!_responseButton) {
        _responseButton = [[UIButton alloc] initWithFrame:CGRectZero];
        _responseButton.backgroundColor = [UIColor clearColor];
        [_responseButton addTarget:self action:@selector(onResponseButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _responseButton;
}

- (UIImageView *)maskBG {
    if (!_maskBG) {
        _maskBG = [[UIImageView alloc] initWithFrame:CGRectZero];
        _maskBG.image = [UIImage imageNamed:@"app_presents" inBundle:[BDPBundle mainBundle] compatibleWithTraitCollection:nil];
        _maskBG.layer.cornerRadius = 8;
        _maskBG.layer.masksToBounds = YES;
    }
    return _maskBG;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        _iconImageView.layer.cornerRadius = 5;
        _iconImageView.layer.masksToBounds = YES;
    }
    return _iconImageView;
}

- (UILabel *)appNameLabel {
    if (!_appNameLabel) {
        _appNameLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _appNameLabel.font = [UIFont systemFontOfSize:14];
        // 因为底部有蒙层，所以lm/dm中需要一样的色值,不使用UD颜色，直接写死
        _appNameLabel.textColor = [UIColor colorWithHexString:kTipViewContentColor];
    }
    return _appNameLabel;
}

- (UILabel *)tipLabel {
    if (!_tipLabel) {
        _tipLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _tipLabel.font = [UIFont systemFontOfSize:14];
        // 因为底部有蒙层，所以lm/dm中需要一样的色值,不使用UD颜色，直接写死
        _tipLabel.textColor = [UIColor colorWithHexString:kTipViewContentColor];
        _tipLabel.text = BDPI18n.OpenPlatform_MobApp_AppPresents;
    }
    return _tipLabel;
}
- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] initWithFrame:CGRectZero];
        // 因为底部有蒙层，所以lm/dm中需要一样的色值,不使用UD颜色，直接写死
        _arrowImageView.image = [UDOCIconBridge getIconByKey:UDOCIConKeyUDOCIConKeyRightBoldOulined renderingMode:UIImageRenderingModeAutomatic iconColor:[UIColor colorWithHexString:kTipViewContentColor]];
    }
    return _arrowImageView;
}

@end
