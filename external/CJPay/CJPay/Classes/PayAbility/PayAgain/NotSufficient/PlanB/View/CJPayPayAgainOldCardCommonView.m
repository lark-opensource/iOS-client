//
//  CJPayPayAgainOldCardCommonView.m
//  Pods
//
//  Created by wangxiaohong on 2021/6/30.
//

#import "CJPayPayAgainOldCardCommonView.h"

#import "CJPayUIMacro.h"

@interface CJPayPayAgainOldCardCommonView()

@property (nonatomic, strong) UILabel *bankPreLabel;
@property (nonatomic, strong) UIImageView *bankIconImageView;
@property (nonatomic, strong) UILabel *bankLabel;

@end

@implementation CJPayPayAgainOldCardCommonView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.bankPreLabel];
    [self addSubview:self.bankIconImageView];
    [self addSubview:self.bankLabel];
    
    CJPayMasMaker(self.bankPreLabel, {
        make.top.left.bottom.equalTo(self);
    });
    
    CJPayMasMaker(self.bankIconImageView, {
        make.left.equalTo(self.bankPreLabel.mas_right).offset(4);
        make.centerY.equalTo(self.bankPreLabel);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.bankLabel, {
        make.left.equalTo(self.bankIconImageView.mas_right).offset(2);
        make.centerY.equalTo(self.bankPreLabel);
        make.right.equalTo(self);
    });
}

- (UILabel *)bankPreLabel {
    if (!_bankPreLabel) {
        _bankPreLabel = [UILabel new];
        _bankPreLabel.textColor = [UIColor cj_161823ff];
        _bankPreLabel.font = [UIFont cj_fontOfSize:14];
        _bankPreLabel.text = CJPayLocalizedStr(@"是否改用");
    }
    return _bankPreLabel;
}

- (UIImageView *)bankIconImageView {
    if (!_bankIconImageView) {
        _bankIconImageView = [UIImageView new];
    }
    return _bankIconImageView;
}

- (UILabel *)bankLabel {
    if (!_bankLabel) {
        _bankLabel = [UILabel new];
        _bankLabel.textColor = [UIColor cj_161823ff];
        _bankLabel.font = [UIFont cj_fontOfSize:14];
        _bankLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;
    }
    return _bankLabel;
}

@end
