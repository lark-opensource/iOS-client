//
//  CJPayMemVerifyItem.m
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPayMemVerifyItem.h"
#import "CJPayUIMacro.h"

@implementation CJPayMemVerifyItem

- (void)verifyWithParams:(NSDictionary *)params fromVC:(UIViewController *)fromVC completion:(void (^)(CJPayMemVerifyResultModel * _Nonnull))completedBlock {
    CJPayLogAssert(NO, @"子类未实现此方法");
}

@end
