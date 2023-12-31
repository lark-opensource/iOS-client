//
//  CJPayCardDetailFreezeTipViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/20.
//

#import "CJPayCardDetailFreezeTipViewModel.h"
#import "CJPayUIMacro.h"
#import "CJPayCommonListViewController.h"

@implementation CJPayCardDetailFreezeTipViewModel

- (Class)getViewClass {
    return [CJPayCardDetailFreezeTipCell class];
}

- (CGFloat)getViewHeight {
    NSMutableString *reasonStr = [NSMutableString stringWithString:CJString(self.freezeReason)];;
    [reasonStr appendString:@" 解绑银行卡> "];
    CGSize resonSize = [reasonStr cj_sizeWithFont:[UIFont cj_fontOfSize:15]
                                          maxSize:CGSizeMake(self.viewController.view.cj_width - 32, MAXFLOAT)];
    return 66 + resonSize.height + 8;
}

@end
