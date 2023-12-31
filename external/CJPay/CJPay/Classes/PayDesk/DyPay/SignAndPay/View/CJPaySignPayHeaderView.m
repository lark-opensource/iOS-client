//
//  CJPaySignPayHeaderView.m
//  CJPaySandBox
//
//  Created by ZhengQiuyu on 2023/6/28.
//

#import "CJPaySignPayHeaderView.h"
#import "CJPayMarketingMsgView.h"
#import "CJPaySignPayModel.h"

#import "CJPayUIMacro.h"

@interface CJPaySignPayHeaderView ()

@property (nonatomic, strong) UIImageView *titleIconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;

@end

@implementation CJPaySignPayHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
        [self setupConstraints];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.titleIconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.marketingMsgView];
}

- (void)setupConstraints {
    CJPayMasMaker(self.titleLabel, {
        make.top.mas_equalTo(self);
        make.centerX.mas_equalTo(self).mas_offset(11);
    });
    
    CJPayMasMaker(self.titleIconImageView, {
        make.right.mas_equalTo(self.titleLabel.mas_left).mas_offset(-6);
        make.centerY.mas_equalTo(self.titleLabel);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.mas_equalTo(self.titleLabel.mas_bottom).mas_offset(6);
        make.left.right.centerX.mas_equalTo(self);
    });
    
    CJPayMasMaker(self.marketingMsgView, {
        make.top.mas_equalTo(self.subTitleLabel.mas_bottom).mas_offset(4);
        make.left.right.bottom.mas_equalTo(self);
    });
}

- (void)updateHeaderViewWithModel:(CJPaySignPayModel *)model {
    [self.titleIconImageView cj_setImageWithURL:model.logoImageURL];
    self.titleLabel.text = CJString(model.title);
    self.subTitleLabel.text = CJString(model.subTitle);
}

- (void)updateMarketingMsgWithPayAmount:(NSString *)payAmount voucherMsg:(NSString *)voucherMsg {
    [self.marketingMsgView updateWithPayAmount:payAmount voucherMsg:voucherMsg];
}

#pragma mark - lazy Load

- (UIImageView *)titleIconImageView {
    if (!_titleIconImageView) {
        _titleIconImageView = [UIImageView new];
    }
    return _titleIconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:16];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _subTitleLabel;
}

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [[CJPayMarketingMsgView alloc] initWithViewStyle:MarketingMsgViewStyleNormal];
    }
    return _marketingMsgView;
}

@end
