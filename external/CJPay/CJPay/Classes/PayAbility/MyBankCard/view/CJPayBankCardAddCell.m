//
//  CJPayBankCardAddCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardAddCell.h"

#import "CJPayBizWebViewController.h"
#import "CJPayBankCardAddViewModel.h"
#import "CJPayBindCardManager.h"
#import "CJPayUIMacro.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBizWebViewController+Biz.h"
#import "CJPaySDKDefine.h"
#import "CJPayStyleButton.h"
#import "UIView+CJTheme.h"

@interface CJPayBankCardAddCell ()

#pragma mark - view
@property(nonatomic, strong) CJPayStyleButton *buttonView;
@property(nonatomic, strong) UIImageView *addImageView;
@property(nonatomic, strong) UILabel *addLabel;
@property (nonatomic, strong) UILabel *tipsLabel;

#pragma mark - constraints
@property (nonatomic, strong) MASConstraint *tipsLabelTopConstraint;
@property (nonatomic, strong) MASConstraint *tipsLabelBottomConstraint;
@end

@implementation CJPayBankCardAddCell

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.buttonView];
    UIView *contentView = [UIView new];
    [self.buttonView addSubview:contentView];
    [contentView addSubview:self.addImageView];
    [contentView addSubview:self.addLabel];
    [self.containerView addSubview:self.tipsLabel];
    
    CJPayMasMaker(self.buttonView, {
        make.top.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.height.mas_equalTo(44);
    });
    
    CJPayMasMaker(self.addImageView, {
        make.top.greaterThanOrEqualTo(contentView);
        make.bottom.lessThanOrEqualTo(contentView);
        make.left.equalTo(contentView);
        make.centerY.equalTo(contentView);
        make.height.width.mas_equalTo(20);
    });
    
    CJPayMasMaker(self.addLabel, {
        make.top.greaterThanOrEqualTo(contentView);
        make.bottom.lessThanOrEqualTo(contentView);
        make.left.equalTo(self.addImageView.mas_right).offset(8);
        make.right.equalTo(contentView);
        make.centerY.equalTo(self.addImageView);
    });
    
    CJPayMasMaker(contentView, {
        make.center.equalTo(self.buttonView);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        self.tipsLabelTopConstraint = make.top.equalTo(self.buttonView.mas_bottom).offset(12);
        make.left.equalTo(self.buttonView);
        make.right.lessThanOrEqualTo(self.buttonView);
        self.tipsLabelBottomConstraint = make.bottom.equalTo(self.containerView).offset(-16);
    });
}

- (void)didSelect {
    CJPayBankCardAddViewModel *addCardViewModel = (CJPayBankCardAddViewModel *) self.viewModel;
    CJ_CALL_BLOCK(addCardViewModel.didClickBlock);
    NSMutableDictionary *mutableDic = [addCardViewModel.trackDic mutableCopy];
    [mutableDic addEntriesFromDictionary:@{@"merchant_id": CJString(addCardViewModel.merchantId),
                                           @"app_id": CJString(addCardViewModel.appId),
                                           @"card_status": @"1"}];
    [CJTracker event:@"wallet_bcard_manage_add" params:mutableDic];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:[CJPayBankCardAddViewModel class]]) {
        CJPayBankCardAddViewModel *addViewModel = (CJPayBankCardAddViewModel *)viewModel;
        self.tipsLabel.text = CJString(addViewModel.noPwdBindCardDisplayDesc);
        if (!Check_ValidString(addViewModel.noPwdBindCardDisplayDesc)) {
            self.tipsLabelTopConstraint.offset = 0;
            self.tipsLabelBottomConstraint.offset = 0;
        } else {
            self.tipsLabelTopConstraint.offset = 12;
            self.tipsLabelBottomConstraint.offset = -16;
        }
    } else {
        self.tipsLabel.text = @"";
    }
}

- (CJPayStyleButton *)buttonView {
    if (!_buttonView) {
        _buttonView = [[CJPayStyleButton alloc] init];
        _buttonView.userInteractionEnabled = NO;
    }
    return _buttonView;
}

- (UIImageView *)addImageView {
    if (!_addImageView) {
        _addImageView = [[UIImageView alloc] init];
        [_addImageView cj_setImage:@"cj_normal_add_bank_card_icon"];
        _addImageView.backgroundColor = [UIColor clearColor];
    }
    return _addImageView;
}

- (UILabel *)addLabel {
    if (!_addLabel) {
        _addLabel = [UILabel new];
        _addLabel.font = [UIFont cj_semiboldFontOfSize:16];
        _addLabel.text = CJPayLocalizedStr(@"添加银行卡");
    }
    return _addLabel;
}

- (UILabel *)tipsLabel {
    if (!_tipsLabel) {
        _tipsLabel = [UILabel new];
        _tipsLabel.font = [UIFont cj_fontOfSize:12];
        _tipsLabel.textColor = [UIColor cj_161823WithAlpha:0.5];
        _tipsLabel.numberOfLines = 0;
    }
    return _tipsLabel;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        _addLabel.textColor = localTheme.addBankButtonNormalTitleColor;
        _tipsLabel.textColor = localTheme.withdrawSubTitleTextColor;
        if ([self cj_responseViewController].cj_currentThemeMode == CJPayThemeModeTypeDark) {
            [_buttonView cj_setBtnBGImage:[UIImage cj_imageWithColor:localTheme.addBankButtonBackgroundColor]];
        }
    }
}

@end
