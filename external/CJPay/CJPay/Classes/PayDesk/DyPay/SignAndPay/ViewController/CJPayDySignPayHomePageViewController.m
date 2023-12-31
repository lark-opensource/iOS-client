//
//  CJPayDySignPayHomePageViewController.m
//  CJPaySandBox
//
//  Created by 郑秋雨 on 2023/3/2.
//

#import "CJPayDySignPayHomePageViewController.h"
#import "CJPayBaseLynxView.h"
#import "CJPayDyPayManager.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayDyPayCreateOrderRequest.h"
#import "CJPaySignPageInfoModel.h"

NSString *kEventBackBizApp = @"close_and_notify";
NSString *kEventSignPay = @"open_verify_component";

@interface CJPayDySignPayHomePageViewController () <CJPayLynxViewDelegate>

@property (nonatomic, copy) NSDictionary *params;//下单时传过来的参数
@property (nonatomic, strong) CJPayBDCreateOrderResponse *response;
@property (nonatomic, copy) NSDictionary *postFEParams;//与前端约定好要传递的参数

@property (nonatomic, strong) CJPayBaseLynxView *lynxCard;

@end

@implementation CJPayDySignPayHomePageViewController

- (instancetype)initPageWithParams:(NSDictionary *)params response:(CJPayBDCreateOrderResponse *)response {
    self = [super init];
    if (self) {
        self.params = params;
        self.response = response;
        NSString *merchantid = CJString([params cj_stringValueForKey:@"partnerid"]);
        
        self.postFEParams = @{
            @"response" : response.originGetResponse ?: @{},
            @"params" : [CJPayDyPayCreateOrderRequest buildRequestParamsWithMerchantId:merchantid
                                                                               bizParams:params]
        };
    }
    return self;
}

#pragma mark - CJPayLynxViewDelegate
- (void)viewDidLoad {
    [super viewDidLoad];
    [self p_LoadLynxCard];
}

- (void)viewDidFinishLoadWithURL:(NSString *)url {
    [self p_moveLynxCardCenter];
}

- (void)viewDidLoadFailedWithUrl:(NSString *)url error:(NSError *)error {
    [self p_handelLoadResult:NO errorCode:CJPayOrderStatusFail];
}

- (void)viewDidRecieveError:(NSError *)error {
    [self p_handelLoadResult:NO errorCode:CJPayOrderStatusFail];
}

- (void)lynxView:(UIView *)lynxView receiveEvent:(NSString *)event withData:(NSDictionary *)data {
    if ([event isEqualToString:kEventBackBizApp]) {
        [self p_handelLoadResult:NO errorCode:CJPayOrderStatusCancel];
    } else if ([event isEqualToString:kEventSignPay]) {
        [self p_openSignPayDesk:data];
    } else {
        CJPayLogInfo([NSString stringWithFormat:@"唤端签约页面无「%@」方法",event]);
    }
}

- (BOOL)cjNeedAnimation {
    return NO;
}

- (BOOL)cjShouldShowBottomView {
    return YES;
}

#pragma mark - private func

- (void)p_LoadLynxCard {
    [self p_setupNav];
    
    [self.view addSubview:self.lynxCard];
    
    [self.lynxCard reload];
}

- (void)p_setupNav {
    self.view.backgroundColor = [UIColor clearColor];
    self.navigationBar.hidden = YES;
}

- (void)p_openSignPayDesk:(NSDictionary *)data {
    //不同的流程拉起不同的收银台
    CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:@{
        @"response":[data cj_dictionaryValueForKey:@"pre_trade_response"]?: @{}
    } error:nil];
    NSString *payType = CJString([data cj_stringValueForKey:@"pay_type"]);
    NSDictionary *deductParams = [data cj_dictionaryValueForKey:@"deduct_params"] ?: @{};
    NSMutableDictionary *allParams = [NSMutableDictionary dictionaryWithDictionary:self.params];
    [allParams cj_setObject:payType forKey:@"pay_type"];
    [allParams cj_setObject:deductParams forKey:@"deduct_params"];
    
    [[CJPayDyPayManager sharedInstance] openDySignPayDesk:allParams response:response completion:nil];
}

- (void)p_handelLoadResult:(BOOL)isSuccess errorCode:(CJPayOrderStatus)errorCode {
    NSError *loadError = nil;
    switch (errorCode) {
        case CJPayOrderStatusFail:
            loadError = [NSError errorWithDomain:@"系统出错了" code:CJPayOrderStatusFail userInfo:nil];
            break;
        case CJPayOrderStatusCancel:
            loadError = [NSError errorWithDomain:@"用户取消签约" code:CJPayOrderStatusCancel userInfo:nil];
            break;
        default:
            break;
    }
    CJ_CALL_BLOCK(self.resultBlock, isSuccess, loadError);
}

- (void)p_moveLynxCardCenter {
    [UIView animateWithDuration:0.25 animations:^{
        self.lynxCard.cj_left = 0;
    } completion:^(BOOL finished) {
        [self p_handelLoadResult:YES errorCode:CJPayOrderStatusSuccess];
    }];
}

- (NSString *)p_lynxUrl {
    return CJString(self.response.signPageInfo.signPageURL);
}

#pragma mark - lazy load
- (CJPayBaseLynxView *)lynxCard {
    if (!_lynxCard) {
        //这里得看看
        _lynxCard = [[CJPayBaseLynxView alloc] initWithFrame:CGRectMake(CJ_SCREEN_WIDTH, 0, CJ_SCREEN_WIDTH, CJ_SCREEN_HEIGHT) scheme:[self p_lynxUrl] initDataStr:[CJPayCommonUtil dictionaryToJson:self.postFEParams]];
        _lynxCard.delegate = self;
    }
    return _lynxCard;
}

@end
