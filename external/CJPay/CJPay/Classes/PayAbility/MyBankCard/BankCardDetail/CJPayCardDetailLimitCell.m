//
//  CJPayCardDetailLimitCell.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import "CJPayCardDetailLimitCell.h"

#import "CJPayCardDetailLimitViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayLocalThemeStyle.h"
#import "UIView+CJTheme.h"

@interface CJPayCardDetailLimitCell()

@property (nonatomic, strong) UIView *topLineView;
@property (nonatomic, strong) UILabel *perDayLimitLabel;
@property (nonatomic, strong) UILabel *perDayLimitValueLabel;
@property (nonatomic, strong) UILabel *perPayLimitLabel;
@property (nonatomic, strong) UILabel *perPayLimitValueLabel;

@end

@implementation CJPayCardDetailLimitCell

- (void)setupUI {
    [super setupUI];
    
    self.topLineView = [CJPayLineUtil addTopLineToView:self.containerView marginLeft:16 marginRight:16 marginTop:16 color:[CJPayLocalThemeStyle defaultThemeStyle].separatorColor];
    [self.containerView addSubview:self.perDayLimitLabel];
    [self.containerView addSubview:self.perDayLimitValueLabel];
    [self.containerView addSubview:self.perPayLimitLabel];
    [self.containerView addSubview:self.perPayLimitValueLabel];
    
    CJPayMasMaker(self.perPayLimitLabel, {
        make.top.equalTo(self.topLineView.mas_bottom).offset(21);
        make.left.equalTo(self.containerView).offset(16);
    });
    CJPayMasMaker(self.perPayLimitValueLabel, {
        make.right.equalTo(self.containerView).offset(-16);
        make.centerY.equalTo(self.perPayLimitLabel);
    });
    CJPayMasMaker(self.perDayLimitLabel, {
        make.left.equalTo(self.perPayLimitLabel);
        make.top.equalTo(self.perPayLimitLabel.mas_bottom).offset(17);
    });
    CJPayMasMaker(self.perDayLimitValueLabel, {
        make.right.equalTo(self.containerView).offset(-16);
        make.centerY.equalTo(self.perDayLimitLabel);
    });
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    CJPayCardDetailLimitViewModel *limitViewModel = (CJPayCardDetailLimitViewModel *)viewModel;
    if (limitViewModel) {
        if (Check_ValidString(limitViewModel.perPayLimitStr)) {
            self.perPayLimitValueLabel.text = [NSString stringWithFormat:@"￥%@", limitViewModel.perPayLimitStr];
            if (Check_ValidString(limitViewModel.perDayLimitStr)) {
                self.perDayLimitLabel.hidden = NO;
                self.perDayLimitValueLabel.text = [NSString stringWithFormat:@"￥%@", limitViewModel.perDayLimitStr];
            }
        } else if (Check_ValidString(limitViewModel.perDayLimitStr)) {
            self.perPayLimitLabel.text = CJPayLocalizedStr(@"银行卡每日限额");
            self.perPayLimitValueLabel.text = [NSString stringWithFormat:@"￥%@", limitViewModel.perDayLimitStr];
        }
    }
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        _topLineView.backgroundColor = localTheme.separatorColor;
        _perDayLimitLabel.textColor = localTheme.subtitleColor;
        _perPayLimitLabel.textColor = localTheme.subtitleColor;
        _perDayLimitValueLabel.textColor = localTheme.limitTextColor;
        _perPayLimitValueLabel.textColor = localTheme.limitTextColor;
    }
}

- (UILabel *)perDayLimitLabel {
    if (!_perDayLimitLabel) {
        _perDayLimitLabel = [[UILabel alloc] init];
        _perDayLimitLabel.frame = CGRectMake(0, 0, 150, 15);
        _perDayLimitLabel.font = [UIFont cj_fontOfSize:14];
        _perDayLimitLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].subtitleColor;
        _perDayLimitLabel.text = CJPayLocalizedStr(@"银行卡每日限额");
        _perDayLimitLabel.hidden = YES;
    }
    return _perDayLimitLabel;
}

- (UILabel *)perPayLimitLabel {
    if (!_perPayLimitLabel) {
        _perPayLimitLabel = [[UILabel alloc] init];
        _perPayLimitLabel.frame = CGRectMake(0, 0, 150, 15);
        _perPayLimitLabel.font = [UIFont cj_fontOfSize:14];
        _perPayLimitLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].subtitleColor;
        _perPayLimitLabel.text = CJPayLocalizedStr(@"银行卡单笔限额");
    }
    return _perPayLimitLabel;
}

- (UILabel *)perDayLimitValueLabel {
    if (!_perDayLimitValueLabel) {
        _perDayLimitValueLabel = [[UILabel alloc] init];
        _perDayLimitValueLabel.frame = CGRectMake(0, 0, CJ_SCREEN_WIDTH - 32 - 150 - 8, 16);
        _perDayLimitValueLabel.textAlignment = NSTextAlignmentRight;
        _perDayLimitValueLabel.font = [UIFont cj_boldFontOfSize:16];
        _perDayLimitValueLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].limitTextColor;
    }
    return _perDayLimitValueLabel;
}

- (UILabel *)perPayLimitValueLabel {
    if (!_perPayLimitValueLabel) {
        _perPayLimitValueLabel = [[UILabel alloc] init];
        _perPayLimitValueLabel.frame = CGRectMake(0, 0, CJ_SCREEN_WIDTH - 32 - 150 - 8, 16);
        _perPayLimitValueLabel.textAlignment = NSTextAlignmentRight;
        _perPayLimitValueLabel.font = [UIFont cj_boldFontOfSize:16];
        _perPayLimitValueLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].limitTextColor;
    }
    return _perPayLimitValueLabel;
}

@end
