//
//  CJPayBDPayMainMessageView.m
//  CJPay
//
//  Created by wangxiaohong on 2020/2/13.
//

#import "CJPayBDPayMainMessageView.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayCoupleLabelView.h"

@interface CJPayBDPayMainMessageView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) UILabel *subDescLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) CJPayCoupleLabelView *voucherLabelView;
@property (nonatomic, assign) BOOL isSubDescLabelForceHidden; // 优惠标签与副标题强制互斥
@property (nonatomic, copy) NSString *subDescStr;

@property (nonatomic, strong) UIView *descContentView;

@property (nonatomic, strong) UIView *disableView;

@property (nonatomic, strong) MASConstraint *descLabelRightbaseSelfConstraint;
@property (nonatomic, strong) MASConstraint *descLabelRightbaseImageViewConstraint;
@property (nonatomic, strong) MASConstraint *subDescLabelHeightConstraint;
@property (nonatomic, strong) MASConstraint *descContentBottomBaseVoucherConstraint;
@property (nonatomic, strong) MASConstraint *descContentBottomBaseSubDescConstraint;

@end

@implementation CJPayBDPayMainMessageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupViews];
    }
    return self;
}

- (void)setStyle:(CJPayBDPayMainMessageViewStyle)style
{
    _style = style;
    if (style == CJPayBDPayMainMessageViewStyleNone) {
        self.arrowImageView.hidden = YES;
        self.iconImageView.hidden = YES;
        [self.descLabelRightbaseImageViewConstraint deactivate];
        [self.descLabelRightbaseSelfConstraint activate];
    } else {
        self.arrowImageView.hidden = NO;
        self.iconImageView.hidden = NO;
        [self.descLabelRightbaseSelfConstraint deactivate];
        [self.descLabelRightbaseImageViewConstraint activate];
    }
}

- (void)setEnable:(BOOL)enable
{
    _enable = enable;
    self.disableView.hidden = enable;
}

- (void)updateTitleLabelText:(NSString *)title
{
    self.titleLabel.text = title;
}

- (void)updateDescLabelText:(NSString *)desc
{
    self.descLabel.text = desc;
}

- (void)updateWithIconUrl:(NSString *)iconUrl {
    if (Check_ValidString(iconUrl)) {
        self.iconImageView.hidden = NO;
        [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:iconUrl]
                                   placeholder:[UIImage cj_roundImageWithColor:[UIColor cj_skeletonScreenColor]]];
    } else {
        self.iconImageView.hidden = YES;
    }
}

- (void)updateWithVoucher:(NSArray *) vouchers {
    [self.voucherLabelView updateCoupleLabelContents:vouchers];
    if (vouchers.count > 0) {
        self.isSubDescLabelForceHidden = YES;
        [self updateSubDescLabelText:@""];
        
        [self.descContentBottomBaseSubDescConstraint deactivate];
        [self.descContentBottomBaseVoucherConstraint activate];
    } else {
        self.isSubDescLabelForceHidden = NO;
        [self updateSubDescLabelText:self.subDescStr];
        
        [self.descContentBottomBaseVoucherConstraint deactivate];
        [self.descContentBottomBaseSubDescConstraint activate];
    }
}

- (void)updateSubDescLabelText:(NSString *)subDesc {
    self.subDescStr = subDesc;
    if (Check_ValidString(subDesc) && !self.isSubDescLabelForceHidden) {  // 有优惠时强制隐藏subDescLabel
        self.subDescLabel.hidden = NO;
        self.subDescLabel.text = subDesc;
        self.subDescLabelHeightConstraint.offset = 17;
    } else {
        self.subDescLabel.hidden = YES;
        self.subDescLabelHeightConstraint.offset = 0;
    }
}

- (void)p_arrowImageViewTapped
{
    if (self.style == CJPayBDPayMainMessageViewStyleArrow) {
        CJ_CALL_BLOCK(self.arrowBlock);
    }
}

- (void)p_setupViews
{
    [self.descContentView addSubview:self.iconImageView];
    [self.descContentView addSubview:self.descLabel];
    [self.descContentView addSubview:self.subDescLabel];
    [self.descContentView addSubview:self.voucherLabelView];
    
    [self addSubview:self.titleLabel];
    [self addSubview:self.descContentView];
    [self addSubview:self.arrowImageView];
    [self addSubview:self.disableView];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self).offset(16);
        make.centerY.equalTo(self);
    });
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.descContentView, {
        make.left.equalTo(self.titleLabel.mas_right).offset(16);
        make.centerY.equalTo(self);
        self.descLabelRightbaseSelfConstraint = make.right.equalTo(self).offset(-16);
        self.descLabelRightbaseImageViewConstraint = make.right.equalTo(self.arrowImageView.mas_left);

        self.descContentBottomBaseSubDescConstraint = make.bottom.equalTo(self.subDescLabel);
        self.descContentBottomBaseVoucherConstraint = make.bottom.equalTo(self.voucherLabelView);
    });
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(20);
    });
        
    CJPayMasMaker(self.descLabel, {
        make.top.right.equalTo(self.descContentView);
    });
    
    [self.descLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    
    CJPayMasMaker(self.subDescLabel, {
        make.top.equalTo(self.descLabel.mas_bottom).offset(1);
        make.right.equalTo(self.descLabel);
        make.left.equalTo(self.descContentView);
        self.subDescLabelHeightConstraint = make.height.mas_equalTo(17);
    });
    
    CJPayMasMaker(self.iconImageView, {
        make.left.greaterThanOrEqualTo(self.descContentView);
        make.width.height.mas_equalTo(20);
        make.right.equalTo(self.descLabel.mas_left).offset(-8);
        make.centerY.equalTo(self.descLabel);
    });
    
    CJPayMasMaker(self.disableView, {
        make.left.equalTo(self.descContentView);
        make.right.equalTo(self);
        make.centerY.equalTo(self);
        make.height.equalTo(self);
    })
    
    CJPayMasMaker(self.voucherLabelView, {
        make.left.greaterThanOrEqualTo(self.descContentView);
        make.top.equalTo(self.descLabel.mas_bottom).offset(2);
        make.right.equalTo(self.descContentView).offset(16);
    });
    [self.voucherLabelView setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
    
    [CJPayLineUtil addBottomLineToView:self marginLeft:16 marginRight:16 marginBottom:0];
    self.enable = YES;
    
    [self cj_viewAddTarget:self
                    action:@selector(p_arrowImageViewTapped)
          forControlEvents:UIControlEventTouchUpInside];
    
    [self.descContentView cj_viewAddTarget:self
                                    action:@selector(p_arrowImageViewTapped)
                          forControlEvents:UIControlEventTouchUpInside];
    
    [self updateSubDescLabelText:@""];  //默认隐藏副标题
}

- (UIView *)disableView {
    if (!_disableView) {
        _disableView = [UIView new];
        _disableView.backgroundColor = [UIColor cj_ffffffWithAlpha:0.8];
    }
    return _disableView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.font = [UIFont cj_fontOfSize:14];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
    }
    return _titleLabel;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] init];
    }
    return _iconImageView;
}

- (UILabel *)descLabel
{
    if (!_descLabel) {
        _descLabel = [[UILabel alloc] init];
        _descLabel.font = [UIFont cj_fontOfSize:14];
        _descLabel.textColor = [UIColor cj_161823ff];
        _descLabel.textAlignment = NSTextAlignmentRight;
    }
    return _descLabel;
}

- (UIImageView *)arrowImageView
{
    if (!_arrowImageView) {
        _arrowImageView = [[UIImageView alloc] init];
        [_arrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _arrowImageView;
}

- (UILabel *)subDescLabel {
    if (!_subDescLabel) {
        _subDescLabel = [UILabel new];
        _subDescLabel.font = [UIFont cj_fontOfSize:12];
        _subDescLabel.textColor = [UIColor cj_999999ff];
        _subDescLabel.textAlignment = NSTextAlignmentRight;
        _subDescLabel.adjustsFontSizeToFitWidth = true;
        _subDescLabel.minimumScaleFactor = 0.7;
    }
    return _subDescLabel;
}

- (UIView *)descContentView {
    if (!_descContentView) {
        _descContentView = [UIView new];
    }
    return _descContentView;
}

- (void)startLoading {
    [self.arrowImageView cj_startLoading];
}

- (void)stopLoading {
    [self.arrowImageView cj_stopLoading];
}

- (CJPayCoupleLabelView *)voucherLabelView {
    if (!_voucherLabelView) {
        _voucherLabelView = [CJPayCoupleLabelView new];
    }
    return _voucherLabelView;
}

@end
