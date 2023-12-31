//
//  CJPayCommonExceptionView.m
//  CJPay
//
//  Created by 尚怀军 on 2019/11/7.
//

#import "CJPayCommonExceptionView.h"
#import "CJPayUIMacro.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayLineUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayStyleButton.h"
#import "UIView+CJTheme.h"

@interface CJPayCommonExceptionView()

@property (nonatomic, copy) NSString *mainTitle;
@property (nonatomic, copy) NSString *subTitle;
@property (nonatomic, copy) NSString *buttonTitle;

@end

@implementation CJPayCommonExceptionView

- (instancetype)initWithFrame:(CGRect)frame
                    mainTitle:(nullable NSString *)mainTitle
                     subTitle:(nullable NSString *)subTitle
                  buttonTitle:(nullable NSString *)buttonTitle {
    self = [super initWithFrame:frame];
    if (self) {
        self.mainTitle = Check_ValidString(mainTitle) ? mainTitle : CJPayLocalizedStr(@"系统拥挤");
        self.subTitle = Check_ValidString(subTitle) ? subTitle : CJPayLocalizedStr(@"排队人数太多了，请休息片刻后再试");
        self.buttonTitle = Check_ValidString(buttonTitle) ? buttonTitle : CJPayLocalizedStr(@"知道了");
        
        [self setupUI];
    }
    return self;
}

- (BOOL)isDouHuoStyle {
    NSString *appId = [CJPayRequestParam gAppInfoConfig].appId;
    return [@[@"1112", @"8663"] containsObject:appId];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if ([self isDouHuoStyle]) {
        self.mainTitleLabel.textColor = [UIColor cj_404040ff];
        self.subTitleLabel.textColor = [UIColor cj_00000072];
        
        self.backgroundColor = [UIColor whiteColor];
    } else {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.backgroundColor = localTheme.mainBackgroundColor;
        self.mainTitleLabel.textColor = localTheme.limitTextColor;
        self.subTitleLabel.textColor = localTheme.subtitleColor;
        self.actionButton.backgroundColor = localTheme.addBankButtonBackgroundColor;
        [self.actionButton setTitleColor:localTheme.limitTextColor forState:UIControlStateNormal];
    }
}

- (void)drawRect:(CGRect)rect {
    if ([self cj_responseViewController].cj_currentThemeMode != CJPayThemeModeTypeDark && ![self isDouHuoStyle]) {
        [CJPayLineUtil cj_drawLines:CJPayLineAllLines withRoundedCorners:UIRectCornerAllCorners radius:2 viewRect:CGRectInset(self.actionButton.frame, -CJ_PIXEL_WIDTH, -CJ_PIXEL_WIDTH) color:[self cj_responseViewController].cjLocalTheme.subtitleColor];
    }
}

- (void)setupUI {
    [self addSubview:self.mainTitleLabel];
    [self addSubview:self.subTitleLabel];
    [self addSubview:self.actionButton];
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self).offset(200);
        make.centerX.equalTo(self);
        make.height.mas_equalTo(24);
    });
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(12);
        make.height.mas_equalTo(20);
        make.centerX.equalTo(self);
    });
    CJPayMasMaker(self.actionButton, {
        make.centerX.equalTo(self);
        make.size.mas_equalTo(CGSizeMake(231, CJ_BUTTON_HEIGHT));
        make.centerY.equalTo(self.mas_bottom).offset(-(156 + CJ_TabBarSafeBottomMargin));
    });
    
    self.mainTitleLabel.text = CJString(self.mainTitle);
    self.subTitleLabel.text = CJString(self.subTitle);
    [self.actionButton setTitle:self.buttonTitle forState:UIControlStateNormal];
}

- (void)actionButtonClick {
    CJ_CALL_BLOCK(self.actionBlock);
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [[UILabel alloc] init];
        _mainTitleLabel.font = [UIFont cj_semiboldFontOfSize:18];
        _mainTitleLabel.textColor = [UIColor cj_222222ff];
        _mainTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.font = [UIFont cj_fontOfSize:15];
        _subTitleLabel.textColor = [UIColor cj_999999ff];
        _subTitleLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _subTitleLabel;
}

- (UIButton *)actionButton {
    if (!_actionButton) {
        if (![self isDouHuoStyle]) {
            _actionButton = [[UIButton alloc] init];
            _actionButton.layer.masksToBounds = YES;
            _actionButton.layer.cornerRadius = 4;
            _actionButton.backgroundColor = [UIColor clearColor];
        } else {
            _actionButton = [CJPayStyleButton new];
        }
        _actionButton.titleLabel.font = [UIFont cj_fontOfSize:14];
        [_actionButton addTarget:self action:@selector(actionButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _actionButton.titleLabel.textAlignment = NSTextAlignmentCenter;
        [_actionButton setTitle:CJString(self.buttonTitle) forState:UIControlStateNormal];
    }
    return _actionButton;
}


@end
