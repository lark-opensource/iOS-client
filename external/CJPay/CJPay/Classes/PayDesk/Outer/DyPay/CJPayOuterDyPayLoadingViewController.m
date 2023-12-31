//
//  CJPayOuterDyPayLoadingViewController.m
//  Aweme
//
//  Created by bytedance on 2022/10/11.
//

#import "CJPayOuterDyPayLoadingViewController.h"
#import "CJPayCreateOrderByTokenRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayHomePageViewController.h"
#import "CJPayOPHomePageViewController.h"
#import "CJPaySubPayTypeSumInfoModel.h"
#import "CJPayDYPayBizDeskModel.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayCommonTrackUtil.h"
#import "CJPayRequestParam.h"
#import "CJPayDeskServiceHeader.h"
#import "CJPayDyPayModule.h"
#import "CJPayKVContext.h"

@interface CJPayOuterDyPayLoadingViewController ()<CJPayAPIDelegate>

@property (nonatomic, strong) CJPayCreateOrderResponse *orderResponse; // 埋点用
@property (nonatomic, assign) BOOL isColdLaunch; // 是否为冷启动进入支付
@property (nonatomic, assign) double lastTimestamp; // 上一次上报 event 的时间戳
@property (nonatomic, strong) CJPayHomePageViewController *homePageVC;
@property (nonatomic, assign) BOOL isVerifyPageFirstDidAppear; //

@end

@implementation CJPayOuterDyPayLoadingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.isVerifyPageFirstDidAppear = YES;
    // Do any additional setup after loading the view.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_verifyPageDidChangedHeight:) name:CJPayVerifyPageDidChangedHeightNotification object:nil];
}

- (void)didFinishParamsCheck:(BOOL)isSuccess {
    if (!isSuccess) {
        return;
    }
    [self p_openCashDesk];
}

- (void)p_verifyPageDidChangedHeight:(NSNotification *)notification {
    if (![notification isKindOfClass:NSNotification.class]) {
        return;
    }
    if ([notification.object isKindOfClass:NSNumber.class]) {
        NSNumber *heightNumber = (NSNumber *)notification.object;
        float topVCContainerHeight = heightNumber.floatValue;
        if (self.isVerifyPageFirstDidAppear) {
            // 首次展示密码页时，构造从下往上移动的动画效果
            self.isVerifyPageFirstDidAppear = NO;
            [self p_updateUserInfoViewLayout:topVCContainerHeight - 200 animate:NO];
        }
        
        self.userInfoView.hidden = NO;
        [self p_updateUserInfoViewLayout:topVCContainerHeight animate:YES];
        return;
    }
    if ([notification.object isKindOfClass:NSDictionary.class]) {
        NSDictionary *param = (NSDictionary *)notification.object;
        BOOL needAnimate = [param cj_boolValueForKey:@"need_animate"];
        float containerViewHeight = [param cj_floatValueForKey:@"container_height"];
        self.userInfoView.hidden = NO;
        NSLog(@"半屏高度:%@", @(containerViewHeight));
        [self p_updateUserInfoViewLayout:containerViewHeight animate:needAnimate];
    }
}

- (void)p_updateUserInfoViewLayout:(float)topVCContainerHeight animate:(BOOL)needAnimated{
    float pageHeight = self.view.cj_height - CJ_STATUSBAR_HEIGHT;
    float space = pageHeight - topVCContainerHeight;
    if (needAnimated) {
        @weakify(self);
        [self.view setNeedsUpdateConstraints];
        [UIView animateWithDuration:0.2 animations:^{
            @strongify(self);
            [self p_updateUserInfoViewConstraints:space];
        }];
    } else {
        [self p_updateUserInfoViewConstraints:space];
    }
}

- (void)p_updateUserInfoViewConstraints:(float)space {
    if (space > 100) {
        self.userInfoView.alpha = 1;
        self.singleLineUserInfoView.alpha = 0;
        CJPayMasUpdate(self.singleLineUserInfoView, {
            make.top.mas_equalTo(self.view).offset(CJ_STATUSBAR_HEIGHT + 50 - 16);
        });
        CJPayMasUpdate(self.userInfoView, {
            make.top.equalTo(self.view).offset(CJ_STATUSBAR_HEIGHT + space/2 - 50);
        });
    } else if (space > 34) {
        self.userInfoView.alpha = 0;
        self.singleLineUserInfoView.alpha = 1;
        CJPayMasUpdate(self.singleLineUserInfoView, {
            make.top.mas_equalTo(self.view).offset(CJ_STATUSBAR_HEIGHT + space/2 - 16);
        });
        CJPayMasUpdate(self.userInfoView, {
            make.top.equalTo(self.view).offset(CJ_STATUSBAR_HEIGHT + 34);
        });
    } else {
        self.userInfoView.alpha = 0;
        self.singleLineUserInfoView.alpha = 0;
    }
    
    [self.view layoutIfNeeded];
}

- (void)p_openCashDesk {
    [self p_updateUserInfoViewLayout:180 animate:NO];
    self.userInfoView.hidden = YES;

    [CJPayPerformanceMonitor trackAPIStartWithAPIScene:CJPayPerformanceAPISceneOuterPay extra:@{}];
    
    double currentTimestamp = [[NSDate dateWithTimeIntervalSinceNow:0] timeIntervalSince1970] * 1000;
    double startTimeStamp = [self.schemaParams btd_doubleValueForKey:@"start_time" default:0];
    self.lastTimestamp = currentTimestamp;
    if ([self.schemaParams cj_objectForKey:@"is_cold_launch"]) {
        self.isColdLaunch = [self.schemaParams cj_boolValueForKey:@"is_cold_launch"];
    } else {
        CJPayLogAssert(NO, @"params is_cold_launch is null.");
    }
    
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    double durationTime = (startTimeStamp > 100000) ? (currentTimestamp - startTimeStamp) : 0;
    [trackData addEntriesFromDictionary:@{@"duration": @(durationTime),
                                          @"client_duration": @(durationTime)}];
    [CJTracker event:@"wallet_cashier_opendouyin_loading" params:trackData];
    
    self.schemaParams.cjpay_referViewController = self;
    [CJ_OBJECT_WITH_PROTOCOL(CJPayDyPayModule) i_openDyPayDeskWithParams:self.schemaParams delegate:self];
}

- (void)callState:(BOOL)success fromScene:(CJPayScene)scene params:(NSDictionary *)params {
    if (params.count) {
        NSString *mobile = [params cj_stringValueForKey:@"mobile"];
        if (Check_ValidString(mobile)) {
            self.userNicknameLabel.text = mobile;
        }
    }
}

- (void)onResponse:(CJPayAPIBaseResponse *)response {
    if ([self.apiDelegate respondsToSelector:@selector(onResponse:)]) {
        [self.apiDelegate onResponse:response];
    }
    
    NSInteger resultCode = response.error.code;
    CJPayDypayResultType type = [CJPayOuterPayUtil dypayResultTypeWithErrorCode:resultCode];
    if (type >= 0) {
        CJPayLogInfo(@"支付结果%lu", (unsigned long)type);
    }
    [self closeCashierDeskAndJumpBackWithResult:type];
}

- (NSDictionary *)p_mergeCommonParamsWith:(NSDictionary *)dic
                                 response:(CJPayCreateOrderResponse *)response {
    NSMutableDictionary *totalDic = [NSMutableDictionary dictionaryWithDictionary:dic];
    NSDictionary *commonParams = [CJPayCommonTrackUtil getCashDeskCommonParamsWithResponse:response
                                                                         defaultPayChannel:response.payInfo.defaultPayChannel];
    [totalDic addEntriesFromDictionary:commonParams];
    [totalDic addEntriesFromDictionary:@{@"douyin_version": CJString([CJPayRequestParam appVersion])}];
    return totalDic;
}

@end
