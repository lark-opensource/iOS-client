//
//  AWERepoMusicSearchModel.m
//  CameraClient-Pods-Aweme
//
//  Created by bytedance on 2021/8/13.
//

#import "AWERepoMusicSearchModel.h"
#import <CameraClient/AWERepoMusicModel.h>

@interface AWEVideoPublishViewModel (RepoMusicSearch) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoMusicSearch)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoMusicSearchModel.class];
    return info;
}

- (AWERepoMusicSearchModel *)repoMusicSearch {
    AWERepoMusicSearchModel *musicSearchModel = [self extensionModelOfClass:AWERepoMusicSearchModel.class];
    NSAssert(musicSearchModel, @"extension model should not be nil");
    return musicSearchModel;
}


@end


@implementation AWERepoMusicSearchModel

#pragma mark - copying

- (id)copyWithZone:(NSZone *)zone {
    AWERepoMusicSearchModel *model = [[AWERepoMusicSearchModel alloc] init];
    model.searchMusicId = self.searchMusicId;
    model.searchId = self.searchId;
    model.searchResultId = self.searchResultId;
    model.listItemId = self.listItemId;
    model.tokenType = self.tokenType;
    return model;
}

- (NSDictionary *)acc_publishTrackEventParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *paramDict = @{}.mutableCopy;
    if ([publishViewModel.repoMusic.music.musicID isEqualToString:self.searchMusicId]) {
        paramDict[@"search_id"] = self.searchId;
        paramDict[@"search_result_id"] = self.searchResultId;
        paramDict[@"list_item_id"] = self.listItemId;
        paramDict[@"token_type"] = self.tokenType;
    }
    return paramDict;
}


@end
