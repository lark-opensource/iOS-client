//
//  CJPayBankCardActivityHeaderCell.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/30.
//

#import "CJPayBankCardActivityHeaderCell.h"
#import "CJPayBankCardActivityHeaderViewModel.h"
#import "CJPayServerThemeStyle.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"


@interface CJPayBankCardActivityHeaderCell ()

@property (nonatomic, strong) UIView *contentBGView;
@property (nonatomic, strong) UILabel *mainTitleLabel;
@property (nonatomic, strong) UILabel *subTitleLabel;

@end

@implementation CJPayBankCardActivityHeaderCell

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.contentBGView];
    [self.contentBGView addSubview:self.mainTitleLabel];
    [self.contentBGView addSubview:self.subTitleLabel];
    
    CJPayMasMaker(self.contentBGView, {
        make.top.equalTo(self.containerView).offset(20);
        make.bottom.equalTo(self.containerView);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    });
    
    CJPayMasMaker(self.mainTitleLabel, {
        make.top.equalTo(self.containerView).offset(36);
        make.height.mas_equalTo(24);
        make.left.equalTo(self.containerView).offset(28);
        make.right.lessThanOrEqualTo(self.containerView).offset(-28);
    });
    CJPayMasMaker(self.subTitleLabel, {
        make.top.equalTo(self.mainTitleLabel.mas_bottom).offset(2);
        make.left.equalTo(self.mainTitleLabel);
        make.right.lessThanOrEqualTo(self.containerView).offset(-28);
    });
}

- (void)drawRect:(CGRect)rect {
    CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
    UIColor *lineColor = localTheme ? localTheme.bankActivityBorderColor : [UIColor cj_161823WithAlpha:0.5];
    [CJPayLineUtil cj_drawLines:CJPayLineLeft | CJPayLineTop | CJPayLineRight
             withRoundedCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                         radius:4
                       viewRect:CGRectMake(16, 20, self.cj_width - 32, 60)
                          color:lineColor];
    
    [self.contentBGView cj_clipTopCorner:4];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    
    if ([viewModel isKindOfClass:[CJPayBankCardActivityHeaderViewModel class]]) {
        CJPayBankCardActivityHeaderViewModel *headerViewModel = (CJPayBankCardActivityHeaderViewModel*)viewModel;
        self.mainTitleLabel.text = headerViewModel.mainTitle;
        self.subTitleLabel.text = headerViewModel.subTitle;
        self.subTitleLabel.hidden = !headerViewModel.ifShowSubTitle;
    } else {
        self.mainTitleLabel.text = CJPayLocalizedStr(@"首次绑卡支付立减");
        self.subTitleLabel.text = CJPayLocalizedStr(@"用户充话费、电商购物");
        self.subTitleLabel.hidden = YES;
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        
        self.mainTitleLabel.textColor = localTheme.bankActivityMainTitleColor;
        self.subTitleLabel.textColor = localTheme.bankActivitySubTitleColor;
        
        CJPayThemeModeType currentThemeModel = [self cj_responseViewController].cj_currentThemeMode;
        
        if (currentThemeModel == CJPayThemeModeTypeDark) {
            self.contentBGView.backgroundColor = [UIColor cj_ffffffWithAlpha:0.03];
        } else if (currentThemeModel == CJPayThemeModeTypeLight) {
            self.contentBGView.backgroundColor = [UIColor clearColor];
        }
    }
}

#pragma mark - laze view

- (UIView *)contentBGView {
    if (!_contentBGView) {
        _contentBGView = [UIView new];
    }
    return _contentBGView;
}

- (UILabel *)mainTitleLabel {
    if (!_mainTitleLabel) {
        _mainTitleLabel = [[UILabel alloc] init];
        _mainTitleLabel.font = [UIFont cj_boldFontOfSize:17];
        _mainTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].bankActivityMainTitleColor;
    }
    return _mainTitleLabel;
}

- (UILabel *)subTitleLabel {
    if (!_subTitleLabel) {
        _subTitleLabel = [[UILabel alloc] init];
        _subTitleLabel.font = [UIFont cj_fontOfSize:12];
        _subTitleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].bankActivityMainTitleColor;
        _subTitleLabel.hidden = YES;
        _subTitleLabel.numberOfLines = 0;
    }
    return _subTitleLabel;
}

@end
