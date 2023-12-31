//
//  CJPayUnionBindCardChooseView.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionBindCardChooseView.h"

#import "CJPayUnionBindCardChooseHeaderView.h"
#import "CJPayUIMacro.h"
#import "CJPayStyleButton.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayUnionBindCardChooseViewModel.h"
#import "CJPayBindCardScrollView.h"
#import "CJPayAccountInsuranceTipView.h"
#import "CJPayUnionCardInfoModel.h"
#import "CJPayUnionBindCardListResponse.h"
#import "CJPayUnionBindCardCommonModel.h"
#import "CJPayUnionPaySignInfo.h"

static CGFloat tableViewPadding = 10;
static CGFloat tableViewCellHeight = 76;

@interface CJPayUnionBindCardChooseView()

@property (nonatomic, strong) CJPayBindCardScrollView *scrollView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayUnionBindCardChooseHeaderView *headerView;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayAccountInsuranceTipView *safeGuardTipView;

@property (nonatomic, strong) MASConstraint *protocolTopBaseScrollViewConstraint;
@property (nonatomic, strong) MASConstraint *safeGuideTipViewHeightConstraint;
@property (nonatomic, strong) MASConstraint *confirmButtonBaseSafeGuideTipViewConstraint;
@property (nonatomic, strong) MASConstraint *confirmButtonBaseSelfViewConstraint;

@end

@implementation CJPayUnionBindCardChooseView

- (instancetype)initWithViewModel:(CJPayUnionBindCardChooseViewModel *)viewModel {
    self = [super init];
    if (self) {
        self.viewModel = viewModel;
        [self p_setupUI];
    }
    return self;
}

- (void)p_setupUI {
    [self addSubview:self.scrollView];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.headerView];
    [self.scrollContentView addSubview:self.tableView];
    [self addSubview:self.protocolView];
    [self addSubview:self.confirmButton];
    [self addSubview:self.safeGuardTipView];
    
    if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        [self.headerView updateTitle:CJPayLocalizedStr(@"选择要同步的云闪付银行卡")];
    }
    
    CJPayMasMaker(self.scrollView, {
        make.top.equalTo(self);
        make.left.right.equalTo(self);
    });
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self);
        make.height.greaterThanOrEqualTo(self.scrollView);
    });
    
    CJPayMasMaker(self.headerView, {
        make.top.left.right.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.tableView, {
        make.top.equalTo(self.headerView.mas_bottom);
        make.left.right.equalTo(self.scrollContentView).inset(16);
        make.height.mas_equalTo(tableViewPadding * 2 + tableViewCellHeight * self.viewModel.cardListResponse.cardList.count);
        make.bottom.equalTo(self.scrollContentView);
    });
    
    CJPayMasMaker(self.protocolView, {
        self.protocolTopBaseScrollViewConstraint = make.top.equalTo(self.scrollView.mas_bottom).offset(8);
        make.left.right.equalTo(self).inset(24);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.protocolView.mas_bottom).offset(8);
        make.left.right.equalTo(self).inset(24);
        make.height.mas_equalTo(CJ_BUTTON_HEIGHT);
        self.confirmButtonBaseSafeGuideTipViewConstraint = make.bottom.lessThanOrEqualTo(self.safeGuardTipView.mas_top).offset(-12).priorityHigh();
        self.confirmButtonBaseSelfViewConstraint = make.bottom.equalTo(self.safeGuardTipView.mas_top).offset(-12).priorityHigh();
    });
    
    CJPayMasMaker(self.safeGuardTipView, {
        make.bottom.equalTo(self);
        self.safeGuideTipViewHeightConstraint = make.height.mas_equalTo(18);
        make.centerX.width.equalTo(self);
    });
    
    [self bringSubviewToFront:self.confirmButton];
    
    [self p_setupData];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.02 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self p_updateViewConstraint];
    });
}

- (void)p_updateViewConstraint {
    CGFloat confirmButtonBottomY = CGRectGetMaxY(self.confirmButton.frame);
    CGFloat safeGuideViewTopY = CGRectGetMinY(self.safeGuardTipView.frame);
    
    BOOL isScroll = safeGuideViewTopY - confirmButtonBottomY <= 12;
    self.protocolTopBaseScrollViewConstraint.offset = isScroll ? 8 : 32;
    
    if (isScroll) {
        [self.confirmButtonBaseSafeGuideTipViewConstraint activate];
        [self.confirmButtonBaseSelfViewConstraint deactivate];
    } else {
        [self.confirmButtonBaseSafeGuideTipViewConstraint deactivate];
        [self.confirmButtonBaseSelfViewConstraint activate];
    }
}

- (void)p_setupData {
    CJPayUnionPaySignInfo *unionPaySignInfo = self.viewModel.unionBindCardCommonModel.unionPaySignInfo;
    [self.headerView updateWithUnionPaySignInfo:unionPaySignInfo];
    
    BOOL isShowSafeGuideTipView = Check_ValidString(unionPaySignInfo.voucherLabel); //有营销信息时展示底部安全险，无营销时隐藏底部安全险
    self.safeGuideTipViewHeightConstraint.offset = isShowSafeGuideTipView ? 18 : 0;
    self.confirmButtonBaseSafeGuideTipViewConstraint.offset = isShowSafeGuideTipView ? -12 : 0;
    self.confirmButtonBaseSelfViewConstraint.offset = isShowSafeGuideTipView ? -12 : 0;
    
    CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
    protocolModel.agreements = self.viewModel.selectedUnionCardInfoModel.agreements;
    protocolModel.groupNameDic = self.viewModel.selectedUnionCardInfoModel.protocolGroupNames;
    protocolModel.guideDesc = self.viewModel.selectedUnionCardInfoModel.guideMessage;
    protocolModel.supportRiskControl = YES;
    [self.protocolView updateWithCommonModel:protocolModel];
}

- (void)reloadWithViewModel:(CJPayUnionBindCardChooseViewModel *)viewModel {
    self.viewModel = viewModel;
    [self.tableView reloadData];
}

- (CJPayBindCardScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[CJPayBindCardScrollView alloc] init];
        _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
        _scrollView.bounces  = YES;
    }
    return _scrollView;
    
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [UIView new];
    }
    return _scrollContentView;
}

- (CJPayUnionBindCardChooseHeaderView *)headerView {
    if (!_headerView) {
        _headerView = [CJPayUnionBindCardChooseHeaderView new];
    }
    return _headerView;
}

- (UITableView *)tableView {
    if (!_tableView) {
        _tableView = [UITableView new];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.scrollEnabled = NO;
        _tableView.contentInset = UIEdgeInsetsMake(tableViewPadding, 0, tableViewPadding, 0);
        _tableView.showsVerticalScrollIndicator = NO;
        _tableView.tableFooterView = [UIView new];
        _tableView.layer.cornerRadius = 8;
        _tableView.bounces = NO;
    }
    return _tableView;
}

- (CJPayCommonProtocolView *)protocolView {
    if (!_protocolView) {
        CJPayCommonProtocolModel *protocolModel = [CJPayCommonProtocolModel new];
        protocolModel.agreements = self.viewModel.selectedUnionCardInfoModel.agreements;
        protocolModel.groupNameDic = self.viewModel.selectedUnionCardInfoModel.protocolGroupNames;
        protocolModel.guideDesc = self.viewModel.selectedUnionCardInfoModel.guideMessage;
        protocolModel.supportRiskControl = YES;

        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:protocolModel];
        @CJWeakify(self)
        _protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
            @CJStrongify(self)
            CJ_CALL_BLOCK(self.protocolClickBlock);
        };
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"同意协议并继续")];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
    }
    return _confirmButton;
}

- (CJPayAccountInsuranceTipView *)safeGuardTipView {
    if (!_safeGuardTipView) {
        _safeGuardTipView = [CJPayAccountInsuranceTipView new];
        _safeGuardTipView.clipsToBounds = YES;
    }
    return _safeGuardTipView;
}

@end
