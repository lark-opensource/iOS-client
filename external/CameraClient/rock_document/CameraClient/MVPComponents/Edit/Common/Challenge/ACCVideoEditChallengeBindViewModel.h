//
//  ACCVideoEditChallengeBindViewModel.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/11/5.
//

#import <Foundation/Foundation.h>
#import "ACCEditViewModel.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;
@class RACSignal<__covariant ValueType>;
@protocol ACCChallengeModelProtocol;

@interface ACCVideoEditChallengeBindViewModel : ACCEditViewModel

/// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
/// 管理模块所携带的话题，统一fetch、缓存、计算、更新到发布页的title以及对应的发布参数中
/// @param challenge  challenge name为空会去fetch，目前不会校验ID，所以没有ID的可以直接绑定name例如MV挑战
/// @param moduleKey 模块的标识，用于diff的计算空间以及草稿的恢复key
/// - - - - - - - - -当前模块 - - - - - - - - -
/// 编辑业外：全民任务、道具、MV挑战、商业化挑战
/// 编辑页内：单段变声、多段变声、音乐、信息化贴纸、投票贴纸、歌词贴纸、自定义贴纸、文本朗读、自动字幕
/// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#pragma mark update

/// 将模块当前绑定的话题重置为challenges
- (void)updateCurrentBindChallenges:(NSArray <id<ACCChallengeModelProtocol>> * _Nullable)challenges
                          moduleKey:(NSString *)moduleKey;

/// 将模块当前绑定的话题重置为challengeId
- (void)updateCurrentBindChallengeWithId:(NSString *)challengeId moduleKey:(NSString *)moduleKey;

/// 将要批量更新的时机，如果不是实时更新的可以在这个时机更新当前绑定的话题，如果已经是实时更新的不需要关注，
@property (nonatomic, strong, readonly) RACSignal *willBatchUpdateSignal;

/// 例如剪辑功能会清除编辑页的一些功能，因为大部分都是会去掉 所以采取忽略策略 不需要清除的加key
- (void)addToIgnoreListWhenRemoveAllEditWithModuleKey:(NSString *)moduleKey;

// 在编辑页内动态刷新标题
@property (nonatomic, assign) BOOL alwaysSynchoronizeTitleImmediately;

// 进入编辑页的时候刷新标题
@property (nonatomic, assign) BOOL shouldSynchoronizeTitleWhenAppear;

#pragma mark - cache
/// 获取当前模块绑定的话题，已去重
- (NSArray <id<ACCChallengeModelProtocol>> *_Nullable)currentBindChallegeSetsWithModuleKey:(NSString *)moduleKey;

/// - - - - - - - - - - - -  新增的模块不需要再自己存储话题相关数据，老模块因为考虑到老草稿数据所以暴露了下接口 - - - - - - - - - - - -
@property (nonatomic, strong, readonly) RACSignal <id<ACCChallengeModelProtocol>> *challengeDetailFetchedSignal;
- (void)preFetchChallengeDetailWithChallengeId:(NSString *)challengeId;
- (NSString *_Nullable)cachedChallengeNameWithId:(NSString *)challengeId;

#pragma mark - private life cycle
- (void)setup;
- (void)onAppear;
- (void)syncToTitleImmediately;
- (void)onGotoPublish;
- (void)onDataClearForBackup;
- (void)onRemovedAllEdits;
- (void)updateExtraModulesChallenges:(NSArray <id<ACCChallengeModelProtocol>> * _Nullable)challenges
                           moduleKey:(NSString *)moduleKey;

@end

NS_ASSUME_NONNULL_END
