//
//  CJPayQuickBindCardTableViewCell.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/12.
//

#import "CJPayQuickBindCardTableViewCell.h"

#import "CJPaySDKMacro.h"
#import "CJPayUIMacro.h"
#import "CJPayLineUtil.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayQuickBindCardViewModel.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayMethodCellTagView.h"
#import "CJPayBindCardVoucherInfo.h"
#import "CJPayBindCardVCModel.h"
#import <BDWebImage/BDWebImage.h>
#import "CJPayBindCardTitleInfoModel.h"
#import "UIView+CJTheme.h"

@interface CJPayQuickBindCardTableViewCell()

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *arrowImageView;
@property (nonatomic, strong) CJPayMethodCellTagView *mainVoucherView;
@property (nonatomic, strong) CJPayMethodCellTagView *subVoucherView;
@property (nonatomic, strong) UIView *bottomLine;

@property (nonatomic, strong) MASConstraint *titleLabelCenterYConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelTopBaseSelfConstraint;
@property (nonatomic, strong) MASConstraint *titleLabelLeftToImageViewConstraint;

@property (nonatomic, assign) CJPayBindCardStyle viewStyle;

@end

@implementation CJPayQuickBindCardTableViewCell

- (void)setupUI
{
    [super setupUI];
    
    [self.containerView addSubview:self.iconImageView];
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.mainVoucherView];
    [self.containerView addSubview:self.subVoucherView];
    [self.containerView addSubview:self.arrowImageView];
    
    [self.iconImageView cj_showCornerRadius:10];
    
    CJPayMasMaker(self.iconImageView, {
        make.left.equalTo(self.containerView).offset(32);
        make.centerY.equalTo(self.containerView);
        make.width.height.mas_offset(20);
    });
    
    CJPayMasMaker(self.titleLabel, {
        self.titleLabelLeftToImageViewConstraint = make.left.equalTo(self.iconImageView.mas_right).offset(12);
        self.titleLabelCenterYConstraint = make.centerY.equalTo(self.containerView).priorityHigh();
        self.titleLabelTopBaseSelfConstraint = make.top.equalTo(self.containerView).offset(10);
    });
    [self.titleLabel setContentCompressionResistancePriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
    [self.titleLabelTopBaseSelfConstraint deactivate];
    
    CJPayMasMaker(self.mainVoucherView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(2);
        make.left.equalTo(self.titleLabel);
        make.right.lessThanOrEqualTo(self.titleLabel);
        make.height.mas_equalTo(16);
    })
    
    CJPayMasMaker(self.subVoucherView, {
        make.top.equalTo(self.mainVoucherView);
        make.left.equalTo(self.mainVoucherView.mas_right).offset(6);
        make.right.lessThanOrEqualTo(self.titleLabel);
        make.height.mas_equalTo(16);
    })
    
    CJPayMasMaker(self.arrowImageView, {
        make.right.equalTo(self.containerView).offset(-32);
        make.centerY.equalTo(self.containerView);
        make.width.height.mas_equalTo(24);
    });
}

- (void)layoutSubviews {
    self.titleLabelLeftToImageViewConstraint.offset(self.viewStyle == CJPayBindCardStyleCardCenter ? 12 : 14);
    if (self.viewStyle ==  CJPayBindCardStyleCardCenter) {
        return;
    }

    CGFloat leftPadding = 58;
    CGFloat rightPadding = 24;
    if ([self.viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]] && [(CJPayQuickBindCardViewModel *)self.viewModel isBottomLineExtend]) {
        leftPadding = 8;
        rightPadding = 8;
    }
    
    if (self.bottomLine.superview) {
        [self.bottomLine removeFromSuperview];
    }
    self.bottomLine = [CJPayLineUtil addBottomLineToView:self.containerView
                                              lineHeight:CJ_PIXEL_WIDTH
                                              marginLeft:leftPadding
                                             marginRight:rightPadding
                                            marginBottom:CJ_PIXEL_WIDTH
                                                   color:[UIColor cj_161823WithAlpha:0.06]];
    [self bringSubviewToFront:self.bottomLine];

    CJPayMasUpdate(self.iconImageView, {
        make.left.equalTo(self.containerView).offset(24);
    });
    
    CJPayMasUpdate(self.arrowImageView, {
        make.right.equalTo(self.containerView).offset(-16);
        make.width.height.mas_equalTo(24);
    });
}

- (void)drawRect:(CGRect)rect
{
    if (self.viewStyle == CJPayBindCardStyleCardCenter) {
        UIRectCorner corner = UIRectCornerTopLeft;
        UIColor *lineColor = [UIColor cj_e8e8e8ff];
        if ([self.viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
            CJPayQuickBindCardViewModel *quickBindCardViewModel = (CJPayQuickBindCardViewModel *)self.viewModel;
            if (quickBindCardViewModel.isBottomRounded) {
                corner = UIRectCornerBottomLeft | UIRectCornerBottomRight;
            }
            lineColor = [self cj_getLocalTheme].quickBindCardBorderColor;
        }
        
        [CJPayLineUtil cj_drawLines:CJPayLineBottom | CJPayLineRight | CJPayLineLeft
                 withRoundedCorners:corner
                             radius:4
                           viewRect:CGRectMake(16, 0, rect.size.width - 32, rect.size.height)
                              color:lineColor];
        return;
    }
    
    [self.containerView cj_innerRect:CGRectMake(4, 0, self.containerView.cj_width - 16, self.containerView.cj_height)
                           fillColor:[UIColor cj_ffffffWithAlpha:1]
                         strokeColor:[UIColor cj_ffffffWithAlpha:1]];
}

- (void)bindViewModel:(CJPayBaseListViewModel *)viewModel
{
    [super bindViewModel:viewModel];
    
    if ([self.viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
        CJPayQuickBindCardViewModel *bindCardViewModel = (CJPayQuickBindCardViewModel *)self.viewModel;
        self.viewStyle = bindCardViewModel.viewStyle;
        
        [self.titleLabelCenterYConstraint activate];
        [self.titleLabelTopBaseSelfConstraint deactivate];
        CJPayMasReMaker(self.mainVoucherView, {
            make.centerY.equalTo(self.containerView);
            make.left.equalTo(self.titleLabel.mas_right).offset(12);
            make.right.lessThanOrEqualTo(self.arrowImageView).offset(-12);
            make.height.mas_equalTo(16);
        })
        
        CJPayMasReMaker(self.subVoucherView, {
            make.centerY.equalTo(self.mainVoucherView);
            make.left.equalTo(self.mainVoucherView.mas_right).offset(6);
            make.right.lessThanOrEqualTo(self.arrowImageView).offset(-12);
            make.height.mas_equalTo(16);
        })
    
        CGFloat titleLabelLeftPadding = self.viewStyle == CJPayBindCardStyleCardCenter ? 12 : 14;
        CJPayMasUpdate(self.titleLabel, {
            make.left.equalTo(self.iconImageView.mas_right).offset(titleLabelLeftPadding);
        })
        [self p_reloadWithViewModel:bindCardViewModel];
    }
}

- (void)startLoading {
    [self.arrowImageView cj_startLoading];
    [self cj_responseViewController].view.window.userInteractionEnabled = NO;
}

- (void)stopLoading {
    [self.arrowImageView cj_stopLoading];
    [self cj_responseViewController].view.window.userInteractionEnabled = YES;
}

- (void)didSelect
{
    if ([self.viewModel isKindOfClass:[CJPayQuickBindCardViewModel class]]) {
        CJPayQuickBindCardViewModel *quickBindCardVM = (CJPayQuickBindCardViewModel *)self.viewModel;
        CJ_CALL_BLOCK(quickBindCardVM.didSelectedBlock, quickBindCardVM.bindCardModel);
    }
}

- (void)p_reloadWithViewModel:(CJPayQuickBindCardViewModel *)viewModel {
    @CJWeakify(self)
    [self.iconImageView cj_setImageWithURL:[NSURL URLWithString:viewModel.bindCardModel.iconUrl] placeholder:[UIImage cj_imageWithColor:[UIColor cj_skeletonScreenColor]] completion:^(UIImage * _Nonnull img, NSData * _Nonnull data, NSError * _Nonnull error) {
        @CJStrongify(self)
        if (!error) {
            [self.iconImageView cj_showCornerRadius:0];
        }
    }];
    self.titleLabel.text = CJString(viewModel.bindCardModel.bankName);
    
    [self p_updateVoucherViewWithViewModel:viewModel];
    [self p_checkSafeDistance];
}

- (void)p_updateVoucherViewWithViewModel:(CJPayQuickBindCardViewModel *)viewModel {
    [self.mainVoucherView updateTitle:@""];
    [self.subVoucherView updateTitle:@""];
    
    if (viewModel.bindCardModel.voucherInfoDict.count == 0) {
        [self.titleLabelTopBaseSelfConstraint deactivate];
        [self.titleLabelCenterYConstraint activate];
        return;
    }
    
    BOOL isShowDebitVoucher = viewModel.bindCardModel.debitBindCardVoucherInfo.isNotShowPromotion != 1;
    BOOL isShowCreditVoucher = viewModel.bindCardModel.creditBindCardVoucherInfo.isNotShowPromotion != 1;
    
    if (!isShowDebitVoucher && !isShowCreditVoucher) {
        return;
    }
    
    NSString *homePageVoucher = @"";
    NSString *cardBinVoucher = @"";
    
    if (isShowCreditVoucher) {
        homePageVoucher = viewModel.bindCardModel.creditBindCardVoucherInfo.aggregateVoucherMsg;
    }
    
    if (!Check_ValidString(homePageVoucher) && isShowDebitVoucher) {
        homePageVoucher = viewModel.bindCardModel.debitBindCardVoucherInfo.aggregateVoucherMsg;
    }
    
    if (isShowCreditVoucher) {
        cardBinVoucher = viewModel.bindCardModel.creditBindCardVoucherInfo.binVoucherMsg;
    }
    
    if (!Check_ValidString(cardBinVoucher) && isShowDebitVoucher) {
        cardBinVoucher = viewModel.bindCardModel.debitBindCardVoucherInfo.binVoucherMsg;
    }
    
    if (Check_ValidString(homePageVoucher) || Check_ValidString(cardBinVoucher)) {
        [self.mainVoucherView updateTitle:homePageVoucher];
        
        if ([self.mainVoucherView isHidden]) {
            [self.mainVoucherView updateTitle:cardBinVoucher];
        } else {
            [self.subVoucherView updateTitle:cardBinVoucher];
        }
        
        return;
    }
    
    NSString* debitVoucherStr = viewModel.bindCardModel.debitBindCardVoucherInfo.voucherMsg;
    NSString* creditVoucherStr = viewModel.bindCardModel.creditBindCardVoucherInfo.voucherMsg;
    
    if (isShowCreditVoucher && isShowDebitVoucher && [creditVoucherStr isEqualToString:debitVoucherStr]) {
        [self.mainVoucherView updateTitle:creditVoucherStr];
    } else if (isShowCreditVoucher && isShowDebitVoucher && ![creditVoucherStr isEqualToString:debitVoucherStr]) {
        if (Check_ValidString(debitVoucherStr)) {
            [self.mainVoucherView updateTitle:[NSString stringWithFormat:@"储蓄卡%@", CJString(debitVoucherStr)]];
        }
        
        if (Check_ValidString(creditVoucherStr)) {
            creditVoucherStr = [NSString stringWithFormat:@"信用卡%@", CJString(creditVoucherStr)];
            
            if ([self.mainVoucherView isHidden]) {
                [self.mainVoucherView updateTitle:creditVoucherStr];
            } else {
                [self.subVoucherView updateTitle:creditVoucherStr];
            }
        }
    } else if (isShowCreditVoucher) {
        [self.mainVoucherView updateTitle:creditVoucherStr];
    } else if (isShowDebitVoucher) {
        [self.mainVoucherView updateTitle:debitVoucherStr];
    }
}

- (void) p_checkSafeDistance {
    //检查是否超过安全距离
    dispatch_async(dispatch_get_main_queue(), ^{
        CGFloat mainVoucherRightCoordinate = self.mainVoucherView.cj_left + self.mainVoucherView.cj_width;
        CGFloat subVoucherRightCoordinate = self.subVoucherView.cj_left + self.subVoucherView.cj_width;
        CGFloat arrowImageLeftCoordinate = self.arrowImageView.cj_left;
        //只有主营销标签的情况，主营销标签长度不能超过右侧箭头，否则标签内容省略显示
        if ([self.subVoucherView isHidden]) {
            if (mainVoucherRightCoordinate + 12 > arrowImageLeftCoordinate) {
                CJPayMasMaker(self.mainVoucherView, {
                    make.right.mas_lessThanOrEqualTo(self.arrowImageView.mas_left).offset(-12);
                })
            }
        }
        //主营销标签+副营销标签长度不能超过右侧箭头，否则隐藏副营销标签
        else {
            if (subVoucherRightCoordinate + 12 > arrowImageLeftCoordinate) {
                self.subVoucherView.hidden = YES;
            }
        }
    });
}

#pragma mark - Lazy View

- (UIImageView *)iconImageView
{
    if (!_iconImageView) {
        _iconImageView = [UIImageView new];
    }
    return _iconImageView;
}

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _titleLabel.textColor = [CJPayLocalThemeStyle defaultThemeStyle].quickBindCardTitleTextColor;
    }
    return _titleLabel;
}

- (UIImageView *)arrowImageView
{
    if (!_arrowImageView) {
        _arrowImageView = [UIImageView new];
        [_arrowImageView cj_setImage:@"cj_quick_bindcard_arrow_light_icon"];
    }
    return _arrowImageView;
}

- (CJPayMethodCellTagView *)mainVoucherView {
    if (!_mainVoucherView) {
        _mainVoucherView = [CJPayMethodCellTagView new];
        _mainVoucherView.hidden = YES;
    }
    return _mainVoucherView;
}

- (CJPayMethodCellTagView *)subVoucherView {
    if (!_subVoucherView) {
        _subVoucherView = [CJPayMethodCellTagView new];
        _subVoucherView.hidden = YES;
    }
    return _subVoucherView;
}

- (void)didMoveToWindow {
    if ([self cj_responseViewController]) {
        CJPayLocalThemeStyle *localTheme = [self cj_getLocalTheme];
        _titleLabel.textColor = localTheme.quickBindCardTitleTextColor;
        [_arrowImageView cj_setImage:localTheme.quickBindCardRightArrowImgName];
    }
}

@end
