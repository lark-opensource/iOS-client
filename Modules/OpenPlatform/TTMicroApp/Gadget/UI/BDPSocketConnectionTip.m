//
//  BDPSocketConnectionTip.m
//  Timor
//
//  Created by tujinqiu on 2020/4/8.
//

#import "BDPSocketConnectionTip.h"
#import <OPFoundation/UIColor+BDPExtension.h>
#import <OPFoundation/BDPI18n.h>
#import <OPFoundation/BDPBundle.h>
#import <Masonry/Masonry.h>

#define TipStatusRowHeight 44
#define FinishButtonRowHeight 60



@interface BDPSocketConnectionTip ()

// 文案、提示、按钮容器视图
@property (nonatomic, strong) UIView *contentView;
// 第一行状态显示、展开按钮
@property (nonatomic, strong) UIView *tipRowView;
// 第二行结束调试按钮
@property (nonatomic, strong) UIView *finishRowView;
// 两行之间的分隔线
@property (nonatomic, strong) UIView *rowSplitLineView;
// 状态 icon
@property (nonatomic, strong) UIImageView *tipIconView;
// 状态提示文案
@property (nonatomic, strong) UILabel *tipTextLabel;
// 展开按钮
@property (nonatomic, strong) UIButton *expandButton;
// 停止调试按钮
@property (nonatomic, strong) UIButton *finishDebugButton;
// 断点命中时的全局遮罩
@property (nonatomic, strong) UIView *maskView;

@property (nonatomic, assign) BOOL expanded;

@property (nonatomic, strong) MASConstraint *finishRowTopConstraint;
@property (nonatomic, strong) MASConstraint *contentHeightConstraint;

@property (nonatomic, strong) UIImage *yesIcon;
@property (nonatomic, strong) UIImage *pauseIcon;

@property (nonatomic, assign) BDPSocketDebugType debugType;

@end

@implementation BDPSocketConnectionTip
#pragma mark - init & setup

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.expanded = NO;
        [self addSubview:self.maskView];
        [self addSubview:self.contentView];
        [self setupContentView];
        [self setupConstraints];
        self.maskView.hidden = true;
    }
    return self;
}

- (void)setupContentView {

    [self.tipRowView addSubview:self.tipIconView];
    [self.tipRowView addSubview:self.tipTextLabel];
    [self.tipRowView addSubview:self.expandButton];

    [self.finishRowView addSubview:self.finishDebugButton];

    [self.contentView addSubview:self.tipRowView];
    [self.contentView addSubview:self.finishRowView];
    [self.contentView addSubview:self.rowSplitLineView];

    if(!self.expanded) {
        self.finishRowView.hidden = true;
        self.finishRowView.alpha = 0;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    [self setupContentViewMask];
}

- (void)setupContentViewMask {
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerBottomLeft)
                                                         cornerRadii:CGSizeMake(4, 4)];
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.path = maskPath.CGPath;
    self.contentView.layer.mask = maskLayer;
}

- (void)setupConstraints
{
    [self.maskView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];

    [self.contentView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.mas_safeAreaLayoutGuideTop).offset(64);
        make.right.equalTo(self);
        self.contentHeightConstraint = make.height.equalTo(@(TipStatusRowHeight + (self.expanded ? FinishButtonRowHeight : 0)));
    }];

    [self.tipRowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.equalTo(self.contentView);
        make.height.equalTo(@TipStatusRowHeight);
    }];

    [self.finishRowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@FinishButtonRowHeight);
        make.left.right.equalTo(self.contentView);
        self.finishRowTopConstraint = make.bottom.equalTo(self.contentView);
    }];

    [self.tipIconView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.equalTo(@14);
        make.centerY.equalTo(self.tipRowView);
        make.leading.equalTo(self.tipRowView).offset(16);
    }];

    [self.tipTextLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.equalTo(self.tipIconView.mas_trailing).offset(8);
        make.centerY.equalTo(self.tipRowView);
        make.trailing.equalTo(self.expandButton.mas_leading).offset(8);
    }];

    [self.expandButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.tipRowView);
        make.trailing.equalTo(self.contentView);
        make.width.height.equalTo(@(TipStatusRowHeight));
    }];

    [self.rowSplitLineView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@1);
        make.top.equalTo(self.tipRowView.mas_bottom);
        make.leading.trailing.equalTo(self.contentView).inset(16);
    }];

    [self.finishDebugButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(self.finishRowView);
        make.leading.trailing.top.bottom.equalTo(self.finishRowView).inset(16);
    }];
}

#pragma mark - logic
- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *hitView = [super hitTest:point withEvent:event];
    if(hitView == self){
        return nil;
    }
    return hitView;
}


- (void)setStatus:(BDPSocketDebugTipStatus)status {
    switch (status) {
        case BDPSocketDebugTipStatusConnected:
            self.tipTextLabel.text = BDPI18n.OpenPlatform_RealdeviceDebug_connected;
            [self.tipIconView setImage:self.yesIcon];
            break;
        case BDPSocketDebugTipStatusConnectFailed:
            self.tipTextLabel.text = BDPI18n.OpenPlatform_RealdeviceDebug_disconnected;
            [self.tipIconView setImage:nil];
            break;
        case BDPSocketDebugTipStatusHitDebugPoint:
            self.tipTextLabel.text = BDPI18n.OpenPlatform_RealdeviceDebug_hitbreakpoint;
            [self.tipIconView setImage:self.pauseIcon];
            break;
        default:
            NSAssert(NO, @"BDPSocketDebugTipStatus: %@ not handled!", status);
            self.tipTextLabel.text = @"";
            break;
    }

    if(status == BDPSocketDebugTipStatusHitDebugPoint) {
        self.maskView.hidden = false;
        if([self.delegate respondsToSelector:@selector(realDeviceDebugMaskVisibleChangedTo:)]) {
            [self.delegate realDeviceDebugMaskVisibleChangedTo:YES];
        }
    } else {
        self.maskView.hidden = true;
        if([self.delegate respondsToSelector:@selector(realDeviceDebugMaskVisibleChanged:)]) {
            [self.delegate realDeviceDebugMaskVisibleChangedTo:NO];
        }
    }
}

-(void)setSocketDebugType:(BDPSocketDebugType)type{
    self.debugType = type;
    if(type == BDPSocketDebugTypePerformanceProfile){
        [self.finishDebugButton setTitle:BDPI18n.OpenPlatform_GadgetAnalytics_StopRecBttn forState:UIControlStateNormal];
    }
}

- (void)toggleExpandStatus {
    self.expanded = !self.expanded;

    CGAffineTransform transform = self.expandButton.imageView.transform;
    transform = CGAffineTransformRotate(transform, M_PI);

    self.rowSplitLineView.hidden = !self.expanded;

    self.contentHeightConstraint.equalTo(@(TipStatusRowHeight + (self.expanded ? FinishButtonRowHeight : 0)));

    [self.contentView setNeedsUpdateConstraints];
    [self.contentView updateConstraintsIfNeeded];

    self.finishRowView.hidden = !self.expanded;

    [UIView animateWithDuration:0.35 animations:^{
        self.expandButton.imageView.transform = transform;
        self.finishRowView.alpha = self.expanded ? 1 : 0;
        [self layoutIfNeeded];
    }];
}

-(void)onFinishDebugButtonTaped:(UIButton *)sender {
    if([self.delegate respondsToSelector:@selector(finishDebugButtonPressedWithType:)]) {
        [self.delegate finishDebugButtonPressedWithType:self.debugType];
    }
}


#pragma mark - lazy init
- (UIView *)maskView {
    if(!_maskView) {
        _maskView = [UIView new];
        _maskView.backgroundColor = [UIColor colorWithHexString:@"1F232966"];
    }
    return _maskView;
}

- (UIView *)contentView {
    if(!_contentView) {
        _contentView = [UIView new];
        _contentView.backgroundColor = [UIColor colorWithHexString:@"#1f2329"];
    }
    return _contentView;
}

- (UIView *)tipRowView {
    if(!_tipRowView) {
        _tipRowView = [UIView new];
    }
    return _tipRowView;
}

- (UIView *)finishRowView {
    if(!_finishRowView) {
        _finishRowView = [UIView new];
    }
    return _finishRowView;
}

- (UIView *)rowSplitLineView {
    if(!_rowSplitLineView) {
        _rowSplitLineView = [UIView new];
        _rowSplitLineView.backgroundColor = [UIColor.whiteColor colorWithAlphaComponent:0.16];
    }
    return _rowSplitLineView;
}

- (UIImageView *)tipIconView {
    if(!_tipIconView) {
        _tipIconView = [UIImageView new];
        UIImage *yesIcon = self.yesIcon;
        [_tipIconView setImage:yesIcon];
    }
    return _tipIconView;
}

- (UILabel *)tipTextLabel {
    if(!_tipTextLabel) {
        _tipTextLabel = [UILabel new];
        _tipTextLabel.font = [UIFont systemFontOfSize:14];
        _tipTextLabel.textColor = UIColor.whiteColor;
        _tipTextLabel.text = BDPI18n.ide_debug_connected;
    }
    return _tipTextLabel;
}

- (UIButton *)expandButton {
    if(!_expandButton) {
        _expandButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *expandImage = [UIImage imageNamed:@"icon_expand-down_filled"
                                                   inBundle:[BDPBundle mainBundle]
                              compatibleWithTraitCollection:nil];
        [_expandButton setImage:expandImage forState:UIControlStateNormal];

        if(!self.expanded) {
            CGAffineTransform transform = CGAffineTransformIdentity;
            transform = CGAffineTransformRotate(transform, M_PI);
            _expandButton.imageView.transform = transform;
        }

        [_expandButton addTarget:self action:@selector(toggleExpandStatus) forControlEvents:UIControlEventTouchUpInside];
    }
    return _expandButton;
}

- (UIButton *)finishDebugButton {
    if(!_finishDebugButton){
        _finishDebugButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _finishDebugButton.titleLabel.font = [UIFont systemFontOfSize:12];
        [_finishDebugButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [_finishDebugButton setTitle:BDPI18n.OpenPlatform_RealdeviceDebug_enddebug forState:UIControlStateNormal];
        [_finishDebugButton addTarget:self action:@selector(onFinishDebugButtonTaped:) forControlEvents:UIControlEventTouchUpInside];
        [_finishDebugButton setContentEdgeInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        _finishDebugButton.layer.cornerRadius = 4;
        _finishDebugButton.layer.borderWidth = 1;
        _finishDebugButton.layer.borderColor = [UIColor colorWithHexString:@"BBBFC4"].CGColor;
    }
    return _finishDebugButton;
}

- (UIImage *) yesIcon {
    if(!_yesIcon) {
        _yesIcon = [UIImage imageNamed:@"icon_yes_filled"
                              inBundle:[BDPBundle mainBundle]
         compatibleWithTraitCollection:nil];
    }
    return _yesIcon;
}

- (UIImage *) pauseIcon {
    if(!_pauseIcon) {
        _pauseIcon = [UIImage imageNamed:@"icon_pause-round_filled"
                                inBundle:[BDPBundle mainBundle]
           compatibleWithTraitCollection:nil];
    }
    return _pauseIcon;
}

@end
