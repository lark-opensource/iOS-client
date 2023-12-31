//
//  CJPayProtocolPopUpViewController.m
//  Pods
//  同意协议弹窗
//  Created by 徐天喜 on 2022/8/02.
//
#import "CJPayErrorButtonInfo.h"
#import "CJPayProtocolPopUpViewController.h"
#import "CJPayCommonProtocolView.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonProtocolModel.h"
#import "CJPayThemeStyleManager.h"
#import "CJPayProtocolListViewController.h"
#import "CJPayProtocolDetailViewController.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "CJPayWebViewUtil.h"

@interface CJPayProtocolPopUpViewController ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) CJPayCommonProtocolView *protocolView;
@property (nonatomic, strong) CJPayButton *confirmButton;
@property (nonatomic, strong) CJPayButton *cancelButton;
@property (nonatomic, strong) CJPayCommonProtocolModel *protocolModel;
@property (nonatomic, copy) NSString *fromPage;
@end

@implementation CJPayProtocolPopUpViewController

- (instancetype)initWithProtocolModel:(CJPayCommonProtocolModel *)model from:(NSString *)fromPage {
    self = [super init];
    if (self) {
        model.selectPattern = CJPaySelectButtonPatternNone;
        model.supportRiskControl = NO;
        model.protocolFont = [UIFont cj_fontOfSize:14];
        model.protocolTextAlignment = NSTextAlignmentCenter;
        model.tailText = CJPayLocalizedStr(@"抖音支付将严格保护你的个人信息安全");
        _protocolModel = model;
        _fromPage = fromPage;
    }
    
    return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self p_trackWithEventName:@"wallet_addbcard_pay_agreement_pop_show" params:@{}];
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 12;
    [self.containerView addSubview:self.titleLabel];
    [self.containerView addSubview:self.protocolView];
    [self p_updateProtocolContent];
    [self p_updateProtocolClickPageStyle];
    [self.protocolView updateWithCommonModel:self.protocolModel];
    [self.containerView addSubview:self.confirmButton];
    [self.containerView addSubview:self.cancelButton];
    
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.centerY.equalTo(self.view);
    });
    
    CJPayMasMaker(self.titleLabel, {
        make.top.equalTo(self.containerView.mas_top).offset(24);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(24);
    });

    CJPayMasMaker(self.protocolView, {
        make.top.equalTo(self.containerView.mas_top).offset(56);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.protocolView.mas_bottom).offset(24);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(44);
    })
    
    CJPayMasMaker(self.cancelButton, {
        make.top.equalTo(self.confirmButton.mas_bottom).offset(13);
        make.left.equalTo(self.containerView).offset(32);
        make.right.equalTo(self.containerView).offset(-32);
        make.height.mas_equalTo(18);
        make.bottom.equalTo(self.containerView.mas_bottom).offset(-13);
    })
}

#pragma mark - private func

- (void)p_updateProtocolContent {
    [self.protocolModel.groupNameDic.allValues enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (idx == 0) {
            // 取第一个协议更新标题
            self.titleLabel.text = CJString(obj);
        }
    }];
}

- (void)p_updateProtocolClickPageStyle {
    if (!self.showFullPageProtocolView) {
        return;
    }
    self.protocolView.protocolClickHandleInBlockOnly = YES;
    @CJWeakify(self)
    self.protocolView.protocolClickBlock = ^(NSArray<CJPayMemAgreementModel *> * _Nonnull agreements) {
        @CJStrongify(self)
        CJPayMemAgreementModel *model = agreements.firstObject;
        [[CJPayWebViewUtil sharedUtil] gotoWebViewControllerFrom:self
                                                           toUrl:CJString((model.url))
                                                          params:@{}
                                               nativeStyleParams:@{@"title": model.name}];
    };
}
#pragma mark - click event

- (void)p_confirmButtonClick {
    [self p_trackWithEventName:@"wallet_addbcard_pay_agreement_pop_click" params:@{
        @"button_name":CJString(self.confirmButton.titleLabel.text)}];
    @CJWeakify(self)
    [self dismissSelfWithCompletionBlock:^{
        @CJStrongify(self)
        CJ_CALL_BLOCK(self.confirmBlock);
    }];
}

- (void)p_cancel {
    [self p_trackWithEventName:@"wallet_addbcard_pay_agreement_pop_click" params:@{
        @"button_name":CJString(self.cancelButton.titleLabel.text)}];
    [self dismissSelfWithCompletionBlock:nil];
}

#pragma mark - getter

- (UILabel *)titleLabel {
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.textColor = [UIColor cj_161823ff];
        _titleLabel.font = [UIFont cj_boldFontOfSize:17];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
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

- (CJPayButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [[CJPayStyleButton alloc] init];
        [_confirmButton cj_setBtnTitle:CJPayLocalizedStr(@"同意协议并继续")];
        [_confirmButton setTitleColor:[UIColor cj_ffffffWithAlpha:1.0] forState:UIControlStateNormal];
        _confirmButton.layer.cornerRadius = 5;
        _confirmButton.layer.masksToBounds = YES;
        _confirmButton.cjEventInterval = 2;
        [_confirmButton addTarget:self action:@selector(p_confirmButtonClick) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (CJPayButton *)cancelButton {
    if (!_cancelButton) {
        _cancelButton = [CJPayButton new];
        [_cancelButton cj_setBtnTitle:CJPayLocalizedStr(@"不同意")];
        [_cancelButton cj_setBtnTitleColor:[UIColor cj_161823WithAlpha:0.6]];
        [_cancelButton addTarget:self action:@selector(p_cancel) forControlEvents:UIControlEventTouchUpInside];
        _cancelButton.titleLabel.font = [UIFont cj_boldFontOfSize:13];
        _cancelButton.cjEventInterval = 1;
    }
    return _cancelButton;
}

#pragma mark - tracker
- (void)p_trackWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    NSMutableDictionary *baseParams = [NSMutableDictionary new];
    [baseParams addEntriesFromDictionary:@{
        @"pay_agreement_source" : CJString(self.fromPage)
    }];
    [baseParams addEntriesFromDictionary:params];
    
    [CJTracker event:eventName params:[baseParams copy]];
}

@end
