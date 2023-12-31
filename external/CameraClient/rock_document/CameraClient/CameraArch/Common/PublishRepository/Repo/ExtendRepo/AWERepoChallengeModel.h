//
//  AWERepoChallengeModel.h
//  CameraClient
//
//  Created by haoyipeng on 2020/10/16.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWERepoChallengeModel : ACCRepoChallengeModel <NSCopying, ACCRepositoryRequestParamsProtocol, ACCRepositoryContextProtocol>

// only for draft
@property (nonatomic, strong, nullable) NSData *challengeJson;
/**
@brief     获取发布页中的所有话题/挑战对应的id号码。Get challengeIDs of the all topics/challenges in the publishmodel.
@details   从allChallengeNameArray修改得到，删除了没有直接暴露的id (mvchallenge)
@return    对应所有挑战编号构成的数组
@retval    NSArray<NSString *> *  allChallengeIDArray
*/
- (NSArray <NSString *> *)allChallengeIdArray;

@end

@interface AWEVideoPublishViewModel (AWERepoChallenge)
 
@property (nonatomic, strong, readonly) AWERepoChallengeModel *repoChallenge;
 
@end

NS_ASSUME_NONNULL_END
