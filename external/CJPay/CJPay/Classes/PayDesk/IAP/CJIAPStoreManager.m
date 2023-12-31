//
//  CJIAPStoreManager.m
//  CJPay
//
//  Created by 王新华 on 2019/3/15.
//

#import "CJIAPStoreManager.h"
#import "CJPaySDKMacro.h"
#import "SAMKeychain+CJPay.h"
#import "CJIAPStoreManager+Delegate.h"
#import "CJPayIAPMonitor.h"
#import "CJPayNewIAPManager.h"
#import "CJPayABTestManager.h"

@interface CJIAPStoreManager()<SKRequestDelegate>
@property (nonatomic, strong) CJPayIAPMonitor *monitor;
@property (nonatomic, assign) BOOL hasStartedupService;
@property (nonatomic, copy, readwrite) NSHashTable *iapDelegates;
@end

@implementation CJIAPStoreManager

+ (CJIAPStoreManager *)shareInstance {
    static CJIAPStoreManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJIAPStoreManager new];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hasStartedupService = NO;
        _monitor = [CJPayIAPMonitor new];
    }
    return self;
}


#pragma mark public
- (void)startupService {
    [[CJPayNewIAPManager shareInstance] startupService];
    self.hasStartedupService = YES;
    [self.monitor monitor:CJPayIAPStageInit category:@{} extra:@{}];
}

- (void)checkUnverifiedTransaction {
    
}

- (void)becomeIESStoreDelegateCenter {
    
}

- (void)startIAPWithParams:(NSDictionary *)bizParams {
    [self startIAPWithParams:bizParams product:nil];
}

- (void)startIAPWithParams:(NSDictionary *)bizParams product:(nullable id)product {
    [[CJPayNewIAPManager shareInstance] startIAPWithParams:bizParams product:product];
}

- (BOOL)canMakePayments {
    return [SKPaymentQueue canMakePayments];
}

- (void)preFetchProducts:(NSSet *)identifiers completion:(void (^)(NSArray<SKProduct *> * _Nonnull, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CJPayNewIAPManager shareInstance] requestSK1ProductsWithIdentifiers:identifiers completion:completion];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //解决获取AB实验过早问题
            [self newPreFetchProducts:identifiers
                           completion:^(NSArray<id<CJPayIAPProductProtocol>> * _Nonnull products, NSError * _Nullable error) {}];
        });
    });
}

- (void)newPreFetchProducts:(NSSet *)identifiers
                 completion:(void (^)(NSArray<id<CJPayIAPProductProtocol>> * _Nullable, NSError * _Nullable))completion {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[CJPayNewIAPManager shareInstance] prefetchProductsWithIdentifiers:identifiers
                                                                 completion:completion];
    });
}

// 恢复购买
- (void)restoreTransactionsWithUid:(NSString *)uid Completion:(void(^)(BOOL success, NSError * _Nullable error))completion {
    [[CJPayNewIAPManager shareInstance] restoreWithUid:uid
                                              callBack:completion];
}

- (void)restoreTransactionsWithUid:(NSString *)uid WithIapIDs:(NSArray<NSString *> *)iapIDs completion:(void (^)(BOOL, NSError * _Nullable))completion {
        [[CJPayNewIAPManager shareInstance] restoreWithUid:uid
                                                  callBack:completion];
}

@end
