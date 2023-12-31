//
//  ACCRepoPublishConfigModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/21.
//

#import "ACCRepoPublishConfigModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>

@interface AWEVideoPublishViewModel (RepoPublishConfig) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoPublishConfig)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoPublishConfigModel.class];
    return info;
}


- (ACCRepoPublishConfigModel *)repoPublishConfig
{
    ACCRepoPublishConfigModel *publishConfigModel = [self extensionModelOfClass:ACCRepoPublishConfigModel.class];
    NSAssert(publishConfigModel, @"extension model should not be nil");
    return publishConfigModel;
}

@end

@interface ACCRepoPublishConfigModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol, ACCRepositoryContextProtocol>

@end

@implementation ACCRepoPublishConfigModel

@synthesize repository;

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoPublishConfigModel *model = [[[self class] alloc] init];
    model.publishTitle = self.publishTitle;
    model.saveToAlbum = self.saveToAlbum;
    model.isHashTag = self.isHashTag;
    model.dynamicCoverStartTime = self.dynamicCoverStartTime;
    model.hotSpotWord = self.hotSpotWord;
    model.coverImage = self.coverImage;
    model.firstFrameImage = self.firstFrameImage;
    model.tosCoverURI = self.tosCoverURI;
    model.coverTextImage = self.coverTextImage;
    model.coverTextModel = self.coverTextModel;
    model.saveToAlbum = self.saveToAlbum;
    
    // deep copy titleExtraInfo to isolate modifications
    NSMutableArray *extraArray = [NSMutableArray array];
    for (id<ACCTextExtraProtocol, NSCopying> extra in self.titleExtraInfo) {
        [extraArray addObject:[extra copyWithZone:zone]];
    }
    model.titleExtraInfo = extraArray.copy;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    return @{};
}

#pragma mark - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams
{
    return @{
        @"title":self.publishTitle?:@"",
    };
}

@end
