//
//  CJPayBankCardEmptyAddCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/19.
//

#import "CJPayBankCardEmptyAddCell.h"
#import "CJPayBankCardEmptyAddViewModel.h"
#import "CJPayBankCardAddCell.h"
#import "CJPayUIMacro.h"
#import "CJPayWebViewUtil.h"
#import "CJPayThemeModeManager.h"
#import "CJPaySettings.h"
#import "CJPaySettingsManager.h"
#import "UIView+CJTheme.h"

@interface CJPayBankCardEmptyAddCell ()

@property (nonatomic, strong) UIView *buttonView;
@property (nonatomic, strong) UIView *addView;
@property (nonatomic, strong) UIImageView *addImageView;
@property (nonatomic, strong) UILabel *addLabel;
@property (nonatomic, strong) UILabel *tipsLabel;

@end

@implementation CJPayBankCardEmptyAddCell

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.buttonView];
    UIView *contentView = [UIView new];
    
    [self.buttonView addSubview:contentView];
    [contentView addSubview:self.addView];
    [contentView addSubview:self.addImageView];
    [contentView addSubview:self.addLabel];
    [contentView addSubview:self.tipsLabel];
    
    BOOL showInsuranceEntrance = [CJPaySettingsManager shared].currentSettings.accountInsuranceEntrance.showInsuranceEntrance;
    CGFloat topOffset = showInsuranceEntrance ? 12 : 0;
    CJPayMasMaker(self.buttonView, {
        make.top.equalTo(self.containerView).offset(topOffset);
        make.bottom.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    });
    
    CJPayMasMaker(contentView, {
        make.edges.equalTo(self.buttonView);
    });
    
    CJPayMasMaker(self.addView, {
        make.top.equalTo(contentView.mas_top).offset(22);
        make.centerX.equalTo(contentView);
        make.height.width.mas_equalTo(56);
    });
    
    CJPayMasMaker(self.addImageView, {
        make.center.equalTo(self.addView);
        make.height.width.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.addLabel, {
        make.top.equalTo(self.addView.mas_bottom).offset(8);
        make.centerX.equalTo(contentView);
        make.height.mas_equalTo(24);
    });
    
    CJPayMasMaker(self.tipsLabel, {
        make.top.equalTo(self.addLabel.mas_bottom).offset(4);
        make.bottom.equalTo(contentView).offset(-20);
        make.centerX.equalTo(contentView);
        make.left.greaterThanOrEqualTo(self.buttonView);
        make.right.lessThanOrEqualTo(self.buttonView);
    });
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.buttonView.layer.borderColor = localTheme.addBankButtonBorderColor.CGColor;
        self.buttonView.backgroundColor = localTheme.addBankBigButtonBackgroundColor;
        self.addView.backgroundColor = localTheme.addBankButtonIconBackgroundColor;
        self.addLabel.textColor = localTheme.addBankButtonTitleColor;
        self.tipsLabel.textColor = localTheme.withdrawSubTitleTextColor;
        if ([self cj_responseViewController].cj_currentThemeMode != CJPayThemeModeTypeDark) {
            self.buttonView.layer.borderWidth = CJ_PIXEL_WIDTH;
        }
    }
}

- (void)didSelect {
    CJPayBankCardEmptyAddViewModel *addCardViewModel = (CJPayBankCardEmptyAddViewModel *) self.viewModel;
    CJ_CALL_BLOCK(addCardViewModel.didClickBlock);
    NSMutableDictionary *mutableDic = [addCardViewModel.trackDic mutableCopy];
    [mutableDic addEntriesFromDictionary:@{@"merchant_id": CJString(addCardViewModel.merchantId),
                                           @"app_id": CJString(addCardViewModel.appId),
                                           @"card_status": @"0",
                                           @"page_scenes": @"my_cards"}];
    [CJTracker event: @"wallet_bcard_manage_add" params:mutableDic];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    
    if ([viewModel isKindOfClass:[CJPayBankCardEmptyAddViewModel class]]) {
        CJPayBankCardEmptyAddViewModel *emptyAddViewModel = (CJPayBankCardEmptyAddViewModel *)viewModel;
        self.tipsLabel.text = CJString(emptyAddViewModel.noPwdBindCardDisplayDesc);
    } else {
        self.tipsLabel.text = @"";
    }
}

- (UIView *)buttonView {
    if (!_buttonView) {
        _buttonView = [[UIView alloc] init];
        _buttonView.backgroundColor = [CJPayLocalThemeStyle defaultThemeStyle].addBankBigButtonBackgroundColor;
        _buttonView.layer.cornerRadius = 4;
    }
    return _buttonView;
}

- (UIView *)addView {
    if (!_addView) {
        _addView = [[UIView alloc] init];
        _addView.backgroundColor = [CJPayLocalThemeStyle defaultThemeStyle].addBankButtonIconBackgroundColor;
        _addView.layer.cornerRadius = 28;
    }
    return _addView;
}

- (UIImageView *)addImageView {
    if (!_addImageView) {
        _addImageView = [[UIImageView alloc] init];
        [_addImageView cj_setImage:@"cj_pm_white_add_icon"];
    }
    return _addImageView;
}

- (UILabel *)addLabel {
    if (!_addLabel) {
        _addLabel = [UILabel new];
        _addLabel.font = [UIFont cj_semiboldFontOfSize:16];
        _addLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].addBankButtonTitleColor;
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

@end
