//
//  CJPayOuterManager.m
//  Aweme
//
//  Created by wangxiaohong on 2022/10/11.
//

#import "CJPayOuterManager.h"

#import "CJPayBioPaymentPlugin.h"
#import "CJPayCreateOrderByTokenRequest.h"
#import "CJPayDyPayModule.h"
#import "CJPayLoginViewController.h"
#import "CJPayOuterSignLoadingViewController.h"
#import "CJPayOuterAuthViewController.h"
#import "CJPayOuterPayLoadingViewController.h"
#import "CJPayOuterDyPayLoadingViewController.h"
#import "CJPaySDKDefine.h"
#import "CJPayUIMacro.h"
#import "CJPayKVContext.h"

typedef void(^CreateOrderRequestCompletionBlock)(NSError * _Nullable error, NSDictionary * _Nullable response);

@interface CJPayOuterManager()

@property (nonatomic, weak) CJPayNavigationController *byteNavVC;
@property (nonatomic, weak) id<CJPayAPIDelegate> apiDelegate;
@property (nonatomic, strong) NSMutableDictionary *preRequestCreateOrderCacheDict;
@property (nonatomic, strong) NSMutableDictionary *preRequestCreateOrderCompletionBlocksDict; // key是startTime，value是block数组
@property (nonatomic, assign) BOOL isPreRequestCreateOrderDoing;
@end

@implementation CJPayOuterManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayOuterModule)
})

+ (instancetype)defaultService {
    static CJPayOuterManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayOuterManager alloc] init];
        manager.preRequestCreateOrderCacheDict = [NSMutableDictionary new];
        manager.preRequestCreateOrderCompletionBlocksDict = [NSMutableDictionary new];
        manager.isPreRequestCreateOrderDoing = NO;
    });
    return manager;
}

- (void)i_openOuterDeskWithSchemaParams:(NSDictionary *)schemaParams
                           withDelegate:(nullable id<CJPayAPIDelegate>)delegate {
    NSMutableDictionary *trackData = [[NSMutableDictionary alloc] initWithDictionary:[self p_outerDyPayTrackData:schemaParams]];
    [CJPayKVContext kv_setValue:trackData forKey:CJPayOuterPayTrackData];
    double lastTimestamp = [trackData btd_doubleValueForKey:@"start_time" default:0];
    double durationTime = (lastTimestamp > 100000) ? ([[NSDate date] timeIntervalSince1970] * 1000 - lastTimestamp) : 0;
    [trackData addEntriesFromDictionary:@{@"client_duration":@(durationTime)}];
    [CJTracker event:@"wallet_cashier_landing_page" params:trackData];
    
    if ([[schemaParams cj_stringValueForKey:@"need_login"] isEqualToString:@"1"]) {
        NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:schemaParams];
        [params removeObjectForKey:@"need_login"];
        CJPayLoginViewController *loginVC = [CJPayLoginViewController new];
        loginVC.delegate = delegate;
        loginVC.schemaParams = params;
        CJPayNavigationController *byteDeskNavVC = [CJPayNavigationController instanceForRootVC:loginVC];
        [self p_presentVCFrom:params.cjpay_referViewController navVC:byteDeskNavVC];
        return;
    }
    
    self.apiDelegate = delegate;
    [self p_openOuterDeskWithSchemaParam:[schemaParams copy] withDelegate:delegate];
}

- (void)i_requestCreateOrderBeforeOpenBytePayDeskWith:(NSDictionary *)schemaParams completion:(CreateOrderRequestCompletionBlock)completion {
    NSMutableDictionary *trackData = [[NSMutableDictionary alloc] initWithDictionary:[self p_outerDyPayTrackData:schemaParams]];
    [CJPayKVContext kv_setValue:trackData forKey:CJPayOuterPayTrackData];
    NSString *paySource = [schemaParams cj_stringValueForKey:@"pay_source"];
    if ([paySource isEqualToString:@"sign_and_pay"] ||
        [paySource isEqualToString:@"sign_only"] ||
        [paySource isEqualToString:@"bind_and_withdraw"]) {
        CJ_CALL_BLOCK(completion, nil, nil);
        return;
    }
    
    if ([paySource isEqualToString:@"outer_dypay"] ||
        [paySource isEqualToString:@"outer_bdpay"]) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        [trackData addEntriesFromDictionary:@{@"pay_source":@"outer_bdpay"}];
        [CJPayKVContext kv_setValue:trackData forKey:CJPayOuterPayTrackData];
        // 唤端追光支付创建订单网络请求
        [self p_dyPayCreateOrderRequestWith:schemaParams completion:completion];
        return;
    }
    
    // 唤端聚合支付创建订单网络请求
    [self p_createOrderByTokenRequestWith:schemaParams completion:completion];
}

- (void)p_dyPayCreateOrderRequestWith:(NSDictionary *)schemaParam completion:(CreateOrderRequestCompletionBlock)completion {
    NSMutableDictionary *allParamsDict = [[NSMutableDictionary alloc] initWithDictionary:schemaParam];
    NSString *allParamsString = [[schemaParam cj_stringValueForKey:@"all_params"] stringByRemovingPercentEncoding];// 中文解码
    if (Check_ValidString(allParamsString)) {
        [allParamsDict removeObjectForKey:@"all_params"];
        [allParamsDict addEntriesFromDictionary:[CJPayCommonUtil jsonStringToDictionary:allParamsString]];
    }
    [CJ_OBJECT_WITH_PROTOCOL(CJPayDyPayModule) i_requestCreateOrderBeforeOpenDyPayDeskWith:allParamsDict completion:completion];
}

- (void)p_createOrderByTokenRequestWith:(NSDictionary *)schemaParams completion:(CreateOrderRequestCompletionBlock)completion {
    NSString *token = [schemaParams cj_stringValueForKey:@"token"]; // 浏览器
    if (!Check_ValidString(token)) {
        // 未取到 token，可能是抖音以外 App 拉起
        token = [schemaParams cj_stringValueForKey:@"pay_token"];
        CJPayLogAssert(Check_ValidString(token), @"params token is null.");
        if (!Check_ValidString(token)) {
            CJ_CALL_BLOCK(completion, nil, nil);
            return;
        }
    }
    
    BOOL isColdLaunch = NO;
    if ([schemaParams cj_objectForKey:@"is_cold_launch"]) {
        isColdLaunch = [schemaParams cj_boolValueForKey:@"is_cold_launch"];
    }
    
    NSString *outerId = [schemaParams cj_stringValueForKey:@"app_id" defaultValue:@""];
    [CJTracker event:@"wallet_rd_cashier_request_create_order_by_token_before_open_pay" params:@{
        @"outer_aid": CJString(outerId),
        @"aid" : [UIApplication btd_appID] ?: @"unknown",
        @"app_platform" : [UIApplication btd_platformName],
        @"os_name" : @"iOS",
        @"is_cold_launch": @(isColdLaunch)
    }];
    
    long long handledLastTime = [schemaParams btd_longLongValueForKey:@"start_time" default:0];
    NSString *cacheKey = [NSString stringWithFormat:@"%ld", handledLastTime];
    if (isColdLaunch) {
        CJPayCreateOrderResponse *cachedResponse = [self.preRequestCreateOrderCacheDict cj_objectForKey:cacheKey];
        if (cachedResponse && [cachedResponse isKindOfClass:[CJPayCreateOrderResponse class]]) {
            [CJTracker event:@"wallet_rd_create_order_by_token_before_open_pay_cached" params:@{
                @"outer_aid": CJString(outerId),
                @"aid" : [UIApplication btd_appID] ?: @"unknown",
                @"app_platform" : [UIApplication btd_platformName],
                @"os_name" : @"iOS",
                @"is_cold_launch": @(isColdLaunch)
            }];
            CJ_CALL_BLOCK(completion, nil, @{@"create_order_by_token_response": cachedResponse});
            return;
        }
        
        if (self.isPreRequestCreateOrderDoing && completion) {
            NSMutableArray *blockArray = [self.preRequestCreateOrderCompletionBlocksDict cj_objectForKey:cacheKey];
            if (blockArray) {
                [blockArray addObject:completion];
            } else {
                [self.preRequestCreateOrderCompletionBlocksDict setObject:[NSMutableArray arrayWithObject:completion] forKey:cacheKey];
            }
            return;
        }
    }
    
    self.isPreRequestCreateOrderDoing = YES;
    NSDictionary *bizParams = @{@"token": CJString(token),
                                @"params": @{@"host_app_name": CJString([schemaParams cj_stringValueForKey:@"app_name"])}};
    @CJWeakify(self);
    [CJPayCreateOrderByTokenRequest startWithBizParams:bizParams
                                                bizUrl:@""
                                          highPriority:YES // 提高请求优先级
                                            completion:^(NSError * _Nonnull error, CJPayCreateOrderResponse * _Nonnull response) {
        @CJStrongify(self);
        self.isPreRequestCreateOrderDoing = NO;
        CJ_CALL_BLOCK(completion, error, response ? @{@"create_order_by_token_response": response} : nil);
        
        if (isColdLaunch) {
            if (!response || ![response isSuccess]) {
                [CJTracker event:@"wallet_rd_cashier_request_create_order_before_open_pay_failed" params:@{
                    @"error": error.localizedDescription ?: @"",
                    @"outer_aid": CJString(outerId),
                    @"aid" : [UIApplication btd_appID] ?: @"unknown",
                    @"os_name" : @"iOS",
                    @"is_cold_launch": @(isColdLaunch)
                }];
            }
            
            [self.preRequestCreateOrderCacheDict removeAllObjects];
            if (response && [response isSuccess]) {
                [self.preRequestCreateOrderCacheDict btd_setObject:response forKey:cacheKey];
            }
                
            NSMutableArray *blockArray = [self.preRequestCreateOrderCompletionBlocksDict cj_objectForKey:cacheKey];
            for (CreateOrderRequestCompletionBlock block in blockArray) {
                CJ_CALL_BLOCK(block, error, response ? @{@"create_order_by_token_response": response} : nil);
            }

            [self.preRequestCreateOrderCompletionBlocksDict removeObjectForKey:cacheKey];
        }
    }];
}

- (void)p_openOuterDeskWithSchemaParam:(NSDictionary *)schemaParam
                          withDelegate:(nonnull id<CJPayAPIDelegate>)delegate {
    [CJ_OBJECT_WITH_PROTOCOL(CJPayBioPaymentPlugin) correctLocalTime];
    // 端外收银台、抖音以外 App 拉起抖音支付
    if (![schemaParam isKindOfClass:NSDictionary.class]) {
        CJPayLogAssert(NO, @"schemaParam error.");
        return;
    }
    
    if ([[schemaParam cj_stringValueForKey:@"invoke_source"] isEqualToString:@"0"]) {
        [CJ_OBJECT_WITH_PROTOCOL(CJPayDyPayModule) i_openDyPayDeskWithParams:schemaParam delegate:delegate];
        return;
    }
    
    CJPayNavigationController *byteDeskNavVC;
    NSString *cashierStyle = @"0";//0:普通收单、1:签约并支付
    NSString *paySource = [schemaParam cj_stringValueForKey:@"pay_source"];
    if ([paySource isEqualToString:@"sign_and_pay"]) {
        cashierStyle = @"1";
        CJPayOuterSignLoadingViewController *signLoadingVC = [CJPayOuterSignLoadingViewController new];
        signLoadingVC.schemaParams = schemaParam;
        byteDeskNavVC = [CJPayNavigationController instanceForRootVC:signLoadingVC];
    } else if ([paySource isEqualToString:@"sign_only"]) {
        cashierStyle = @"1";
        CJPayOuterSignLoadingViewController *signLoadingVC = [CJPayOuterSignLoadingViewController new];
        signLoadingVC.schemaParams = schemaParam;
        signLoadingVC.isSignOnly = YES;
        byteDeskNavVC = [CJPayNavigationController instanceForRootVC:signLoadingVC];
    } else if ([paySource isEqualToString:@"bind_and_withdraw"]) {
        CJPayOuterAuthViewController *outerHomeVC = [CJPayOuterAuthViewController new];
        outerHomeVC.schemaParams = schemaParam;
        outerHomeVC.apiDelegate = delegate;
        byteDeskNavVC = [CJPayNavigationController instanceForRootVC:outerHomeVC];
    } else if ([paySource isEqualToString:@"outer_dypay"] || [paySource isEqualToString:@"outer_bdpay"]) {
        NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
        [trackData addEntriesFromDictionary:@{@"pay_source": @"outer_bdpay"}];
        [CJPayKVContext kv_setValue:trackData forKey:CJPayOuterPayTrackData];
        CJPayOuterDyPayLoadingViewController *outerPayVC = [CJPayOuterDyPayLoadingViewController new];
        outerPayVC.schemaParams = schemaParam;
        outerPayVC.apiDelegate = delegate;
        byteDeskNavVC = [CJPayNavigationController instanceForRootVC:outerPayVC];
    } else {
        CJPayOuterPayLoadingViewController *outerPayVC = [CJPayOuterPayLoadingViewController new];
        outerPayVC.schemaParams = schemaParam;
        outerPayVC.apiDelegate = delegate;
        outerPayVC.view;
        byteDeskNavVC = [CJPayNavigationController instanceForRootVC:outerPayVC];
    }
    
    NSMutableDictionary *trackData = [CJPayKVContext kv_valueForKey:CJPayOuterPayTrackData];
    [trackData addEntriesFromDictionary:@{@"cashier_style": cashierStyle}];
    [CJPayKVContext kv_setValue:trackData forKey:CJPayOuterPayTrackData];
    
    [self p_presentVCFrom:schemaParam.cjpay_referViewController navVC:byteDeskNavVC];
}

- (NSDictionary *)p_outerDyPayTrackData:(NSDictionary *)schemaParam {
    NSDictionary *allParams = [schemaParam cj_dictionaryValueForKey:@"all_params"];
    NSDictionary *trackInfo = [allParams cj_dictionaryValueForKey:@"track_info"]  ?: [NSDictionary new];
    
    NSString *openMerchantId = [allParams cj_stringValueForKey:@"partnerid" defaultValue:@""];
    if (!Check_ValidString(openMerchantId)) {
        openMerchantId = [allParams cj_stringValueForKey:@"merchant_id" defaultValue:@""];
    }
    NSString *outerId = [allParams cj_stringValueForKey:@"app_id" defaultValue:@""];
    if (!Check_ValidString(outerId)) {
        outerId = [allParams cj_stringValueForKey:@"merchant_app_id" defaultValue:@""];
    }
    
    // 预下单ID
    NSString *prepayId = [allParams cj_stringValueForKey:@"prepayid"];
    if (!Check_ValidString(prepayId)) {
        prepayId = [allParams cj_stringValueForKey:@"prepay_id"];
    }
    if (!Check_ValidString(prepayId)) {
        prepayId = [[allParams cj_stringValueForKey:@"package"] stringByReplacingOccurrencesOfString:@"prepay_id=" withString:@""]; //JSAPI路径里prepayid在package字段下
    }
    
    return @{
        @"outer_aid": CJString(outerId),
        @"trace_id": CJString([trackInfo cj_stringValueForKey:@"trace_id"]),
        @"app_id": CJString(outerId),
        @"prepay_id": CJString(prepayId),
        @"merchant_id": CJString(openMerchantId),
        @"is_cold_launch": @([schemaParam cj_boolValueForKey:@"is_cold_launch"]),
        @"start_time":@([schemaParam btd_doubleValueForKey:@"start_time" default:0]),
        @"outer_sdk_version":CJString([schemaParam cj_stringValueForKey:@"outer_sdk_version"]),
        @"is_login_on_start":CJString([schemaParam cj_stringValueForKey:@"is_login_on_start"]),
        @"platform":@"NATIVE",//NATIVE或JSAPI
        @"client_session_id":CJString([schemaParam cj_stringValueForKey:@"client_session_id"]),
    };
}

- (void)p_presentVCFrom:(UIViewController *)fromVC navVC:(CJPayNavigationController *)navVC {
    navVC.modalPresentationStyle = CJ_Pad ? UIModalPresentationFormSheet : UIModalPresentationFullScreen;
    // 解决重复拉起时，把之前的支付流程清空
    if (self.byteNavVC && self.byteNavVC.presentingViewController) {
        NSArray *byteNavVCs = self.byteNavVC.viewControllers;
        if (byteNavVCs.count == 1 && [byteNavVCs.firstObject isKindOfClass:CJPayLoginViewController.class]) {
            NSMutableArray *newVCs = [self.byteNavVC.viewControllers mutableCopy];
            [newVCs addObjectsFromArray:navVC.viewControllers];
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                [newVCs removeObjectAtIndex:0];
                [self.byteNavVC setViewControllers:[newVCs copy] animated:NO];
            }];
            [self.byteNavVC setViewControllers:[newVCs copy] animated:YES];
            [CATransaction commit];
        } else {
            @CJWeakify(self);
            [self.byteNavVC.presentingViewController dismissViewControllerAnimated:NO completion:^{
                @CJStrongify(self);
                self.byteNavVC = navVC;
                [[UIViewController cj_foundTopViewControllerFrom:fromVC] presentViewController:navVC animated:YES completion:^{}];
            }];
        }
    } else {
        self.byteNavVC = navVC;
        [[UIViewController cj_foundTopViewControllerFrom:fromVC] presentViewController:navVC animated:NO completion:^{}];
    }
}

@end
