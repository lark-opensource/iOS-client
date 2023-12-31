//
//  HMDStoreCondition.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/1/17.
//

#import "HMDStoreCondition.h"

@implementation HMDStoreCondition

- (instancetype)init {
    self = [super init];
    if (self) {
        self.judgeType = HMDConditionJudgeNone;
    }
    return self;
}

@end
