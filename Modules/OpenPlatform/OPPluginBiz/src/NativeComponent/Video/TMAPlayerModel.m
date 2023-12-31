//
//  TMAPlayerModel.m
//  OPPluginBiz
//
//  Created by bupozhuang on 2019/1/3.
//

#import "TMAPlayerModel.h"

@implementation TMAPlayerModel

- (instancetype)init
{
    if (self = [super init]) {
        _controls = YES;
        _showMuteBtn = YES;
    }
    return self;
}

@end
