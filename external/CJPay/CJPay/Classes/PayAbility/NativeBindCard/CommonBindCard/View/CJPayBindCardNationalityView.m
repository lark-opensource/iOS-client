//
//  CJPayBindCardNationalityView.m
//  Pods
//
//  Created by renqiang on 2020/8/3.
//

#import "CJPayBindCardNationalityView.h"
#import "CJPayLineUtil.h"
#import "CJPayUIMacro.h"


@interface CJPayBindCardNationalityView()

@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UILabel *mainTitleLabel;

@end

@implementation CJPayBindCardNationalityView

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
    [self addSubview:self.mainTitleLabel];
    [self addSubview:self.rightImageView];
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.mas_equalTo(self).offset(10);
        make.left.mas_equalTo(self).offset(24);
        make.right.mas_lessThanOrEqualTo(self.rightImageView.mas_left).offset(-24);
        make.height.mas_equalTo(17);
    });
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.centerY.mas_equalTo(self);
        make.left.mas_equalTo(self.subTitleLabel);
        make.right.mas_lessThanOrEqualTo(self.rightImageView.mas_left).offset(-24);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.rightImageView, {
        make.centerY.mas_equalTo(self.mainTitleLabel);
        make.right.mas_equalTo(self).offset(-24);
        make.size.mas_equalTo(CGSizeMake(20, 20));
    });
    
    [CJPayLineUtil addBottomLineToView:self marginLeft:24 marginRight:24 marginBottom:0];
}

- (void)updateWithStr:(NSString *)Str
{
    if (Check_ValidString(Str)) {
        self.mainTitleLabel.text = Str;
        [self p_updateStyle];
    }
}

- (void)p_updateStyle {
    self.subTitleLabel.hidden = NO;
    self.mainTitleLabel.textColor = [UIColor cj_222222ff];
    
    CJPayMasUpdate(self.mainTitleLabel, {
        make.centerY.mas_equalTo(self).offset(10.5);
    });
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.font = [UIFont cj_fontOfSize:13];
        _subTitleLabel.textColor = [UIColor cj_999999ff];
        _subTitleLabel.text = CJPayLocalizedStr(@"国家/地区");
        _subTitleLabel.hidden = YES;
    }
    return _subTitleLabel;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.font = [UIFont cj_fontOfSize:16];
        _mainTitleLabel.textColor = [UIColor cj_999999ff];
        _mainTitleLabel.text = CJPayLocalizedStr(@"请选择国家/地区");
    }
    return _mainTitleLabel;
}

- (UIImageView *)rightImageView {
    if (!_rightImageView) {
        _rightImageView = [UIImageView new];
        [_rightImageView cj_setImage:@"cj_arrow_icon"];
    }
    return _rightImageView;
}

@end
