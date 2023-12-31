//
//  CJPayQuickBindCardAbbreviationView.m
//  Pods
//
//  Created by renqiang on 2021/6/30.
//

#import "CJPayQuickBindCardAbbreviationView.h"
#import "CJPayQuickBindCardAbbreviationViewModel.h"
#import "CJPayBindCardVCModel.h"
#import "CJPayUIMacro.h"

@interface CJPayQuickBindCardAbbreviationView ()

@property (nonatomic, strong) UILabel *mainTitleView;
@property (nonatomic, strong) UIImageView *arrowImageView;

@property (nonatomic, assign) CJPayBindCardStyle viewStyle;

@end

@implementation CJPayQuickBindCardAbbreviationView

- (void)setupUI {
    [super setupUI];
    
    [self.containerView addSubview:self.mainTitleView];
    [self.containerView addSubview:self.arrowImageView];
    
    CJPayMasMaker(self.mainTitleView, {
        make.centerY.equalTo(self.containerView);
        make.top.greaterThanOrEqualTo(self.containerView);
        make.bottom.lessThanOrEqualTo(self.containerView);
        make.left.equalTo(self.containerView).offset(58);
    })
    CJPayMasMaker(self.arrowImageView, {
        make.left.equalTo(self.mainTitleView.mas_right).offset(4);
        make.right.lessThanOrEqualTo(self.containerView);
        make.centerY.equalTo(self.mainTitleView);
        make.size.mas_equalTo(CGSizeMake(12, 12));
    })
}

- (void)drawRect:(CGRect)rect {
    UIRectCorner rectCorner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
    if (CJOptionsHasValue(self.viewStyle, CJPayBindCardStyleDeepFold)) {
        rectCorner = UIRectCornerAllCorners;
    }
    [self.containerView cj_innerRect:CGRectMake(4, 0, self.containerView.cj_width - 16, self.containerView.cj_height)
                          rectCorner:rectCorner
                        cornerRadius:CGSizeMake(8, 8)
                           fillColor:[UIColor cj_ffffffWithAlpha:1]
                         strokeColor:[UIColor cj_ffffffWithAlpha:1]];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel {
    [super bindViewModel:viewModel];
    
    if ([self.viewModel isKindOfClass:[CJPayQuickBindCardAbbreviationViewModel class]]) {
        CJPayQuickBindCardAbbreviationViewModel *abbreViationViewModel = (CJPayQuickBindCardAbbreviationViewModel *)self.viewModel;
        self.viewStyle = abbreViationViewModel.bindCardVCModel.vcStyle;
        self.arrowImageView.hidden = NO;
        switch (self.viewStyle) {
            case CJPayBindCardStyleFold:
                if (abbreViationViewModel.bindCardBankCount <= abbreViationViewModel.banksLength) {
                    self.arrowImageView.hidden = YES;
                    self.mainTitleView.text = CJPayLocalizedStr(@"其他银行暂不支持，请手动输入卡号添加");
                    self.mainTitleView.textColor = [UIColor cj_161823WithAlpha:0.5];
                    break;
                }
                self.mainTitleView.text = [NSString stringWithFormat:CJPayLocalizedStr(@"查看全部%d家银行"), abbreViationViewModel.bindCardBankCount];
                self.mainTitleView.textColor = [UIColor cj_161823ff];
                self.mainTitleView.font = [UIFont cj_fontOfSize:14];
                self.mainTitleView.text = [NSString stringWithFormat:CJPayLocalizedStr(@"展开全部%d家银行"), abbreViationViewModel.bindCardBankCount];
                self.mainTitleView.textColor = [UIColor cj_161823WithAlpha:0.6];
                self.arrowImageView.hidden =YES;
                
                CJPayMasUpdate(self.mainTitleView, {
                    make.left.equalTo(self.containerView).offset(58);
                })
                [self setNeedsDisplay];
                break;
            case CJPayBindCardStyleDeepFold:
                self.mainTitleView.textColor = [UIColor cj_161823WithAlpha:0.75];
                self.mainTitleView.text = CJPayLocalizedStr(@"以下银行，免输卡号");
                self.mainTitleView.font = [UIFont cj_boldFontOfSize:12];
                CJPayMasUpdate(self.mainTitleView, {
                    make.left.mas_equalTo(self.containerView).offset(24);
                })
                [self setNeedsDisplay];
                break;
            default:
                self.mainTitleView.text = CJPayLocalizedStr(@"查看全部银行");
                break;
        }
    } else {
        self.mainTitleView.text = CJPayLocalizedStr(@"查看全部银行");
    }
}

- (void)didSelect {
    if ([self.viewModel isKindOfClass:[CJPayQuickBindCardAbbreviationViewModel class]]) {
        CJPayQuickBindCardAbbreviationViewModel *abbreviationViewModel = (CJPayQuickBindCardAbbreviationViewModel *)self.viewModel;
        CJPayBindCardStyle curStyle = abbreviationViewModel.bindCardVCModel.vcStyle;
        if (CJOptionsHasValue(curStyle, CJPayBindCardStyleDeepFold)) {
            abbreviationViewModel.bindCardVCModel.vcStyle = abbreviationViewModel.bindCardVCModel.latestVCStyle ?: CJPayBindCardStyleFold;
        } else if (CJOptionsHasValue(curStyle, CJPayBindCardStyleFold)) {
            if (abbreviationViewModel.bindCardBankCount <= abbreviationViewModel.banksLength) {
                return;
            }
            abbreviationViewModel.bindCardVCModel.vcStyle = CJPayBindCardStyleUnfold;
        }
        [abbreviationViewModel.bindCardVCModel reloadQuickBindCardList];
        [abbreviationViewModel.bindCardVCModel.viewController.view setNeedsUpdateConstraints];
        [abbreviationViewModel.bindCardVCModel.viewController.view updateConstraintsIfNeeded];
        [abbreviationViewModel.bindCardVCModel abbreviationButtonClick];
    }
}

#pragma mark - lazy view
- (UILabel *)mainTitleView {
    if (!_mainTitleView) {
        _mainTitleView = [UILabel new];
        _mainTitleView.textColor = [UIColor cj_161823WithAlpha:0.5];
        _mainTitleView.font = [UIFont cj_fontOfSize:12];
    }
    return _mainTitleView;
}

- (UIImageView *)arrowImageView {
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_bindcard_down_icon"];
    }
    return _arrowImageView;
}

@end
