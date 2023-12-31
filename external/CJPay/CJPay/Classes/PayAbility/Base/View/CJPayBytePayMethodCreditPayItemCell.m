//
//  CJPayBytePayMethodCreditPayItemCell.m
//  Pods
//
//  Created by bytedance on 2021/7/27.
//

#import "CJPayBytePayMethodCreditPayItemCell.h"
#import "CJPayBytePayCreditPayMethodModel.h"
#import "CJPayUIMacro.h"

@interface CJPayBytePayMethodCreditPayItemCell ()

@property (nonatomic, strong) UIView *borderView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *contentLabel;
@property (nonatomic, strong) UILabel *iconLabel;
@property (nonatomic, strong) UIView *iconBgView;
@property (nonatomic, strong) UIView *iconView;

@end

@implementation CJPayBytePayMethodCreditPayItemCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    self.contentView.layer.cornerRadius = 4;
    
    [self.contentView addSubview:self.borderView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.contentLabel];
    [self.contentView addSubview:self.iconView];
    [self.contentView addSubview:self.iconBgView];
    [self.contentView addSubview:self.iconLabel];
    
    CJPayMasMaker(self.borderView, {
        make.edges.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.contentView).offset(10);
        make.left.equalTo(self.contentView).offset(5);
        make.right.equalTo(self.contentView).offset(-5);
        make.height.equalTo(@18);
    });
    
    CJPayMasMaker(self.contentLabel, {
        make.top.equalTo(self.contentView).offset(28);
        make.left.equalTo(self.contentView).offset(5);
        make.right.equalTo(self.contentView).offset(-5);
        make.height.equalTo(@14);
    });
    
    CJPayMasMaker(self.iconLabel, {
        make.centerY.equalTo(self.iconBgView);
        make.left.equalTo(self.iconBgView).offset(4);
        make.right.equalTo(self.iconBgView).offset(-4);
        make.height.equalTo(@16);
    });
    
    CJPayMasMaker(self.iconBgView, {
        make.top.equalTo(self.contentView).offset(-6);
        make.right.equalTo(self.contentView);
        make.left.mas_greaterThanOrEqualTo(self.contentView);
        make.height.equalTo(@16);
    });
    
    CJPayMasMaker(self.iconView, {
        make.edges.equalTo(self.iconBgView);
    });
}

- (void)setModel:(CJPayBytePayCreditPayMethodModel *)model {
    self.contentView.backgroundColor = model.choose ? [UIColor cj_fe2c55WithAlpha:0.05] : [UIColor cj_161823WithAlpha:0.03];
    self.borderView.layer.borderColor = (model.choose ? [UIColor cj_fe2c55WithAlpha:0.12] : [UIColor cj_161823WithAlpha:0.03]).CGColor;
    self.borderView.layer.borderWidth = model.choose ? 0.5 : 0;

    
    if ([model.status isEqualToString:@"0"]) {
        self.titleLabel.textColor =  [UIColor cj_161823WithAlpha:0.24];
        self.contentLabel.textColor =  [UIColor cj_161823WithAlpha:0.24];
        self.iconLabel.textColor = [UIColor cj_fe2c55WithAlpha:0.24];
    } else {
        self.titleLabel.textColor =  model.choose ?  [UIColor cj_fe2c55ff] : [UIColor cj_161823WithAlpha:0.75];
        self.contentLabel.textColor =  model.choose ?  [UIColor cj_fe2c55WithAlpha:0.75] : [UIColor cj_161823WithAlpha:0.34];
        self.iconLabel.textColor = [UIColor cj_fe2c55WithAlpha:0.90];
    }
    id voucherMsg = [model.voucherMsg cj_objectAtIndex:0];
    NSString *voucherStr;
    if ([voucherMsg isKindOfClass:NSString.class]) {
        voucherStr = (NSString *)voucherMsg;
    }
    self.iconLabel.text = CJString(voucherStr);
    self.iconLabel.hidden = !Check_ValidString(voucherStr);
    self.iconBgView.hidden = !Check_ValidString(voucherStr);
    self.iconView.hidden = !Check_ValidString(voucherStr);
    self.titleLabel.text = model.payTypeDesc;
    self.contentLabel.text = model.feeDesc;
    if ([model.status isEqualToString:@"0"] && model.feeDesc.length <= 0) {
        self.contentLabel.text = model.msg;
    }
}

- (UIView *)borderView {
    if (!_borderView) {
        _borderView = [UIView new];
        _borderView.backgroundColor = [UIColor clearColor];
        _borderView.layer.borderWidth = 0.5;
        _borderView.layer.cornerRadius = 4;
    }
    return _borderView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:12];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [UILabel new];
        _contentLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:10];
        _contentLabel.textColor = [UIColor cj_161823WithAlpha:0.34];
        _contentLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _contentLabel;
}

- (UILabel *)iconLabel {
    if (!_iconLabel) {
        _iconLabel = [UILabel new];
        _iconLabel.font = [UIFont cj_fontWithoutFontScaleOfSize:10];
        _iconLabel.textColor = [UIColor cj_fe2c55WithAlpha:0.90];
        _iconLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _iconLabel;
}

- (UIView *)iconBgView {
    if (!_iconBgView) {
        _iconBgView = [UIView new];
        _iconBgView.backgroundColor = [UIColor cj_fe2c55WithAlpha:0.12];
        _iconBgView.layer.cornerRadius = 2;
    }
    return _iconBgView;
}

- (UIView *)iconView {
    if (!_iconView) {
        _iconView = [UIView new];
        _iconView.backgroundColor = [UIColor whiteColor];
        _iconView.layer.cornerRadius = 2;
    }
    return _iconView;
}

@end
