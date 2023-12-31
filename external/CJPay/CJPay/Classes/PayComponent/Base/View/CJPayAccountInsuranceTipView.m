//
//  CJPayAccountInsuranceTipView.m
//  Pods
//
//  Created by 王新华 on 2021/3/5.
//

#import "CJPayAccountInsuranceTipView.h"
#import "CJPayUIMacro.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "UIImageView+CJPay.h"
#import "CJPayFullPageBaseViewController+Theme.h"

@interface CJPayAccountInsuranceTipView()

@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, assign) BOOL isDarkThemeOnly;

@end

@implementation CJPayAccountInsuranceTipView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self p_setupUI];
        _showEnable = YES;
        _isDarkThemeOnly = NO;
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.imageView];

    CJPayMasMaker(self.imageView, {
        make.center.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(271, 18));
    });
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if (![CJPayAccountInsuranceTipView shouldShow]) {
        return;
    }
    CJPayThemeModeType mode = [[self cj_responseViewController] cj_currentThemeMode];
    CJPayABSettingsModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel;
    NSString *imageUrl = model.darkAccountInsuranceUrl;
    if (mode == CJPayThemeModeTypeLight || mode == CJPayThemeModeTypeOrigin) {
        imageUrl = model.lightAccountInsuranceUrl;
    }
    if (self.isDarkThemeOnly) {
        imageUrl = model.darkAccountInsuranceUrl;
    }
    [self.imageView cj_setImageWithURL:[NSURL URLWithString:imageUrl] placeholder:nil completion:^(UIImage * _Nonnull image, NSData * _Nonnull data, NSError * _Nonnull error) {
        if (!error && image && self.showEnable) {
            self.hidden = NO;
        } else {
            self.hidden = YES;
        }
    }];
}

+ (BOOL)shouldShow {
    return [CJPaySettingsManager shared].currentSettings.abSettingsModel.showAccountInsuracne;
}

- (void)darkThemeOnly {
    self.isDarkThemeOnly = YES;
}

- (UIImageView *)imageView {
    if (!_imageView) {
        _imageView = [UIImageView new];
        _imageView.backgroundColor = UIColor.clearColor;
    }
    return _imageView;
}

+ (NSString *)keyboardLogo {
    CJPayABSettingsModel *model = [CJPaySettingsManager shared].currentSettings.abSettingsModel;
    return model.keyboardDenoiseIconUrl;
}

@end
