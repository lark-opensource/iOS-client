//
//  ACCRepoGameModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCAwemeModelProtocol.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoGameModel : NSObject <NSCopying>

@property (nonatomic, assign) ACCGameType gameType;
@property (nonatomic, assign) NSInteger game2DScore;

@end

@interface AWEVideoPublishViewModel (RepoGame)
 
@property (nonatomic, strong, readonly) ACCRepoGameModel *repoGame;
 
@end

NS_ASSUME_NONNULL_END
