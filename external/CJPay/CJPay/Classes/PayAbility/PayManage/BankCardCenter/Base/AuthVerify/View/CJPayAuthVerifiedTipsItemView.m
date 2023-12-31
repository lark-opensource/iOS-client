//
//  CJPayAuthVerifiedTipsItemView.m
//  BDAlogProtocol
//
//  Created by bytedance on 2020/7/20.
//

#import "CJPayAuthVerifiedTipsItemView.h"
#import "CJPayUIMacro.h"



@interface CJPayAuthVerifiedTipsItemView()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation CJPayAuthVerifiedTipsItemView

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    [self addSubview:self.iconImageView];
    [self addSubview:self.titleLabel];
    
    CJPayMasMaker(self.iconImageView, {
        make.left.equalTo(self);
        make.centerY.equalTo(self);
        make.height.width.mas_equalTo(12);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.bottom.right.equalTo(self);
        make.left.equalTo(self.iconImageView.mas_right).offset(8);
    });
}

- (void)updateTitle:(NSString *)title
{
    self.titleLabel.text = title;
}

#pragma mark - Getter
- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
        [_iconImageView cj_setImage:@"cj_auth_select_icon"];
    }
    return _iconImageView;;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:13];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
    }
    return _titleLabel;
}

@end
