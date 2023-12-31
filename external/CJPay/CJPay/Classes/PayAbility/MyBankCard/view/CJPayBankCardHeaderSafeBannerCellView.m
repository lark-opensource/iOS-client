//
//  CJPayBankCardHeaderSafeBannerCellView.m
//  Pods
//
//  Created by 孔伊宁 on 2021/8/11.
//

#import "CJPayBankCardHeaderSafeBannerCellView.h"
#import "CJPayBankCardHeaderSafeBannerViewModel.h"
#import "CJPayUIMacro.h"
#import "UIView+CJTheme.h"

@interface CJPayBankCardHeaderSafeBannerCellView ()

@property (nonatomic, strong) UIImageView *safeImageView;
@property (nonatomic, strong) UILabel *safeTextLabel;

@end

@implementation CJPayBankCardHeaderSafeBannerCellView

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.safeImageView];
    [self.containerView addSubview:self.safeTextLabel];
    
    CJPayMasUpdate(self.contentView, {
        make.height.mas_equalTo(32);
        make.top.bottom.equalTo(self);
    });
    
    CJPayMasMaker(self.safeImageView, {
        make.left.equalTo(self.containerView).offset(20);
        make.centerY.equalTo(self);
        make.height.width.mas_equalTo(12);
    });
    CJPayMasMaker(self.safeTextLabel, {
        make.left.equalTo(self.safeImageView.mas_right).offset(4);
        make.centerY.equalTo(self.safeImageView);
    });
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(p_safeBannerTapped)];
    [self addGestureRecognizer:tapGesture];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:CJPayBankCardHeaderSafeBannerViewModel.class]) {
        self.safeBannerViewModel = (CJPayBankCardHeaderSafeBannerViewModel *)viewModel;
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayThemeModeType currentThemeModel = [self cj_responseViewController].cj_currentThemeMode;
        if (currentThemeModel == CJPayThemeModeTypeDark) {
            self.safeTextLabel.textColor = [UIColor cj_17a37eff];
            self.backgroundColor = [UIColor cj_17a37eWithAlpha:0.12];
        } else if (currentThemeModel == CJPayThemeModeTypeLight) {
            self.safeTextLabel.textColor = [UIColor cj_418f82ff];
            self.backgroundColor = [UIColor cj_e1fbf8ff];
        }
    }
}

- (void)p_safeBannerTapped {
    [self.safeBannerViewModel gotoH5WebView];
    [CJTracker event:@"wallet_addbcard_insurance_title_click" params:self.safeBannerViewModel.passParams];
}

- (void)updateSafeString:(NSString *)str {
    if(self.safeTextLabel) {
        self.safeTextLabel.text = CJPayLocalizedStr(str);
    }
}


#pragma mark Getter
- (UIImageView *)safeImageView {
    if(!_safeImageView) {
        _safeImageView = [UIImageView new];
        [_safeImageView cj_setImage:@"cj_safe_defense_icon"];
    }
    return _safeImageView;
}

- (UILabel *)safeTextLabel {
    if(!_safeTextLabel) {
        _safeTextLabel = [UILabel new];
        _safeTextLabel.text = CJPayLocalizedStr(@"添加银行卡，享百万资金安全保障");
        _safeTextLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _safeTextLabel;
}

- (CJPayBankCardHeaderSafeBannerViewModel *)safeBannerViewModel {
    if (!_safeBannerViewModel) {
        _safeBannerViewModel = [CJPayBankCardHeaderSafeBannerViewModel new];
    }
    return _safeBannerViewModel;
}

@end
