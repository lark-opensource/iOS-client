//
//  ACCBeautyDataServiceImpl.m
//  CameraClient-Pods-Aweme
//
//  Created by machao on 2021/5/24.
//

#import "ACCBeautyDataServiceImpl.h"
#import <CreationKitComponents/ACCBeautyDataService.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoBeautyModel.h>

@interface ACCBeautyDataServiceImpl()

@property (nonatomic, weak) AWEVideoPublishViewModel *repository;

@end

@implementation ACCBeautyDataServiceImpl

@synthesize gameType;

- (instancetype)initWithRepository:(AWEVideoPublishViewModel *)repository
{
    self = [super init];
    if (self) {
        _repository = repository;
    }
    return self;
}

- (NSString *)enterFrom
{
    return self.repository.repoTrack.enterFrom;
}

- (NSInteger)gender {
    return self.repository.repoBeauty.gender;
}

- (void)setGender:(NSInteger)gender {
    self.repository.repoBeauty.gender = gender;
}

- (NSDictionary *)referExtra
{
    return self.repository.repoTrack.referExtra;
}

@end
    
