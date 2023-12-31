//
//  CJPayNoNetworkView.m
//  CJPay
//
//  Created by wangxiaohong on 2019/11/22.
//

#import "CJPayNoNetworkView.h"
#import "CJPayButton.h"
#import "CJPayUIMacro.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "UIView+CJTheme.h"

#import <Masonry/Masonry.h>

@interface CJPayNoNetworkView()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) CJPayButton *refreshButton;

@end

@implementation CJPayNoNetworkView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI
{
    self.backgroundColor = [UIColor whiteColor];
    
//    CGFloat topMargin  = (CJ_SCREEN_HEIGHT - 293) * 148 / 374;
    //TODO: // 需要处理这里的布局
    [self addSubview:self.imageView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.refreshButton];
    
    CJPayMasMaker(self.imageView, {
        make.centerY.equalTo(self).offset(-50);
        make.centerX.equalTo(self);
        make.width.mas_equalTo(240);
        make.height.mas_equalTo(160);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.imageView.mas_bottom).offset(24);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(16);
        make.centerX.equalTo(self);
    });
    
    CJPayMasMaker(self.refreshButton, {
        make.top.equalTo(self.subTitleLabel.mas_bottom).offset(16);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(36);
        make.width.mas_equalTo(159);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.titleLabel.textColor = localTheme.titleColor;
        self.subTitleLabel.textColor = localTheme.subtitleColor;
        self.backgroundColor = localTheme.mainBackgroundColor;
    }
}

- (void)p_refreshButtonTapped
{
    CJ_CALL_BLOCK(self.refreshBlock);
}

- (UIImageView *)imageView
{
    if (!_imageView) {
        _imageView = [[UIImageView alloc] init];
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        [_imageView cj_setImage:@"cj_no_network_icon"];
    }
    return _imageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.text = CJPayLocalizedStr(@"没有网络");
        _titleLabel.font = [UIFont cj_boldFontOfSize:18];
    }
    return _titleLabel;
}

- (UILabel *)subTitleLabel
{
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _subTitleLabel.text = CJPayNoNetworkMessage;
        _subTitleLabel.font = [UIFont cj_fontOfSize:15];
    }
    return _subTitleLabel;
}

- (CJPayButton *)refreshButton
{
    if (!_refreshButton) {
        _refreshButton = [[CJPayButton alloc] init];
        _refreshButton.translatesAutoresizingMaskIntoConstraints = NO;
        _refreshButton.backgroundColor = [UIColor cj_fe2c55ff];
        _refreshButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_refreshButton setTitle:CJPayLocalizedStr(@"刷新") forState:UIControlStateNormal];
        [_refreshButton setTitle:CJPayLocalizedStr(@"刷新") forState:UIControlStateHighlighted];
        _refreshButton.cjEventInterval = 2;
        _refreshButton.layer.cornerRadius = 4;
        [_refreshButton addTarget:self action:@selector(p_refreshButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _refreshButton;
}

@end
