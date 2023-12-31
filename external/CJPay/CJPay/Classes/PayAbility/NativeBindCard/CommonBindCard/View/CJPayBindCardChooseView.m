//
//  CJPayBindCardChooseView.m
//  CJPay
//
//  Created by 徐天喜 on 2022/08/05
//

#import "CJPayBindCardChooseView.h"
#import "CJPayUIMacro.h"

@interface CJPayBindCardChooseView()

@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UIView *bottomLine;

@end

@implementation CJPayBindCardChooseView

#pragma mark - init

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

#pragma mark - public func

- (void)updateWithMainStr:(NSString *)mainStr
                   subStr:(NSString *)subStr {
    self.mainTitleLabel.text = mainStr;
    self.subTitleLabel.text  = subStr;
}

#pragma mark - privater func

- (void)p_setupUI {
    [self addSubview:self.mainTitleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.rightImageView];
    [self addSubview:self.bottomLine];
    self.isClickStyle = NO;

    CJPayMasMaker(self.mainTitleLabel, {
        make.left.centerY.equalTo(self);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.left.equalTo(self.mainTitleLabel).offset(88);
        make.right.equalTo(self.rightImageView.mas_left).offset(-12);
        make.centerY.equalTo(self.mainTitleLabel);
        make.height.mas_equalTo(22);
    });
    
    CJPayMasMaker(self.rightImageView, {
        make.right.equalTo(self);
        make.centerY.equalTo(self.mainTitleLabel);
        make.width.mas_equalTo(20);
        make.height.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.bottomLine, {
        make.left.right.bottom.equalTo(self);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
}

- (void)p_updateStyle {
    if (self.isClickStyle) {
        self.subTitleLabel.textColor = [UIColor cj_161823ff];
        self.rightImageView.hidden = NO;
    } else {
        self.subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.34];
        self.rightImageView.hidden = YES;
    }
}

#pragma mark - getter & setter

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
        _subTitleLabel.font = [UIFont cj_boldFontOfSize:16];
        _subTitleLabel.textColor = [UIColor cj_161823WithAlpha:0.34];
    }
    return _subTitleLabel;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [[UILabel alloc] init];
        _mainTitleLabel.font = [UIFont cj_fontOfSize:16];
        _mainTitleLabel.textColor = [UIColor cj_161823ff];
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

- (void)setIsClickStyle:(BOOL)isClickStyle {
    _isClickStyle = isClickStyle;
    [self p_updateStyle];
}

@end
