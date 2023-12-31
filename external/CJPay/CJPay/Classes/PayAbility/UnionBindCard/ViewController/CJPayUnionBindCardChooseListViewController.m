//
//  CJPayUnionBindCardChooseListViewController.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/24.
//

#import "CJPayUnionBindCardChooseListViewController.h"

#import "CJPayUnionBindCardChooseViewModel.h"
#import "CJPayUnionBindCardChooseTableViewCell.h"
#import "CJPayUnionBindCardListResponse.h"
#import "CJPayBindCardScrollView.h"
#import "CJPayUnionBindCardChooseHeaderView.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayProtocolViewManager.h"
#import "CJPayStyleButton.h"
#import "CJPayUnionBindCardChooseView.h"
#import "CJPayMemberSignResponse.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayAlertUtil.h"
#import "CJPayHalfSignCardVerifySMSViewController.h"
#import "CJPayUnionCardInfoModel.h"
#import "CJPayMetaSecManager.h"
#import "CJPayBindCardManager.h"
#import "CJPayBindUnionPayBindCardRequest.h"
#import "CJPayBindUnionPayBankCardResponse.h"
#import "CJPayPasswordSetFirstStepViewController.h"
#import "CJPayPasswordVerifyViewController.h"
#import "CJPayProtocolPopUpViewController.h"

@interface CJPayUnionBindCardChooseListViewController ()<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) CJPayUnionBindCardChooseView *chooseView;

@property (nonatomic, strong) CJPayUnionBindCardChooseViewModel *viewModel;

@end

@implementation CJPayUnionBindCardChooseListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self p_setupUI];
    [self p_trackWithEventName:@"wallet_ysf_bcard_list_show" params:@{@"ysf_bank_list":CJString([self p_ysfBankList])}];
    [[CJPayMetaSecManager defaultService] reportForSceneType:CJPayRiskMsgTypeUnionPayCardListRequest];
}

- (void)p_setupUI {
    self.navigationBar.backgroundColor = [UIColor cj_f5f5f5WithAlpha:1];
    self.navigationBar.titleLabel.text = self.chooseView.headerView.titleLabel.text;
    self.navigationBar.titleLabel.alpha = 0;
    self.view.backgroundColor = [UIColor cj_f5f5f5WithAlpha:1];
    
    [self.view addSubview:self.chooseView];
    
    CJPayMasMaker(self.chooseView, {
        make.top.equalTo(self.view).offset([self navigationHeight]);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-16 - CJ_TabBarSafeBottomMargin);
    });
    
    @CJWeakify(self);
    [self.chooseView.confirmButton btd_addActionBlock:^(__kindof UIControl * _Nonnull sender) {
        @CJStrongify(self);
        [self.chooseView.protocolView executeWhenProtocolSelected:^{
            @CJStrongify(self)
            [self p_buttonClick];
        } notSeleted:^{
            @CJStrongify(self)
            CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.chooseView.protocolView.protocolModel from:@"云闪付选卡页"];
            popupProtocolVC.confirmBlock = ^{
                @CJStrongify(self)
                [self.chooseView.protocolView setCheckBoxSelected:YES];
                [self p_buttonClick];
            };
            [self.navigationController pushViewController:popupProtocolVC animated:YES];
        } hasToast:NO];
    } forControlEvents:UIControlEventTouchUpInside];
    
    [self p_initSelectCardsForSync];
    
    [self.chooseView reloadWithViewModel:self.viewModel];
}

- (void)p_buttonClick {
    if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        [self p_syncCard];
    } else if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeBindAndSign) {
        [self p_sendSMS];
    }
}

- (void)p_initSelectCardsForSync {
    if (self.viewModel.bindUnionCardType != CJPayBindUnionCardTypeSyncBind) {
        return;
    }
    
    if (!self.viewModel.selectedCards) {
        self.viewModel.selectedCards = [NSMutableSet new];
    }
    
    [self.viewModel.cardListResponse.cardList enumerateObjectsUsingBlock:^(CJPayUnionCardInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.status isEqualToString:@"1"]) {
            [self.viewModel.selectedCards btd_addObject:obj.bankCardId];
        }
    }];
}

- (void)p_syncCard {
    [self.chooseView.confirmButton startLoading];
    @CJWeakify(self)
    NSDictionary *params = @{@"app_id" : self.viewModel.appId,
                             @"merchant_id" : self.viewModel.merchantId,
                             @"bank_card_id_list" : self.viewModel.selectedCards.allObjects,
                             @"member_biz_order_no" : self.viewModel.signOrderNo};
    
    [CJPayBindUnionPayBindCardRequest startRequestWithParams:params
                                                  completion:^(NSError * _Nonnull error, CJPayBindUnionPayBankCardResponse * _Nonnull response) {
        @CJStrongify(self)
        [self.chooseView.confirmButton stopLoading];
        [self p_trackWithEventName:@"wallet_ysf_bcard_click"
                            params:@{
                                @"button_name" : @"1",
                                @"result" : [response isSuccess] ? @"1" : @"0",
                                @"error_code" : CJString(response.code),
                                @"error_message" : CJString(response.msg),
                                @"ysf_card_list" : CJString([self p_selectCardList])}];
        
        if (![response isSuccess]) {
            [CJToast toastText:CJString(response.msg) ?: CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        if ([response.isSetPwd isEqualToString:@"0"]) {
            [self p_setPwd];
        } else {
            [self closeBindCardProcessWithResult:YES token:@"" completionBlock:^{}];
        }
    }];
}

- (void)p_setPwd {
    CJPayPasswordSetModel *model = [CJPayPasswordSetModel new];
    model.appID = self.viewModel.appId;
    model.merchantID = self.viewModel.merchantId;
    model.smchID = self.viewModel.specialMerchantId;
    model.signOrderNo = self.viewModel.signOrderNo;
    model.isSetAndPay = NO;
    model.isNeedCardInfo = YES;
    @CJWeakify(self)
    model.backCompletion = ^{
        @CJStrongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self closeBindCardProcessWithResult:NO token:@"" completionBlock:^{}];
        });
    };
    model.source = [[CJPayBindCardManager sharedInstance] bindCardTrackerSource];
//    model.processInfo = self.viewModel.processInfo;
    UIViewController *vc = [[CJPayBindCardManager sharedInstance] openPage:CJPayBindCardPageSetPWDFirstStep params:@{} completion:nil];
    
    if (![vc isKindOfClass:[CJPayPasswordSetFirstStepViewController class]]) {
        CJPayLogAssert(NO, @"vc类型异常%@", [vc cj_trackerName]);
        return;
    }
    
    CJPayPasswordSetFirstStepViewController *setPassViewController = (CJPayPasswordSetFirstStepViewController *)vc;
    
    setPassViewController.setModel = model;
    setPassViewController.completion = ^(NSString * _Nullable token, BOOL isSuccess, BOOL isExit) {
        @CJStrongify(self)
        if (isSuccess) {
            [self closeBindCardProcessWithResult:YES token:token completionBlock:^{}];
            return;
        }
        
        // exit: 主动退出设密流程
        if (isExit) {
            [self closeBindCardProcessWithResult:NO token:@"" completionBlock:^{}];
        }
    };
}

- (void)closeBindCardProcessWithResult:(BOOL)isSuccess token:(NSString *)token
                       completionBlock:(void(^)(void))completionBlock {
    CJPayBindCardResultModel *resultModel = [CJPayBindCardResultModel new];
    resultModel.result = isSuccess ? CJPayBindCardResultSuccess : CJPayBindCardResultFail;
    resultModel.token = token;
    resultModel.memberBizOrderNo = self.viewModel.signOrderNo;
    if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
        resultModel.isSyncUnionCard = YES;
    }
    
    [[CJPayBindCardManager sharedInstance] finishBindCard:resultModel completionBlock:completionBlock];
}

- (void)back {
    [self p_trackWithEventName:@"wallet_ysf_bcard_click" params:@{@"button_name" : @"0"}];
    [self p_trackWithEventName:@"wallet_page_back_click"
                        params:@{@"page_name": @"wallet_ysf_bcard_list_page"}];
    
    __block BOOL shouldReturn = NO;
    @CJWeakify(self)
    [self.navigationController.viewControllers enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        @CJStrongify(self)
        if ([obj isKindOfClass:NSClassFromString(@"CJPayBindCardBaseViewController")]) {
            [self.navigationController popToViewController:obj animated:YES];
            *stop = YES;
            shouldReturn = YES;
        }
    }];
    
    if (shouldReturn) {
        return;
    }
    
    if (![[CJPayBindCardManager sharedInstance] cancelBindCard]) {
        [super back];
    }
}

- (void)p_sendSMS {
    @CJWeakify(self);
    [self.chooseView.confirmButton startLoading];
    [self.viewModel sendSMSWithCompletion:^(NSError * _Nonnull error, CJPaySendSMSResponse * _Nonnull response) {
        @CJStrongify(self);
        [self.chooseView.confirmButton stopLoading];
        [self p_trackWithEventName:@"wallet_ysf_bcard_click"
                            params:@{
                                @"button_name" : @"1",
                                @"result" : [response isSuccess] ? @"1" : @"0",
                                @"error_code" : CJString(response.code),
                                @"error_message" : CJString(response.msg)
        }];
        
        if (error) {
            [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
            return;
        }
        
        if ([response isSuccess]) {
            [self p_verifySMS:response];
            
        } else if (response.buttonInfo) {
            CJPayButtonInfoHandlerActionsModel *actionModels = [self p_buttonInfoActions:response];
            [[CJPayBDButtonInfoHandler shareInstance] handleButtonInfo:response.buttonInfo fromVC:self
                                                            errorMsg:response.buttonInfo.page_desc ?: CJString(response.msg)
                                                         withActions:actionModels
                                                           withAppID:self.viewModel.appId
                                                          merchantID:self.viewModel.merchantId];
        } else {
            // 单button alert
            [self p_showSingleButtonAlertWithResponse:response];
        }
    }];
}

- (void)p_showSingleButtonAlertWithResponse:(CJPaySendSMSResponse *)response {
    if (!Check_ValidString(response.msg)) {
        [CJToast toastText:CJPayNoNetworkMessage inWindow:self.cj_window];
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [CJPayAlertUtil customSingleAlertWithTitle:response.msg
                                           content:CJString(response.code)
                                        buttonDesc:CJPayLocalizedStr(@"知道了")
                                       actionBlock:nil
                                             useVC:self];
    });
}

- (CJPayButtonInfoHandlerActionsModel *)p_buttonInfoActions:(CJPaySendSMSResponse *)response {
    CJPayButtonInfoHandlerActionsModel *actionModel = [CJPayButtonInfoHandlerActionsModel new];
    @CJWeakify(self)
    actionModel.errorInPageAction = ^(NSString * _Nonnull errorText) {
        @CJStrongify(self);
        [CJToast toastText:errorText inWindow:self.cj_window];
    };
    
    return actionModel;
}

- (void)p_verifySMS:(CJPaySendSMSResponse *)response {
    [self.view endEditing:YES];
    [self.viewModel verifySMSViewControllerWithResponse:response];
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    CGFloat offsetY = scrollView.contentOffset.y;
    
    CGRect frame = self.chooseView.headerView.titleLabel.frame;
    CGFloat labelY = frame.origin.y + frame.size.height;
    
    [UIView animateWithDuration:0.1 animations:^{
        self.navigationBar.titleLabel.alpha = labelY - offsetY > 0 ?  0 : 1;
    }];
}

#pragma mark - UITableViewDataSource & UITableViewDelegate
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    // cell 并未复用, 后续考虑优化
    CJPayUnionBindCardChooseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(CJPayUnionBindCardChooseTableViewCell.class)];
    if (cell == nil) {
        cell = [[CJPayUnionBindCardChooseTableViewCell alloc] init];
    }
    if (indexPath.row >= 0 && indexPath.row < self.viewModel.cardListResponse.cardList.count) {
        CJPayUnionCardInfoModel *cardInfoModel = [self.viewModel.cardListResponse.cardList cj_objectAtIndex:indexPath.row];
        [cell updateWithUnionCardInfoModel:cardInfoModel];
        if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
            cell.isSelected = [self.viewModel.selectedCards containsObject:cardInfoModel.bankCardId];
        } else {
            cell.isSelected = [cardInfoModel.cardNoMask isEqualToString:self.viewModel.selectedUnionCardInfoModel.cardNoMask];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row >= 0 && indexPath.row < self.viewModel.cardListResponse.cardList.count) {
        CJPayUnionCardInfoModel *cardInfoModel = [self.viewModel.cardListResponse.cardList cj_objectAtIndex:indexPath.row];
        [self p_cellClickTracker:cardInfoModel];
        if ([cardInfoModel.status isEqualToString:@"0"]) {
            return;
        }
        if (self.viewModel.bindUnionCardType == CJPayBindUnionCardTypeSyncBind) {
            if ([self.viewModel.selectedCards containsObject:cardInfoModel.bankCardId]) {
                [self.viewModel.selectedCards removeObject:cardInfoModel.bankCardId];
            } else {
                [self.viewModel.selectedCards addObject:cardInfoModel.bankCardId];
            }
            self.chooseView.confirmButton.enabled = self.viewModel.selectedCards.count > 0;
        } else {
            self.viewModel.selectedUnionCardInfoModel = cardInfoModel;
        }
        [self.chooseView reloadWithViewModel:self.viewModel];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 76;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.viewModel.cardListResponse.cardList.count;
}

#pragma mark - protocol
- (void)createAssociatedModelWithParams:(NSDictionary<NSString *,id> *)dict {
    if (dict.count > 0) {
        NSError *error;
        self.viewModel = [[CJPayUnionBindCardChooseViewModel alloc] initWithDictionary:dict error:&error];
        if (error) {
        } else {
            if (self.viewModel.cardListResponse.cardList.count > 0) {
                self.viewModel.selectedUnionCardInfoModel = self.viewModel.cardListResponse.cardList.firstObject;
            }
        }
    }
}

+ (Class)associatedModelClass {
    return [CJPayUnionBindCardChooseViewModel class];
}

#pragma mark - lazy View

- (CJPayUnionBindCardChooseViewModel *)viewModel {
    if (!_viewModel) {
        _viewModel = [CJPayUnionBindCardChooseViewModel new];
        _viewModel.selectedUnionCardInfoModel = _viewModel.cardListResponse.cardList.firstObject;
    }
    return _viewModel;
}

- (CJPayUnionBindCardChooseView *)chooseView {
    if (!_chooseView) {
        _chooseView = [[CJPayUnionBindCardChooseView alloc] initWithViewModel:self.viewModel];
        _chooseView.tableView.delegate = self;
        _chooseView.tableView.dataSource = self;
        _chooseView.scrollView.delegate = self;
        @CJWeakify(self)
        _chooseView.protocolClickBlock = ^{
            @CJStrongify(self)
            [self p_trackWithEventName:@"wallet_ysf_bcard_click" params:@{@"button_name" : @"2"}];
        };
    }
    return _chooseView;
}

#pragma mark - tracker
    
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [[[CJPayBindCardManager sharedInstance] bindCardTrackerBaseParams] mutableCopy];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

- (NSString *)p_ysfBankList {
    NSString *list = @"";
    if([[self.viewModel.cardListResponse.cardList valueForKey:@"bankName"] isKindOfClass:[NSArray class]]) {
        list = [((NSArray *)[self.viewModel.cardListResponse.cardList valueForKey:@"bankName"]) componentsJoinedByString:@","];
    }
    return list;
}

- (NSString *)p_selectCardList {
    NSMutableString *cardList = [NSMutableString new];
    [self.viewModel.cardListResponse.cardList enumerateObjectsUsingBlock:^(CJPayUnionCardInfoModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([self.viewModel.selectedCards containsObject:obj.bankCardId]) {
            [cardList appendString:CJString(obj.bankName)];
            [cardList appendString:@","];
        }
    }];
    
    if (cardList.length > 1) {
        [cardList deleteCharactersInRange:NSMakeRange(cardList.length - 1, 1)];
    }
    
    return [cardList copy];
}

- (void)p_cellClickTracker:(CJPayUnionCardInfoModel *)cardInfoModel {
    NSMutableDictionary *cardTypeNameDic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"DEBIT" : @"储蓄卡",
        @"CREDIT" : @"信用卡",
        @"ALL" : @"储蓄卡、信用卡"
    }];
    [self p_trackWithEventName:@"wallet_ysf_bcard_list_click"
                        params:@{@"bank_name" : CJString(cardInfoModel.bankName),
                                 @"bank_type" : CJString([cardTypeNameDic cj_stringValueForKey:CJString(cardInfoModel.cardType)])}];
}

@end
