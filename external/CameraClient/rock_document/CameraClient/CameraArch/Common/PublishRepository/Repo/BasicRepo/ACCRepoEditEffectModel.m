//
//  ACCRepoEditEffectModel.m
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2021/1/27.
//

#import "ACCRepoEditEffectModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <TTVideoEditor/IESMMEffectTimeRange.h>
#import <CreativeKit/ACCMacros.h>

@interface AWEVideoPublishViewModel (RepoEditEffect) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoEditEffect)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoEditEffectModel.class];
    return info;
}

- (ACCRepoEditEffectModel *)repoEditEffect
{
    ACCRepoEditEffectModel *effectModel = [self extensionModelOfClass:ACCRepoEditEffectModel.class];
    NSAssert(effectModel, @"extension model should not be nil");
    return effectModel;
}

@end

@implementation ACCRepoEditEffectModel

- (NSMutableArray *)displayTimeRanges {
    if (!_displayTimeRanges) {
        _displayTimeRanges = @[].mutableCopy;
    }
    return _displayTimeRanges;
}

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoEditEffectModel *model = [[[self class] alloc] init];
    model.displayTimeRanges = self.displayTimeRanges.mutableCopy;
    model.displayTimeRangesJson = self.displayTimeRangesJson;
    return model;
}

- (BOOL)isEqualToObject:(ACCRepoEditEffectModel *)object
{
    if (![object isKindOfClass:[ACCRepoEditEffectModel class]]) {
        return NO;
    }
    if (self.displayTimeRanges.count != object.displayTimeRanges.count) {
        return NO;
    }
    for (NSInteger idx = 0; idx < self.displayTimeRanges.count; ++idx) {
        IESMMEffectTimeRange *current = self.displayTimeRanges[idx];
        IESMMEffectTimeRange *other = object.displayTimeRanges[idx];
        if (!ACC_FLOAT_EQUAL_TO(current.startTime, other.startTime) ||
            !ACC_FLOAT_EQUAL_TO(current.endTime, other.endTime) ||
            current.effectType != other.effectType ||
            current.filterType != other.filterType ||
            current.timeMachineStatus != other.timeMachineStatus) {
            return NO;
        }
    }
    return YES;
}

@end
