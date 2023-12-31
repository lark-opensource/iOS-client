//
//  ACCRepoFilterModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//
#import "ACCRepoFilterModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoFilter) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoFilter)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoFilterModel.class];
}

- (ACCRepoFilterModel *)repoFilter
{
    ACCRepoFilterModel *filterModel = [self extensionModelOfClass:ACCRepoFilterModel.class];
    NSAssert(filterModel, @"extension model should not be nil");
    return filterModel;
}

@end

@interface ACCRepoFilterModel()<ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoFilterModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoFilterModel *model = [[[self class] alloc] init];
    model.colorFilterId = self.colorFilterId;
    model.colorFilterName = self.colorFilterName;
    model.colorFilterIntensityRatio = self.colorFilterIntensityRatio;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    NSMutableDictionary *params = @{}.mutableCopy;
    NSNumber *isOriginalFilter = @1;
    NSNumber *filterValue = @1;
    if (self.colorFilterIntensityRatio != nil) {
        isOriginalFilter = @0;
        filterValue = self.colorFilterIntensityRatio;
    }
    params[@"is_original_filter"] = isOriginalFilter;
    params[@"filter_value"] = [filterValue stringValue];
    return params;
}

@synthesize colorFilterId;

@synthesize colorFilterIntensityRatio;

@synthesize colorFilterName;

@end
