//
//  CJPayProcessPool.m
//  CJPay
//
//  Created by 王新华 on 2018/12/3.
//

#import "CJPayProcessPool.h"

@implementation CJPayProcessPool

+ (instancetype)shared{
    static CJPayProcessPool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[CJPayProcessPool alloc] init];
    });
    return instance;
}

@end
