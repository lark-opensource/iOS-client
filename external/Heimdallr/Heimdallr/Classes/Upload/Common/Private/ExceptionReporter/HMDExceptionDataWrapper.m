//
//  HMDExceptionDataWrapper.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/6/9.
//

#import "HMDExceptionDataWrapper.h"

@implementation HMDExceptionDataWrapper

- (instancetype)init {
    if (self = [super init]) {
        _modules = [NSMutableArray array];
        _dataDicts = [NSMutableArray array];
    }
    return self;
}

@end
