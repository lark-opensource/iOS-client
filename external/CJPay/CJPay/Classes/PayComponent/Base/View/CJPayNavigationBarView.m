//
//  CJPayNavigationBarView.m
//  CJPay
//
//  Created by wangxinhua on 2018/10/17.
//

#import "CJPayNavigationBarView.h"
#import "CJPayFullPageBaseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayButton.h"

@interface CJPayNavigationBarView()
@property (nonatomic, strong) UIView *statusSpaceView;
@property (nonatomic, strong) UIView *navibarView;
@property (nonatomic, strong) UIImageView *titleImageView;
@end

@implementation CJPayNavigationBarView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        [self p_setupConstrants];
    }
    return self;
}

- (void)p_setupUI{
    self.statusSpaceView = [UIView new];
    [self addSubview:self.statusSpaceView];
    self.navibarView = [UIView new];
    [self addSubview:self.navibarView];
    [self addSubview:self.titleLabel];
    [self addSubview:self.titleImageView];
    [self.navibarView addSubview:self.backBtn];
    [self.navibarView addSubview:self.shareBtn];
    
    self.bottomLine = [UIView new];
    self.bottomLine.backgroundColor = [UIColor cj_divideLineColor];
    [self.navibarView addSubview:self.bottomLine];
    [self.navibarView bringSubviewToFront:self.bottomLine];
}

- (void)p_setupConstrants {
    CJPayMasMaker(self.statusSpaceView, {
        make.left.top.right.equalTo(self);
        make.height.mas_equalTo(CJ_STATUSBAR_HEIGHT);
    });
    CJPayMasMaker(self.navibarView, {
        make.left.right.bottom.equalTo(self);
        make.top.equalTo(self.statusSpaceView.mas_bottom);
        make.top.equalTo(self).priority(UILayoutPriorityDefaultLow);
    });
    CJPayMasMaker(self.backBtn, {
        make.left.equalTo(self.navibarView).offset(16);
        make.size.mas_equalTo(CGSizeMake(24, 24));
        make.centerY.equalTo(self.navibarView);
    });
    CJPayMasMaker(self.shareBtn, {
        make.right.equalTo(self.navibarView).offset(-16);
        make.size.mas_equalTo(CGSizeMake(24, 24));
        make.centerY.equalTo(self.navibarView);
    });
    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.navibarView);
        make.centerY.equalTo(self.navibarView);
        make.width.lessThanOrEqualTo(self.navibarView).offset(-96);
    });
    CJPayMasMaker(self.titleImageView, {
        make.centerX.equalTo(self.navibarView);
        make.centerY.equalTo(self.navibarView);
        make.size.mas_equalTo(CGSizeMake(86, 24));
    });
    CJPayMasMaker(self.bottomLine, {
        make.left.bottom.right.equalTo(self.navibarView);
        make.height.mas_equalTo(CJ_PIXEL_WIDTH);
    });
}

- (void)setViewType:(CJPayViewType)viewType {
    _viewType = viewType;
    if (_viewType == CJPayViewTypeDenoise) {
        [self.backBtn cj_setImageName:self.isCloseBackImage ? @"cj_close_denoise_icon" : @"cj_navback_denoise_icon"  forState:UIControlStateNormal];
        self.bottomLine.hidden = YES;
        CJPayMasReMaker(self.backBtn, {
            make.left.equalTo(self.navibarView).offset(16);
            make.centerY.equalTo(self.navibarView);
            make.size.mas_equalTo(CGSizeMake(20, 20));
        });
    } else {
        [self.backBtn cj_setImageName:self.isCloseBackImage ? @"cj_close_icon" : @"cj_navback_icon" forState:UIControlStateNormal];
        self.bottomLine.hidden = NO;
        CJPayMasReMaker(self.backBtn, {
            make.left.equalTo(self.navibarView).offset(16);
            make.size.mas_equalTo(CGSizeMake(24, 24));
            make.centerY.equalTo(self.navibarView);
        });
    }
}

- (void)back {
    if (self.delegate != nil) {
        [self.delegate back];
    } else {
        
    }
}

- (void)share {
    if (self.delegate != nil) {
        [self.delegate share];
    } else {
        
    }
}

- (void)setTitle:(NSString *)title{
    _title = title;
    self.titleLabel.text = title;
}

- (void)setTitleImage:(NSString *)imageName {
    self.titleImageView.hidden = NO;
    [self.titleImageView cj_setImage:imageName];
}

- (void)setLeftImage:(UIImage *)image{
    [self.backBtn setImage:image forState:UIControlStateNormal];
}

- (void)hideBottomLine {
    self.bottomLine.hidden = YES;
}

- (void)removeStatusBarPlaceView {
    [self.statusSpaceView removeFromSuperview];
}

#pragma mark - Getter

- (CJPayButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [[CJPayButton alloc] init];
        [_backBtn cj_setImageName:@"cj_navback_icon" forState:UIControlStateNormal];
        [_backBtn addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        _backBtn.accessibilityLabel = @"返回";
    }
    return _backBtn;
}

- (CJPayButton *)shareBtn {
    if (!_shareBtn) {
        _shareBtn = [[CJPayButton alloc] init];
        [_shareBtn addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
        _shareBtn.accessibilityLabel = @"分享";
        _shareBtn.hidden = YES;
        [_shareBtn cj_setBtnImage:[UIImage cj_imageWithName:@"cj_share_icon"]];
    }
    return _shareBtn;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [[UILabel alloc] init];
        _titleLabel.cj_centerY = self.cj_height / 2;
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.text = self.title;
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 1;
        _titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    }
    return _titleLabel;
}

- (UIImageView *)titleImageView {
    if (!_titleImageView) {
        _titleImageView = [[UIImageView alloc] init];
        _titleImageView.backgroundColor = [UIColor clearColor];
        _titleImageView.hidden = YES;
    }
    
    return _titleImageView;
}

@end
