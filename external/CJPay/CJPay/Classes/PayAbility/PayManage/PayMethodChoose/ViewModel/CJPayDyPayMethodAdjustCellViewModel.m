//
//  CJPayDyPayMethodAdjustCellViewModel.m
//  CJPaySandBox
//
//  Created by 利国卿 on 2022/11/23.
//

#import "CJPayDyPayMethodAdjustCellViewModel.h"
#import "CJPayDyPayMethodNumAdjustCell.h"

@implementation CJPayDyPayMethodAdjustCellViewModel

- (Class)getViewClass {
    return [CJPayDyPayMethodNumAdjustCell class];
}

- (CGFloat)viewHeight {
    return 30.0;
}

@end
