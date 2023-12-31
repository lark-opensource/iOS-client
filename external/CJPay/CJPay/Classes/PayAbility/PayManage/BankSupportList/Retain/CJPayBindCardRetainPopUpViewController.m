//
//  CJPayBindCardRetainPopUpViewController.m
//  Pods
//
//  Created by youerwei on 2021/9/6.
//

#import "CJPayBindCardRetainPopUpViewController.h"
#import "CJPayStyleButton.h"
#import "CJPayUIMacro.h"
#import "UITapGestureRecognizer+CJPay.h"
#import "CJPayWebViewUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBindCardRetainInfo.h"
#import "CJPayStyleCheckBox.h"
#import "CJPayBaseRequest.h"
#import "CJPayWebViewService.h"
#import "CJPayLineUtil.h"

@interface CJPayBindCardRetainPopUpViewController ()

@property (nonatomic, strong) CJPayButton *closeButton;
@property (nonatomic, strong) UIView *retainContentView;
@property (nonatomic, strong) CJPayStyleButton *confirmButton;

@property (nonatomic, copy) NSString *activityTitle;
@property (nonatomic, copy) NSString *securityDetail;
@property (nonatomic, strong) CJPayBindCardRetainInfo *retainInfo;

@property (nonatomic, strong) UILabel *titleLabel;

@end

@implementation CJPayBindCardRetainPopUpViewController

- (instancetype)initWithRetainInfo:(CJPayBindCardRetainInfo *)retainInfo
{
    self = [super init];
    if (self) {
        _retainInfo = retainInfo;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_trackPopUpWithEvent:@"wallet_addbcard_keep_pop_show" params:@{
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    self.view.hidden = NO;
    [super viewDidAppear:animated];
}

- (void)setupUI {
    [super setupUI];
    self.containerView.layer.cornerRadius = 12;
    CJPayMasReMaker(self.containerView, {
        make.left.equalTo(self.view).offset(48);
        make.right.equalTo(self.view).offset(-48);
        make.center.equalTo(self.view);
    });
    
    [self.containerView addSubview:self.retainContentView];
    CJPayMasMaker(self.retainContentView, {
        make.centerX.equalTo(self.containerView);
        make.left.right.equalTo(self.containerView);
    });
    [self p_setupUIForCommonWithButtonMsg:self.retainInfo.buttonMsg];
}

- (void)p_setupUIForCommonWithButtonMsg:(NSString *)buttonMsg {
    [self.containerView addSubview:self.confirmButton];
    [self.containerView addSubview:self.closeButton];
    
    CJPayMasMaker(self.closeButton, {
        make.width.height.mas_equalTo(20);
        make.top.equalTo(self.containerView).offset(16);
        make.left.equalTo(self.containerView).offset(16);
    });
    
    CJPayMasMaker(self.confirmButton, {
        make.top.equalTo(self.retainContentView.mas_bottom);
        make.left.equalTo(self.containerView).offset(20);
        make.right.equalTo(self.containerView).offset(-20);
        make.height.mas_equalTo(44);
    });
    
    //单button样式
    CJPayMasMaker(self.retainContentView, {
        make.top.equalTo(self.containerView);
    });
    CJPayMasMaker(self.confirmButton, {
        make.bottom.equalTo(self.containerView).offset(-20);
    });
    if (Check_ValidString(buttonMsg)) {
        [self.confirmButton cj_setBtnTitle:CJString(buttonMsg)];
    }
}

- (void)closeTapped {
    [self p_trackPopUpWithEvent:@"wallet_addbcard_keep_pop_click" params:@{
        @"button_name": @"关闭"
    }];
    [self dismissSelfWithCompletionBlock:self.retainInfo.cancelBlock];
}

- (void)confirmTapped {
    [self p_trackPopUpWithEvent:@"wallet_addbcard_keep_pop_click" params:@{
        @"button_name": CJString(self.confirmButton.titleLabel.text)
    }];
    [self dismissSelfWithCompletionBlock:self.retainInfo.continueBlock];
}

- (void)p_trackPopUpWithEvent:(NSString *)event params:(nullable NSDictionary *)params {
    NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:@{
        @"activity_title": CJString(self.retainInfo.title),
    }];
    
    if (params) {
        [dic addEntriesFromDictionary:params];
    }
    [self p_trackWithEvent:event params:dic];
}

- (void)p_trackWithEvent:(NSString *)event params:(nullable NSDictionary *)params {
    if (self.retainInfo.trackDelegate && [self.retainInfo.trackDelegate respondsToSelector:@selector(event:params:)]) {
        [self.retainInfo.trackDelegate event:event params:params];
    }
}

- (CJPayButton *)closeButton {
    if (!_closeButton) {
        _closeButton = [CJPayButton new];
        [_closeButton cj_setImageName:@"cj_close_denoise_icon" forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (CJPayStyleButton *)confirmButton {
    if (!_confirmButton) {
        _confirmButton = [CJPayStyleButton new];
        _confirmButton.titleLabel.font = [UIFont cj_boldFontOfSize:15];
        _confirmButton.titleLabel.textColor = [UIColor whiteColor];
        [_confirmButton cj_setBtnBGColor:[UIColor cj_fe2c55ff]];
        [_confirmButton setTitle:CJPayLocalizedStr(@"查看支持银行列表") forState:UIControlStateNormal];
        [_confirmButton addTarget:self action:@selector(confirmTapped) forControlEvents:UIControlEventTouchUpInside];
    }
    return _confirmButton;
}

- (UIView *)retainContentView {
    if (!_retainContentView) {
        _retainContentView = [_retainInfo generateRetainView];
    }
    return _retainContentView;
}

@end
