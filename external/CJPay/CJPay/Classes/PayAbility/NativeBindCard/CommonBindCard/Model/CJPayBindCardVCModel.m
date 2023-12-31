//
//  CJPayBindCardVCModel.m
//  Pods
//
//  Created by renqiang on 2021/6/29.
//

#import "CJPayBindCardVCModel.h"
#import "CJPayQuickBindCardModel.h"
#import "CJPayMemBankSupportListRequest.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayBindCardTitleInfoModel.h"
#import "CJPayQuickBindCardViewController.h"
#import "CJPayQuickBindCardTypeChooseViewController.h"
#import "CJPayUIMacro.h"
#import "CJPayQuickBindCardManager.h"
#import "CJPayBindPageInfoResponse.h"
#import "CJPayVoucherBankInfo.h"
#import "CJPayBindCardRetainInfo.h"
#import "CJPayFullPageBaseViewController+Theme.h"
#import "CJPayNativeBindCardManager.h"

@implementation CJPayBindCardVCDataModel

+ (NSDictionary <NSString *, NSString *> *)keyMapperDict {
    NSMutableDictionary *dict = [NSMutableDictionary new];

    [dict addEntriesFromDictionary:@{
        @"specialMerchantId" : CJPayBindCardShareDataKeySpecialMerchantId,
        @"signOrderNo" : CJPayBindCardShareDataKeySignOrderNo,
        @"bankListResponse" : CJPayBindCardShareDataKeyBankListResponse,
        @"isEcommerceAddBankCardAndPay" : CJPayBindCardShareDataKeyIsEcommerceAddBankCardAndPay,
    }];
    
    [dict addEntriesFromDictionary:[super keyMapperDict]];
    
    return dict;
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPayBindCardVCLoadModel
@end

@interface CJPayBindCardVCModel()

#pragma mark - vc
@property (nonatomic, strong) CJPayQuickBindCardViewController *bindCardViewController;
#pragma mark - model
@property (nonatomic, strong) CJPayBindCardVCDataModel *dataModel;
@property (nonatomic, assign) NSInteger banksLength;
@property (nonatomic, copy) NSDictionary *quickBankInfo;

@end

@implementation CJPayBindCardVCModel

+ (NSArray <NSString *>*)dataModelKey {
    return [CJPayBindCardVCDataModel keysOfParams];
}

- (instancetype)initWithBindCardDictonary:(NSDictionary *)dict {
    if (self = [super init]) {
        if (dict.count > 0) {
            self.dataModel = [[CJPayBindCardVCDataModel alloc] initWithDictionary:dict error:nil];
        }
    }
    return self;
}

- (void)fetchSupportCardlistWithCompletion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nullable))completion {
    NSDictionary *exts = @{
        @"promotion_experiment_tag" : @"0",
    };
    
    if (self.dataModel.bankListResponse &&
        self.dataModel.bankListResponse.oneKeyBanks.count) {
        [self p_syncResponse];
        [self p_handleResponse];
        CJ_CALL_BLOCK(completion, nil, self.supportCardListResponse);
        return;
    }
    
    if (self.dataModel.isEcommerceAddBankCardAndPay) {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinStyleLoading];
    } else {
        [[CJPayLoadingManager defaultService] startLoading:CJPayLoadingTypeDouyinLoading vc:self.viewController];
    }
    @CJWeakify(self)
    [CJPayMemBankSupportListRequest startWithAppId:CJString(self.dataModel.appId)
                                        merchantId:CJString(self.dataModel.merchantId)
                                 specialMerchantId:CJString(self.dataModel.specialMerchantId)
                                       signOrderNo:CJString(self.dataModel.signOrderNo)
                                              exts:exts
                                        completion:^(NSError * _Nullable error, CJPayMemBankSupportListResponse * _Nonnull response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading];
        self.supportCardListResponse = response;
        [self p_handleResponse];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

- (void)p_handleResponse {
    
    self.banksList = self.supportCardListResponse.oneKeyBanks;
    self.banksLength = (self.supportCardListResponse.oneKeyBanksLength == 0) ? 6 : self.supportCardListResponse.oneKeyBanksLength;
    
    NSDictionary *dict = @{
        CJPayBindCardShareDataKeyVoucherBankStr : CJString(self.supportCardListResponse.voucherBank),
        CJPayBindCardShareDataKeyVoucherMsgStr : CJString(self.supportCardListResponse.voucherMsg),
        CJPayBindCardShareDataKeyDisplayIcon : CJString(self.supportCardListResponse.bindCardTitleModel.displayIcon),
        CJPayBindCardShareDataKeyDisplayDesc : CJString(self.supportCardListResponse.bindCardTitleModel.displayDesc),
        CJPayBindCardShareDataKeyRetainInfo : [self.supportCardListResponse.retainInfo toDictionary] ?: @{}
    };
    
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:^(NSArray<NSString *> * _Nonnull modifyedKeysArray) {
        
    }];
    
    [self reloadQuickBindCardList];
    
    if (self.quickBankInfo) {
        NSMutableDictionary *trackerParams = [[self getCommonTrackerParams] mutableCopy];
        [trackerParams addEntriesFromDictionary:self.quickBankInfo];
        NSString *bindCardTeaSource = [[CJPayBindCardManager sharedInstance] bindCardTeaSource];
        [trackerParams addEntriesFromDictionary:@{@"tea_source" : bindCardTeaSource}];
        [self p_trackWithEventName:@"wallet_addbcard_first_page_only_cardid_imp" params:trackerParams];
    } else {
        // 一键绑卡列表获取到后才上报页面展现埋点
        NSString *topTitle = self.supportCardListResponse.bindCardTitleModel.displayDesc;
        
        if (Check_ValidString(self.supportCardListResponse.voucherMsg)) {
            if (Check_ValidString(self.supportCardListResponse.voucherBank)) {
                topTitle = [NSString stringWithFormat:@"%@,%@", CJString(self.supportCardListResponse.voucherBank), CJString(self.supportCardListResponse.voucherMsg)];
            } else {
                topTitle = CJString(self.supportCardListResponse.voucherMsg);
            }
        }
        BOOL frontBindCardViewIsShowVoucher = Check_ValidString(self.supportCardListResponse.voucherMsg) || [self.supportCardListResponse.voucherBankInfo hasVoucher];
        BOOL isShowBankVoucher = Check_ValidString(self.supportCardListResponse.voucherBank) && !self.supportCardListResponse.isSupportOneKey;
        
        NSString *inputTitleType = @"";
        if (frontBindCardViewIsShowVoucher && !isShowBankVoucher) {
            inputTitleType = @"营销";
        } else if (Check_ValidArray(self.supportCardListResponse.recommendBanks)) {
            inputTitleType = @"银行";
        }
        
        NSString *bindCardTeaSource = [[CJPayBindCardManager sharedInstance] bindCardTeaSource];
        [self p_trackWithEventName:@"wallet_addbcard_first_page_imp"
                            params:@{
                                @"onestep_bank_list" : CJString([self p_oneStepBankList]),
                                @"top_title" : CJString(topTitle),
                                @"campaign_info" : [self p_oneKeyBanksActivityInfo] ?: @[],
                                @"input_title_type" : inputTitleType,
                                @"tea_source" : bindCardTeaSource
                            }];
        
        [self p_trackWithEventName:@"wallet_addbcard_onestep_bank_page_imp" params:@{
            @"show_onestep_bank_list" : CJString([self p_oneStepBankList])
        }];
    }
}

- (NSDictionary *)getCommonTrackerParams {
    NSString *topTitle = self.supportCardListResponse.bindCardTitleModel.displayDesc;
    
    if (Check_ValidString(self.supportCardListResponse.voucherMsg)) {
        if (Check_ValidString(self.supportCardListResponse.voucherBank)) {
            topTitle = [NSString stringWithFormat:@"%@,%@", CJString(self.supportCardListResponse.voucherBank), CJString(self.supportCardListResponse.voucherMsg)];
        } else {
            topTitle = CJString(self.supportCardListResponse.voucherMsg);
        }
    }
    
    BOOL frontBindCardViewIsShowVoucher = Check_ValidString(self.supportCardListResponse.voucherMsg) || [self.supportCardListResponse.voucherBankInfo hasVoucher];
    BOOL isShowBankVoucher = Check_ValidString(self.supportCardListResponse.voucherBank) && !self.supportCardListResponse.isSupportOneKey;
    
    NSString *inputTitleType = @"";
    if (frontBindCardViewIsShowVoucher && !isShowBankVoucher) {
        inputTitleType = @"营销";
    } else if (Check_ValidArray(self.supportCardListResponse.recommendBanks)) {
        inputTitleType = @"银行";
    }
    
    NSDictionary *params = @{
        @"top_title" : CJString(topTitle),
        @"campaign_info" : [self p_oneKeyBanksActivityInfo] ?: @[],
        @"input_title_type" : inputTitleType
    };
    return params;
}

- (void)rollUpQuickBindCardList {
    if(self.vcStyle != CJPayBindCardStyleDeepFold) {
        self.latestVCStyle = self.vcStyle;
        self.vcStyle = CJPayBindCardStyleDeepFold;
        [self reloadQuickBindCardList];
    }
}

- (void)rollDownQuickBindCardList {
    self.vcStyle = self.latestVCStyle;
    [self reloadQuickBindCardList];
}

- (void)reloadQuickBindCardList {
    [self reloadQuickBindCardListWith:self.supportCardListResponse];
}

- (void)reloadQuickBindCardListWith:(CJPayMemBankSupportListResponse *)response {
    [self reloadQuickBindCardListWith:response showBottomLabel:NO];
}

- (void)abbreviationButtonClick {
    CJ_CALL_BLOCK(self.abbrevitionViewButtonBlock);
}

- (void)updateBanksLength: (NSInteger)length {
    self.banksLength = length;
}

- (CGFloat)getBindCardViewModelsHeight:(CJPayMemBankSupportListResponse *)response {
    NSString *title = @"";
    NSString *subTitle = @"";
    title = CJString(response.bindCardTitleModel.title);
    subTitle = CJString(response.bindCardTitleModel.subTitle);
    
    if (!Check_ValidString(title)) {
        title = response.title;
    }
    
    CJPayBindCardVCLoadModel *vcLoadModel = [CJPayBindCardVCLoadModel new];
    
    vcLoadModel.banksLength = self.banksLength;
    vcLoadModel.banksList = [self.banksList copy];
    vcLoadModel.title = title;
    vcLoadModel.subTitle = subTitle;
    
    NSMutableArray<CJPayBaseListViewModel *> *viewModels = [[self.bindCardViewController getViewModelsWithLoadModel:vcLoadModel] mutableCopy];
    
    return [self.bindCardViewController getTableViewHeightWithViewModels:viewModels];
}

- (void)reloadQuickBindCardListWith:(CJPayMemBankSupportListResponse *)response
                    showBottomLabel:(BOOL)show {

    NSString *title = @"";
    NSString *subTitle = @"";
    title = CJString(response.bindCardTitleModel.title);
    subTitle = CJString(response.bindCardTitleModel.subTitle);

    if (!Check_ValidString(title)) {
        title = response.title;
    }
    
    CJPayBindCardVCLoadModel *vcLoadModel = [CJPayBindCardVCLoadModel new];
    
    vcLoadModel.banksLength = self.banksLength;
    vcLoadModel.banksList = [self.banksList copy];
    vcLoadModel.title = title;
    vcLoadModel.subTitle = subTitle;
    
    if (!CJOptionsHasValue(self.vcStyle, CJPayBindCardStyleDeepFold)) {
        [self.viewController.view endEditing:YES];
    }
    
    [self.bindCardViewController reloadWithModel:vcLoadModel];
    
    if (CJOptionsHasValue(self.bindCardViewController.vcStyle, CJPayBindCardStyleUnfold)) {
        [self p_trackWithEventName:@"wallet_addbcard_first_page_openonestep_click" params:nil];
    }
}

- (BOOL)isShowOneStep {
    return (self.supportCardListResponse.oneKeyBanks.count > 0);
}

#pragma mark - private method

- (void)p_syncResponse {
    if (self.dataModel.bankListResponse) {
        self.supportCardListResponse = [CJPayMemBankSupportListResponse new];
        self.supportCardListResponse.code = @"MP000000";
        self.supportCardListResponse.creditBanks = self.dataModel.bankListResponse.creditBanks;
        self.supportCardListResponse.debitBanks = self.dataModel.bankListResponse.debitBanks;
        self.supportCardListResponse.oneKeyBanks = self.dataModel.bankListResponse.oneKeyBanks;
        self.supportCardListResponse.title = self.dataModel.bankListResponse.title;
        self.supportCardListResponse.subTitle = self.dataModel.bankListResponse.subTitle;
        self.supportCardListResponse.noPwdBindCardDisplayDesc = self.dataModel.bankListResponse.noPwdBindCardDisplayDesc;
        self.supportCardListResponse.voucherMsg = self.dataModel.bankListResponse.voucherMsg;
        self.supportCardListResponse.voucherList = self.dataModel.bankListResponse.voucherList;
        self.supportCardListResponse.voucherBank = self.dataModel.bankListResponse.voucherBank;
        self.supportCardListResponse.voucherBankInfo.iconUrl = self.dataModel.bankListResponse.voucherBankIcon;
        self.supportCardListResponse.isSupportOneKey = self.dataModel.bankListResponse.isSupportOneKey;
        self.supportCardListResponse.cardNoInputTitle = self.dataModel.bankListResponse.cardNoInputTitle;
        self.supportCardListResponse.retainInfo = self.dataModel.bankListResponse.retainInfo;
        self.supportCardListResponse.oneKeyBanks = self.dataModel.bankListResponse.oneKeyBanks;
        self.supportCardListResponse.oneKeyBanksLength = self.dataModel.bankListResponse.oneKeyBanksLength;
        self.supportCardListResponse.exts = self.dataModel.bankListResponse.exts;
        self.supportCardListResponse.recommendBanksLenth = self.dataModel.bankListResponse.recommendBanksLenth;
        self.supportCardListResponse.recommendBanks = self.dataModel.bankListResponse.recommendBanks;
        self.supportCardListResponse.recommendBindCardTitleModel = self.dataModel.bankListResponse.recommendBindCardTitleModel;
        self.supportCardListResponse.bindCardTitleModel = self.dataModel.bankListResponse.bindCardTitleModel;
    }
}

- (NSArray *)p_oneKeyBanksActivityInfo {
    NSMutableArray *activityInfos = [NSMutableArray array];
    [self.supportCardListResponse.oneKeyBanks enumerateObjectsUsingBlock:^(CJPayQuickBindCardModel * _Nonnull bindCardModel, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *cardModelInfos = [bindCardModel activityInfoWithCardType:bindCardModel.cardType];
        if (cardModelInfos.count > 0) {
            [activityInfos addObjectsFromArray:cardModelInfos];
        }
    }];
    return activityInfos;
}

- (NSString *)p_oneStepBankList
{
    NSString *list = @"";
    if ([[self.supportCardListResponse.oneKeyBanks valueForKey:@"bankName"] isKindOfClass:[NSArray class]]) {
        NSUInteger count = [self.supportCardListResponse.oneKeyBanks count];
        NSArray *abbreviationOneKeyBanks = [self.supportCardListResponse.oneKeyBanks cj_subarrayWithRange:NSMakeRange(0, (count >= 6) ? 6 : count)];
        list = [((NSArray *)[abbreviationOneKeyBanks valueForKey:@"bankName"]) componentsJoinedByString:@","];
    }
    return list;
}

- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    if (self.trackerDelegate && [self.trackerDelegate respondsToSelector:@selector(event:params:)]) {
        [self.trackerDelegate event:eventName params:params];
    }
}

- (void)p_oneKeyBindCardWithViewModel:(CJPayQuickBindCardViewModel *)viewModel {
    // 一键绑卡
    @CJStartLoading(viewModel)
    NSDictionary *dict = @{
        CJPayBindCardShareDataKeyBindUnionCardType: @(CJPayBindUnionCardTypeDefault),
    };
    
    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:^(NSArray * _Nonnull modifyedKeysArray) {
                    
    }];

    [[CJPayNativeBindCardManager shared] enterQuickBindCardWithCompletionBlock:^(BOOL isOpenedSuccess, UIViewController * _Nonnull firstVC) {
        @CJStopLoading(viewModel)
    }];
}

#pragma mark - getter && setter
- (CJPayQuickBindCardViewController *)bindCardViewController {
    if (!_bindCardViewController) {
        _bindCardViewController = [CJPayQuickBindCardViewController new];
        _bindCardViewController.tableView.showsVerticalScrollIndicator = NO;
        _bindCardViewController.tableView.showsHorizontalScrollIndicator = NO;
        _bindCardViewController.tableView.backgroundColor = [UIColor clearColor];
        _bindCardViewController.view.backgroundColor = [UIColor clearColor];
        _bindCardViewController.vcStyle = CJPayBindCardStyleFold;
        _bindCardViewController.bindCardVCModel = self;
        _bindCardViewController.cjInheritTheme = self.viewController.cjInheritTheme;
        @CJWeakify(self)
        _bindCardViewController.didSelectedBlock = ^(CJPayQuickBindCardViewModel * _Nonnull viewmodel) {
            @CJStrongify(self)

            // 判断是云闪付绑卡还是一键绑卡, bank_code = UPYSFBANK
            if (viewmodel.bindCardModel.isUnionBindCard) {
                // 云闪付绑卡
                if (self.isSyncUnionCard) {
                    NSDictionary *dict = @{
                        CJPayBindCardShareDataKeyBindUnionCardType: @(CJPayBindUnionCardTypeSyncBind)};
                    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:nil];
                } else {
                    NSDictionary *dict = @{
                        CJPayBindCardShareDataKeyBindUnionCardType: @(CJPayBindUnionCardTypeBindAndSign)};
                    [[CJPayBindCardManager sharedInstance] modifySharedDataWithDict:dict completion:nil];
                }
                
                @CJStartLoading(viewmodel);
                [[CJPayBindCardManager sharedInstance] enterUnionBindCardAndCreateOrderWithFromVC:self.viewController completionBlock:^(BOOL isOpenedSuccess, UIViewController * _Nonnull firstVC) {
                    @CJStopLoading(viewmodel);
                }];
            }  else {
                [self p_oneKeyBindCardWithViewModel:viewmodel];
            }
            
            [self p_trackWithEventName:@"wallet_addbcard_onestepbind_click" params:@{
                @"bank_name": CJString(viewmodel.bindCardModel.bankName),
                @"onestep_bank_list": CJString([self p_oneStepBankList]),
                @"activity_info" : [viewmodel.bindCardModel activityInfoWithCardType:viewmodel.bindCardModel.cardType] ?: @[],
                @"bank_rank" : CJString(viewmodel.bindCardModel.bankRank),
                @"rank_type" : CJString(viewmodel.bindCardModel.rankType)
            }];
        };
        
        _bindCardViewController.didSelectedTipsBlock = ^{
            @CJStrongify(self);
            CJ_CALL_BLOCK(self.inputCardNoBlock);
        };
    }
    return _bindCardViewController;
}

- (void)setVcStyle:(CJPayBindCardStyle)vcStyle {
    _vcStyle = vcStyle;
    self.bindCardViewController.vcStyle = vcStyle;
}

- (void)setQuickBankInfo:(NSDictionary *)bankInfo {
    _quickBankInfo = [bankInfo copy];
}

@end
