//
//  AWERepoGameModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import <CreationKitArch/ACCRepoGameModel.h>


NS_ASSUME_NONNULL_BEGIN

@interface AWERepoGameModel : ACCRepoGameModel

@property (nonatomic, assign) BOOL publishBackToGame;

@end

@interface AWEVideoPublishViewModel (AWERepoGame)
 
@property (nonatomic, strong, readonly) AWERepoGameModel *repoGame;
 
@end

NS_ASSUME_NONNULL_END
