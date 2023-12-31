//
//  CJPayBizWebRiskBannerView.m
//  CJPayBizWebRiskBannerView
//
//  Created by pay_ios_wxh on 2021/9/26.
//

#import "CJPayBizWebRiskBannerView.h"
#import "CJPayButton.h"
#import "CJPayUIMacro.h"
#import <Masonry/Masonry.h>

@interface CJPayBizWebRiskBannerView()

@property (nonatomic, strong) CJPayButton *closeBtn;
@property (nonatomic, strong) UILabel *reskInfoLabel;
@property (nonatomic, strong) UIImageView *warningImageView;
@property (nonatomic, strong) UIView *backColorView;

@end

@implementation CJPayBizWebRiskBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.backColorView];
    [self addSubview:self.reskInfoLabel];
    [self addSubview:self.closeBtn];
    [self addSubview:self.warningImageView];
    
    CJPayMasMaker(self.backColorView, {
        make.edges.equalTo(self);
    })
    CJPayMasMaker(self.warningImageView, {
        make.centerY.equalTo(self);
        make.left.equalTo(self).offset(17);
    })
    CJPayMasMaker(self.reskInfoLabel, {
        make.left.equalTo(self).offset(42);
        make.top.equalTo(self).offset(15);
        make.bottom.equalTo(self).offset(-15);
        make.right.equalTo(self).offset(-44);
    });
    CJPayMasMaker(self.closeBtn, {
        make.right.centerY.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    });
    
    self.backgroundColor = UIColor.whiteColor;
}

- (void)updateWarnContent:(NSString *)content {
    self.reskInfoLabel.text = content;
//    [self invalidateIntrinsicContentSize];
}

#pragma - mark lazy init
- (CJPayButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [CJPayButton new];
        [_closeBtn cj_setBtnImage:[UIImage cj_imageWithName:@"cj_web_warn_close_icon"]];
        @CJWeakify(self);
        [_closeBtn btd_addActionBlockForTouchUpInside:^(__kindof UIButton * _Nonnull sender) {
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.closeBlock);
        }];
    }
    return _closeBtn;
}

- (UIView *)backColorView {
    if (!_backColorView) {
        _backColorView = [UIView new];
        _backColorView.backgroundColor = [UIColor cj_fe3824WithAlpha:0.04f];
    }
    return _backColorView;
}

- (UILabel *)reskInfoLabel {
    if (!_reskInfoLabel) {
        _reskInfoLabel = [UILabel new];
        _reskInfoLabel.backgroundColor = [UIColor clearColor];
        _reskInfoLabel.numberOfLines = 0;
        _reskInfoLabel.font = [UIFont cj_fontOfSize:14];
        _reskInfoLabel.textColor = [UIColor cj_fe3824ff];
    }
    return _reskInfoLabel;
}

- (UIImageView *)warningImageView {
    if (!_warningImageView) {
        _warningImageView = [UIImageView new];
        [_warningImageView cj_setImage:@"cj_web_warn_icon"];
    }
    return _warningImageView;
}


@end
