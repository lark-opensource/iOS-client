//
//  CJPayUniteSignManager.m
//  CJPay-021e20ba
//
//  Created by 王新华 on 2022/9/15.
//

#import "CJPayUniteSignManager.h"
#import "CJPayPrivateServiceHeader.h"
#import "CJPayUniteSignViewController.h"
#import "CJPaySignRequestUtil.h"

@interface CJPayUniteSignManager()<CJPayUniteSignModule>

@property (nonatomic, strong) id<CJPayAPIDelegate> delegate;

@end

@implementation CJPayUniteSignManager

CJPAY_REGISTER_COMPONENTS({
    CJPayRegisterCurrentClassWithSharedSelectorToPtocol(self, @selector(sharedInstance), CJPayUniteSignModule)
})

+ (instancetype)shareInstance {
    static CJPayUniteSignManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [CJPayUniteSignManager new];
    });
    return manager;
}

- (void)i_uniteSignOnlyWithDataDict:(NSDictionary *)dataDict delegate:(id<CJPayAPIDelegate>)delegate {
    self.delegate = delegate;
    if (dataDict.count < 1) {
        CJPayLogInfo(@"传入的dataDict参数不合法");
        if ([self.delegate respondsToSelector:@selector(callState:fromScene:)]) {
            [self.delegate callState:NO fromScene:CJPaySceneSign];
        }
        return;
    }
    @CJWeakify(self);
    [CJPaySignRequestUtil startSignCreateRequestWithParams:dataDict completion:^(NSError * _Nonnull error, CJPaySignCreateResponse * _Nonnull response) {
        @CJStrongify(self);
        if ([response isSuccess]) {
            CJPayUniteSignViewController *uniteSignVC = [[CJPayUniteSignViewController alloc] initWithBizParams:dataDict response:response completionBlock:^(CJPaySignQueryResponse * _Nullable queryResponse, CJPayDypayResultType status) {
                @CJStrongify(self);
                [self p_callbackSignResult:queryResponse signStatus:status];
            }];
            uniteSignVC.animationType = HalfVCEntranceTypeFromBottom;
            uniteSignVC.exitAnimationType = HalfVCEntranceTypeFromBottom;
            [uniteSignVC presentWithNavigationControllerFrom:nil useMask:YES completion:^{
                CJPayLogInfo(@"签约页面打开成功");
            }];
        } else {
            [self p_callbackSignResult:nil signStatus:CJPayDypayResultTypeFailed];
            CJPayLogInfo(@"签约下单接口调用失败，error: %@", error);
        }
    }];
}

- (void)p_callbackSignResult:(CJPaySignQueryResponse *)response signStatus:(CJPayDypayResultType)status {
    if ([self.delegate respondsToSelector:@selector(onResponse:)]) {
        CJPayAPIBaseResponse *apiResponse = [CJPayAPIBaseResponse new];
        apiResponse.scene = CJPaySceneSign;
        apiResponse.data = @{@"sign_status": CJString(response.signStatus), @"pt_code": CJString(response.ptCode), @"sign_order_status": CJString(response.signOrderStatus)};
        NSInteger errCode = CJPayErrorCodeFail;
        NSString *errMSG = response.msg;
        if (status == CJPayDypayResultTypeFailed) {
            errCode = CJPayErrorCodeFail;
            errMSG = @"签约失败";
        } else if (status == CJPayDypayResultTypeSuccess) {
            errCode = CJPayErrorCodeSuccess;
            errMSG = @"签约成功";
        } else if (status == CJPayDypayResultTypeProcessing) {
            errCode = CJPayErrorCodeProcessing;
            errMSG = @"签约行为处理中";
        } else if (status == CJPayDypayResultTypeCancel) {
            errCode = CJPayErrorCodeCancel;
            errMSG = @"签约取消";
        } else if (status == CJPayDypayResultTypeTimeout) {
            errCode = CJPayErrorCodeOrderTimeOut;
            errMSG = @"签约停留时间过长，已超时";
        }
        apiResponse.error = [[NSError alloc] initWithDomain:CJPayErrorDomain code:errCode userInfo:@{@"msg": CJString(errMSG)}];
        if([self.delegate respondsToSelector:@selector(onResponse:)]) {
            [self.delegate onResponse:apiResponse];
        }
    } else {
        CJPayLogInfo(@"unite sign delegate未实现");
    }
    // 处理签约结果，并回调
}

- (void)callState:(BOOL)success fromScene:(CJPayScene)scene from:(id<CJPayAPIDelegate>)delegate {
    if (delegate && [delegate respondsToSelector:@selector(callState:fromScene:)]) {
        [delegate callState:success fromScene:scene];
    }
}
- (void)onResponse:(CJPayAPIBaseResponse *)response from:(id<CJPayAPIDelegate>)delegate {
    if (delegate && [delegate respondsToSelector:@selector(onResponse:)]) {
        [delegate onResponse:response];
    }
}

@end
