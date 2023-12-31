//
//  ACCPublishShareModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2019/12/30.
//

#import "ACCPublishShareModel.h"

@implementation ACCPublishShareModel

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCPublishShareModel *model = [[[self class] allocWithZone:zone] init];
    model.shareCompletion = self.shareCompletion;
    return model;
}

@end
