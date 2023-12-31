//
//  BDABTestExperimentItemModel.m
//  ABSDKDemo
//
//  Created by bytedance on 2018/7/24.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "BDABTestExperimentItemModel.h"

@interface BDABTestExperimentItemModel ()

@property (nonatomic, strong) id val;
@property (nonatomic, strong) NSNumber *vid;

@end

@implementation BDABTestExperimentItemModel

- (instancetype)initWithVal:(id)val vid:(NSNumber *)vid {
    self = [super init];
    if (self) {
        _val = val;
        _vid = vid;
    }
    return self;
}

@end
