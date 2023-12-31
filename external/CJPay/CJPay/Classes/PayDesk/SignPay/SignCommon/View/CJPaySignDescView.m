//
//  CJPaySignDescView.m
//  Aweme
//
//  Created by chenbocheng on 2022/7/21.
//

#import "CJPaySignDescView.h"
#import "CJPayUIMacro.h"

@interface CJPaySignDescView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subDesLabel;

@end

@implementation CJPaySignDescView

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
    self.subDesLabel.text = subDesc;
    
    if (Check_ValidString(title) && Check_ValidString(subDesc)) {
        self.hidden = NO;
    } else {
        self.hidden = YES;
    }
}

#pragma mark - private method

- (void)p_setupUI {
    [self addSubview:self.titleLabel];
    [self addSubview:self.subDesLabel];
    
    CJPayMasMaker(self.titleLabel, {
        make.left.top.equalTo(self);
    });
    
    CJPayMasMaker(self.subDesLabel, {
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

- (UILabel *)subDesLabel {
    if (!_subDesLabel) {
        _subDesLabel = [UILabel new];
        _subDesLabel.textColor = [UIColor cj_161823ff];
        _subDesLabel.font = [UIFont cj_fontOfSize:14];
        _subDesLabel.numberOfLines = 0;
    }
    return _subDesLabel;
}

@end
