//
//  CJPaySignPayDescView.m
//  Aweme
//
//  Created by ZhengQiuyu on 2023/7/12.
//

#import "CJPaySignPayDescView.h"
#import "CJPayUIMacro.h"

@interface CJPaySignPayDescView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subDescLabel;

@end

@implementation CJPaySignPayDescView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - public method

- (void)updateTitle:(NSString *)title subDesc:(NSString *)subDesc {
    self.titleLabel.text = title;
    self.subDescLabel.text = subDesc;
    
    if (Check_ValidString(title) && Check_ValidString(subDesc)) {
        self.hidden = NO;
    } else {
        self.hidden = YES;
    }
}

#pragma mark - private method

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.subDescLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.top.equalTo(self);
        make.right.lessThanOrEqualTo(self);
    });
    
    CJPayMasMaker(self.subDescLabel, {
        make.top.equalTo(self.titleLabel);
        make.right.equalTo(self);
        make.left.equalTo(self).offset(80);
        make.left.greaterThanOrEqualTo(self.titleLabel.mas_right).offset(24).priorityHigh();
        make.bottom.equalTo(self);
    });
}

#pragma mark - lazy view

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.6];
        _titleLabel.font = [UIFont cj_fontOfSize:14];
    }
    return _titleLabel;
}

- (UILabel *)subDescLabel {
    if (!_subDescLabel) {
        _subDescLabel = [UILabel new];
        _subDescLabel.textColor = [UIColor cj_161823ff];
        _subDescLabel.font = [UIFont cj_fontOfSize:14];
        _subDescLabel.numberOfLines = 0;
    }
    return _subDescLabel;
}
@end
