//
//  ACCVideoEditChallengeBindViewModel.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/11/5.
//

#import "ACCVideoEditChallengeBindViewModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreativeKit/ACCMacros.h>
#import <ReactiveObjC/RACSignal.h>
#import <ReactiveObjC/RACSubject.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import "ACCChallengeNetServiceProtocol.h"
#import <CreationKitArch/ACCChallengeModelProtocol.h>
#import "ACCRepoChallengeBindModel.h"
#import <CreationKitArch/ACCModelFactoryServiceProtocol.h>
#import "AWEVideoPublishViewModel+PublishTitleHandler.h"
#import "ACCVideoEditChallengeBindViewModel+ACCExtraModuleHandler.h"
#import <CreativeKit/ACCServiceLocator.h>
#import <CreationKitArch/ACCRepoDraftModel.h>

#define p_checkModuleKeyAndReturnIfEmpty \
if (ACC_isEmptyString(moduleKey)) { \
    NSAssert(NO, @"Invalid parameter : moduleKey"); \
    return; \
}

static NSInteger const kExtraModuleOrderIndex = -1;

NS_INLINE NSComparisonResult p_orderResultWithTargets(NSInteger firstIndex, NSInteger secondIndex)
{
    if (firstIndex > secondIndex) {
        return NSOrderedDescending;
    } else if (firstIndex < secondIndex) {
        return NSOrderedAscending;
    } else {
        return NSOrderedSame;
    }
}

@interface ACCChallengeModelUtil : NSObject

+ (NSInteger)p_orderIndexForChallenge:(id<ACCChallengeModelProtocol>)challenge;
+ (void)p_setOrderIndex:(NSInteger)p_orderIndex forChallenge:(id<ACCChallengeModelProtocol>)challenge;
+ (BOOL)p_isChallenge:(id<ACCChallengeModelProtocol>)challenge equal2Other:(id<ACCChallengeModelProtocol>)target; // 相同ID和name的视为同一个话题
+ (BOOL)p_isBothIdAndNameEmpty:(id<ACCChallengeModelProtocol>)challenge;
+ (NSDictionary *)p_convertToDraftChallenge:(id<ACCChallengeModelProtocol>)challenge withModuleKey:(NSString *)moduleKey;

@end

@interface NSArray(ChallengeBind)

- (void)p_performFillDetailFromTarget:(id<ACCChallengeModelProtocol>)result;
- (BOOL)p_containEqualChallenge:(id<ACCChallengeModelProtocol>)target;
- (id<ACCChallengeModelProtocol>)p_getFirstEqualChallenge:(id<ACCChallengeModelProtocol>)target;
- (NSArray <id<ACCChallengeModelProtocol>> *)p_challengeSets;
- (NSArray <NSString *> *)p_challengeNameSets;
- (NSArray <id<ACCChallengeModelProtocol>> *)p_ascendingList; // 按照orderIndex升序

@end

@interface NSMutableArray(ChallengeBind)

- (void)p_mergeFromChallenges:(NSArray <id<ACCChallengeModelProtocol>> *)challenges; // 已经存在不会重复增加

@end

@interface ACCChallengeBindWrapModel : NSObject

- (instancetype)initWithModuleKey:(NSString *)moduleKey;
@property (nonatomic, copy, readonly) NSString *moduleKey;

- (void)markSyncedToTitle; // 已经更新diff到标题
- (void)markAllNeedDelete;
- (void)updateCurrentBindChallenges:(NSArray <id<ACCChallengeModelProtocol>> *)challenges;

// 待删除的话题diff
@property (nonatomic, strong, readonly) NSArray <id<ACCChallengeModelProtocol>> *needDeleteChallenges;
@property (nonatomic, strong, readonly) NSArray <id<ACCChallengeModelProtocol>> *currentBindChallenges;

@end

@interface ACCVideoEditChallengeBindViewModel ()

#pragma mark - container
@property (nonatomic, strong) NSMutableDictionary <NSString *, ACCChallengeBindWrapModel *> *moduleChallengeBindMaping;
@property (nonatomic, strong) NSMutableArray <NSString *> *removeAllEditIgnoreList;

@property (nonatomic, strong) NSMutableDictionary <NSString *, NSString *> *challengeNameCache;
@property (nonatomic, strong) NSMutableSet <NSString *> *fetchingChallengeIds;

#pragma mark -
@property (nonatomic, strong) RACSubject<id<ACCChallengeModelProtocol>> *challengeDetailFetchedSubject;
@property (nonatomic, strong) RACSubject *willBatchUpdateSubject;

@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;

#pragma mark - flag
@property (nonatomic, assign) NSInteger currentOrderIndex;

@property (nonatomic, assign) BOOL didCleared;
@property (nonatomic, assign) BOOL didSetup;
// appear过才需要同步到title，一方面避开首帧，一方面从草稿回复到发布页本身不需要去更新标题
@property (nonatomic, assign) BOOL readyToSync;

@property (nonatomic, assign) BOOL batchUpdating;

@end


@implementation ACCVideoEditChallengeBindViewModel
IESAutoInject(ACCBaseServiceProvider(), videoConfig, ACCVideoConfigProtocol)

- (instancetype)init
{
    self = [super init];
    if (self) {
        _shouldSynchoronizeTitleWhenAppear = YES;
    }
    return self;
}

#pragma mark - public handler
- (void)updateCurrentBindChallengeWithId:(NSString *)challengeId moduleKey:(NSString *)moduleKey
{
    id<ACCChallengeModelProtocol> challenge = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeId challengeName:nil];
    if (challenge) {
        [self updateCurrentBindChallenges:@[challenge] moduleKey:moduleKey];
    }
}

- (void)updateCurrentBindChallenges:(NSArray<id<ACCChallengeModelProtocol>> *)challenges
                          moduleKey:(NSString *)moduleKey
{
    [self updateCurrentBindChallenges:challenges moduleKey:moduleKey isExtraModule:NO isRecoverMode:NO];
}

- (void)updateExtraModulesChallenges:(NSArray<id<ACCChallengeModelProtocol>> *)challenges moduleKey:(NSString *)moduleKey
{
    [self updateCurrentBindChallenges:challenges moduleKey:moduleKey isExtraModule:YES isRecoverMode:NO];
}

- (void)updateCurrentBindChallenges:(NSArray<id<ACCChallengeModelProtocol>> *)challenges
                          moduleKey:(NSString *)moduleKey
                      isExtraModule:(BOOL)isExtraModule
                      isRecoverMode:(BOOL)isRecoverMode
{
    p_checkModuleKeyAndReturnIfEmpty;
    
    if (isExtraModule) {
        [self addToIgnoreListWhenRemoveAllEditWithModuleKey:moduleKey];
    }
    
    if (!self.didSetup) {
        [self setup];
    }
    
    [self p_addCacheFromChallenges:challenges];

    ACCChallengeBindWrapModel *wrapModel = self.moduleChallengeBindMaping[moduleKey];
    if (!wrapModel) {
        wrapModel = [[ACCChallengeBindWrapModel alloc] initWithModuleKey:moduleKey];
        self.moduleChallengeBindMaping[moduleKey] = wrapModel;
    }
    
    if (!isRecoverMode) {
        [[challenges copy] enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (isExtraModule) {
                // PM已确认 : 编辑页外带进来的都排到最前面,所以不需要order
                [ACCChallengeModelUtil p_setOrderIndex:kExtraModuleOrderIndex forChallenge:obj];
            } else {
                id<ACCChallengeModelProtocol> exitEqualChallenge = [wrapModel.currentBindChallenges p_getFirstEqualChallenge:obj];
                if (exitEqualChallenge) {
                    [ACCChallengeModelUtil p_setOrderIndex:[ACCChallengeModelUtil p_orderIndexForChallenge:exitEqualChallenge] forChallenge:obj];
                } else {
                    // PM已确认，新增会加到后面，但已有的不会改变顺序
                    [ACCChallengeModelUtil p_setOrderIndex:(++self.currentOrderIndex) forChallenge:obj];
                }
            }
        }];
    }
    
    [wrapModel updateCurrentBindChallenges:challenges];
    
    [self p_fetchChallengeDetailsIfNeedWithChallenges:challenges needDoSyncWhenFinished:YES];
    
    if (!isRecoverMode) {
        [self syncToTitleIfNeed];
    }
}

- (void)addToIgnoreListWhenRemoveAllEditWithModuleKey:(NSString *)moduleKey
{
    p_checkModuleKeyAndReturnIfEmpty
    [self.removeAllEditIgnoreList addObject:moduleKey];
}

#pragma mark - private life cycle
- (void)setup
{
    if (self.didSetup) {
        return;
    }
    self.didSetup = YES;
    [[self publishModel] syncMentionUserToTitleIfNeed];
    [self p_recoverChallengeBindFromDraft];
    [self updateExtraModulesChallengeIfNeed];
}

- (void)onAppear
{
    if (self.shouldSynchoronizeTitleWhenAppear) {
        self.shouldSynchoronizeTitleWhenAppear = NO;
        self.readyToSync = YES;
        [self syncToTitleIfNeed];
    }
}

- (void)onGotoPublish
{
    if (self.alwaysSynchoronizeTitleImmediately) {
        return;
    }
    self.batchUpdating = YES;
    /// 理论上外部带入的不会变 保险起见更新下diff
    [self updateExtraModulesChallengeIfNeed];
    [self.willBatchUpdateSubject sendNext:nil];
    [self syncToTitleImmediately];
    self.batchUpdating = NO;
}

- (void)onDataClearForBackup
{
    [self.moduleChallengeBindMaping.allValues enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj markAllNeedDelete];
    }];
    [self syncToTitleImmediately];
}

- (void)dealloc
{
    self.didCleared = YES;
    [self.challengeDetailFetchedSubject sendCompleted];
    [self.willBatchUpdateSubject sendCompleted];
}

- (void)syncToTitleIfNeed
{
    if (!self.batchUpdating && self.readyToSync) {
        // 极速版实验组 V2 投稿链路三变二
        if (self.alwaysSynchoronizeTitleImmediately) {
            [self syncToTitleImmediately];
        }
    }
}

#pragma mark - private handler
- (void)syncToTitleImmediately
{
    
    NSArray <id<ACCChallengeModelProtocol>> *currentBindChallenges = [self p_currentBindChallenges];
    
    NSArray <NSString *> *needRemoveChallengeNames = [self p_currentNeedDeleteChallengeNames];
    
    // 重置diff
    [self.moduleChallengeBindMaping.allValues enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj markSyncedToTitle];
    }];
    
    // PM已确认:不是按照模块排序 而是新加的放后面 所以做一次排序后再取出
    NSArray <NSString *> *currentBindChallengeNames = [[currentBindChallenges p_ascendingList] p_challengeNameSets];
    NSInteger publishMaxTitleLength = self.videoConfig.publishMaxTitleLength;
    
    // -------- publish model  sync begin --------
    [[self publishModel] removeChallengesFromTitleWithNames:needRemoveChallengeNames];
    [[self publishModel] appendChallengesToTitleWithNames:currentBindChallengeNames maxTitleLength:publishMaxTitleLength];
    [[self publishModel] syncTitleChallengeInfosToTitleExtraInfo];
    // -------- publish model  sync end   --------
    
    [self p_syncCurrentBindChallengeInfosToDraft];
}

- (void)onRemovedAllEdits
{
    [self.moduleChallengeBindMaping.allValues enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![self.removeAllEditIgnoreList containsObject:obj.moduleKey]) {
            [obj markAllNeedDelete];
        }
    }];
    [self syncToTitleIfNeed];
}

#pragma mark - challenge detail handler
- (void)preFetchChallengeDetailWithChallengeId:(NSString *)challengeId
{
    if (ACC_isEmptyString(challengeId)) {
        return;
    }
    
    if (!ACC_isEmptyString([self cachedChallengeNameWithId:challengeId])) {
        return;
    }
    
    id<ACCChallengeModelProtocol> challenge = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:challengeId challengeName:nil];
    if (challenge) {
        [self p_fetchChallengeDetailIfNeedWithChallenge:challenge needDoSyncWhenFinished:NO];
    }
}

- (NSString *)cachedChallengeNameWithId:(NSString *)challengeId
{
    if (ACC_isEmptyString(challengeId)) {
        return nil;
    }
    return self.challengeNameCache[challengeId];
}

- (void)addChallengeCacheWithName:(NSString *)challengeName challengeId:(NSString *)challengeId
{
    if (!ACC_isEmptyString(challengeName) && !ACC_isEmptyString(challengeId)) {
        if (ACC_isEmptyString([self cachedChallengeNameWithId:challengeId])) {
            self.challengeNameCache[challengeId] = challengeName;
        }
    }
}

- (void)p_addCacheFromChallenges:(nonnull NSArray<id<ACCChallengeModelProtocol>> *)challenges
{
    [[challenges copy] enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addChallengeCacheWithName:obj.challengeName challengeId:obj.itemID];
    }];
}

- (void)p_fetchChallengeDetailsIfNeedWithChallenges:(NSArray<id<ACCChallengeModelProtocol>> *)challenges
                             needDoSyncWhenFinished:(BOOL)needDoSyncWhenFinished
{
    [[challenges copy] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [self p_fetchChallengeDetailIfNeedWithChallenge:obj needDoSyncWhenFinished:needDoSyncWhenFinished];
    }];
}

- (void)p_fetchChallengeDetailIfNeedWithChallenge:(id<ACCChallengeModelProtocol>)challenge needDoSyncWhenFinished:(BOOL)needDoSyncWhenFinished
{
    if (ACC_isEmptyString(challenge.itemID) || !ACC_isEmptyString(challenge.challengeName)) {
        return;
    }
    
    if (self.challengeNameCache[challenge.itemID]) {
        challenge.challengeName = self.challengeNameCache[challenge.itemID];
        [self p_performFillDetailFromTarget:challenge needDoSyncWhenFinished:NO];
        return;
    }
    
    if ([self.fetchingChallengeIds containsObject:challenge.itemID]) {
        return;
    }
    
    NSString *itemID = challenge.itemID;
    
    [self.fetchingChallengeIds addObject:itemID];

    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCChallengeNetServiceProtocol) requestChallengeItemWithID:challenge.itemID completion:^(id<ACCChallengeModelProtocol> _Nullable model, NSError * _Nullable error) {
        @strongify(self);
        if (self.didCleared || ACC_isEmptyString(model.challengeName)) {
            return;
        }
        model.itemID = itemID;
        challenge.challengeName = model.challengeName;
        [self addChallengeCacheWithName:model.challengeName challengeId:itemID];
        [self p_performFillDetailFromTarget:model needDoSyncWhenFinished:needDoSyncWhenFinished];
        [self.fetchingChallengeIds removeObject:itemID];
    }];
}

- (void)p_performFillDetailFromTarget:(id<ACCChallengeModelProtocol>)result needDoSyncWhenFinished:(BOOL)needDoSyncWhenFinished
{
    [self.challengeDetailFetchedSubject sendNext:result];
    
    [[self.moduleChallengeBindMaping allValues] enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.currentBindChallenges p_performFillDetailFromTarget:result];
        [obj.needDeleteChallenges p_performFillDetailFromTarget:result];
    }];
    
    if (needDoSyncWhenFinished) {
        [self syncToTitleIfNeed];
    }
}

#pragma mark -  getter
- (NSArray<id<ACCChallengeModelProtocol>> *)currentBindChallegeSetsWithModuleKey:(NSString *)moduleKey
{
    if (ACC_isEmptyString(moduleKey)) {
        return nil;
    }
    return [self.moduleChallengeBindMaping[moduleKey].currentBindChallenges p_challengeSets];
}

- (NSArray <NSString *> *)currentBindChallengeNames
{
    return [[[self p_currentBindChallenges] p_ascendingList] p_challengeNameSets];
}

- (NSArray <id<ACCChallengeModelProtocol>> *)p_currentBindChallenges
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *ret = [NSMutableArray array];
    [[self.moduleChallengeBindMaping allValues] enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [ret p_mergeFromChallenges:obj.currentBindChallenges];
    }];
    return [ret p_challengeSets];
}

- (NSArray <NSString *> *)p_currentNeedDeleteChallengeNames
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *allDiff = [NSMutableArray array];
    NSArray <id<ACCChallengeModelProtocol>> *currentBindChallenges = [self p_currentBindChallenges];
    NSArray <NSString *> *currentBindChallengeNames = [currentBindChallenges p_challengeNameSets];
    
    [[self.moduleChallengeBindMaping allValues] enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [allDiff p_mergeFromChallenges:obj.needDeleteChallenges];
    }];
    
    NSMutableArray <id<ACCChallengeModelProtocol>> *needDeleteChallenges = [NSMutableArray array];
    
    // 引用计数 : 有任意模块 包括自身模块还在引用的说明不需要删除
    [[allDiff copy] enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![currentBindChallenges p_containEqualChallenge:obj]) {
            [needDeleteChallenges addObject:obj];
        }
    }];
    
    NSMutableSet <NSString *> *ret = [NSMutableSet set];
    [ret addObjectsFromArray:[needDeleteChallenges p_challengeNameSets]];
    
    NSArray <NSString *> *needRemoveWhenReRecordChallenges = [self publishModel].repoChallengeBind.needRemoveWhenReRecordChallenges;
    
    if (!ACC_isEmptyArray(needRemoveWhenReRecordChallenges)) {
        [self publishModel].repoChallengeBind.needRemoveWhenReRecordChallenges = nil;
        [needRemoveWhenReRecordChallenges enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            // 草稿恢复从拍摄页重新拍摄的 如果现在没绑定了 需要删掉
            if (![currentBindChallengeNames containsObject:obj]) {
                [ret addObject:obj];
            }
        }];
    }
    
    return [ret allObjects];
}

#pragma mark - draft handler
- (void)p_syncCurrentBindChallengeInfosToDraft
{
    ACCRepoChallengeBindModel *repoChallengeBindModel = [self publishModel].repoChallengeBind;
    
    NSMutableArray <NSDictionary<NSString *, NSString *> *> *challengesInfo = [NSMutableArray array];
    
    [self.moduleChallengeBindMaping.allValues enumerateObjectsUsingBlock:^(ACCChallengeBindWrapModel * _Nonnull wrapModel, NSUInteger idx, BOOL * _Nonnull stop) {
        [wrapModel.currentBindChallenges enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [challengesInfo addObject:[ACCChallengeModelUtil p_convertToDraftChallenge:obj withModuleKey:wrapModel.moduleKey]];
        }];
    }];
    
    [challengesInfo sortUsingComparator:^NSComparisonResult(NSDictionary<NSString *, NSString *> * obj1, NSDictionary<NSString *, NSString *> *obj2) {
        NSInteger orderIndex1 = [obj1[ACCRepoChallengeBindInfoOrderIndexKey] integerValue];
        NSInteger orderIndex2 = [obj2[ACCRepoChallengeBindInfoOrderIndexKey] integerValue];
        return p_orderResultWithTargets(orderIndex1, orderIndex2);
    }];
    
    repoChallengeBindModel.currentBindChallengeInfos = [challengesInfo copy];
    repoChallengeBindModel.didHandleChallengeBind = YES;
}

- (void)p_recoverChallengeBindFromDraft
{
    if (![self publishModel].repoDraft.isDraft) {
        return;
    }
    
    ACCRepoChallengeBindModel *repoChallengeBindModel = [self publishModel].repoChallengeBind;
    NSMutableDictionary <NSString *, NSMutableArray <id<ACCChallengeModelProtocol>> *> *moduleBindMapping = [NSMutableDictionary dictionary];
    
    [[repoChallengeBindModel.currentBindChallengeInfos copy] enumerateObjectsUsingBlock:^(NSDictionary<NSString *, NSString *> * _Nonnull info, NSUInteger idx, BOOL * _Nonnull stop) {
 
        NSString *moduleKey = info[ACCRepoChallengeBindInfoModuleKey];
        
        if (!ACC_isEmptyString(moduleKey)) {
            id<ACCChallengeModelProtocol> challenge = [IESAutoInline(self.serviceProvider, ACCModelFactoryServiceProtocol) createChallengeModelWithItemID:info[ACCRepoChallengeBindInfoIdKey] challengeName:info[ACCRepoChallengeBindInfoNameKey]];
            if (challenge) {
                [ACCChallengeModelUtil p_setOrderIndex:[info[ACCRepoChallengeBindInfoOrderIndexKey] integerValue] forChallenge:challenge];
                
                NSMutableArray <id<ACCChallengeModelProtocol>> *challenges = moduleBindMapping[moduleKey];
                if (!challenges) {
                    challenges = [NSMutableArray array];
                }
                [challenges addObject:challenge];
                moduleBindMapping[moduleKey] = challenges;
            }
        }
    }];
    
    self.batchUpdating = YES;
    [moduleBindMapping enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSMutableArray<id<ACCChallengeModelProtocol>> * _Nonnull challenges, BOOL * _Nonnull stop) {
        // 如果模块提前已经set了 那不需要从本地取了
        if (!self.moduleChallengeBindMaping[key]) {
            [self updateCurrentBindChallenges:[challenges copy] moduleKey:key isExtraModule:NO isRecoverMode:YES];
        }
    }];
    self.batchUpdating = NO;
}

#pragma mark - lazy getter
- (AWEVideoPublishViewModel *)publishModel
{
    return self.inputData.publishModel;
}

- (RACSubject<id<ACCChallengeModelProtocol>> *)challengeDetailFetchedSubject
{
    if (!_challengeDetailFetchedSubject) {
        _challengeDetailFetchedSubject = [RACSubject subject];
    }
    return _challengeDetailFetchedSubject;
}

- (RACSignal<id<ACCChallengeModelProtocol>> *)challengeDetailFetchedSignal
{
    return self.challengeDetailFetchedSubject;
}

- (RACSubject *)willBatchUpdateSubject
{
    if (!_willBatchUpdateSubject) {
        _willBatchUpdateSubject = [RACSubject subject];
    }
    return _willBatchUpdateSubject;;
}

- (RACSignal *)willBatchUpdateSignal
{
    return self.willBatchUpdateSubject;
}

- (NSMutableDictionary<NSString *, ACCChallengeBindWrapModel *> *)moduleChallengeBindMaping
{
    if (!_moduleChallengeBindMaping) {
        _moduleChallengeBindMaping = [NSMutableDictionary dictionary];
    }
    return _moduleChallengeBindMaping;
}

- (NSMutableDictionary<NSString *,NSString *> *)challengeNameCache
{
    if (!_challengeNameCache) {
        _challengeNameCache = [NSMutableDictionary dictionary];
    }
    return _challengeNameCache;
}

- (NSMutableSet<NSString *> *)fetchingChallengeIds
{
    if (!_fetchingChallengeIds) {
        _fetchingChallengeIds = [NSMutableSet set];
    }
    return _fetchingChallengeIds;
}

- (NSMutableArray<NSString *> *)removeAllEditIgnoreList
{
    if (!_removeAllEditIgnoreList) {
        _removeAllEditIgnoreList = [NSMutableArray array];
    }
    return _removeAllEditIgnoreList;
}

@end

#pragma mark - ACCChallengeBindWrapModel
@implementation ACCChallengeBindWrapModel

- (instancetype)initWithModuleKey:(NSString *)moduleKey
{
    if (self = [super init]) {
        _moduleKey = moduleKey;
    }
    return self;
}

- (void)markSyncedToTitle
{
    _needDeleteChallenges = nil;
}

- (void)markAllNeedDelete
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *deletedDiff = [NSMutableArray array];
    [deletedDiff p_mergeFromChallenges:self.needDeleteChallenges];
    [deletedDiff p_mergeFromChallenges:self.currentBindChallenges];
    _needDeleteChallenges = [deletedDiff copy];
    _currentBindChallenges = nil;
}

- (void)updateCurrentBindChallenges:(NSArray<id<ACCChallengeModelProtocol>> *)challenges
{
    challenges = [challenges p_challengeSets];
    
    NSArray <id<ACCChallengeModelProtocol>> *currentbindChallenges = [self.currentBindChallenges copy];
    NSMutableArray <id<ACCChallengeModelProtocol>> *deletedDiff = [NSMutableArray array];
    
    // 计算删除的diff
    [currentbindChallenges enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![challenges p_containEqualChallenge:obj]) {
            [deletedDiff addObject:obj];
        }
    }];
    
    [deletedDiff p_mergeFromChallenges:self.needDeleteChallenges];
    _needDeleteChallenges = [deletedDiff copy];
    
    _currentBindChallenges = [challenges copy];
}

@end

#pragma mark - ACCChallengeModel cate
@implementation ACCChallengeModelUtil

+ (BOOL)p_isChallenge:(id<ACCChallengeModelProtocol>)challenge equal2Other:(id<ACCChallengeModelProtocol>)target
{
    if (![target conformsToProtocol:@protocol(ACCChallengeModelProtocol)]) {
        return NO;
    }
    
    return ([challenge.itemID isEqualToString:target.itemID] ||
            [challenge.challengeName isEqualToString:target.challengeName]);
}

+ (BOOL)p_isBothIdAndNameEmpty:(id<ACCChallengeModelProtocol>)challenge
{
    return ACC_isEmptyString(challenge.challengeName) && ACC_isEmptyString(challenge.itemID);
}

+ (NSInteger)p_orderIndexForChallenge:(id<ACCChallengeModelProtocol>)challenge
{
    NSNumber *indexNum = objc_getAssociatedObject(challenge, @selector(p_orderIndexForChallenge:));
    if (indexNum == nil) {
        return kExtraModuleOrderIndex;
    }
    return [indexNum integerValue];
}

+ (void)p_setOrderIndex:(NSInteger)p_orderIndex forChallenge:(id<ACCChallengeModelProtocol>)challenge
{
    objc_setAssociatedObject(challenge, @selector(p_orderIndexForChallenge:), @(p_orderIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (NSDictionary <NSString *, NSString *> *)p_convertToDraftChallenge:(id<ACCChallengeModelProtocol>)challenge withModuleKey:(NSString *)moduleKey
{
    return @{
        ACCRepoChallengeBindInfoIdKey : challenge.itemID ?: @"",
        ACCRepoChallengeBindInfoNameKey : challenge.challengeName ?: @"",
        ACCRepoChallengeBindInfoModuleKey : moduleKey ?: @"",
        ACCRepoChallengeBindInfoOrderIndexKey : [NSString stringWithFormat:@"%li", (long)[ACCChallengeModelUtil p_orderIndexForChallenge:challenge]]
    };
}

@end

#pragma mark - NSArray cate
@implementation NSArray(ChallengeBind)

- (BOOL)p_containEqualChallenge:(id<ACCChallengeModelProtocol>)target
{
    return [self p_getFirstEqualChallenge:target] != nil;
}

- (id<ACCChallengeModelProtocol>)p_getFirstEqualChallenge:(id<ACCChallengeModelProtocol>)target
{
    for (id obj in [self copy]) {
        if ([ACCChallengeModelUtil p_isChallenge:target equal2Other:obj]) {
            return obj;
        }
    }
    return nil;
}

- (void)p_performFillDetailFromTarget:(id<ACCChallengeModelProtocol>)target
{
    if (ACC_isEmptyString(target.challengeName)) {
        return;
    }
    [[self copy] enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if ([ACCChallengeModelUtil p_isChallenge:obj equal2Other:target]) {
            obj.challengeName = target.challengeName;
        }
    }];
}

- (NSArray<NSString *> *)p_challengeNameSets
{
    NSArray <id<ACCChallengeModelProtocol>> *valildChallenges = [self p_challengeSets];
    NSMutableArray <NSString *> *ret = [NSMutableArray array];
    [valildChallenges enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString(obj.challengeName) && ![ret containsObject:obj.challengeName]) {
            [ret addObject:obj.challengeName];
        }
    }];
    return [ret copy];
}

- (NSArray<id<ACCChallengeModelProtocol>> *)p_challengeSets
{
    NSMutableArray <id<ACCChallengeModelProtocol>> *ret = [NSMutableArray array];
    // 去重不需要倒序
    [[self copy] enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj conformsToProtocol:@protocol(ACCChallengeModelProtocol)] &&
            ![ACCChallengeModelUtil p_isBothIdAndNameEmpty:obj] &&
            ![ret p_containEqualChallenge:obj]) {
            [ret addObject:obj];
        }
    }];
    
    return [ret copy];
}

- (NSArray<id<ACCChallengeModelProtocol>> *)p_ascendingList
{
    return [[self copy] sortedArrayUsingComparator:^NSComparisonResult(id<ACCChallengeModelProtocol> _Nonnull obj1, id<ACCChallengeModelProtocol> _Nonnull obj2) {
        return p_orderResultWithTargets([ACCChallengeModelUtil p_orderIndexForChallenge:obj1], [ACCChallengeModelUtil p_orderIndexForChallenge:obj2]);
    }];
}

@end

@implementation NSMutableArray(ChallengeBind)

- (void)p_mergeFromChallenges:(NSArray<id<ACCChallengeModelProtocol>> *)challenges
{
    [[challenges copy] enumerateObjectsUsingBlock:^(id<ACCChallengeModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![ACCChallengeModelUtil p_isBothIdAndNameEmpty:obj] && ![self p_containEqualChallenge:obj]) {
            [self addObject:obj];
        }
    }];
}

@end
