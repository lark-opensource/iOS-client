//
//  ACCRepoEditPropModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Liu Bing on 2021/1/18.
//

#import "ACCRepoEditPropModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <TTVideoEditor/IESMMEffectTimeRange.h>

@interface AWEVideoPublishViewModel (RepoProp) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoProp)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoEditPropModel.class];
}

- (ACCRepoEditPropModel *)repoEditProp
{
    ACCRepoEditPropModel *propModel = [self extensionModelOfClass:ACCRepoEditPropModel.class];
    NSAssert(propModel, @"extension model should not be nil");
    return propModel;
}

@end


@implementation ACCRepoEditPropModel
@synthesize repository;

- (nonnull id)copyWithZone:(nullable NSZone *)zone
{
    ACCRepoEditPropModel *copy = [[[self class] alloc] init];
    
    copy.displayTimeRanges = self.displayTimeRanges.mutableCopy;
    
    return copy;
}

- (NSMutableArray *)displayTimeRanges
{
    if (!_displayTimeRanges) {
        _displayTimeRanges = @[].mutableCopy;
    }
    return _displayTimeRanges;
}

@end

