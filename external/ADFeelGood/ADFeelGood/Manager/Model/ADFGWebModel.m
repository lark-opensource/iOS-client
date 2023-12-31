//
//  ADFGWebModel.m
//  ADFeelGood
//
//  Created by cuikeyi on 2021/3/10.
//

#import "ADFGWebModel.h"

@implementation ADFGWebModel

- (instancetype)init
{
    if (self = [super init]) {
        _timeoutInterval = 10.f;
        _showLocalSubmitRecord = NO;
        _scrollEnabled = YES;
    }
    return self;
}

@end
