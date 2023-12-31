//
//  CJPayBinaryAdapter.m
//  CJPay
//
//  Created by 王新华 on 2019/5/30.
//

#import "CJPayBinaryAdapter.h"

@implementation CJPayBinaryAdapter

+ (instancetype)shared {
    static CJPayBinaryAdapter *adapter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        adapter = [CJPayBinaryAdapter new];
    });
    return adapter;
}

@end
