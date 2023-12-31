//
//  CJPaySuperPayLoadingItem.m
//  Pods
//
//  Created by 易培淮 on 2022/3/27.
//

#import "CJPaySuperPayLoadingItem.h"
#import "CJPayUIMacro.h"

@implementation CJPaySuperPayLoadingItem

+ (CJPayLoadingType)loadingType {
    return CJPayLoadingTypeSuperPayLoading;
}

- (NSString *)loadingTitle {
    return CJPayLocalizedStr(@"极速付款中");
}

- (NSString *)loadingIcon {
    return Check_ValidString(self.logoUrl) ? self.logoUrl : @"cj_super_pay_logo_icon";
}

@end
