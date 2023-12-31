//
//  CJPaySignHeaderView.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/8.
//

#import "CJPaySignHeaderView.h"

#import "CJPayHomePageAmountView.h"
#import "CJPayUIMacro.h"

@interface CJPaySignHeaderView()

@property (nonatomic, strong) UIImageView *titleIconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *descLabel;
@property (nonatomic, strong) CJPayMarketingMsgView *marketingMsgView;
@property (nonatomic, strong) UIImageView *logoImageView;
@property (nonatomic, strong) UILabel *logoDescLabel;
@property (nonatomic, strong) UILabel *logoSubDescLabel;

@end

@implementation CJPaySignHeaderView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.titleIconImageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.descLabel];
    [self addSubview:self.marketingMsgView];
    [self addSubview:self.logoImageView];
    [self addSubview:self.logoDescLabel];
    [self addSubview:self.logoSubDescLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self);
        make.centerX.equalTo(self).offset(11);
    });
    
    CJPayMasMaker(self.titleIconImageView, {
        make.right.equalTo(self.titleLabel.mas_left).offset(-6);
        make.centerY.equalTo(self.titleLabel);
        make.width.height.mas_equalTo(16);
    });
    
    CJPayMasMaker(self.descLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(6);
        make.left.right.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.marketingMsgView, {
        make.top.equalTo(self.descLabel.mas_bottom).offset(4);
        make.left.right.bottom.equalTo(self);
    });
    
    CJPayMasMaker(self.logoImageView, {
        make.top.equalTo(self);
        make.centerX.equalTo(self);
        make.width.height.mas_equalTo(68);
    });
    
    CJPayMasMaker(self.logoDescLabel, {
        make.top.equalTo(self.logoImageView.mas_bottom).offset(16);
        make.centerX.equalTo(self);
    })
    
    CJPayMasMaker(self.logoSubDescLabel, {
        make.top.equalTo(self.logoDescLabel.mas_bottom).offset(6);
        make.centerX.equalTo(self);
        make.bottom.lessThanOrEqualTo(self);
    })
}

- (void)setIsSignOnly:(BOOL)isSignOnly {
    _isSignOnly = isSignOnly;
    if (isSignOnly) {
        self.logoImageView.hidden = NO;
        self.logoDescLabel.hidden = NO;
        self.logoSubDescLabel.hidden = NO;
        self.titleIconImageView.hidden = YES;
        self.titleLabel.hidden = YES;
        self.descLabel.hidden = YES;
        self.marketingMsgView.hidden = YES;
    } else {
        self.logoImageView.hidden = YES;
        self.logoDescLabel.hidden = YES;
        self.logoSubDescLabel.hidden = YES;
        self.titleIconImageView.hidden = NO;
        self.titleLabel.hidden = NO;
        self.descLabel.hidden = NO;
        self.marketingMsgView.hidden = NO;
    }
}

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
        _titleLabel.font = [UIFont cj_fontOfSize:16];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _titleLabel;
}

- (UILabel *)descLabel {
    if (!_descLabel) {
        _descLabel = [UILabel new];
        _descLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _descLabel.font = [UIFont cj_fontOfSize:12];
        _descLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _descLabel;
}

- (CJPayMarketingMsgView *)marketingMsgView {
    if (!_marketingMsgView) {
        _marketingMsgView = [CJPayMarketingMsgView new];
    }
    return _marketingMsgView;
}

- (UIImageView *)logoImageView {
    if (!_logoImageView) {
        _logoImageView = [UIImageView new];
    }
    return _logoImageView;
}

- (UILabel *)logoDescLabel {
    if (!_logoDescLabel) {
        _logoDescLabel = [UILabel new];
        _logoDescLabel.font = [UIFont cj_boldFontOfSize:18];
        _logoDescLabel.textColor = [UIColor cj_161823ff];
    }
    return _logoDescLabel;
}

- (UILabel *)logoSubDescLabel {
    if (!_logoSubDescLabel) {
        _logoSubDescLabel = [UILabel new];
        _logoSubDescLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _logoSubDescLabel.font = [UIFont cj_fontOfSize:12];
        _logoSubDescLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _logoSubDescLabel;
}

@end
