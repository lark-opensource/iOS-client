//
//  CJPayBioGuideTipsItemView.m
//  Pods
//
//  Created by 易培淮 on 2021/7/18.
//

#import "CJPayBioGuideTipsItemView.h"
#import "CJPayUIMacro.h"

@interface CJPayBioGuideTipsItemView()
@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation CJPayBioGuideTipsItemView


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
        make.height.width.mas_equalTo(15);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.bottom.right.equalTo(self);
        make.left.equalTo(self.iconImageView.mas_right).offset(8);
    });
}

- (void)updateItemWithTitle:(NSString *)title url:(NSString *)url
{
    if (url) {
        [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:url]
                                   placeholder:nil];
    }
    self.titleLabel.text = title;
}

#pragma mark - Getter
- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_fontOfSize:15];
        _titleLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}


@end
