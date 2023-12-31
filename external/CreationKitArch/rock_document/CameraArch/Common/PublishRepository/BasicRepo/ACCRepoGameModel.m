//
//  ACCRepoGameModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import "ACCRepoGameModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (RepoGame) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoGame)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo
{
    return [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoGameModel.class];
}

- (ACCRepoGameModel *)repoGame
{
    ACCRepoGameModel *gameModel = [self extensionModelOfClass:ACCRepoGameModel.class];
    NSAssert(gameModel, @"extension model should not be nil");
    return gameModel;
}

@end

@interface ACCRepoGameModel()<ACCRepositoryRequestParamsProtocol, ACCRepositoryTrackContextProtocol>

@end

@implementation ACCRepoGameModel

- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoGameModel *model = [[[self class] alloc] init];
    model.gameType = self.gameType;
    model.game2DScore = self.game2DScore;
    return model;
}

#pragma mark - ACCRepositoryRequestParamsProtocol

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel {
    return @{
        @"game_type" : @(self.gameType),
        @"game_score" : @(self.game2DScore),
    };
}

#pragma makr - ACCRepositoryTrackContextProtocol

- (NSDictionary *)acc_errorLogParams
{
    return @{
        @"game_type" : @(self.gameType),
        @"gameScore" : @(self.game2DScore),
    };
}

@end
