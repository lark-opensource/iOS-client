//
//  CJPayResultDetailItemView.m
//  Pods
//
//  Created by wangxiaohong on 2022/7/19.
//

#import "CJPayResultDetailItemView.h"

#import "CJPayUIMacro.h"

@interface CJPayResultDetailItemView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *detailLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UIImageView *unfoldArrow;

@end

@implementation CJPayResultDetailItemView

- (instancetype)init {
    self = [super init];
    if (self) {
        [self p_setupUI];
        _needScaleFont = YES;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithTitle:(NSString *)titleStr detail:(NSString *)detailStr {
    [self updateWithTitle:titleStr detail:detailStr iconUrl:nil];
}

- (void)updateWithTitle:(NSString *)titleStr detail:(NSString *)detailStr iconUrl:(NSString *)iconUrlStr {
    self.titleLabel.text = CJString(titleStr);
    self.detailLabel.text = CJString(detailStr);
    if (Check_ValidString(iconUrlStr)) {
        self.iconImageView.hidden = NO;
        [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:iconUrlStr]];
    }
    
    if (!self.needScaleFont) {
        self.titleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        self.detailLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
    }
}

- (void)updateFoldViewWithTitle:(NSString *)titleStr detail:(NSString *)detailStr {
    [self updateWithTitle:titleStr detail:detailStr];
    self.unfoldArrow.hidden = NO;
    [self addSubview:self.unfoldArrow];
    
    CJPayMasReMaker(self.detailLabel, {
        make.right.equalTo(self.unfoldArrow.mas_left).offset(-2);
        make.top.equalTo(self.titleLabel);
    });
    
    CJPayMasMaker(self.unfoldArrow, {
        make.right.equalTo(self).offset(-16);
        make.centerY.equalTo(self.titleLabel);
        make.height.width.mas_equalTo(16);
    });
    if (!self.needScaleFont) {
        self.titleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
        self.detailLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:13];
    }
}

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.detailLabel];
    [self addSubview:self.iconImageView];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.equalTo(self).offset(16);
        make.top.bottom.equalTo(self);
    });
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    CJPayMasMaker(self.detailLabel, {
        make.left.mas_greaterThanOrEqualTo(self.titleLabel.mas_right).mas_offset(20);
        make.right.equalTo(self).offset(-16);
        make.top.mas_equalTo(self.titleLabel);
    });
    
    self.iconImageView.hidden = YES;
    CJPayMasMaker(self.iconImageView, {
        make.left.mas_greaterThanOrEqualTo(self.titleLabel.mas_right).offset(8);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(18);
        make.right.equalTo(self.detailLabel.mas_left).offset(-3);
    });
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
    }
    return _titleLabel;
}

- (UILabel *)detailLabel {
    if (!_detailLabel) {
        _detailLabel = [UILabel new];
        _detailLabel.font = [UIFont cj_fontOfSize:13];
        _detailLabel.textColor = [UIColor cj_161823ff];
        _detailLabel.textAlignment = NSTextAlignmentRight;
    }
    return _detailLabel;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
        _iconImageView.hidden = YES;
    }
    return _iconImageView;
}

- (UIImageView *)unfoldArrow {
    if (!_unfoldArrow) {
        _unfoldArrow = [UIImageView new];
        [_unfoldArrow cj_setImage:@"cj_paymethod_unfold_arrow_icon"];
        _unfoldArrow.hidden = YES;
    }
    return _unfoldArrow;
}

@end
