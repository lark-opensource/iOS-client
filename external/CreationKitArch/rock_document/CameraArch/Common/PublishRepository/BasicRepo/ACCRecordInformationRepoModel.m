//
//  ACCRecordInformationRepoModel.m
//  CameraClient
//
//  Created by haoyipeng on 2020/10/14.
//

#import "ACCRecordInformationRepoModel.h"

#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import "ACCVideoFragmentInfoProtocol.h"
#import "ACCVideoDataProtocol.h"
#import <CreationKitInfra/ACCLogProtocol.h>

@interface ACCRecordInformationRepoModel ()

@property (nonatomic, copy) NSArray<__kindof id<ACCVideoFragmentInfoProtocol>> *recordFragmentInfo;

@end


@interface AWEVideoPublishViewModel (RepoRecordInformation) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoRecordInformation)

#pragma mark - ACCRepositoryElementRegisterCategoryProtocol

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRecordInformationRepoModel.class];
    return info;
}

- (ACCRecordInformationRepoModel *)repoRecordInfo
{
    ACCRecordInformationRepoModel *recordInfoModel = [self extensionModelOfClass:ACCRecordInformationRepoModel.class];
    NSAssert(recordInfoModel, @"extension model should not be nil");
    return recordInfoModel;
}

@end

@implementation ACCRecordInformationRepoModel

@synthesize repository;

- (NSArray *)originalFrameNamesArray
{
    ASSERT_IN_SUB_CLASS
    return @[];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    ACCRecordInformationRepoModel *copy = [[[self class] alloc] init];
    return copy;
}

#pragma mark - Getter

- (NSMutableArray<__kindof id<ACCVideoFragmentInfoProtocol>> *)fragmentInfo
{
    ASSERT_IN_SUB_CLASS
    return @[].mutableCopy;
}

- (NSDictionary *)beautifyTrackInfoDic
{
    ASSERT_IN_SUB_CLASS
    return @{};
}


@end
