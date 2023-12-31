//
//  CJPayBindCardContainerView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/14.
//

#import "CJPayBindCardContainerView.h"
#import "CJPayUIMacro.h"

@interface CJPayBindCardContainerView()

@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation CJPayBindCardContainerView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupUI];
    }
    return self;
}

- (void)setupUI {
    [self addSubview:self.subTitleLabel];
    CJPayMasMaker(self.subTitleLabel, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.top.equalTo(self).offset(10);
        make.height.mas_equalTo(17);
    });
    
    [self addSubview:self.mainTitleLabel];
    CJPayMasMaker(self.mainTitleLabel, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.top.equalTo(self).offset(33);
        make.height.mas_equalTo(24);
    });
    
    [self addSubview:self.rightImageView];
    CJPayMasMaker(self.rightImageView, {
        make.right.equalTo(self).offset(-24);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
        make.top.equalTo(self).mas_offset(33);
    });
    
    [self addSubview:self.bottomLine];
    CJPayMasMaker(self.bottomLine, {
        make.left.equalTo(self).offset(24);
        make.right.equalTo(self).offset(-24);
        make.top.equalTo(self).offset(69);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
    
    self.isClickStyle = NO;
}

- (void)updateWithMainStr:(NSString *)mainStr
                   subStr:(NSString *)subStr {
    self.mainTitleLabel.text = mainStr;
    self.subTitleLabel.text  = subStr;
}

- (void)setIsClickStyle:(BOOL)isClickStyle {
    _isClickStyle = isClickStyle;
    [self updateStyle];
}

- (void)updateStyle {
    if (self.isClickStyle) {
        self.subTitleLabel.textColor = [UIColor cj_999999ff];
        self.mainTitleLabel.textColor = [UIColor cj_222222ff];
        self.rightImageView.hidden = NO;
    } else {
        self.subTitleLabel.textColor = [UIColor cj_cacacaff];
        self.mainTitleLabel.textColor = [UIColor cj_cacacaff];
        self.rightImageView.hidden = YES;
    }
}

- (UIView *)bottomLine {
    if (!_bottomLine) {
        _bottomLine = [[UIView alloc] init];
        _bottomLine.backgroundColor = [UIColor cj_e8e8e8ff];
    }
    return _bottomLine;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
        _subTitleLabel.textColor = [UIColor cj_999999ff];
    }
    return _subTitleLabel;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [[UILabel alloc] init];
        _mainTitleLabel.font = [UIFont cj_fontOfSize:16];
        _mainTitleLabel.textColor = [UIColor cj_222222ff];
    }
    return _mainTitleLabel;
}

- (UIImageView *)rightImageView {
    if (!_rightImageView) {
        _rightImageView = [[UIImageView alloc] init];
        [_rightImageView cj_setImage:@"cj_arrow_icon"];
        _rightImageView.hidden = YES;
    }
    return _rightImageView;
}

@end
