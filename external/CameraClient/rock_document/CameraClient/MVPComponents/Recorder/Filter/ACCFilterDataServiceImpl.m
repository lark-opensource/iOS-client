//
//  ACCFilterDataServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/5/20.
//

#import "ACCFilterDataServiceImpl.h"
#import <CreationKitComponents/ACCFilterDataService.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "AWERepoContextModel.h"
#import <CreationKitArch/ACCRepoFilterModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

@interface ACCFilterDataServiceImpl()

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

@implementation ACCFilterDataServiceImpl

-(instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository
{
    self = [super init];
    if (self) {
        _repository = repository;
    }
    return self;
}

- (NSDictionary *)referExtra
{
    return self.repository.repoTrack.referExtra;
}

- (AWERecordSourceFrom)recordSourceFrom
{
    return self.repository.repoContext.recordSourceFrom;
}

- (void)setColorFilterIntensityRatio:(NSNumber *)colorFilterIntensityRatio
{
    self.repository.repoFilter.colorFilterIntensityRatio = colorFilterIntensityRatio;
}

-(NSString *)referString
{
    return self.repository.repoTrack.referString;
}

- (NSString *)createId
{
    return self.repository.repoContext.createId;
}

- (NSString *)enterFrom
{
    return self.repository.repoTrack.enterFrom;
}

- (AWEVideoType)videoType
{
    return self.repository.repoContext.videoType;
}

@end
