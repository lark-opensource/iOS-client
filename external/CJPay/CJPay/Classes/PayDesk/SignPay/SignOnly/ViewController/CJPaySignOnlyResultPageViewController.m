//
//  CJPaySignOnlyResultPageViewController.m
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPaySignOnlyResultPageViewController.h"

#import "CJPayResultDetailItemView.h"
#import "CJPayResultPageView.h"
#import "CJPayHalfPageBaseViewController+Biz.h"
#import "CJPayUIMacro.h"

@interface CJPaySignOnlyResultPageViewController ()<CJPayResultPageViewDelegate>

@property (nonatomic, strong) CJPayResultPageView *resultView;
@property (nonatomic, assign) CJPayStateType stateType;
@property (nonatomic, strong) CJPayResultDetailItemView *successDescView;
@property (nonatomic, strong) UILabel *failDescLabel;

@end

@implementation CJPaySignOnlyResultPageViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_setupUI];
    [self p_update];
    [self p_trackEvent:@"wallet_cashier_pay_finish_page_imp" params:@{
        @"cashier_style" : @"2",
        @"result" : CJString(self.result.signStatus),
        @"error_message" : CJString(self.result.signFailReason)
    }];
    [self closeActionAfterTime:(int)self.result.remainTime];
}


- (void)closeActionAfterTime:(NSInteger)time {
    if (time < 0) { // 小于0的话，不关闭结果页，让用户手动关闭
        return;
    }
    @CJWeakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(time * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @CJStrongify(self);
        // 当APP处于前台且签约结果页为topVC时，才自动结束签约流程
        if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive && [UIViewController cj_topViewController] == self) {
            [self back];
        }
    });
}


- (void)p_setupNaviBar {
    if (self.isFromOuterApp) {
        // 端外结果页，导航栏不展示返回按钮
        self.navigationBar.backBtn.hidden = YES;
    } else {
        [self useCloseBackBtn];
    }
    self.navigationBar.title = @"";
    [self.navigationBar setTitleImage:@"cj_nav_title_image_icon"];
}

- (void)p_update {
    self.stateView.isPaymentForOuterApp = self.isFromOuterApp;
    if (self.isFromOuterApp) {
        [self.resultView setResultPageType:CJPayResultPageTypeOuterPay];
    }
    self.stateType = [self p_stateTypeWithSignStatus:self.result.signStatus];
    [self p_setStateWithType:self.stateType];
    [self showState:self.stateType];
    if (self.stateType == CJPayStateTypeSuccess) {
        self.successDescView.hidden = NO;
        self.failDescLabel.hidden = YES;
        [self.successDescView updateWithTitle:CJPayLocalizedStr(@"开通服务") detail:CJString(self.result.serviceName)];
    } else {
        self.successDescView.hidden = YES;
        self.failDescLabel.hidden = NO;
        self.failDescLabel.text = self.result.signFailReason;
    }
}

- (void)p_setupUI {
    [self p_setupNaviBar];
    [self.contentView addSubview:self.resultView];
    [self.contentView addSubview:self.successDescView];
    [self.contentView addSubview:self.failDescLabel];
    
    CJPayMasMaker(self.successDescView, {
        make.top.equalTo(self.stateView.mas_bottom).offset(20);
        make.left.right.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.failDescLabel, {
        make.top.equalTo(self.stateView.mas_bottom).offset(8);
        make.left.right.equalTo(self.contentView);
    });
    
    CJPayMasMaker(self.resultView, {
        make.top.equalTo(self.stateView.mas_bottom);
        make.left.right.bottom.equalTo(self.contentView);
    });
}

- (CJPayStateType)p_stateTypeWithSignStatus:(NSString *)signStatus {
    if ([signStatus isEqualToString:@"SUCCESS"]) {
        return CJPayStateTypeSuccess;
    }
    if ([signStatus isEqualToString:@"FAIL"]) {
        return CJPayStateTypeFailure;
    }
    if ([signStatus isEqualToString:@"PROCESSING"]) {
        return CJPayStateTypeWaiting;
    }
    CJPayLogError(@"签约结果异常%@", CJString(signStatus));
    return CJPayStateTypeWaiting;
}

- (NSString *)p_descTitleWithOrderStatus:(CJPayOrderStatus)orderStatus {
    switch (orderStatus) {
        case CJPayOrderStatusSuccess:
            return CJPayLocalizedStr(@"开通成功");
            break;
        case CJPayOrderStatusProcess:
            return CJPayLocalizedStr(@"开通中");
            break;
        case CJPayOrderStatusFail:
            return CJPayLocalizedStr(@"开通失败");
            break;
        default:
            return CJPayLocalizedStr(@"开通中");
            break;
    }
}

- (NSString *)p_iconWithStatus:(CJPayStateType)orderStatus {
    switch (orderStatus) {
        case CJPayStateTypeSuccess:
            return @"cj_new_finish_gif";
            break;
        case CJPayStateTypeWaiting:
            return @"cj_new_pay_processing_icon";
            break;
        case CJPayStateTypeFailure:
            return @"cj_sorry_icon";
            break;
        default:
            return @"cj_new_pay_processing_icon";
            break;
    }
}

- (void)p_setStateWithType:(CJPayStateType)orderStatus {
    NSString *contentTitle = CJString(self.result.signStatusDesc); // [self p_descTitleWithOrderStatus:orderStatus];
    CJPayStateShowModel *showModel = [CJPayStateShowModel new];
    showModel.titleAttributedStr = [CJPayStateView updateTitleWithContent:contentTitle];
    showModel.iconName = [self p_iconWithStatus:orderStatus];
    showModel.iconBackgroundColor = [UIColor clearColor];
    [self.stateView updateShowConfigsWithType:self.stateType model:showModel];
}

- (void)p_trackEvent:(NSString *)eventName params:(NSDictionary *)params {
    [CJTracker event:eventName params:params];
}

#pragma mark - CJPayResultPageViewDelegate
- (void)stateButtonClick:(NSString *)buttonName {
    [super back];
}

- (UILabel *)failDescLabel {
    if (!_failDescLabel) {
        _failDescLabel = [UILabel new];
        _failDescLabel.font = [UIFont cj_fontOfSize:14];
        _failDescLabel.textColor = [UIColor cj_161823WithAlpha:0.75];
        _failDescLabel.hidden = YES;
        _failDescLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _failDescLabel;
}

- (CJPayResultDetailItemView *)successDescView {
    if (!_successDescView) {
        _successDescView = [CJPayResultDetailItemView new];
        _successDescView.hidden = YES;
    }
    return _successDescView;
}

- (CJPayResultPageView *)resultView {
    if (!_resultView) {
        _resultView = [CJPayResultPageView new];
        _resultView.delegate = self;
    }
    return _resultView;
}

@end
