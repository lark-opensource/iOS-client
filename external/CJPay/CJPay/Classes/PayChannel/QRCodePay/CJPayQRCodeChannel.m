//
//  CJPayQRCodeChannel.m
//  CJPay-Example
//
//  Created by 易培淮 on 2020/10/28.
//

#import "CJPayQRCodeChannel.h"
#import "CJPayQRCodeViewController.h"
#import "CJPayQRCodeModel.h"
#import "CJPaySDKDefine.h"
#import "CJPayChannelManager.h"
#import "CJPayUIMacro.h"

@implementation CJPayQRCodeChannel

CJPAY_REGISTER_PLUGIN({
    [[CJPayChannelManager sharedInstance] registerChannelClass:self channelType:CJPayChannelTypeQRCodePay];
})

- (instancetype)init {
    self = [super init];
    if (self) {
        self.channelType = CJPayChannelTypeQRCodePay;
    }
    return self;
}

//检查是否可用
+ (BOOL)isAvailableUse {
    return YES;
}

- (BOOL)canProcessWithURL:(NSURL *)URL { //不处理任何支付回调
    return NO;
}

- (BOOL)isInstalled {
    return YES;
}

- (void)payActionWithDataDict:(NSDictionary *)dataDict completionBlock:(CJPayCompletion) completionBlock {
    [super payActionWithDataDict:dataDict completionBlock:completionBlock];
    
    self.delegate = [dataDict cj_objectForKey:@"delegate"];
    
    NSError *err = nil;
    CJPayQRCodeModel *model = [[CJPayQRCodeModel alloc] initWithDictionary:dataDict error:&err];
    CJPayQRCodeViewController *qrcode = [[CJPayQRCodeViewController alloc] initWithModel:model];
    @CJWeakify(self)
    void(^queryResultBlock)(void(^notifyVCStopQueryBlock)(BOOL)) = ^(void(^notifyVCStopQueryBlock)(BOOL)){
        if ([weak_self.delegate respondsToSelector:@selector(queryQROrderResult:)]) {
            [weak_self.delegate queryQROrderResult:^(BOOL isSuccess){
                if(notifyVCStopQueryBlock){
                    notifyVCStopQueryBlock(isSuccess);
                }
                if(isSuccess){
                    [weak_self p_handleQueryResult];
                }
            }];
        }
    };
    void(^trackBlock)(void) = ^{
        if ([weak_self.delegate respondsToSelector:@selector(trackWithName:params:)]) {
            [weak_self.delegate trackWithName:@"wallet_cashier_scancode_save_click" params:@{@"method" : @"qrcode"}];
        }
    };
    qrcode.queryResultBlock = queryResultBlock;
    qrcode.trackBlock = trackBlock;
    if ([self.delegate respondsToSelector:@selector(pushViewController:)]) {
        [self.delegate pushViewController:qrcode];
    }
    self.QRCodeVC = qrcode;
}

#pragma mark - private method
- (void)p_handleQueryResult {
    self.QRCodeVC.isNeedQueryResult = NO;//停止查单
    [self exeCompletionBlock:self.channelType resultType:CJPayResultTypeSuccess];
    self.dataDict = nil;
}

- (void)exeCompletionBlock:(CJPayChannelType)type resultType:(CJPayResultType) resultType {
    CJ_CALL_BLOCK(self.completionBlock, type, resultType, 0);
    self.completionBlock = nil;
}


@end
