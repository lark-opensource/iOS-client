//
//  CJPayCardDetailLimitViewModel.m
//  CJPay
//
//  Created by 尚怀军 on 2019/9/23.
//

#import "CJPayCardDetailLimitViewModel.h"
#import "CJPayCardDetailLimitCell.h"

@implementation CJPayCardDetailLimitViewModel

- (Class)getViewClass {
    return [CJPayCardDetailLimitCell class];
}

-(CGFloat)getViewHeight {
    return 106;
}

@end
