//
//  AWERepoGameModel.m
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import "AWERepoGameModel.h"
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>

@interface AWEVideoPublishViewModel (AWERepoGame) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (AWERepoGame)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
	ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:AWERepoGameModel.class];
	return info;
}

- (AWERepoGameModel *)repoGame
{
    AWERepoGameModel *gameModel = [self extensionModelOfClass:AWERepoGameModel.class];
    NSAssert(gameModel, @"extension model should not be nil");
    return gameModel;
}

@end

@interface AWERepoGameModel()

@end

@implementation AWERepoGameModel


@end
