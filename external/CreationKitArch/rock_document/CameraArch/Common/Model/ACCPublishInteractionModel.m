//
//  ACCPublishInteractionModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2019/12/30.
//

#import "ACCPublishInteractionModel.h"


@implementation ACCPublishInteractionModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _interactionModelArray = [NSMutableArray array];
        _currentSectionLocations = [NSMutableArray array];
    }
    return self;
}

- (instancetype)copyWithZone:(NSZone *)zone
{
    ACCPublishInteractionModel *model = [[[self class] allocWithZone:zone] init];
    model.interactionModelArray = [[NSMutableArray alloc] initWithArray:self.interactionModelArray copyItems:YES];
    model.currentSectionLocations = [[NSMutableArray alloc] initWithArray:self.currentSectionLocations copyItems:YES];;
    return model;
}

@end
