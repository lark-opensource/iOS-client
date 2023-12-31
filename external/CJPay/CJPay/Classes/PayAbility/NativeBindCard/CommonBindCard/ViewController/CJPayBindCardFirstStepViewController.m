//
//  CJPayBindCardFirstStepViewController.m
//  Pods
//
//  Created by renqiang on 2021/6/28.
//

#import "CJPayBindCardManager.h"
#import "CJPayBindCardFirstStepViewController.h"
#import "CJPayBindCardTopHeaderView.h"
#import "CJPayBindCardFirstStepCardTipView.h"
#import "CJPayQuickBindCardViewController.h"
#import "CJPayBindCardVCModel.h"
#import "CJPayBindCardNumberViewModel.h"
#import "CJPayBindCardNumberView.h"
#import "CJPayQuickBindCardFooterView.h"
#import "CJPayQuickBindCardQuickFrontHeaderViewModel.h"
#import "CJPayBizAuthViewController.h"
#import "CJPayBizAuthInfoModel.h"
#import "CJPayUserInfo.h"
#import "CJPayAlertUtil.h"
#import "CJPayTrackerProtocol.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCenterTextFieldContainer.h"
#import "CJPayStyleButton.h"
#import "CJPayKVContext.h"
#import "CJPaySDKDefine.h"
#import "CJPayQuickBindCardKeysDefine.h"
#import "CJPayOrderInfoView.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "CJPayBindCardRecommendBankView.h"
#import "CJPayBindCardTopHeaderViewModel.h"
#import "CJPayChangeOtherBankCardView.h"
#import "CJPayCommonBindCardUtil.h"
#import "CJPaySettingsManager.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayToast.h"
#import "UIView+CJTheme.h"
#import "CJPayUIMacro.h"

#define CJ_BACKGROUND_VIEW_WIDTH 375.0
#define CJ_BACKGROUND_VIEW_HEIGHT 380.0
#define CJ_BACKGROUND_LOGO_WIDTH 200
#define CJ_STANDARD_WIDTH 375.0

@implementation BDPayBindCardQuickFrontFirstStepModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    [dict addEntriesFromDictionary:@{
        @"jumpQuickBindCard" : CJPayBindCardShareDataKeyJumpQuickBindCard,
        @"orderAmount" : CJPayBindCardShareDataKeyOrderAmount,
        @"isShowOrderInfo" : CJPayBindCardPageParamsKeyFirstStepVCShowOrderView,
        @"retainInfo" : CJPayBindCardShareDataKeyRetainInfo,
        @"backgroundImageURL" : CJPayBindCardShareDataKeyFirstStepBackgroundImageURL
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@interface CJPayBindCardFirstStepViewController ()<CJPayCustomTextFieldContainerDelegate, UIGestureRecognizerDelegate, UIScrollViewDelegate>

#pragma mark - vc
@property (nonatomic, strong) CJPayQuickBindCardViewController *bindCardViewController;

#pragma mark - view
@property (nonatomic, strong) UIImageView *titleBGImageView;
@property (nonatomic, strong) UIView *scrollContentView;
@property (nonatomic, strong) CJPayBindCardTopHeaderView *topHeaderView;
@property (nonatomic, strong) CJPayBindCardNumberView *frontBindCardView;
@property (nonatomic, strong) CJPayQuickBindCardFooterView *footerView;
@property (nonatomic, strong) CJPayQuickBindCardFooterView *fixedFooterView;//滑动时吸底
@property (nonatomic, strong) CJPayOrderInfoView *orderInfoView;
@property (nonatomic, strong) UIView *emptyView;//为了支持滑动加入空白view
@property (nonatomic, strong) UIImageView *backgroundImageView;
@property (nonatomic, strong) CJPayChangeOtherBankCardView *changeOtherBankCardView;

#pragma mark - model
@property (nonatomic, strong) BDPayBindCardQuickFrontFirstStepModel *viewModel;
@property (nonatomic, strong) CJPayBindCardVCModel *bindCardVCModel;
@property (nonatomic, strong) CJPayBindCardNumberViewModel *cardNumberViewModel;

#pragma mark - flag
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL isConstraintsMake;
@property (nonatomic, assign) BOOL isShowChangeOtherBankView;
@property (nonatomic, strong) CJPayBindCardTopHeaderViewModel *topHeaderViewModel;

#pragma mark - constraints
@property (nonatomic, strong) MASConstraint *quickBindVCHeightConstraint;

@end

@implementation CJPayBindCardFirstStepViewController

+ (Class)associatedModelClass {
    return [BDPayBindCardQuickFrontFirstStepModel class];
}

- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        self.viewModel = [[BDPayBindCardQuickFrontFirstStepModel alloc] initWithDictionary:dict error:nil];

        if ([self.viewModel.jumpQuickBindCard isEqualToString:@"1"]) {
            self.isShowChangeOtherBankView = YES;
        }
    }
}

- (instancetype)init {
    if (self = [super init]) {
        self.isFirstAppear = YES;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    self.frontBindCardView.hidden = YES;
    self.topHeaderView.hidden = YES;
    self.changeOtherBankCardView.hidden = YES;

    [[CJPayBindCardManager sharedInstance] setEntryName:@"0"];
    
    // 进入设密页面后，刷新当前页面展示，展示为默认样式
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadCurrentView) name:CJPayBindCardSetPwdShowNotification object:nil];
    
    // 请求支持的银行卡列表接口
    @CJWeakify(self);
    [self.bindCardVCModel fetchSupportCardlistWithCompletion:^(NSError * _Nullable error, CJPayMemBankSupportListResponse * _Nullable response) {
        @CJStrongify(self);
        
        //一键绑卡列表扩列为7张卡时，客户端对各机型适配，保证输入卡号框至少显示一半，同时一键绑卡列表最少显示5张卡
        if (response.oneKeyBanksLength == 7) {
            CGFloat quickBindCardViewHeight = [self.bindCardVCModel getBindCardViewModelsHeight:response];
            CGFloat scrollViewHeight = self.scrollView.cj_height;
            CGFloat topHeaderViewHeight = self.topHeaderView.cj_height;
            NSInteger newBanksLength = 7;
            for (; newBanksLength>=5 ; newBanksLength--) {
                if (quickBindCardViewHeight + topHeaderViewHeight + 100 > scrollViewHeight) {
                    quickBindCardViewHeight -= 60;
                } else {
                    break;
                }
            }
            [self.bindCardVCModel updateBanksLength:newBanksLength];
            [self.bindCardVCModel reloadQuickBindCardListWith:response];
        }
        
        [CJPayPerformanceMonitor trackPageFinishRenderWithVC:self name:@"" extra: @{}];
        self.cardNumberViewModel.bankSupportListResponse = response;
        
        if (self.viewModel.isShowKeyboard) { // 聚焦到输入框
            self.viewModel.isShowKeyboard = NO;
            [self.frontBindCardView.cardNumContainer.textField becomeFirstResponder];
        }
    
        [self p_updateTopHeaderView];
        if (!self.viewModel.isQuickBindCardListHidden) {
            [self.orderInfoView updateWithText:self.viewModel.orderInfo iconURL:self.viewModel.iconURL];
        }
        
        if (self.viewModel.isShowOrderInfo) {
            [self.orderInfoView updateWithText:self.viewModel.orderInfo iconURL:self.viewModel.iconURL];
        }
        
        if (response.isSuccess) {
            self.backgroundImageView.hidden = NO;
            self.frontBindCardView.hidden = NO;
            self.topHeaderView.hidden = NO;
            if ([self.viewModel.jumpQuickBindCard isEqualToString:@"1"]) {
                self.changeOtherBankCardView.hidden = NO;
            }
            if (self.scrollContentView.cj_height - self.scrollView.cj_height < 40) {
                CGRect frame = self.scrollContentView.frame;
                frame.size.height += 40;
                self.scrollContentView.frame = frame;
            }
            if (self.isFirstAppear && !self.viewModel.isQuickBindCardListHidden) {
                [self showBizAuthViewController];
                self.isFirstAppear = NO;
            }
            
            if ([self.viewModel.skipPwd isEqualToString:@"1"] && !self.viewModel.isFromQuickBindCard) {
                // 不统计加验密码的流程, 不统计从一键绑卡过来的流程
                if (self.viewModel.startTimestamp > 100000) {
                    // 过滤无效的时间戳数据
                    NSDate *date = [NSDate dateWithTimeIntervalSinceNow:0];
                    NSTimeInterval currentTimestamp = [date timeIntervalSince1970] * 1000;
                    long duration = currentTimestamp - self.viewModel.startTimestamp;
                    [CJTracker event:@"wallet_bindcard_perf_track_event" params:@{
                        @"duration" : @(duration)
                    }];
                }
            }
            
        } else {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
        }
        
    }];
    
    [self.scrollView cj_bindCouldFoucsView:self.frontBindCardView.cardNumContainer];
    [self.scrollView cj_bindCouldFoucsView:self.frontBindCardView.phoneContainer];
    [self.scrollView cj_bindCouldFoucsView:self.frontBindCardView.nextStepButton];
    
    if (@available(iOS 13.0, *)) {
        self.modalInPresentation = CJ_Pad;
    } else {
        // Fallback on earlier versions
    }
    [self p_registerForKeyboardNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_unionBindCardUnavailable) name:CJPayUnionBindCardUnavailableNotification object:nil];
    if ([self respondsToSelector:@selector(event:params:)])
    {
        [self event:@"wallet_addbcard_first_page_imp_launch" params:@{}];
    }
    
    if (self.viewModel.pageFromCashierDesk) {
        NSMutableDictionary *cardTypeNameDic = [NSMutableDictionary dictionaryWithDictionary:@{
            @"DEBIT" : @"储蓄卡",
            @"CREDIT" : @"信用卡"
        }];
        NSString *bankTypeName = [cardTypeNameDic btd_stringValueForKey:self.viewModel.selectedBankType];
        [self.bindCardVCModel setQuickBankInfo:@{
            @"bank_name" : CJString(self.viewModel.selectedBankName),
            @"bank_type" : CJString(bankTypeName)
        }];
    }
}

- (void)reloadCurrentView {
    self.bindCardVCModel.vcStyle = CJPayBindCardStyleFold;
    [self.bindCardVCModel reloadQuickBindCardList];
    self.scrollView.contentOffset = CGPointZero;
    [self.frontBindCardView.cardNumContainer clearText];
    [self.frontBindCardView changeShowTypeTo:CJPayBindCardNumberViewShowTypeOriginal];
    self.bindCardVCModel.supportCardListResponse.retainInfo.isHadShowRetain = YES;
}

#pragma mark - private
- (void)p_setupUI {
    self.scrollView.delegate = self;
    self.view.backgroundColor = [UIColor cj_f8f8f8ff];
    [self.view addSubview:self.scrollView];
    [self.view addSubview:self.fixedFooterView.contentView];
    [self.view addSubview:self.navigationBar];
    [self.scrollView addSubview:self.scrollContentView];
    [self.scrollContentView addSubview:self.backgroundImageView];
    self.navigationBar.backgroundColor = [UIColor cj_f8f8f8ff];
    
    [self.scrollContentView addSubview:self.topHeaderView];
    if (!self.viewModel.isQuickBindCardListHidden) {
        [self addChildViewController:self.bindCardViewController];
        [self.scrollContentView addSubview:self.bindCardViewController.view];
    }
    [self.scrollContentView addSubview:self.frontBindCardView];
    [self.scrollContentView addSubview:self.footerView.contentView];
    self.emptyView.backgroundColor = self.view.backgroundColor;
    [self.scrollContentView addSubview:self.emptyView];
    [self.navigationBar addSubview:self.orderInfoView];
    [self p_addGesture];
    [self p_setupBackgroundImageView];
    
    if (Check_ValidString(self.viewModel.backgroundImageURL)) {
        [self.scrollContentView addSubview:self.titleBGImageView];
        [self.scrollContentView bringSubviewToFront:self.navigationBar];
        CJPayMasMaker(self.titleBGImageView, {
            make.top.equalTo(self.navigationBar.mas_top);
            make.left.right.equalTo(self.navigationBar);
            make.height.mas_equalTo(80);
        });
    }
    
    CJPayMasMaker(self.orderInfoView, {
        make.centerX.equalTo(self.navigationBar);
        make.centerY.equalTo(self.navigationBar.backBtn);
    });
    
    CJPayMasMaker(self.scrollView, {
        make.left.right.bottom.equalTo(self.view);
        make.top.equalTo(self.view);
    })
    
    CJPayMasMaker(self.scrollContentView, {
        make.edges.equalTo(self.scrollView);
        make.width.equalTo(self.view);
        make.height.greaterThanOrEqualTo(self.scrollView);
        make.height.mas_equalTo(100).priorityLow();
    })
    CJPayMasMaker(self.topHeaderView, {
        make.top.equalTo(self.scrollContentView).offset([self navigationHeight]);
        make.left.equalTo(self.scrollContentView).offset(16);
        make.right.equalTo(self.scrollContentView).offset(-16);
    })
    if (!self.viewModel.isQuickBindCardListHidden) {
        CJPayMasMaker(self.bindCardViewController.view, {
            make.top.equalTo(self.topHeaderView.mas_bottom);
            make.left.equalTo(self.scrollContentView).offset(-16);
            make.right.equalTo(self.scrollContentView).offset(16);
            self.quickBindVCHeightConstraint = make.height.mas_equalTo(1);
        })
    }
    

    CJPayMasReMaker(self.frontBindCardView, {
        if (self.viewModel.isQuickBindCardListHidden){
            make.top.equalTo(self.topHeaderView.mas_bottom).offset(12);
        } else {
            make.top.equalTo(self.bindCardViewController.view.mas_bottom).offset(12);
        }
        make.left.right.equalTo(self.scrollContentView);
        make.bottom.lessThanOrEqualTo(self.scrollContentView);
    })
    
    CJPayMasMaker(self.emptyView, {
        make.left.right.equalTo(self.scrollContentView);
        make.top.equalTo(self.frontBindCardView.mas_bottom);
        make.height.equalTo(@40);
    });

    CJPayMasMaker(self.footerView.contentView, {
        make.left.right.equalTo(self.scrollContentView);
        make.height.mas_equalTo(42);
        make.centerX.equalTo(self.scrollContentView);
        make.top.greaterThanOrEqualTo(self.emptyView.mas_bottom);
        make.bottom.lessThanOrEqualTo(self.scrollView).offset(-CJ_TabBarSafeBottomMargin - 16);
    });
    
    CJPayMasMaker(self.fixedFooterView.contentView, {
        make.left.right.equalTo(self.scrollContentView);
        make.height.mas_equalTo(42);
        make.centerX.equalTo(self.scrollContentView);
        make.bottom.equalTo(self.scrollView).offset(-CJ_TabBarSafeBottomMargin - 16);
    });
    
    if (self.isShowChangeOtherBankView) {
        [self.view addSubview:self.changeOtherBankCardView];
        CJPayMasMaker(self.changeOtherBankCardView, {
            make.top.equalTo(self.frontBindCardView.mas_bottom).offset(20);
            make.left.right.equalTo(self.view);
        });
    }
}

- (void)p_setupBackgroundImageView {
    self.navigationBar.backgroundColor = [UIColor cj_colorWithHexString:@"cj_f8f8f8" alpha:0];
    self.scrollView.bounces = NO;
    
    if (![CJPaySettingsManager shared].currentSettings.abSettingsModel.isHiddenDouyinLogo) {
        [self.backgroundImageView cj_setImage:@"cj_bindcard_logo_icon"];
    }
    
    CJPayMasMaker(self.backgroundImageView, {
        make.top.equalTo(self.scrollContentView);
        make.right.equalTo(self.scrollContentView);
        make.width.height.mas_equalTo(self.view.cj_width * CJ_BACKGROUND_LOGO_WIDTH / CJ_STANDARD_WIDTH);
    });
}

- (void)changeOtherBank {
    [self p_changeOtherBank];
}

- (void)p_updateEmptyViewHeight:(CGFloat)height {
    CJPayMasUpdate(self.emptyView, {
        make.height.equalTo(@(height));
    });
    [self.scrollView setNeedsLayout];
    [self.scrollView layoutIfNeeded];
}

- (void)p_addGesture {
    UITapGestureRecognizer *tapEndEditGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_endEditMode)];
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(p_endEditMode)];
    tapEndEditGesture.delegate = self;
    
    [self.view addGestureRecognizer:tapEndEditGesture];
    [self.view addGestureRecognizer:swipeGesture];
}

- (void)p_endEditMode {
    [self.view endEditing:YES];
}

- (void)p_registerForKeyboardNotifications {
    if (CJ_Pad) {
        return;
    }
}

- (void)p_unionBindCardUnavailable {
    [CJPayKVContext kv_setValue:@"1" forKey:CJPayUnionPayIsUnAvailable];
    [self p_reloadQuickBindCardListWithResponse:self.cardNumberViewModel.bankSupportListResponse];
}

- (void)p_reloadQuickBindCardListWithResponse:(CJPayMemBankSupportListResponse *)response
{
    [self.bindCardVCModel reloadQuickBindCardListWith:response showBottomLabel:NO];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateCertificationStatus {
    [self.cardNumberViewModel updateCertificationStatus:self.viewModel.isCertification];
}

- (NSDictionary *)p_genDictionaryByKeys:(NSArray <NSString *>*)keys fromViewModel:(BDPayBindCardQuickFrontFirstStepModel *)viewModel {
    if (keys == nil || keys.count == 0 || viewModel == nil) {
        return nil;
    }
    
    NSDictionary *allSharedDataDict = [viewModel toDictionary];
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    [keys enumerateObjectsUsingBlock:^(NSString * _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([allSharedDataDict cj_objectForKey:key]) {
            [returnDict cj_setObject:[allSharedDataDict cj_objectForKey:key] forKey:key];
        }
    }];
    
    return [returnDict copy];
}

- (void)p_updateEmptyViewForRoll {
    if (self.bindCardVCModel.vcStyle != CJPayBindCardStyleDeepFold) {
        return;
    }
    //12-距离键盘的最小距离，（-42 - CJ_TabBarSafeBottomMargin - 16）安全险高度及其距离底部距离
    CGFloat emptyViewHeight = [self.frontBindCardView.cardNumContainer getKeyBoardHeight] + 12 - 42 - CJ_TabBarSafeBottomMargin - 16;
    [self p_updateEmptyViewHeight:emptyViewHeight];
    CGFloat contentOffsetY = self.scrollView.contentOffset.y > 0 ? : 0;
    self.scrollView.contentOffset = CGPointMake(0, self.scrollContentView.cj_height - self.scrollView.cj_height - contentOffsetY);
}

- (void)p_updateTopHeaderView {
    self.topHeaderViewModel.displayIcon = self.cardNumberViewModel.bankSupportListResponse.bindCardTitleModel.displayIcon;
    self.topHeaderViewModel.displayDesc = self.cardNumberViewModel.bankSupportListResponse.bindCardTitleModel.displayDesc;
    self.topHeaderViewModel.voucherList = self.cardNumberViewModel.bankSupportListResponse.voucherList;
    
    if (self.viewModel.isQuickBindCardListHidden && self.viewModel.isFromQuickBindCard) {
        [self p_updateTopHeaderViewByViewModel];
    } else {
        [self p_updateTopHeaderViewByResponse];
    }
}

- (void)p_updateTopHeaderViewByViewModel {
    self.topHeaderViewModel.bankIcon = self.viewModel.selectedBankIcon;
    
    self.topHeaderViewModel.preTitle = @"";
    self.topHeaderViewModel.orderAmount = self.viewModel.orderAmount;
    if (!Check_ValidString(self.topHeaderViewModel.orderAmount)) {
        self.topHeaderViewModel.preTitle = CJPayLocalizedStr(@"添加");
    }
    
    if (self.viewModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay) {
        self.topHeaderViewModel.title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@"), self.viewModel.selectedBankName, @"卡支付"];
    } else {
        self.topHeaderViewModel.title = [NSString stringWithFormat:CJPayLocalizedStr(@"%@%@"), self.viewModel.selectedBankName, @"卡"];
    }
   
    if (!self.viewModel.pageFromCashierDesk) {
        CJPayQuickBindCardModel *model = [CJPayQuickBindCardModel new];
        model.bankName = self.viewModel.selectedBankName;
        model.iconUrl = self.viewModel.selectedBankIcon;
        model.voucherMsg = self.viewModel.selectedCardTypeVoucher ? : self.cardNumberViewModel.bankSupportListResponse.voucherMsg;
        model.selectedCardType = self.viewModel.selectedBankType;
        [self.cardNumberViewModel updateBankAndVoucherInfo:model];
    }
    self.topHeaderViewModel.forceShowTopSafe = self.forceShowTopSafe;
    [self.topHeaderView updateWithModel:self.topHeaderViewModel];
}

- (void)p_updateTopHeaderViewByResponse {
    self.topHeaderViewModel.title = self.viewModel.firstStepMainTitle;
    if (!Check_ValidString(self.topHeaderViewModel.title) && self.viewModel.cardBindSource == CJPayCardBindSourceTypeBindAndPay) {
        self.topHeaderViewModel.title = CJPayLocalizedStr(@"添加银行卡支付");
    }
    self.topHeaderViewModel.bankIcon = @"";
    self.topHeaderViewModel.preTitle = @"";
    self.topHeaderViewModel.orderAmount = @"";
    [self.topHeaderView updateWithModel:self.topHeaderViewModel];
}

- (void)p_updateFooterView {
    if (self.scrollContentView.cj_height - self.scrollView.contentOffset.y - self.emptyView.cj_height + self.footerView.contentView.cj_height < self.scrollView.cj_height + 2) {//+2避免弹跳
        self.footerView.contentView.hidden = YES;
        self.fixedFooterView.contentView.hidden = NO;//吸底
    }
    
    if (self.scrollContentView.cj_height - self.scrollView.contentOffset.y > self.scrollView.cj_height){
        self.footerView.contentView.hidden = NO;
        self.fixedFooterView.contentView.hidden = YES;
    }
}

- (void)p_changeOtherBank {
    self.forceShowTopSafe = NO;
    [self p_updateTopHeaderView];
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:@{CJPayBindCardShareDataKeyJumpQuickBindCard: @"0"}
                                                         completion:^(NSArray * _Nonnull modifyedKeysArray) {}];
    
    self.viewModel.isQuickBindCardListHidden = NO;
    
    // 添加 bindCardViewController 并展开
    [self addChildViewController:self.bindCardViewController];
    [self.scrollContentView addSubview:self.bindCardViewController.view];
    
    CJPayMasReMaker(self.bindCardViewController.view, {
        make.top.equalTo(self.topHeaderView.mas_bottom);
        make.left.equalTo(self.scrollContentView).offset(-16);
        make.right.equalTo(self.scrollContentView).offset(16);
        self.quickBindVCHeightConstraint = make.height.mas_equalTo(1);
    })
    
    CJPayMasReMaker(self.frontBindCardView, {
        make.top.equalTo(self.bindCardViewController.view.mas_bottom).offset(12);
        make.left.right.equalTo(self.scrollContentView);
        make.bottom.lessThanOrEqualTo(self.scrollContentView);
    })
    
    self.bindCardVCModel.vcStyle = CJPayBindCardStyleFold;
    [self.bindCardVCModel reloadQuickBindCardList];
                   
    // 更新标题
    [self p_updateTopHeaderViewByResponse];
    
    // 隐藏更换其他银行卡按钮
    self.changeOtherBankCardView.hidden = YES;
    
    // 收起输入框
    [self.view endEditing:YES];
    
    NSMutableDictionary *trackerParams = [[self.bindCardVCModel getCommonTrackerParams] mutableCopy];
    [trackerParams cj_setObject:self.viewModel.selectedBankName forKey:@"bank_name"];
    [trackerParams cj_setObject:self.viewModel.selectedBankType forKey:@"bank_type"];
    [trackerParams cj_setObject:@"1" forKey:@"page_from"];
    [self p_trackerWithEventName:@"wallet_addbcard_onestepbind_banktype_return_banklist_click" params:trackerParams];
}

- (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [self p_updateFooterView];
    CGFloat offsetY = self.scrollView.contentOffset.y;
    
    self.navigationBar.backgroundColor = [UIColor cj_colorWithHexString:@"f8f8f8" alpha:offsetY/64];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    // 设置指定子View是否接受来自VC的手势事件

    // 点到一键绑卡的header部分，也需要失焦
    if (!self.viewModel.isQuickBindCardListHidden && [touch.view isDescendantOfView:self.bindCardViewController.tableViewHeader]) {
        return YES;
    }
    
    if ((!self.viewModel.isQuickBindCardListHidden && [touch.view isDescendantOfView:self.bindCardViewController.view]) || [touch.view isDescendantOfView:self.frontBindCardView.protocolView]) {
        return NO;
    }
    
    return YES;
}

- (UIImageView *)titleBGImageView {
    if (!_titleBGImageView) {
        _titleBGImageView = [UIImageView new];
        _titleBGImageView.backgroundColor = [UIColor clearColor];
        if (Check_ValidString(self.viewModel.backgroundImageURL)) {
            [_titleBGImageView cj_setImageWithURL:[NSURL URLWithString:self.viewModel.backgroundImageURL]];
        }
    }
    return _titleBGImageView;
}

- (UIView *)scrollContentView {
    if (!_scrollContentView) {
        _scrollContentView = [[UIView alloc] init];
        _scrollContentView.clipsToBounds = NO;
    }
    return _scrollContentView;
}

- (CJPayOrderInfoView *)orderInfoView {
    if (!_orderInfoView) {
        _orderInfoView = [[CJPayOrderInfoView alloc] init];
    }
    return _orderInfoView;
}

- (CJPayBindCardTopHeaderView *)topHeaderView {
    if (!_topHeaderView) {
        _topHeaderView = [CJPayBindCardTopHeaderView new];
    }
    return _topHeaderView;
}

- (CJPayBindCardVCModel *)bindCardVCModel {
    if (!_bindCardVCModel) {
        NSArray *needParams = [CJPayBindCardVCModel dataModelKey];
        NSDictionary *paramsDict = [self p_genDictionaryByKeys:needParams fromViewModel:self.viewModel];
        _bindCardVCModel = [[CJPayBindCardVCModel alloc] initWithBindCardDictonary:paramsDict];
        
        _bindCardVCModel.vcStyle = CJPayBindCardStyleFold;
        _bindCardVCModel.trackerDelegate = self;
        _bindCardVCModel.viewController =  self;
        _bindCardVCModel.isSyncUnionCard = self.viewModel.isSyncUnionCard;
        @CJWeakify(self);
        _bindCardVCModel.inputCardNoBlock = ^{
            @CJStrongify(self);
            [self.frontBindCardView.cardNumContainer.textField becomeFirstResponder];
        };
        
        _bindCardVCModel.abbrevitionViewButtonBlock = ^{
            @CJStrongify(self);
            if ([self.frontBindCardView isNotInput]) {
                [self.frontBindCardView changeShowTypeTo:self.frontBindCardView.firstShowType];
            }
        };
    }
    return _bindCardVCModel;
}

- (CJPayBindCardNumberViewModel *)cardNumberViewModel {
    if (!_cardNumberViewModel) {
        NSArray *needParams = [CJPayBindCardNumberViewModel dataModelKey];
        NSDictionary *paramsDict = [self p_genDictionaryByKeys:needParams fromViewModel:self.viewModel];
        _cardNumberViewModel = [[CJPayBindCardNumberViewModel alloc] initWithBindCardDictonary:paramsDict];
        
        _cardNumberViewModel.viewController = self;
        _cardNumberViewModel.trackerDelegate = self;
        
        @CJWeakify(self);
        _cardNumberViewModel.rollUpQuickBindCardListBlock = ^{
            @CJStrongify(self);
            [self.bindCardVCModel rollUpQuickBindCardList];
            [self p_updateEmptyViewForRoll];
        };
        
        _cardNumberViewModel.rollDownQuickBindCardListBlock = ^{
            @CJStrongify(self);
            [self.bindCardVCModel rollDownQuickBindCardList];
        };
    }
    return _cardNumberViewModel;
}

- (CJPayQuickBindCardViewController *)bindCardViewController {
    if (!_bindCardViewController) {
        _bindCardViewController = self.bindCardVCModel.bindCardViewController;
        @CJWeakify(self)
        _bindCardViewController.contentHeightDidChangeBlock = ^(CGFloat newHeight) {
            @CJStrongify(self);
            self.quickBindVCHeightConstraint.offset = newHeight;
            // 做个延迟，不然会有一种情况下，tableview有布局问题
            [self.view setNeedsUpdateConstraints];
            [self.view updateConstraintsIfNeeded];
            [self.bindCardViewController.tableView scrollsToTop];
            
            if (self.bindCardVCModel.vcStyle != CJPayBindCardStyleDeepFold && self.emptyView.cj_height != 40) {
                [self p_updateEmptyViewHeight:40];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self p_updateFooterView];
            });
        };
    }
    return _bindCardViewController;
}

- (CJPayBindCardNumberView *)frontBindCardView {
    if (!_frontBindCardView) {
        _frontBindCardView = self.cardNumberViewModel.frontBindCardView;
    }
    return _frontBindCardView;
}

- (CJPayQuickBindCardFooterView *)footerView {
    if (!_footerView) {
        _footerView = [CJPayQuickBindCardFooterView new];
        CJPayQuickBindCardFooterViewModel *vm = [CJPayQuickBindCardFooterViewModel new];
        [_footerView bindViewModel:vm];
    }
    return _footerView;
}

- (CJPayQuickBindCardFooterView *)fixedFooterView {
    if (!_fixedFooterView) {
        _fixedFooterView = [CJPayQuickBindCardFooterView new];
        CJPayQuickBindCardFooterViewModel *vm = [CJPayQuickBindCardFooterViewModel new];
        [_fixedFooterView bindViewModel:vm];
        _fixedFooterView.contentView.hidden = YES;
    }
    return _fixedFooterView;
}

- (UIView *)emptyView {
    if (!_emptyView) {
        _emptyView = [UIView new];
    }
    return _emptyView;
}

- (UIImageView *)backgroundImageView {
    if (!_backgroundImageView) {
        _backgroundImageView = [UIImageView new];
        _backgroundImageView.hidden = YES;
    }
    return _backgroundImageView;
}

- (CJPayChangeOtherBankCardView *)changeOtherBankCardView {
    if (!_changeOtherBankCardView) {
        _changeOtherBankCardView = [CJPayChangeOtherBankCardView new];
        
        @CJWeakify(self)
        _changeOtherBankCardView.changeBankCardBtnClick = ^{
            @CJStrongify(self);
            [self p_changeOtherBank];
        };
    }
    return _changeOtherBankCardView;
}

- (CJPayBindCardTopHeaderViewModel *)topHeaderViewModel {
    if (!_topHeaderViewModel) {
        _topHeaderViewModel = [CJPayBindCardTopHeaderViewModel new];
    }
    return _topHeaderViewModel;
}

@end
