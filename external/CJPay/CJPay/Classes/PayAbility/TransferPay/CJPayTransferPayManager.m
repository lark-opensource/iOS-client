//
//  CJPayTransferPayManager.m
//  CJPaySandBox
//
//  Created by shanghuaijun on 2023/5/22.
//

#import "CJPayTransferPayManager.h"
#import "CJPayTransferPayModule.h"
#import "CJPayProtocolManager.h"
#import "CJPaySDKMacro.h"
#import "CJPayManagerDelegate.h"
#import "CJPayTransferPayController.h"

@interface CJPayTransferPayManager()<CJPayTransferPayModule>

@property (nonatomic, strong) NSMutableArray *mutableControllers;

@end

@implementation CJPayTransferPayManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(defaultService), CJPayTransferPayModule)
})

+ (instancetype)defaultService {
    static CJPayTransferPayManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[CJPayTransferPayManager alloc] init];
    });
    return manager;
}

- (void)startTransferPayWithParams:(NSDictionary *)params
                        completion:(void (^)(CJPayManagerResultType type, NSString *errorMsg))completion {
    @CJWeakify(self)
    CJPayTransferPayController *largePayController = [CJPayTransferPayController new];
    @CJWeakify(largePayController)
    [self.mutableControllers addObject:largePayController];
    [largePayController startPaymentWithParams:params
                                    completion:^(CJPayManagerResultType type, NSString * _Nonnull errorMsg) {
        CJ_CALL_BLOCK(completion, type, errorMsg);
        [self.mutableControllers removeObject:largePayController];
    }];
}


@end

