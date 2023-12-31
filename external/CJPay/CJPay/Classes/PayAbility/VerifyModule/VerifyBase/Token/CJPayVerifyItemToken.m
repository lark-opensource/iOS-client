//
//  CJPayVerifyItemToken.m
//  Aweme
//
//  Created by liutianyi on 2022/10/17.
//

#import "CJPayVerifyItemToken.h"
#import "CJPayBaseVerifyManager.h"
#import "CJPayKVContext.h"
#import "CJPaySDKMacro.h"

@implementation CJPayVerifyItemToken

- (void)requestVerifyWithCreateOrderResponse:(CJPayBDCreateOrderResponse *)response
                                       event:(nullable CJPayEvent *)event {
    [self p_startConfirmRequest];
}

- (void)p_startConfirmRequest {
    [self.manager submitConfimRequest:@{@"req_type":@"11",
                                        @"token":CJString(self.manager.token),
                                      }
                       fromVerifyItem:self];
}

- (NSString *)checkType {
    return @"6";
}

@end
