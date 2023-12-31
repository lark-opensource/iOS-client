//
//  CJPayBankCardActivityItemViewModel.m
//  Pods
//
//  Created by xiuyuanLee on 2020/12/29.
//

#import "CJPayBankCardActivityItemViewModel.h"
#import "CJPayBankCardActivityItemCell.h"
#import "CJPayBankActivityInfoModel.h"

@interface CJPayBankCardActivityItemViewModel ()

@end

@implementation CJPayBankCardActivityItemViewModel

- (Class)getViewClass {
    return [CJPayBankCardActivityItemCell class];
}

- (CGFloat)getViewHeight {
    return self.isLastBankActivityRowViewModel ? 128 : 116;
}

@end
