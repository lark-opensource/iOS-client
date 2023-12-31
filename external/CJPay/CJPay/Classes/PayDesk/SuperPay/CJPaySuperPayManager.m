//
//  CJPaySuperChannel.m
//  Pods
//
//  Created by 易培淮 on 2022/3/28.
//

#import "CJPaySuperPayManager.h"
#import "CJPaySuperPayQueryRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayChannelManager.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayEnumUtil.h"
#import "CJPaySuperPayResultView.h"
#import "CJPayFrontCashierResultModel.h"
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "CJPayHalfPageBaseViewController.h"
#import "CJPaySuperPayController.h"
#import "CJPayCashierModule.h"
#import "CJPaySuperPayCallBackModel.h"

typedef void(^CJPaySuperPaycallBack) (CJPaySuperPayCallBackModel *model);

@interface CJPaySuperPayManager()<CJPaySuperPayService>

@property (nonatomic, strong) CJPaySuperPayController *homePageVC;
@property (nonatomic, assign) CJPayChannelType channelType;
@property (nonatomic, copy) NSDictionary *dataDict;
@property (nonatomic, copy) NSDictionary *trackParam;
@property (nonatomic, copy) CJPaySuperPaycallBack completionBlock;
@property (nonatomic, copy) NSDictionary *queryResult;

@end

@implementation CJPaySuperPayManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPaySuperPayService)
})

+ (instancetype)defaultService {
    static CJPaySuperPayManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPaySuperPayManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeSuperPay;
    }
    return self;
}

//检查是否可用
+ (BOOL)isAvailableUse {
    return YES;
}

- (BOOL)canProcessWithURL:(NSURL *)URL {
    return NO;
}

- (BOOL)isInstalled {
    return YES;
}


- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPaySuperPaycallBack) completionBlock {
    self.dataDict = dataDict;
    self.trackParam = [dataDict cj_dictionaryValueForKey:@"track_info"];
    self.completionBlock = [completionBlock copy];

    @CJWeakify(self)
    self.homePageVC.completion = ^(CJPayResultType resultType, CJPaySuperPayQueryResponse *response) {
        @CJStrongify(self)
        [[CJPayLoadingManager defaultService] stopLoading:CJPayLoadingTypeSuperPayLoading];
        //避免关闭页面动作影响到前端的转场行为
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self exeCompletionBlock:self.channelType resultType:resultType response:response];
        });
    };
    
    [self.homePageVC startQueryResultWithParams:dataDict];
    
}

- (void)exeCompletionBlock:(CJPayChannelType)type resultType:(CJPayResultType) resultType response:(CJPaySuperPayQueryResponse *)response{
    CJPaySuperPayCallBackModel *model = [[CJPaySuperPayCallBackModel alloc] initWithChannelType:type resultType:resultType response:response];
    
    CJ_CALL_BLOCK(self.completionBlock, model);
    self.completionBlock = nil;
}

#pragma - mark wake by universalPayDesk
- (BOOL)wakeByUniversalPayDesk:(NSDictionary *)dictionary withDelegate:(id<CJPayAPIDelegate>)delegate {
    [self i_openSuperPayWithParams:dictionary delegate:delegate];
    return YES;
}

- (void)i_openSuperPayWithParams:(NSDictionary *)params delegate:(id<CJPayAPIDelegate>)delegate {
    [self payActionWithDataDict:params completionBlock:^(CJPaySuperPayCallBackModel *model) {
        CJPayErrorCode returnCode = CJPayErrorCodeFail;
        NSString *errorMsg = nil;
        switch (model.resultType) {
            case CJPayResultTypeCancel:
                returnCode = CJPayErrorCodeCancel;
                errorMsg = @"用户取消支付";
                break;
            case CJPayResultTypeFail:
                returnCode = CJPayErrorCodeFail;
                errorMsg = @"支付失败";
                break;
            case CJPayResultTypeSuccess:
                returnCode = CJPayErrorCodeSuccess;
                errorMsg = @"支付成功";
                break;;
            case CJPayResultTypeProcessing:
                returnCode = CJPayErrorCodeProcessing;
                errorMsg = @"正在处理中，请查询商户订单列表中订单的支付状态";
                break;
            default:
                break;
        }
        
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = CJPaySceneEcommercePay;//电商与本地生活处理相同，这里就不额外判断了
        apiResponse.error = [NSError errorWithDomain:CJPayErrorDomain code:returnCode userInfo:@{NSLocalizedDescriptionKey: NSLocalizedString(CJString(errorMsg), nil)}];
        NSDictionary *newCreateOrderResponse = [params cj_dictionaryValueForKey:@"create_order_response"];
        self.queryResult = @{
            @"sdk_code": @(returnCode),
            @"sdk_msg": CJString(errorMsg),
            @"payment_info": model.paymentInfo ?: @{},
            @"create_order_response" : Check_ValidDictionary(newCreateOrderResponse) ? newCreateOrderResponse : @{}
        };
        apiResponse.data = self.queryResult;
        
        if ([delegate respondsToSelector:@selector(onResponse:)]) {
            [delegate onResponse:apiResponse];
        }
    }];
}

- (NSDictionary *)getQueryResultData {
    return self.queryResult;
}

#pragma mark - Getter
- (CJPaySuperPayController *)homePageVC {
    if (!_homePageVC) {
        _homePageVC = [CJPaySuperPayController new];
    }
    return _homePageVC;
}

@end
