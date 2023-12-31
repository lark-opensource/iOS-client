//
// Created by 易培淮 on 2020/10/27.
//

#import "CJPayUIMacro.h"
#import "CJPayQRCodeView.h"
#import "CJPayFullPageBaseViewController+Theme.h"

@implementation CJPayQRCodeView

- (instancetype)initWithData:(CJPayQRCodeModel*)model{
    self = [super init];
    if (self) {
        self.qrCodeModel = model;
        [self p_setupUI];
    }
    return self;
}

#pragma mark - Private Methods
- (void)p_setupUI {
    [self addSubview:self.payAmountLabel];
    [self addSubview:self.payAmountDiscountLabel];
    [self addSubview:self.unitLabel];
    [self addSubview:self.tradeNameLabel];
    [self addSubview:self.imageContainerView];
    [self.imageContainerView addSubview:self.qrCodeImageView];
    [self.imageContainerView addSubview:self.faviconView];
    [self.imageContainerView addSubview:self.loadingView];
    [self addSubview:self.alertLabel];
    [self addSubview:self.reloadButton];
    [self addSubview:self.payMethodBackgroundView];
    [self.payMethodBackgroundView addSubview:self.tbPayIconView];
    [self.payMethodBackgroundView addSubview:self.weBayIconView];
    [self.payMethodBackgroundView addSubview:self.tipsLabel];
    [self addSubview:self.saveLabel];

    CJPayMasMaker(self.payAmountLabel, {
        make.top.equalTo(self).offset(29);
        make.height.mas_equalTo(42);
        make.centerX.equalTo(self);
    });

    CJPayMasMaker(self.payAmountDiscountLabel, {
        make.left.equalTo(self.payAmountLabel.mas_right).offset(10);
        make.bottom.equalTo(self.payAmountLabel);
    });

    CJPayMasMaker(self.unitLabel, {
        make.right.equalTo(self.payAmountLabel.mas_left);
        make.top.equalTo(self).offset(44);
        make.height.mas_equalTo(22);
    });

    CJPayMasMaker(self.tradeNameLabel, {
        make.top.equalTo(self.payAmountLabel.mas_bottom).offset(10);
        make.left.equalTo(self).offset(16);
        make.right.equalTo(self).offset(-16);
        make.height.mas_equalTo(14);
    });

    CJPayMasMaker(self.imageContainerView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.tradeNameLabel.mas_bottom).offset(30);
        make.height.width.mas_equalTo(200);
    });

    CJPayMasMaker(self.qrCodeImageView, {
        make.top.bottom.right.left.equalTo(self.imageContainerView);
    });

    CJPayMasMaker(self.faviconView, {
        make.centerX.equalTo(self.qrCodeImageView);
        make.centerY.equalTo(self.qrCodeImageView);
        make.height.width.mas_equalTo(33);
    });

    CJPayMasMaker(self.loadingView, {
        make.centerX.equalTo(self.qrCodeImageView);
        make.centerY.equalTo(self.qrCodeImageView);
        make.height.width.mas_equalTo(44);
    });

    CJPayMasMaker(self.alertLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.tradeNameLabel.mas_bottom).offset(92);
    });

    CJPayMasMaker(self.reloadButton, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.alertLabel.mas_bottom).offset(18);
        make.width.mas_equalTo(120);
        make.height.mas_equalTo(36);
    });

    CJPayMasMaker(self.payMethodBackgroundView, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.qrCodeImageView.mas_bottom);
        make.height.mas_equalTo(24);
        make.width.mas_equalTo(200);
    });

    CJPayMasMaker(self.tbPayIconView, {
        make.left.equalTo(self.payMethodBackgroundView).offset(40);
        make.centerY.equalTo(self.payMethodBackgroundView);
        make.height.width.mas_equalTo(15);
    });

    CJPayMasMaker(self.weBayIconView, {
        make.left.equalTo(self.tbPayIconView.mas_right).offset(10);
        make.centerY.equalTo(self.payMethodBackgroundView);
        make.height.width.mas_equalTo(15);
    });

    CJPayMasMaker(self.tipsLabel, {
        make.right.equalTo(self.payMethodBackgroundView).offset(-40);
        make.centerY.equalTo(self.payMethodBackgroundView);
        make.height.mas_equalTo(18);
    });

    CJPayMasMaker(self.saveLabel, {
        make.centerX.equalTo(self);
        make.top.equalTo(self.payMethodBackgroundView.mas_bottom).offset(17);
        make.height.mas_equalTo(20);
    });
}

- (void)p_saveQRCode {
    if (self.delegate && [self.delegate respondsToSelector:@selector(saveImage)]) {
        [self.delegate saveImage];
    }
}

- (void)p_reloadButtonTapped {
    if (self.delegate && [self.delegate respondsToSelector:@selector(reloadImage)]) {
        [self.delegate reloadImage];
    }
};

#pragma mark - Getter
- (UILabel *)unitLabel
{
    if (!_unitLabel) {
        _unitLabel = [self p_getUnitLabel];
    }
    return _unitLabel;
}

- (UILabel *)p_getUnitLabel {
    UILabel *label = [UILabel new];
    label.text = @"￥";
    label.font = [UIFont cj_boldByteNumberFontOfSize:22];
    return label;
}

- (CJPayCounterLabel *)payAmountLabel {
    if (!_payAmountLabel) {
        _payAmountLabel = [self p_getPayAmountLabel];
    }
    return _payAmountLabel;
}

- (CJPayCounterLabel *)p_getPayAmountLabel {
    CJPayCounterLabel *counterLabel = [CJPayCounterLabel new];
    counterLabel.textAlignment = NSTextAlignmentLeft;
    counterLabel.font = [UIFont cj_boldByteNumberFontOfSize:42];
    counterLabel.text = CJString(self.qrCodeModel.amount);
    return counterLabel;
}

- (UILabel *)payAmountDiscountLabel
{
    if (!_payAmountDiscountLabel) {
        _payAmountDiscountLabel = [UILabel new];
        _payAmountDiscountLabel.font = [UIFont cj_fontOfSize:14];
        _payAmountDiscountLabel.textColor = [UIColor cj_999999ff];
        _payAmountDiscountLabel.hidden = YES;
    }
    return _payAmountDiscountLabel;
}

- (UILabel *)tradeNameLabel {
    if (!_tradeNameLabel) {
        _tradeNameLabel = [UILabel new];
        _tradeNameLabel.cj_centerY = 88;
        _tradeNameLabel.font = [UIFont cj_fontOfSize:12];
        _tradeNameLabel.textAlignment = NSTextAlignmentCenter;
        _tradeNameLabel.textColor = [UIColor cj_999999ff];
        _tradeNameLabel.text = CJString(self.qrCodeModel.tradeName);
    }
    return _tradeNameLabel;
}

- (UILabel *)saveLabel
{
    if (!_saveLabel) {
        _saveLabel = [UILabel new];
        NSMutableAttributedString *saveAttrString = [[NSMutableAttributedString alloc] initWithString:CJPayLocalizedStr(@"保存图片") attributes:@{NSForegroundColorAttributeName:[UIColor cj_colorWithHexString:@"#4BA1F8"]}];
        NSAttributedString *customAttrString = [[NSAttributedString alloc] initWithString:CJString(self.qrCodeModel.shareDesc) attributes:@{}];
        NSMutableAttributedString *commentString = [[NSMutableAttributedString alloc] init];
        [commentString appendAttributedString: saveAttrString];
        [commentString appendAttributedString: customAttrString];
        [_saveLabel cj_viewAddTarget:self
                              action:@selector(p_saveQRCode)
                    forControlEvents:UIControlEventTouchUpInside];
        _saveLabel.userInteractionEnabled = YES;
        _saveLabel.attributedText = commentString.copy;
        _saveLabel.font = [UIFont cj_fontOfSize:14];
        _saveLabel.hidden = YES;
    }
    return _saveLabel;
}

- (UIView *)payMethodBackgroundView {
    if (!_payMethodBackgroundView) {
        _payMethodBackgroundView = [self p_getPayMethodBackgroundView];
    }
    return _payMethodBackgroundView;
}

- (UIView *)p_getPayMethodBackgroundView {
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,24)];
    CJPayLocalThemeStyle *localTheme = [CJPayLocalThemeStyle defaultThemeStyle];
    view.backgroundColor = localTheme.addBankButtonIconBackgroundColor;
    [view cj_clipBottomCorner:8];
    return view;
}

- (UIView *)imageContainerView {
    if (!_imageContainerView) {
        _imageContainerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,200,200)];
        _imageContainerView.backgroundColor = [UIColor cj_colorWithHexString:@"#F8F8F8"];
        [_imageContainerView cj_clipTopCorner:8];
    }
    return _imageContainerView;
}

- (UIImageView *)qrCodeImageView {
    if (!_qrCodeImageView) {
        _qrCodeImageView = [self p_getQRCodeImageView];
        _qrCodeImageView.hidden = YES;
    }
    return _qrCodeImageView;
}

- (UIImageView *)p_getQRCodeImageView {
    UIImageView * imageView= [[UIImageView alloc] initWithFrame:CGRectMake(0,0,200,200)];
    [imageView cj_clipTopCorner:8];
    return imageView;
}

- (UIImageView *)faviconView {
    if (!_faviconView) {
        _faviconView = [UIImageView new];
        _faviconView.hidden = YES;
    }
    return _faviconView;
}

- (UIImageView *)loadingView {
    if (!_loadingView) {
        _loadingView = [UIImageView new];
        [_loadingView cj_setImage:@"cj_loading_icon"];
        _loadingView.hidden = YES;
    }
    return _loadingView;
}

- (UIImageView *)tbPayIconView {
    if (!_tbPayIconView) {
        _tbPayIconView = [self p_getTbPayIconView];
    }
    return _tbPayIconView;
}

- (UIImageView *)p_getTbPayIconView {
    UIImageView *imageView = [UIImageView new];
    NSString *cdnName = [NSString stringWithFormat:@"cj_%@_icon", EN_zfb];
    [imageView cj_setImage:cdnName];
    return imageView;
}

- (UIImageView *)weBayIconView {
    if (!_weBayIconView) {
        _weBayIconView = [self p_getWEBayIconView];
    }
    return _weBayIconView;
}

- (UIImageView *)p_getWEBayIconView {
    UIImageView *imageView = [UIImageView new];
    [imageView cj_setImage:@"cj_wxpay_icon"];
    return imageView;
}

- (UILabel *)tipsLabel
{
    if (!_tipsLabel) {
        _tipsLabel = [self p_getTipsLabel];
    }
    return _tipsLabel;
}

- (UILabel *)p_getTipsLabel {
    UILabel *label = [UILabel new];
    label.font = [UIFont cj_fontOfSize:12];
    label.textColor = [UIColor whiteColor];
    label.text = CJPayLocalizedStr(@"使用扫码支付");
    return label;
}


- (UILabel *)alertLabel
{
    if (!_alertLabel) {
        _alertLabel = [UILabel new];
        _alertLabel.font = [UIFont cj_fontOfSize:13];
        _alertLabel.textColor = [UIColor cj_colorWithHexString:@"#505050"];
        _alertLabel.text = CJPayLocalizedStr(@"二维码刷新失败，请重新加载");
        _alertLabel.hidden = YES;
    }
    return _alertLabel;
}

- (CJPayButton *)reloadButton
{
    if (!_reloadButton) {
        _reloadButton = [CJPayButton new];
        _reloadButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_reloadButton setTitleColor:[UIColor cj_colorWithHexString:@"#4BA1F8"] forState:UIControlStateNormal];
        [_reloadButton setTitle:CJPayLocalizedStr(@"重新加载") forState:UIControlStateNormal];
        _reloadButton.cjEventInterval = 1;
        [_reloadButton addTarget:self action:@selector(p_reloadButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [_reloadButton cj_showCornerRadius:18];
        [_reloadButton cj_showBorder:[UIColor cj_colorWithHexString:@"#4BA1F8"] borderWidth:1];
        _reloadButton.backgroundColor = [UIColor cj_colorWithHexString:@"#F8F8F8"];
        _reloadButton.hidden = YES;
    }
    return _reloadButton;
}



- (UIImage *)getQRCodeImage {
    UIView *snapshotView  = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 375, 560)];
    CJPayLocalThemeStyle *localTheme = [CJPayLocalThemeStyle defaultThemeStyle];
    snapshotView.backgroundColor = localTheme.addBankButtonIconBackgroundColor;
    UILabel *titleName = [UILabel new];
    titleName.text = CJString(self.qrCodeModel.shareImage.payeeName);
    titleName.font = [UIFont cj_boldFontOfSize:34];
    titleName.textColor = [UIColor whiteColor];

    UILabel *timeTips = [UILabel new];
    timeTips.text = CJString(self.qrCodeModel.shareImage.validityDesc);
    timeTips.font = [UIFont cj_fontOfSize:14];
    timeTips.textColor = [UIColor whiteColor];

    UIView *contextView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, 300, 415)];
    contextView.backgroundColor = [UIColor whiteColor];
    [contextView cj_showCornerRadius:12];

    UILabel *userName = [UILabel new];
    userName.text = CJString(self.qrCodeModel.shareImage.userNameDesc);
    userName.font = [UIFont cj_fontOfSize:12];
    userName.textColor = [UIColor blackColor];

    UILabel *productName = [UILabel new];
    productName.text = CJString(self.tradeNameLabel.text);
    productName.textColor = [UIColor blackColor];
    productName.font = [UIFont cj_fontOfSize:12];
    productName.numberOfLines = 0;
    productName.textAlignment = NSTextAlignmentCenter;

    UILabel *temp_unitLabel = [self p_getUnitLabel];
    CJPayCounterLabel *temp_counterLabel = [self p_getPayAmountLabel];
    UIImageView *temp_qrCode = [self p_getQRCodeImageView];
    temp_qrCode.image = self.qrCodeImageView.image;
    UIImageView *temp_faviconView = [UIImageView new];
    temp_faviconView.image = self.faviconView.image;
    UIImageView *temp_tbpayIcon = [self p_getTbPayIconView];
    UIImageView *temp_wxpayIcon = [self p_getWEBayIconView];
    UILabel *temp_tipsLabel = [self p_getTipsLabel];
    UIView  *temp_payMethodView = [self p_getPayMethodBackgroundView];

    [snapshotView addSubview:titleName];
    [snapshotView addSubview:contextView];
    [contextView addSubview:userName];
    [contextView addSubview:temp_unitLabel];
    [contextView addSubview:temp_counterLabel];
    [contextView addSubview:productName];
    [contextView addSubview:temp_qrCode];
    [temp_qrCode addSubview:temp_faviconView];
    [contextView addSubview:temp_payMethodView];
    [temp_payMethodView addSubview:temp_tbpayIcon];
    [temp_payMethodView addSubview:temp_wxpayIcon];
    [temp_payMethodView addSubview:temp_tipsLabel];
    [snapshotView addSubview:timeTips];

    CJPayMasMaker(titleName, {
        make.centerX.equalTo(snapshotView);
        make.top.equalTo(snapshotView).offset(31);
        make.height.mas_equalTo(42);
    });

    CJPayMasMaker(contextView, {
        make.centerX.equalTo(snapshotView);
        make.top.equalTo(snapshotView).offset(89);
        make.width.mas_equalTo(300);
        make.height.mas_equalTo(415);
    });

    CJPayMasMaker(userName, {
        make.centerX.equalTo(contextView);
        make.top.equalTo(contextView).offset(21);
        make.height.mas_equalTo(18);
    });

    CJPayMasMaker(temp_counterLabel, {
        make.centerX.equalTo(contextView);
        make.top.equalTo(contextView).offset(47);
        make.height.mas_equalTo(46);
    });

    CJPayMasMaker(temp_unitLabel, {
        make.right.equalTo(temp_counterLabel.mas_left).offset(0);
        make.top.equalTo(contextView).offset(63);
        make.height.mas_equalTo(24);
    });

    CJPayMasMaker(productName, {
        make.left.equalTo(contextView).offset(40);
        make.right.equalTo(contextView).offset(-40);
        make.top.equalTo(temp_counterLabel.mas_bottom).offset(1);
    });

    CJPayMasMaker(temp_qrCode, {
        make.centerX.equalTo(contextView);
        make.top.equalTo(productName.mas_bottom).offset(25);
        make.height.width.mas_equalTo(200);
    });

    CJPayMasMaker(temp_faviconView, {
        make.centerX.equalTo(temp_qrCode);
        make.centerY.equalTo(temp_qrCode);
        make.height.width.mas_equalTo(33);
    });

    CJPayMasMaker(temp_payMethodView, {
        make.centerX.equalTo(contextView);
        make.top.equalTo(temp_qrCode.mas_bottom).offset(0);
        make.height.mas_equalTo(24);
        make.width.mas_equalTo(200);
    });

    CJPayMasMaker(temp_tbpayIcon, {
        make.left.equalTo(temp_payMethodView).offset(40);
        make.centerY.equalTo(temp_payMethodView);
        make.height.width.mas_equalTo(15);
    });

    CJPayMasMaker(temp_wxpayIcon, {
        make.left.equalTo(temp_tbpayIcon.mas_right).offset(10);
        make.centerY.equalTo(temp_payMethodView);
        make.height.width.mas_equalTo(15);
    });

    CJPayMasMaker(temp_tipsLabel, {
        make.right.equalTo(temp_payMethodView).offset(-40);
        make.centerY.equalTo(temp_payMethodView);
        make.height.mas_equalTo(18);
    });

    CJPayMasMaker(timeTips, {
        make.centerX.equalTo(snapshotView);
        make.top.equalTo(contextView.mas_bottom).offset(17);
    });

    UIImage *saveImage = [snapshotView cjpay_snapShotImage];
    return saveImage;

}

@end
