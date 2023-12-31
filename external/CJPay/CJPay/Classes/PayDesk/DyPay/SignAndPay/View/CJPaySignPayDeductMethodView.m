//
//  CJPaySignPayDeductMethodView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/29.
//

#import "CJPaySignPayDeductMethodView.h"
#import "CJPayUIMacro.h"
#import "CJPaySignPayModel.h"
#import "CJPayDefaultChannelShowConfig.h"

@interface CJPaySignPayDeductMethodView ()

@property (nonatomic, strong) UILabel *deductMethodTitleLabel;

@property (nonatomic, strong) UIView *deductContentView;

@property (nonatomic, strong) UIImageView *deductIconImageView;
@property (nonatomic, strong) UILabel *deductTitleLabel;
@property (nonatomic, strong) UILabel *subDeductTitleLabel;

@property (nonatomic, strong) UIImageView *deductArrowImageView;

@end

@implementation CJPaySignPayDeductMethodView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

#pragma mark - private func

- (void)p_arrowClick {
    CJ_CALL_BLOCK(self.payMethodClick);
}

- (void)setupUI {
    [self addSubview:self.deductMethodTitleLabel];
    
    [self addSubview:self.deductContentView];
    
    [self.deductContentView addSubview:self.deductArrowImageView];
    
    [self.deductContentView addSubview:self.deductIconImageView];
    [self.deductContentView addSubview:self.deductTitleLabel];
    [self.deductContentView addSubview:self.subDeductTitleLabel];
}

- (void)setupConstraints {
    CJPayMasMaker(self.deductMethodTitleLabel, {
        make.left.mas_equalTo(self).mas_offset(16);
        make.right.bottom.mas_lessThanOrEqualTo(self);
        make.top.mas_equalTo(self);
        make.width.mas_equalTo(56);
    });
    
    CJPayMasMaker(self.deductContentView, {
        make.top.mas_equalTo(self.deductMethodTitleLabel);
        make.left.mas_equalTo(self.deductMethodTitleLabel.mas_right).mas_offset(24);
        make.right.mas_equalTo(self);
        make.bottom.mas_lessThanOrEqualTo(self);
    });
    
    CJPayMasMaker(self.deductArrowImageView, {
        make.right.mas_equalTo(self.deductContentView).mas_offset(-16);
        make.centerY.mas_equalTo(self.deductMethodTitleLabel);
        make.height.width.mas_equalTo(20);
    });

    CJPayMasMaker(self.deductIconImageView, {
        make.left.mas_equalTo(self.deductContentView);
        make.right.bottom.mas_lessThanOrEqualTo(self.deductContentView);
        make.top.mas_equalTo(self.deductContentView);
        make.height.width.mas_equalTo(16);
    });

    CJPayMasMaker(self.deductTitleLabel, {
        make.left.mas_equalTo(self.deductIconImageView.mas_right).mas_offset(4);
        make.right.mas_equalTo(self.deductArrowImageView.mas_left).mas_offset(-2);
        make.centerY.mas_equalTo(self.deductIconImageView);
    });

    CJPayMasMaker(self.subDeductTitleLabel, {
        make.left.right.mas_equalTo(self.deductTitleLabel);
        make.top.mas_equalTo(self.deductTitleLabel.mas_bottom).mas_offset(2);
        make.bottom.mas_lessThanOrEqualTo(self.deductContentView);
    });
}

- (void)updateDeductMethodViewWithModel:(CJPaySignPayModel *)model {
    self.deductMethodTitleLabel.text = CJPayLocalizedStr(@"付款方式");
    [self.deductIconImageView cj_setImageWithURL:model.deductIconImageURL];
    self.deductTitleLabel.text = CJString(model.deductMethodDesc);
    self.subDeductTitleLabel.text = CJString(model.deductMethodSubDesc);
}

- (void)updateDeductMethodViewWithConfig:(CJPayDefaultChannelShowConfig *)defaultConfig {
    NSURL *deductIconImageURL = [NSURL cj_URLWithString:defaultConfig.iconUrl];
    [self.deductIconImageView cj_setImageWithURL:deductIconImageURL];
    self.deductTitleLabel.text = CJString(defaultConfig.title);
}

#pragma mark - lazy load

- (UILabel *)deductMethodTitleLabel {
    if (!_deductMethodTitleLabel) {
        _deductMethodTitleLabel = [UILabel new];
        _deductMethodTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _deductMethodTitleLabel.font = [UIFont cj_fontOfSize:14];
    }
    return _deductMethodTitleLabel;
}

- (UIView *)deductContentView {
    if (!_deductContentView) {
        _deductContentView = [UIView new];
        [_deductContentView cj_viewAddTarget:self action:@selector(p_arrowClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _deductContentView;
}

- (UIImageView *)deductArrowImageView {
    if (!_deductArrowImageView) {
        _deductArrowImageView = [UIImageView new];
        [_deductArrowImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _deductArrowImageView;
}

- (UIImageView *)deductIconImageView {
    if (!_deductIconImageView) {
        _deductIconImageView = [UIImageView new];
    }
    return _deductIconImageView;
}

-(UILabel *)deductTitleLabel {
    if (!_deductTitleLabel) {
        _deductTitleLabel = [UILabel new];
        _deductTitleLabel.textColor = [UIColor cj_161823ff];
        _deductTitleLabel.font = [UIFont cj_fontOfSize:14];
        _deductTitleLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _deductTitleLabel;
}

- (UILabel *)subDeductTitleLabel {
    if (!_subDeductTitleLabel) {
        _subDeductTitleLabel = [UILabel new];
        _subDeductTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _subDeductTitleLabel.font = [UIFont cj_fontOfSize:12];
        _subDeductTitleLabel.numberOfLines = 0;
    }
    return _subDeductTitleLabel;
}

@end
