//
//  CJPaySyncUnionViewModel.m
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/9/1.
//

#import "CJPaySyncUnionViewModel.h"
#import "UIFont+CJPay.h"

@implementation CJPaySyncUnionViewModel

- (Class)getViewClass {
    return NSClassFromString(@"CJPayBankCardSyncUnionCell");
}

- (CGFloat)getViewHeight {
    return 78 * [UIFont cjpayFontScale] + 20;//cell的自身高度+距上距离
}

@end
