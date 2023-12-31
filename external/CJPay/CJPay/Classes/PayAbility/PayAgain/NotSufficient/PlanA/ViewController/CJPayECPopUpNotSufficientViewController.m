//
//  CJPayECPopUpNotSufficientViewController.m
//  Pods
//
//  Created by 王新华 on 2021/6/7.
//

#import "CJPayECPopUpNotSufficientViewController.h"
#import "CJPayStyleButton.h"

@interface CJPayECPopUpNotSufficientViewController ()

@property (nonatomic, strong) UIImageView *iconView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayStyleButton *changePayMethodBtn;
@property (nonatomic, strong) CJPayButton *closeBtn;

@end

@implementation CJPayECPopUpNotSufficientViewController

- (void)setupUI {
    [super setupUI];
    [self.containerView addSubview:self.iconView];
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.changePayMethodBtn];
    [self.containerView addSubview:self.closeBtn];
    CJPayMasReMaker(self.containerView, {
        make.center.equalTo(self.view);
        make.size.mas_equalTo([self p_calSize]);
    });
    CJPayMasMaker(self.closeBtn, {
        make.top.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.width.height.mas_equalTo(20);
    });
    CJPayMasMaker(self.iconView, {
        make.centerX.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(24);
        make.size.mas_equalTo(CGSizeMake(60, 60));
    });
    CJPayMasMaker(self.titleLabel, {
        make.centerX.equalTo(self.iconView);
        make.top.equalTo(self.iconView.mas_bottom).offset(16);
        make.width.mas_lessThanOrEqualTo(240);
    });
    CJPayMasMaker(self.changePayMethodBtn, {
        make.centerX.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(-20);
        make.size.mas_equalTo(CGSizeMake(240, 44));
    });
    
    self.titleLabel.text = self.showTitle ?: CJPayLocalizedStr(@"余额不足");
}

- (CGSize)p_calSize {
    NSString *content = self.showTitle ?: CJPayLocalizedStr(@"余额不足");
    CGSize titleSize = [content cj_sizeWithFont:self.titleLabel.font maxSize:CGSizeMake(240, 60)];
    return CGSizeMake(280, MAX(titleSize.height + 184, 208));
}

- (void)p_close {
    @CJWeakify(self);
    [self dismissSelfWithCompletionBlock:^{
        @CJStrongify(self);
        CJ_CALL_BLOCK(self.closeActionCompletionBlock, YES);
    }];
}

#pragma mark - Get
- (UIImageView *)iconView {
    if (!_iconView) {
        _iconView = [UIImageView new];
        [_iconView cj_setImage:@"cj_sorry_icon"];
    }
    return _iconView;
}

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.numberOfLines = 2;
        _titleLabel.adjustsFontSizeToFitWidth = YES;
    }
    return _titleLabel;
}

- (CJPayStyleButton *)changePayMethodBtn {
    if (!_changePayMethodBtn) {
        _changePayMethodBtn = [CJPayStyleButton new];
        [_changePayMethodBtn setTitle:CJPayLocalizedStr(@"更换支付方式") forState:UIControlStateNormal];
        _changePayMethodBtn.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        @CJWeakify(self);
        [_changePayMethodBtn btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_close];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _changePayMethodBtn;
}

- (CJPayButton *)closeBtn {
    if (!_closeBtn) {
        _closeBtn = [CJPayButton new];
        [_closeBtn cj_setImageName:@"cj_close_icon" forState:UIControlStateNormal];
        @CJWeakify(self);
        [_closeBtn btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
            @CJStrongify(self);
            [self p_close];
        } forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeBtn;
}

@end
