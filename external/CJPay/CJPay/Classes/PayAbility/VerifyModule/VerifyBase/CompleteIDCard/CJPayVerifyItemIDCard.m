//
//  CJPayVerifyItemIDCard.m
//  CJPay
//
//  Created by liyu on 2020/3/27.
//

#import "CJPayVerifyItemIDCard.h"
#import "CJPayBaseVerifyManager+ButtonInfoHandler.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeUtil.h"
#import "CJPayVerifyIDCardViewController.h"
#import "CJPayVerifyPassPortViewController.h"

@interface CJPayVerifyItemIDCard ()

@property (nonatomic, strong) CJPayFullPageBaseViewController<CJPayVerifyIDVCProtocol> *currentVerifyVC;

@end


@implementation CJPayVerifyItemIDCard

#pragma mark - Override

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self _requestVerifyVC];
}

- (BOOL)shouldHandleVerifyResponse:(CJPayOrderConfirmResponse *)response
{
    if (self.manager.lastConfirmVerifyItem == self) {
        [self event:@"wallet_riskcontrol_identified_page_result" params:@{
            @"result" : [response isSuccess] ? @"1" : @"0",
            @"error_code" : CJString(response.code),
            @"error_message" : CJString(response.msg)
        }];
    }
    if (!response.isSuccess) {
        [self.currentVerifyVC clearInput];
    }
    
    if ([response.code isEqualToString:@"CD001001"]) {
        return YES;
    } else if ([response.code isEqualToString:@"MU010008"]) {
        return YES;
    } else if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        return YES;
    }
    return NO;
}

- (void)handleVerifyResponse:(CJPayOrderConfirmResponse *)response
{
    if ([response.code isEqualToString:@"CD001001"]) {
        [self _requestVerifyVC];
    } else if ([response.code isEqualToString:@"MU010008"]) {
        [self.currentVerifyVC updateTips:response.msg];
    } else if ([CJPayBDButtonInfoHandler showErrorTips:response.buttonInfo]) {
        [self.currentVerifyVC updateErrorText:response.buttonInfo.page_desc];
    }
}

#pragma mark - Private

- (void)_requestVerifyVC {
    CJPayFullPageBaseViewController<CJPayVerifyIDVCProtocol> *vc = [self createVerifyVC];
    @CJWeakify(self)
    vc.completion = ^(NSString * _Nonnull content) {
        @CJStrongify(self)
        [self p_verifyIDCardWith:content];
    };
    @CJWeakify(vc)
    vc.cjBackBlock = ^{
        @CJStrongify(vc)
        [vc closeWithCompletionBlock:^{
            @CJStrongify(self)
            [self notifyVerifyCancel];
        }];
    };
    
    [self.manager.homePageVC push:vc animated:YES];
}

- (void)p_verifyIDCardWith:(NSString *)last6Digits
{
    NSMutableDictionary *IDCardDic = [NSMutableDictionary new];
    [IDCardDic cj_setObject:[CJPaySafeUtil encryptField:[NSString stringWithFormat:@"%@%@", last6Digits, self.manager.response.processInfo.processId]] forKey:@"cert_code"];
    [IDCardDic cj_setObject:self.manager.response.userInfo.certificateType forKey:@"cert_type"];
    [IDCardDic cj_setObject:@"3" forKey:@"req_type"];
    [IDCardDic addEntriesFromDictionary:[self.manager loadSpecificTypeCacheData:CJPayVerifyTypeLast]]; // 获取上次的验证数据
    [self.manager submitConfimRequest:IDCardDic fromVerifyItem:self];
}

- (CJPayFullPageBaseViewController<CJPayVerifyIDVCProtocol> *)createVerifyVC
{
    if (self.currentVerifyVC && self.currentVerifyVC.navigationController) {
        CJPayLogInfo(@"已经在身份证后6位验证界面，后台让再次进入");
        NSMutableArray *vcs = [self.currentVerifyVC.navigationController.viewControllers mutableCopy];
        [vcs removeObjectIdenticalTo:self.currentVerifyVC];
        [self.currentVerifyVC.navigationController setViewControllers:[vcs copy] animated:YES];
    } else {
        if ([self.manager.response.userInfo.certificateType isEqualToString:@"ID_CARD"]) {
            self.currentVerifyVC = [CJPayVerifyIDCardViewController new];
        } else {
            self.currentVerifyVC = [CJPayVerifyPassPortViewController new];
        }
    }

    self.currentVerifyVC.response = self.manager.response;
    self.currentVerifyVC.trackDelegate = self;
    return self.currentVerifyVC;
}

- (NSString *)checkTypeName {
    NSString *typeName = @"证件后六位";
    if ([self.manager.response.userInfo.certificateType isEqualToString:@"ID_CARD"]) {
        typeName = @"证件后六位";
    }
    return typeName;
}

@end
