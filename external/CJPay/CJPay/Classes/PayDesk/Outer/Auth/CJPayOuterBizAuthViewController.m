//
//  CJPayOuterBizAuthViewController.m
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//
#import "CJPayErrorButtonInfo.h"
#import "CJPayOuterBizAuthViewController.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayProtocolDetailViewController.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "CJPayQueryBindBytepayRequest.h"
#import "CJPayQueryBindBytepayResponse.h"
#import "CJPayWebViewUtil.h"
#import "CJPayQueryBindAuthorizeInfoResponse.h"
#import "CJPayBDButtonInfoHandler.h"
#import "CJPayRequestParam.h"
#import "CJPayAlertUtil.h"
#import "CJPayCommonUtil.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayDeskUtil.h"
#import "CJPayBizWebViewController.h"

@interface CJPayOuterBizAuthViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;
@property (nonatomic, strong) CJPayCommonProtocolModel *protocolModel;
@property (nonatomic, strong) CJPayQueryBindAuthorizeInfoResponse *queryBindResponse;

@end

@implementation CJPayOuterBizAuthViewController

- (instancetype)initWithResponse:(CJPayQueryBindAuthorizeInfoResponse *)response {
    self = [super init];
    if (self) {
        _protocolModel = [CJPayCommonProtocolModel new];
        _protocolModel.selectPattern = CJPaySelectButtonPatternCheckBox;
        _protocolModel.supportRiskControl = NO;
        _protocolModel.protocolFont = [UIFont cj_fontOfSize:14];
        _protocolModel.protocolTextAlignment = NSTextAlignmentLeft;
        _protocolModel.guideDesc = response.protocolModel.guideMessage;
        _protocolModel.tailText = response.protocolModel.tailGuideMessage;
        _protocolModel.agreements = [response.protocolModel.agreements copy];
        _protocolModel.protocolCheckBoxStr = response.protocolModel.protocolCheckBox;
        _protocolModel.groupNameDic = response.protocolModel.protocolGroupNames;
        _queryBindResponse = response;
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    [self p_trackWithEventName:@"wallet_tixian_businesstopay_auth_show" params:@{}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
}

- (void)setupUI {
    self.containerView.layer.cornerRadius = 12;
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.protocolView];
    [self.protocolView updateWithCommonModel:self.protocolModel];
    [self.containerView addSubview:self.confirmButton];

    self.titleLabel.text = CJString(self.queryBindResponse.authBriefModel.displayDesc);
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.containerView.mas_top).offset(50);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.height.mas_equalTo(24);
    });

    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.titleLabel.mas_bottom).offset(8);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.protocolView.mas_bottom).offset(24);
        make.left.equalTo(self.containerView).offset(16);
        make.right.equalTo(self.containerView).offset(-16);
        make.height.mas_equalTo(44);
    })
}

#pragma mark - private func

- (CGFloat)containerHeight {
    return CJ_IPhoneX ? 230 + 34 : 230;
}

- (void)p_startRequest{
    NSDictionary *bizParams = @{
        @"bind_content" : CJString(self.bindContent),
    };
    @CJWeakify(self)
    @CJStartLoading(self.confirmButton)
    [CJPayQueryBindBytepayRequest startWithAppId:[CJPayRequestParam gAppInfoConfig].appId bizParam:bizParams completion:^(NSError * _Nonnull error, CJPayQueryBindBytepayResponse * _Nonnull response) {
        @CJStrongify(self)
        @CJStopLoading(self.confirmButton)
        if (![response isSuccess]) {
            [self p_trackWithEventName:@"wallet_tixian_businesstopay_auth_result" params:@{
                @"result": @(0), @"error_code": CJString(response.code), @"error_message" : CJString(response.msg)}];
            if (response.buttonInfo) {
                [CJPayAlertUtil customSingleAlertWithTitle:CJString(response.buttonInfo.mainTitle)
                                                   content:CJString(response.buttonInfo.page_desc)
                                                buttonDesc:CJPayLocalizedStr(@"我知道了")
                                               actionBlock:^{
                                            @CJStrongify(self)
                                            CJ_CALL_BLOCK(self.cancelBlock, CJPayDypayResultTypeFailed);
                } useVC:self];
            } else {
                // alert
                [CJToast toastText:CJPayLocalizedStr( Check_ValidString(response.msg)?response.msg:@"系统繁忙，请稍后重试") inWindow:self.cj_window];
            }
        } else {
            if ( !response.isComplete && Check_ValidString(response.redirectURL)) {
                
                [self p_trackWithEventName:@"wallet_tixian_businesstopay_auth_result" params:@{
                    @"result": @(1)}];
                if (response.isLnyxURL) {
                    [CJPayDeskUtil openLynxPageBySchema:response.redirectURL completionBlock:^(CJPayAPIBaseResponse * _Nonnull response) {
                        @CJStrongify(self)
                        CJPayLogInfo(@"outer biz auth lynx return msg");
                        NSDictionary *dic = response.data;
                        /**
                         code == 0,     lynx/h5 成功，回到头条并给成功结果
                         code == -1,     lynx/h5 失败，回到头条并给失败结果
                         code == 其他值，lynx/h5 取消，停留在半屏页
                         */
                        if (dic && [dic isKindOfClass:NSDictionary.class]) {
                            CJPayLogInfo(@"outer biz auth lynx return msg:%@", dic);
                            NSString *service = [dic cj_stringValueForKey:@"service"];
                            if (![service isEqualToString:@"98"] || !self) {
                                return;
                            }
                            
                            NSDictionary *dataDic = [dic cj_dictionaryValueForKey:@"data"];
                            if (![dataDic isKindOfClass:NSDictionary.class]) {
                                return;
                            }
                            
                            NSDictionary *msgDic = [dataDic cj_dictionaryValueForKey:@"msg"];
                            if (![msgDic isKindOfClass:NSDictionary.class]) {
                                return;
                            }
                            
                            int code = [msgDic cj_intValueForKey:@"code" defaultValue:1];
                            if (code == 0) {
                                CJ_CALL_BLOCK(self.confirmBlock);
                            } else if (code == -1) {
                                CJ_CALL_BLOCK(self.cancelBlock, CJPayDypayResultTypeCancel);
                            } else {
                                // do nothing
                            }
                        }
                    }];
                    return;
                }
                
                // h5
                NSMutableDictionary *params = [NSMutableDictionary dictionary];
                [params cj_setObject:@"03014210" forKey:@"service"];
                [params cj_setObject:@"sdk" forKey:@"source"];
                CJPayBizWebViewController *webvc = [[CJPayWebViewUtil sharedUtil] buildWebViewControllerWithUrl:response.redirectURL fromVC:self params:params nativeStyleParams:@{} closeCallBack:^(id  _Nonnull data) {
                    @CJStrongify(self)
                    NSDictionary *dic = nil;
                    if ([data isKindOfClass:NSDictionary.class]) {
                        dic = (NSDictionary *)data;
                    }
                    /**
                     code == 0,     lynx/h5 成功，回到头条并给成功结果
                     code == -1,     lynx/h5 失败，回到头条并给失败结果
                     code == 其他值，lynx/h5 取消，停留在半屏页
                     */
                    CJPayLogInfo(@"outer biz auth h5 return msg");
                    if (dic && [dic isKindOfClass:NSDictionary.class]) {
                        CJPayLogInfo(@"outer biz auth h5 return msg:%@", dic);
                        NSString *service = [dic cj_stringValueForKey:@"service"];
                        if (![service isEqualToString:@"99"] || !self) {
                            return;
                        }
                        
                        NSDictionary *dataDic = [dic cj_dictionaryValueForKey:@"data"];
                        if (![dataDic isKindOfClass:NSDictionary.class]) {
                            return;
                        }
                        
                        int code = [dataDic cj_intValueForKey:@"code" defaultValue:1];
                        if (code == 0) {
                            CJ_CALL_BLOCK(self.confirmBlock);
                        } else if (code == -1) {
                            CJ_CALL_BLOCK(self.cancelBlock, CJPayDypayResultTypeCancel);
                        } else {
                            // do nothing
                        }
                    }
                }];
                [self.navigationController pushViewController:webvc animated:YES];
            } else if ( response.isComplete ) {
                [self p_trackWithEventName:@"wallet_tixian_businesstopay_auth_result" params:@{
                    @"result": @(1), @"error_code": CJString(response.code), @"error_message" : CJString(response.msg)}];
                // return to source app
                CJ_CALL_BLOCK(self.confirmBlock);
            } else {
            }
        }
    }];
}

#pragma mark - click event

- (void)p_confirmButtonClick {
    [self p_trackWithEventName:@"wallet_tixian_businesstopay_auth_click" params:@{
        @"button_name":CJString(self.confirmButton.titleLabel.text)}];
    @CJWeakify(self);
    
    [self.protocolView executeWhenProtocolSelected:^{
        [self p_startRequest];
        } notSeleted:^{
            @CJStrongify(self)
            if (self.protocolModel.agreements.count) {
                CJPayProtocolPopUpViewController *popupProtocolVC = [[CJPayProtocolPopUpViewController alloc] initWithProtocolModel:self.protocolModel from:@"唤端绑卡授权页"];
                popupProtocolVC.confirmBlock = ^{
                    @CJStrongify(self)
                    [self.protocolView setCheckBoxSelected:YES];
                    
                    [self p_startRequest];
                };
                [self.navigationController pushViewController:popupProtocolVC animated:YES];
            }
        } hasToast:NO];
}

- (void)close {
    [self p_trackWithEventName:@"wallet_tixian_businesstopay_auth_click" params:@{
        @"button_name": @"关闭"}];
    CJ_CALL_BLOCK(self.cancelBlock, CJPayDypayResultTypeFailed);
}

#pragma mark - getter
- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentLeft;
        _titleLabel.numberOfLines = 0;
    }
    return _titleLabel;
}

- (CJPayCommonProtocolView *)protocolView {
    if(!_protocolView) {
        _protocolView = [[CJPayCommonProtocolView alloc] initWithCommonProtocolModel:[CJPayCommonProtocolModel new]];
    }
    return _protocolView;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"同意协议并继续")];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        [_confirmButton setTitleColor:[UIColor cj_ffffffWithAlpha:1.0] forState:UIControlStateNormal];
        _confirmButton.layer.cornerRadius = 5;
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.cjEventInterval = 2;
        [_confirmButton addTarget:self action:@selector(p_confirmButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

#pragma mark - tracker
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [NSMutableDictionary new];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

@end
