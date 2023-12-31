//
//  CJPayCardOCRResultModel.m
//  CJPay
//
//  Created by 尚怀军 on 2020/5/20.
//

#import "CJPayCardOCRResultModel.h"

@implementation CJPayCardOCRResultModel

- (instancetype)initWithResult:(CJPayCardOCRResult)result
{
    self = [self init];
    if (self) {
        _result = result;
    }
    return self;
}

@end
