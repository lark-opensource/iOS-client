//
//  ACCRepoChallengeBindModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/11/17.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

FOUNDATION_EXTERN NSString * const ACCRepoChallengeBindInfoIdKey;
FOUNDATION_EXTERN NSString * const ACCRepoChallengeBindInfoNameKey;
FOUNDATION_EXTERN NSString * const ACCRepoChallengeBindInfoModuleKey;
FOUNDATION_EXTERN NSString * const ACCRepoChallengeBindInfoOrderIndexKey;

NS_ASSUME_NONNULL_BEGIN

@interface ACCRepoChallengeBindModel : NSObject

#pragma mark - public
- (NSArray <NSString *> *)currentBindChallengeNames;

- (NSArray <NSString *> *)currentBindChallengeIds;

/// 有些从老草稿恢复的并没有经过编辑页处理过则为NO
@property (nonatomic, assign) BOOL didHandleChallengeBind;

// 开拍schema携带的多话题
@property (nonatomic, copy) NSString *challengeIDsFromSchema;
@property (nonatomic, assign) BOOL banAutoAddHashStickers;

#pragma mark - private
@property (nonatomic, copy) NSArray <NSDictionary<NSString *, NSString *> *> *_Nullable currentBindChallengeInfos;
@property (nonatomic, copy) NSArray <NSString *> *_Nullable needRemoveWhenReRecordChallenges;
- (void)markNeedRemoveWhenReRecord;

@end

@interface AWEVideoPublishViewModel (RepoChallengeBind)
 
@property (nonatomic, strong, readonly) ACCRepoChallengeBindModel *repoChallengeBind;
 
@end


NS_ASSUME_NONNULL_END
