//
//  CJPayUnionBindCardChooseHeaderView.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionBindCardChooseHeaderView.h"

#import "CJPayUIMacro.h"
#import "CJPayUnionPaySignInfo.h"

@interface CJPayUnionBindCardChooseHeaderView()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *descTitleLabel;
@property (nonatomic, strong) UILabel *discountLabel;
@property (nonatomic, strong) UIView *subContentView;

@end

@implementation CJPayUnionBindCardChooseHeaderView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)updateWithUnionPaySignInfo:(CJPayUnionPaySignInfo *)payInfo {
    if (Check_ValidString(payInfo.voucherLabel)) {
        self.discountLabel.hidden = NO;
        self.iconImageView.hidden = YES;
        self.descTitleLabel.hidden = YES;
        
        self.discountLabel.text = payInfo.voucherLabel;
    } else {
        self.discountLabel.hidden = YES;
        self.iconImageView.hidden = NO;
        self.descTitleLabel.hidden = NO;
        if (Check_ValidString(payInfo.displayIcon)) {
            [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:payInfo.displayIcon]];
        }
        self.descTitleLabel.text = CJString(payInfo.displayDesc);
    }
}

- (void)updateTitle:(NSString *)title {
    self.titleLabel.text = title;
}

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.discountLabel];
    [self addSubview:self.subContentView];
    
    [self.subContentView addSubview:self.iconImageView];
    [self.subContentView addSubview:self.descTitleLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self).offset(8);
        make.centerX.equalTo(self);
    })
    
    CJPayMasMaker(self.discountLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.centerX.equalTo(self);
        make.bottom.equalTo(self).offset(-22);
    })
    
    CJPayMasMaker(self.subContentView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.centerX.equalTo(self);
        make.bottom.equalTo(self).offset(-22);
    })
    
    CJPayMasMaker(self.iconImageView, {
        make.width.height.mas_equalTo(16);
        make.left.centerY.equalTo(self.subContentView);
    })
    
    CJPayMasMaker(self.descTitleLabel, {
        make.left.equalTo(self.iconImageView.mas_right).offset(4);
        make.top.bottom.right.equalTo(self.subContentView);
    })
    
    self.discountLabel.hidden = YES;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:22];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.text = CJPayLocalizedStr(@"选择绑定的云闪付银行卡");
    }
    return _titleLabel;
}

- (UIView *)subContentView {
    if (!_subContentView) {
        _subContentView = [UIView new];
    }
    return _subContentView;
}

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (UILabel *)descTitleLabel {
    if (!_descTitleLabel) {
        _descTitleLabel = [UILabel new];
        _descTitleLabel.font = [UIFont cj_fontOfSize:14];
        _descTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
    }
    return _descTitleLabel;
}

- (UILabel *)discountLabel {
    if (!_discountLabel) {
        _discountLabel = [UILabel new];
        _discountLabel.font = [UIFont cj_boldFontOfSize:14];
        _discountLabel.textColor = [UIColor cj_fe2c55ff];
    }
    return _discountLabel;
}



@end
