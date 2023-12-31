//
//  ACCRepoChallengeModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCChallengeModelProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoChallengeModel : NSObject <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol, ACCRepositoryTrackContextProtocol>

@property (nonatomic, strong) id<ACCChallengeModelProtocol> challenge;

- (NSArray <NSString *> *)allChallengeNameArray;

@end

@interface AWEVideoPublishViewModel (RepoChallenge)
 
@property (nonatomic, strong, readonly) ACCRepoChallengeModel *repoChallenge;
 
@end

NS_ASSUME_NONNULL_END
