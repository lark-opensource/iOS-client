//
//  CJPayNewIAPManager.m
//  CJPay
//
//  Created by 尚怀军 on 2022/2/21.
//

#import "CJPayNewIAPManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayNewIAPOrderCreateModel.h"
#import "CJPayIAPMonitor.h"
#import "CJIAPStoreManager+Delegate.h"
#import "SAMKeychain+CJPay.h"
#import "CJPayNewIAPOrderCreateRequest.h"
#import "CJPayNewIAPSK1ConfirmRequest.h"
#import "CJPayNewIAPSK2ConfirmRequest.h"
#import "CJPayNewIAPConfirmResponse.h"
#import "CJPaySettingsManager.h"
#import "CJPaySettings.h"
#import "CJPayIAPFailPopupConfigModel.h"
#import "CJPayIAPRetainUtil.h"

@interface CJPayNewIAPManager()

@property (nonatomic, strong) CJPayIAPMonitor *monitor;
@property (nonatomic, assign) BOOL enableSK2;
@property (nonatomic, assign) BOOL enableSK1Observer;
@property (nonatomic, assign) BOOL needPendingReturnFail;
@property (nonatomic, copy) NSDictionary *bizParams;
@property (nonatomic, strong) id product;
@property (nonatomic, strong) CJPayIAPRetainUtil *retainUtil;
//埋点用
@property (nonatomic, copy) NSString *tradeNo;
@property (nonatomic, copy) NSString *lastTradeNo;

@end

@implementation CJPayNewIAPManager

+ (CJPayNewIAPManager *)shareInstance {
    static CJPayNewIAPManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayNewIAPManager new];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _monitor = [CJPayIAPMonitor new];
    }
    return self;
}

- (void)startupService {
    if (![self isSupportNewIAP]) {
        [CJMonitor trackService:@"wallet_rd_iap_exception"
                       category:@{@"aid": CJString([CJPayRequestParam gAppInfoConfig].appId)}
                          extra:@{}];
        [CJTracker event:@"wallet_rd_iap_exception" params:@{@"type": @"CJSwiftIAPStore"}];
    }
    CJPayLogAssert([self isSupportNewIAP], @"Please add CJSwiftIAPStore in your podfile!")
    if (@available(iOS 15.0.1, *)) {
        self.monitor.iapType = @"swift_sk2";
    } else {
        self.monitor.iapType = @"swift_sk1";
    }
    [self configIAPSettings];
    [self disableIESStoreObserver];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class oldStoreClass = NSClassFromString(@"CJSwiftIAPStoreManager");
    if (oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"setupServiceDelegate:")]) {
        [oldStoreClass performSelector:NSSelectorFromString(@"setupServiceDelegate:")
                            withObject:self];
    }
    #pragma clang diagnostic pop
}

- (BOOL)shouldUseNewIAP {
    return YES;
}

// frozen, app生命周期内值是一致的
- (void)configIAPSettings {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //解决IAP初始化过早settings反序列化耗时长问题
        CJPayIAPConfigModel *iapConfigModel = [CJPaySettingsManager shared].iapConfigModel;
        if (iapConfigModel) {
            _enableSK2 = iapConfigModel.enableSK2;
            _enableSK1Observer = iapConfigModel.enableSK1Observer;
            _needPendingReturnFail = iapConfigModel.isNeedPendingReturnFail;
            return;
        }
        CJPaySettings *curSettings = [CJPaySettingsManager shared].currentSettings;
        
        if (curSettings.iapConfigModel && curSettings.iapConfigModel.enableSK2) {
            _enableSK2 = YES;
        }

        if (curSettings.iapConfigModel && curSettings.iapConfigModel.enableSK1Observer) {
            _enableSK1Observer = YES;
        }
        
        if (curSettings.iapConfigModel && curSettings.iapConfigModel.isNeedPendingReturnFail) {
            _needPendingReturnFail = YES;
        }
    });
}

// 兜底异常，新流程禁用IESStore的监听
- (void)disableIESStoreObserver {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class iesStoreClass = NSClassFromString(@"IESStore");
    id iesStoreSharedInstance;
    if (iesStoreClass && [iesStoreClass respondsToSelector:NSSelectorFromString(@"defaultStore")]) {
        iesStoreSharedInstance = [iesStoreClass performSelector:NSSelectorFromString(@"defaultStore")];
    }
   
    if (iesStoreSharedInstance && [iesStoreSharedInstance respondsToSelector:NSSelectorFromString(@"removeTransactionObserver")]) {
        [iesStoreSharedInstance performSelector:NSSelectorFromString(@"removeTransactionObserver")];
    }
    
    if (iesStoreSharedInstance && ![iesStoreSharedInstance respondsToSelector:NSSelectorFromString(@"removeTransactionObserver")]) {
        [CJTracker event:@"wallet_rd_iap_exception" params:@{@"type": @"IESStore"}];
    }
    
    #pragma clang diagnostic pop
}

- (BOOL)isSupportNewIAP {
    Class oldStoreClass = NSClassFromString(@"CJSwiftIAPStoreManager");
    BOOL hasSwiftAPI = oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"startIAPWithParams::")];
    BOOL canSetDelegate = oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"setupServiceDelegate:")];
    return hasSwiftAPI && canSetDelegate;
}

- (void)startIAPWithParams:(NSDictionary *)bizParams
                   product:(nullable id)product {
    self.retainUtil.orderInProgress = YES;
    [self.retainUtil showLoading:[bizParams cj_stringValueForKey:@"product_id"]];
    [self.retainUtil iapConfigWithAppid:[bizParams cj_stringValueForKey:@"app_id"]
                             merchantId:[bizParams cj_stringValueForKey:@"merchant_id"]
                                    uid:[bizParams cj_stringValueForKey:@"uid"]];
    self.bizParams = bizParams;
    self.product = product;
    self.monitor.businessIdentify = [[CJIAPStoreManager shareInstance] businessIdentify:[bizParams cj_stringValueForKey:@"product_id"]];
    self.monitor.version = [bizParams cj_stringValueForKey:@"version"];
    
    [self.monitor monitor:CJPayIAPStageWakeup
                 category:@{}
                    extra:@{}];
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class oldStoreClass = NSClassFromString(@"CJSwiftIAPStoreManager");
    if (oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"startIAPWithParams::")]) {
        [oldStoreClass performSelector:NSSelectorFromString(@"startIAPWithParams::")
                            withObject:bizParams
                            withObject:product];
    }
    #pragma clang diagnostic pop
}

- (void)restoreWithUid:(NSString *)uid
              callBack:(void(^)(BOOL success, NSError * _Nullable error))callBack {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class oldStoreClass = NSClassFromString(@"CJSwiftIAPStoreManager");
    if (oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"restoreWithUid:callBack:")]) {
        [oldStoreClass performSelector:NSSelectorFromString(@"restoreWithUid:callBack:")
                            withObject:uid
                            withObject:callBack];
    }
    #pragma clang diagnostic pop

}

- (void)prefetchProductsWithIdentifiers:(NSSet *)identifiers
                             completion:(void (^)(NSArray<id<CJPayIAPProductProtocol>> * _Nullable, NSError * _Nullable))completion {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    Class oldStoreClass = NSClassFromString(@"CJSwiftIAPStoreManager");
    if (oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"prefetchProductsWithIdentifiers::")]) {
        [oldStoreClass performSelector:NSSelectorFromString(@"prefetchProductsWithIdentifiers::")
                            withObject:identifiers
                            withObject:completion];
    }
    #pragma clang diagnostic pop
}

- (void)requestSK1ProductsWithIdentifiers:(NSSet *)identifiers
                               completion:(void (^)(NSArray<SKProduct *> * _Nullable, NSError * _Nullable))completion {
    Class oldStoreClass = NSClassFromString(@"CJSwiftIAPStoreManager");
    if (oldStoreClass && [oldStoreClass respondsToSelector:NSSelectorFromString(@"requestSK1ProductsWithIdentifiers::")]) {
        [oldStoreClass performSelector:NSSelectorFromString(@"requestSK1ProductsWithIdentifiers::")
                            withObject:identifiers
                            withObject:completion];
    }
}

#pragma mark - CJPayNewIAPServiceProtocol

- (void)didFinishProductOrder:(CJPayNewIAPOrderCreateModel *)orderCreateModel
                 isBackground:(BOOL)isBackground
                   resultType:(CJPayIAPResultType)resultType
                        error:(NSError *)error {
    self.retainUtil.orderInProgress = NO;
    self.tradeNo = orderCreateModel.tradeNo;
    self.retainUtil.tradeNo = orderCreateModel.tradeNo;
    self.retainUtil.merchantId = orderCreateModel.merchantId;
    self.retainUtil.merchantKey = [self p_merchantKey];
    if (![self.tradeNo isEqualToString:self.lastTradeNo]) {
        self.retainUtil.isRetainShown = NO;
    }
    
    NSDictionary *bizExtraDic = [self.bizParams cj_dictionaryValueForKey:@"biz_extra"];
    BOOL frontDisableRetain = NO;
    if (bizExtraDic && [bizExtraDic cj_boolValueForKey:@"disable_retain"]) {
        frontDisableRetain = YES;
    }
    
    if (!isBackground && resultType != CJPayIAPResultTypePaySuccess && error && !frontDisableRetain) {
        @CJWeakify(self)
        BOOL popShown = [self.retainUtil showRetainPopWithIapType:orderCreateModel.iapType error:error completion:^{
            @CJStrongify(self)
            [self p_didFinishProductOrder:orderCreateModel isBackground:isBackground resultType:resultType error:error];
        }];
        if (popShown) {
            return;
        }
    }
    self.lastTradeNo = self.tradeNo;
    [self p_didFinishProductOrder:orderCreateModel isBackground:isBackground resultType:resultType error:error];
}

- (void)createTradeOrderWithAppID:(nullable NSString *)appid
                           params:(nullable NSDictionary *)params
                             exts:(nullable NSDictionary *)extParams
                       completion:(void (^)(NSError * _Nullable, CJPayNewIAPOrderCreateModel * _Nullable))completionBlock {
    [CJPayNewIAPOrderCreateRequest startRequest:appid
                                         params:params
                                           exts:extParams
                                     completion:^(NSError * _Nullable error, CJPayNewIAPOrderCreateResponse * _Nullable response) {
        CJ_CALL_BLOCK(completionBlock, error, [response toNewIAPOrderCreateModel]);
    }];
}

- (void)sk1ConfirmWithCommonParams:(NSDictionary *)commonParams
                  bizContentParams:(NSDictionary *)bizParams
                        completion:(void (^)(NSError * Nullable, CJPayNewIAPConfirmModel * _Nullable))completionBlock {
    [CJPayNewIAPSK1ConfirmRequest startRequest:commonParams
                              bizContentParams:bizParams
                                    completion:^(NSError * _Nonnull error, CJPayNewIAPConfirmResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completionBlock, error, [response toNewIAPConfirmModel]);
    }];
}

- (void)sk2ConfirmWithCommonParams:(NSDictionary *)bizParams
                  bizContentParams:(NSDictionary *)params
                        completion:(void (^)(NSError * _Nonnull, CJPayNewIAPConfirmModel * _Nonnull))completionBlock {
    [CJPayNewIAPSK2ConfirmRequest startRequest:bizParams
                              bizContentParams:params
                                    completion:^(NSError * _Nonnull error, CJPayNewIAPConfirmResponse * _Nonnull response) {
        CJ_CALL_BLOCK(completionBlock, error, [response toNewIAPConfirmModel]);
    }];
}

- (void)event:(NSString *)event
       params:(NSDictionary *)params {
    NSString *productId = [params cj_stringValueForKey:@"product_id"];
    NSString *bizIdStr = [[CJIAPStoreManager shareInstance] businessIdentify:CJString(productId)];
    NSMutableDictionary *trackParams = [NSMutableDictionary dictionaryWithDictionary:params];
    trackParams[@"business_id"] = CJString(bizIdStr);
    trackParams[@"platform"] = @"iap";
    [CJTracker event:event params:trackParams];
}

- (void)monitorWithStage:(CJPayIAPStage)stage
             categoryDic:(NSDictionary *)categoryDic
               extralDic:(NSDictionary *)extralDic {
    [self.monitor monitor:stage
                 category:categoryDic
                    extra:extralDic];
}

- (void)keyChainSafeSave:(NSString *)value forkey:(NSString *)key {
    [SAMKeychain cj_save:value forKey:key];
}

- (NSString *)keyChainStringValueForkey:(NSString *)key {
    return [SAMKeychain cj_stringForKey:key];
}

- (BOOL)isEnableSK2 {
    return self.enableSK2;
}

- (BOOL)isEnableSK1Observer {
    return self.enableSK1Observer;
}

- (BOOL)isNeedPendingReturnFail {
    return self.needPendingReturnFail;
}

- (void)paymentQueue:(SKPaymentQueue *)queue shouldAddStorePayment:(SKPayment *)payment for:(SKProduct *)product {
    [[CJIAPStoreManager shareInstance] paymentQueue:queue shouldAddStorePayment:payment for:product];
}

#pragma mark - private method

- (void)p_didFinishProductOrder:(CJPayNewIAPOrderCreateModel *)orderCreateModel
                   isBackground:(BOOL)isBackground
                     resultType:(CJPayIAPResultType)resultType
                          error:(NSError *)error {
    CJIAPProduct *product = [orderCreateModel toCJIAPProductModel];
    product.isRetainShown = self.retainUtil.isRetainShown;
    if (isBackground) {
        [[CJIAPStoreManager shareInstance] didFinishProductOrderInBack:product
                                                            resultType:resultType
                                                                 error:error];
    } else {
        [[CJIAPStoreManager shareInstance] didFinishProductOrder:product
                                                      resultType:resultType
                                                           error:error];
    }
}

- (NSString *)p_merchantKey {
    return [NSString stringWithFormat:@"%@_%@", [self.bizParams cj_stringValueForKey:@"merchant_id"], [self.bizParams cj_stringValueForKey:@"uid"]];
}

- (CJPayIAPRetainUtil *)retainUtil {
    if (!_retainUtil) {
        _retainUtil = [CJPayIAPRetainUtil new];
        @CJWeakify(self)
        _retainUtil.confirmBlock = ^{
            @CJStrongify(self)
            [self startIAPWithParams:self.bizParams product:self.product];
        };
    }
    return _retainUtil;
}

@end
