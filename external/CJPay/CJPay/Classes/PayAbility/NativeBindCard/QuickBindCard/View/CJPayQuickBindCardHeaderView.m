//
//  CJPayQuickBindCardHeaderView.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/12.
//

#import "CJPayQuickBindCardHeaderView.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayQuickBindCardQuickFrontHeaderViewModel.h"
#import "CJPayAlertUtil.h"
#import "CJPayInComePayAlertContentView.h"
#import "CJPaySubPayTypeIconTipModel.h"
#import "CJPaySubPayTypeIconTipInfoModel.h"
#import "UIView+CJTheme.h"

@interface CJPayQuickBindCardHeaderView()

#pragma mark - view
@property (nonatomic, strong) UILabel *separateLabel;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;
@property (nonatomic, strong) UIView *leftLine;
@property (nonatomic, strong) UIView *rightLine;

@end

@implementation CJPayQuickBindCardHeaderView

- (void)setupUI
{
    [super setupUI];

    [self.containerView addSubview:self.separateLabel];
    [self.containerView addSubview:self.mainTitleLabel];
    [self.containerView addSubview:self.subTitleLabel];
    [self.containerView addSubview:self.leftLine];
    [self.containerView addSubview:self.rightLine];
    
    CJPayMasMaker(self.separateLabel, {
        make.top.equalTo(self.containerView).offset(28);
        make.centerX.equalTo(self.containerView);
    });
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.separateLabel.mas_bottom).offset(32);
        make.left.equalTo(self.containerView).offset(32);
        make.right.lessThanOrEqualTo(self.containerView).offset(-16);
    });
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(5);
        make.bottom.equalTo(self.containerView).offset(-12);
        make.left.equalTo(self.mainTitleLabel);
        make.right.lessThanOrEqualTo(self.containerView).offset(-16);
    });
    CJPayMasMaker(self.leftLine, {
        make.top.equalTo(self.containerView).offset(37);
        make.centerX.equalTo(self.containerView).offset(-54);
        make.size.mas_equalTo(CGSizeMake(40, 0.5));
    });
    CJPayMasMaker(self.rightLine, {
        make.top.equalTo(self.containerView).offset(37);
        make.centerX.equalTo(self.containerView).offset(54);
        make.size.mas_equalTo(CGSizeMake(40, 0.5));
    });
}

- (void)drawRect:(CGRect)rect {
    CJPayLocalThemeStyle *localTheme =  [self cj_getLocalTheme];
    UIColor *lineColor = localTheme ? localTheme.quickBindCardBorderColor : [UIColor cj_e8e8e8ff];
    [CJPayLineUtil cj_drawLines:CJPayLineAllLines
            withRoundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                        radius:4
                      viewRect:CGRectMake(16, 62, self.cj_width - 32, self.cj_height - 62)
                         color:lineColor];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel
{
    [super bindViewModel:viewModel];
    if ([viewModel isKindOfClass:[CJPayQuickBindCardHeaderViewModel class]]) {
        CJPayQuickBindCardHeaderViewModel *headerViewModel = (CJPayQuickBindCardHeaderViewModel *)viewModel;
        if (Check_ValidString(headerViewModel.title)) {
            self.mainTitleLabel.text = CJPayLocalizedStr(headerViewModel.title);
        }
        if (Check_ValidString(headerViewModel.subTitle)) {
            self.subTitleLabel.text = CJPayLocalizedStr(headerViewModel.subTitle);
        }
    } else {
        self.mainTitleLabel.textColor = [UIColor cj_222222ff];
        self.mainTitleLabel.text = CJPayLocalizedStr(@"免输卡号，快速添加");
        self.subTitleLabel.text = CJPayLocalizedStr(@"已和下列银行合作，可查询本人卡号");
    }
}

#pragma mark - lazy view

- (UILabel *)separateLabel {
    if (!_separateLabel) {
        _separateLabel = [UILabel new];
        _separateLabel.text = CJPayLocalizedStr(@"或选择");
        _separateLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardDescTextColor;
        _separateLabel.font = [UIFont cj_fontOfSize:12];
    }
    return _separateLabel;
}

- (UILabel *)mainTitleLabel
{
    if (!_mainTitleLabel) {
        _mainTitleLabel = [UILabel new];
        _mainTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardTitleTextColor;
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:16];
        _mainTitleLabel.numberOfLines = 0;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [UILabel new];
        _subTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardDescTextColor;
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

- (UIView *)leftLine {
    if (!_leftLine) {
        _leftLine = [UIView new];
        _leftLine.backgroundColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardBorderColor;
    }
    return _leftLine;
}

- (UIView *)rightLine {
    if (!_rightLine) {
        _rightLine = [UIView new];
        _rightLine.backgroundColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardBorderColor;
    }
    return _rightLine;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        self.mainTitleLabel.textColor = localTheme.quickBindCardTitleTextColor;
        self.subTitleLabel.textColor = localTheme.quickBindCardDescTextColor;
        self.leftLine.backgroundColor = localTheme.quickBindCardBorderColor;
        self.rightLine.backgroundColor = localTheme.quickBindCardBorderColor;
        self.separateLabel.textColor = localTheme.quickBindCardDescTextColor;
    }
}

@end
