//
//  AWEStickerDataManager.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/4/13.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEStickerDataManager.h"
#import <CreativeKit/ACCMonitorProtocol.h>

#import <CreationKitArch/AWEStudioMeasureManager.h>
#import <CreationKitArch/AWEStickerMusicManager.h>
#import "ACCVideoMusicProtocol.h"
#import "ACCStudioGlobalConfig.h"

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import "AWEStickerMusicManager+Local.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import <CreationKitInfra/ACCGroupedPredicate.h>

static NSInteger const StickerPageCount = 0;
static NSString * const kStickerDataManagerTaskErrorDomain = @"com.aweme.sticker";

typedef void(^FetchStickersSuccessBlockForPaging)(BOOL success, NSInteger index);

@interface AWEStickerDataManager ()

@property (nonatomic, strong) IESEffectPlatformResponseModel *response;
@property (nonatomic, strong) IESEffectPlatformNewResponseModel *responseNew;

/// 收藏的道具特效
@property (nonatomic, strong) NSMutableArray<IESEffectModel *> *p_collectionEffects;
@property (nonatomic, assign) BOOL isRequestOnAir;
@property (nonatomic, assign) BOOL needUpdate;
@property (nonatomic, strong, readwrite) NSMutableSet *updatedCategoriesSet;
@property (nonatomic, strong) NSMutableArray *comletionArray;
@property (nonatomic, strong) NSMutableDictionary *comletionDictionary;     //分页加载
@property (nonatomic, readwrite) NSDictionary<NSString *, NSArray<IESEffectModel *> *> *collectionEffectDict;
@property (nonatomic, copy) NSArray<IESCategoryModel *> *stickerCategories;
/** 新版道具UI面板新加参数，因为新的接口不支持一次获取全部分类下的数据，所以采用请求所有分类接口的方式去拼接数据 */
/// 分类并发控制的group
@property (nonatomic, strong) dispatch_group_t categoryReqGroup;
@property (nonatomic, strong) dispatch_queue_t categoryReqQueue;
/// 用来记录对应的分类请求重试的次数
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *categoryReqRetryTimesDic;

/* 预加载数据 **/
@property (nonatomic, copy) NSString *preCateKey;
@property (nonatomic, strong) IESEffectPlatformNewResponseModel *preFetchResponse;

@property (nonatomic, assign) BOOL hasPreFetched;
@property (nonatomic, copy) void(^preFetchCategoriesCompletion)(BOOL success);

// 关联特效 https://bytedance.feishu.cn/docs/doccnINR7CbXJmHxAadUxfOul2c
@property (nonatomic, strong) NSMutableDictionary<NSString*, IESEffectModel*> *bindEffectsMap;

// 因为收藏列表接口和普通 Tab 接口的数据格式不一样，所以需要区分处理 bindEffect 的存储
// 存在收藏列表中道具特效的绑定特效
@property (nonatomic, strong) NSMutableArray<IESEffectModel*> *favorviteBindEffects;
@property (nonatomic) dispatch_block_t configExtraParamsBlock;

@end

@implementation AWEStickerDataManager

@synthesize needFilterEffect = _needFilterEffect;

- (void)dealloc {
    AWELogToolDebug(AWELogToolTagRecord, @"%@ dealloc",[self class]);
}

- (instancetype)initWithPanelType:(AWEStickerPanelType)panelType configExtraParamsBlock:(dispatch_block_t)configExtraParamsBlock
{
    self = [super init];
    if (self) {
        _configExtraParamsBlock = configExtraParamsBlock;
        _panelType = panelType;
        // TODO: 这2个对象的初始化是否可以去掉? 只是通过 KVO 赋值一个空数组
        _response = [self p_configPresetModel];
        _responseNew = [self p_configNewPresetModel];
        _needUpdate = YES;
        _updatedCategoriesSet = [NSMutableSet new];
        _comletionArray = @[].mutableCopy;
        _comletionDictionary = [NSMutableDictionary dictionary];
        _categoryReqGroup = dispatch_group_create();
        _categoryReqQueue = dispatch_queue_create("com.AWEStudio.queue.dataManager.categoryReq", DISPATCH_QUEUE_CONCURRENT);
        _categoryReqRetryTimesDic = [NSMutableDictionary new];
        _bindEffectsMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (NSString *)panelName
{
    return  [self getPanelNameForType:self.panelType];
}

- (IESEffectPlatformResponseModel *)p_configPresetModel
{
    IESEffectPlatformResponseModel *responseModel = [[IESEffectPlatformResponseModel alloc] init];
    NSArray <IESCategoryModel *> *category = @[];
    [responseModel setValue:category forKey:@"categories"];
    return responseModel;
}

- (IESEffectPlatformNewResponseModel *)p_configNewPresetModel
{
    IESEffectPlatformNewResponseModel *responseModel = [[IESEffectPlatformNewResponseModel alloc] init];
    NSArray <IESCategoryModel *> *category = @[];
    [responseModel setValue:category forKey:@"categories"];
    return responseModel;
}

- (void)downloadRecordStickerWithCompletion:(void(^)(BOOL downloadSuccess))completion
{
    if (!self.needUpdate) {
        ACCBLOCK_INVOKE(completion, YES);
        return;
    }
    
    if (completion) {
        [self.comletionArray addObject:completion];
    }
    
    void(^completionWrapper)(BOOL downloadSuccess) = ^(BOOL downloadSuccess) {
        NSArray *completionArray = self.comletionArray.copy;
        [completionArray enumerateObjectsUsingBlock:^(void(^obj)(BOOL downloadSuccess), NSUInteger idx, BOOL * _Nonnull stop) {
            ACCBLOCK_INVOKE(obj, downloadSuccess);
        }];
        
        [self.comletionArray removeAllObjects];
        self.needUpdate = !downloadSuccess;
        self.isRequestOnAir = NO;
    };
    
    if (self.isRequestOnAir) {
        return;
    }

    self.isRequestOnAir = YES;
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    [EffectPlatform checkEffectUpdateWithPanel:self.panelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName];
        BOOL hasValidCache = NO;
        if (self.panelType == AWEStickerPanelTypeZoom) {
            hasValidCache = cachedResponse.effects.count;
        } else {
            hasValidCache = cachedResponse.categories.count;
        }
        if (!needUpdate && hasValidCache) {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                             status:0
                              extra:@{
                                      @"panel" : self.panelName ?: @"",
                                      @"panelType" : @(self.panelType),
                                      @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                      @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                      @"needUpdate" : @(NO)
                                      }];
            self.response = cachedResponse;
            [self updateCollectionEffectDict];
            [self updateStickerCategories];
            ACCBLOCK_INVOKE(completionWrapper, YES);
        } else {
            ACCBLOCK_INVOKE(self.configExtraParamsBlock);
            
            CFTimeInterval stickerListStartTime = CFAbsoluteTimeGetCurrent();
            [EffectPlatform downloadEffectListWithPanel:self.panelName
                                   effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                             completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                                                @strongify(self);
                                                 if (!error && response.effects.count > 0) {
                                                     [ACCMonitor() trackService:@"aweme_effect_list_error"
                                                                      status:0
                                                                       extra:@{
                                                                               @"panel" : self.panelName ?: @"",
                                                                               @"panelType" : @(self.panelType),
                                                                               @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                                                               @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                                               @"needUpdate" : @(YES)
                                                                               }];
                                                     
                                                     NSMutableDictionary *params = @{@"api_type":@"effect_list",
                                                                                     @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                                                                     @"status":@(0)}.mutableCopy;
                                                     [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                                                     [ACCTracker() trackEvent:@"tool_performance_api" params:params needStagingFlag:NO];
                                                     
                                                     self.response = response;
                                                     // 每次response有更新时，更新一下collectionEffectDict.
                                                     [self updateCollectionEffectDict];
                                                     [self updateStickerCategories];
                                                     ACCBLOCK_INVOKE(completionWrapper, YES);
                                                 } else {
                                                     [ACCMonitor() trackService:@"aweme_effect_list_error"
                                                                      status:1
                                                                       extra:@{
                                                                               @"panel" : self.panelName ?: @"",
                                                                               @"panelType" : @(self.panelType),
                                                                               @"errorDesc":error.description ?: @"",
                                                                               @"errorCode":@(error.code),
                                                                               @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                                                               @"needUpdate" : @(YES)
                                                                               }];
                                                     NSMutableDictionary *params = @{@"api_type":@"effect_list",
                                                                                     @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                                                                     @"status":@(1),
                                                                                     @"error_domain":error.domain ?: @"",
                                                                                     @"error_code":@(error.code)}.mutableCopy;
                                                     [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                                                     [ACCTracker() trackEvent:@"tool_performance_api"
                                                                        params:params.copy
                                                               needStagingFlag:NO];
                                                     
                                                     BOOL usedCachedResponse = NO;
                                                     if (cachedResponse.categories.count) {
                                                         self.response = cachedResponse;
                                                         usedCachedResponse = YES;
                                                     } else if (self.panelType == AWEStickerPanelTypeZoom &&
                                                                cachedResponse.effects.count) {
                                                         self.response = cachedResponse;
                                                         usedCachedResponse = YES;
                                                     } else {
                                                         self.response = [self p_configPresetModel];
                                                     }
                                                     
                                                     // 每次response有更新时，更新一下collectionEffectDict.
                                                     [self updateCollectionEffectDict];
                                                     [self updateStickerCategories];
                                                     ACCBLOCK_INVOKE(completionWrapper, usedCachedResponse);
                                                 }
                                             }];
        }
    }];
}

- (void)downloadCollectionStickersWithCompletion:(void(^)(BOOL downloadSuccess))completion
{
    ACCBLOCK_INVOKE(self.configExtraParamsBlock);

    CFTimeInterval collectionStickersStartTime = CFAbsoluteTimeGetCurrent();
    
    [EffectPlatform downloadMyEffectListWithPanel:self.panelName completion:^(NSError * _Nullable error, NSArray<IESMyEffectModel *> * _Nullable effects) {
        
        //////////////////////////////////////////////////////////////////////////
        ///  @description: 旧道具面板收藏接口性能监控
        ///  @poc: yuanxin.07
        ///  @date: 2021/May/20
        //////////////////////////////////////////////////////////////////////////
        
        NSMutableDictionary *params = @{@"api_type":@"effect_favourite_list",
                                        @"duration":@((CFAbsoluteTimeGetCurrent() - collectionStickersStartTime) * 1000)}.mutableCopy;
        if (error != nil) {
            params[@"status"] = @(1);
            params[@"error_domain"] = error.domain ?: @"";
            params[@"error_code"] = @(error.code);
        } else {
            params[@"status"] = @(0);
        }
        
        [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
        [ACCTracker() trackEvent:@"tool_performance_api"
                          params:params.copy
                 needStagingFlag:NO];
        
        
        if (!error && effects.count > 0) {
            NSArray *effectsArray = effects.firstObject.effects;
            NSMutableArray *effectModelArray = [NSMutableArray array];
            for (IESEffectModel *effect in effectsArray) {
                if ([self shouldAddToStickerList:effect]) {
                    [effectModelArray addObject:effect];
                }
            }
            if (effectModelArray.count > 0) {
                self.p_collectionEffects = [effectModelArray mutableCopy];
                [self updateCollectionEffectDict];
            } else {
                self.p_collectionEffects = [@[] mutableCopy];
            }
            
            // 关联道具处理
            [self addBindEffectModelIfNeed:effects.firstObject.bindEffects];
            
            ACCBLOCK_INVOKE(completion, YES);
        } else {
            AWELogToolError(AWELogToolTagNone, @"download my effect list|panelName=%@|error=%@", self.panelName, error);
            self.p_collectionEffects = [@[] mutableCopy];
            ACCBLOCK_INVOKE(completion, NO);
        }
    }];
}

#pragma mark -

- (IESEffectPlatformResponseModel *)cachedRecordStickerResponseModel
{
    return [EffectPlatform cachedEffectsOfPanel:self.panelName];
}

- (IESEffectPlatformResponseModel *)responseModel
{
    return self.response;
}

- (IESEffectPlatformNewResponseModel *)responseModelNew
{
    return self.responseNew;
}

- (NSArray<IESEffectModel *> *)collectionEffects
{
    if (!self.p_collectionEffects || self.p_collectionEffects.count == 0) {
        return @[];
    }
    return self.p_collectionEffects.copy;
}

- (NSArray *)effectsArray
{
    if (!self.response) {
        return nil;
    }
    return self.response.effects;
}

- (NSArray *)cachedEffectsArray
{
    if (!self.cachedRecordStickerResponseModel) {
        return nil;
    }
    return self.cachedRecordStickerResponseModel.effects;
}

- (void)addFavoriteEffect:(IESEffectModel *)effectModel
{
    if (![self.p_collectionEffects containsObject:effectModel]) {
        [self.p_collectionEffects insertObject:effectModel atIndex:0];
    }
}

- (void)removeFavoriteEffect:(IESEffectModel *)effectModel
{
    if ([self.p_collectionEffects containsObject:effectModel]) {
        [self.p_collectionEffects removeObject:effectModel];
    }
}

- (IESEffectModel *)firstChildEffectForEffect:(IESEffectModel *)effectModel {
    if (!effectModel.effectIdentifier || effectModel.effectIdentifier.length == 0) {
        return nil;
    }
    NSArray *modelArray = self.collectionEffectDict[effectModel.effectIdentifier];
    IESEffectModel *retModel = nil;
    for (IESEffectModel *effectModel in modelArray) {
        if (effectModel.effectType != IESEffectModelEffectTypeSchema) {
            retModel = effectModel;
            break;
        }
    }
    return retModel;
}

- (IESEffectModel *)parentEffectForEffect:(IESEffectModel *)effectModel {
    if (!effectModel.effectIdentifier || effectModel.effectIdentifier.length == 0) {
        return nil;
    }
    for (NSString *effectIdentifier in self.collectionEffectDict.allKeys) {
        NSArray<IESEffectModel *> *children = self.collectionEffectDict[effectIdentifier];
        if ([children containsObject:effectModel]) {
            if ([self enablePagingStickers]) {
                for (IESCategoryEffectsModel *category in self.responseModelNew.categories) {
                    for (IESEffectModel *model in category.effects) {
                        if ([model.effectIdentifier isEqualToString:effectIdentifier]) {
                            return model;
                        }
                    }
                }
                return [self collectedEffectWithEffectIdentifier:effectIdentifier];
            } else {
                for (IESEffectModel *model in self.responseModel.effects) {
                    if ([model.effectIdentifier isEqualToString:effectIdentifier]) {
                        return model;
                    }
                }
                return [self collectedEffectWithEffectIdentifier:effectIdentifier];
            }
        }
    }
    return nil;
}

- (IESEffectModel *)collectedEffectWithEffectIdentifier:(NSString *)effectIdentifier
{
    __block IESEffectModel *model = nil;
    [self.p_collectionEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.effectIdentifier isEqualToString:effectIdentifier]) {
            *stop = YES;
            model = obj;
        }
    }];
    return model;
}

- (NSMutableArray<IESEffectModel *> *)p_collectionEffects {
    if (!_p_collectionEffects) {
        _p_collectionEffects = [NSMutableArray array];
    }
    return _p_collectionEffects;
}

+ (IESCategoryModel *)createCategoryModelWithName:(NSString *)name
{
    IESCategoryModel *categoryModel = [[IESCategoryModel alloc] init];
    [categoryModel setValue:name forKey:@"categoryName"];
    return categoryModel;
}

- (void)updateStickerCategories
{
    NSArray *initCategories = self.responseModel.categories;
    if ([self enablePagingStickers]) {
        initCategories = self.responseModelNew.categories;
    }
    
    for (IESCategoryModel *category in initCategories) {
        [self recoverStickersForCategory:category];
    }
    // 贴纸强插
    if ([self.delegate respondsToSelector:@selector(insertStickersForCategories:)]) {
        [self.delegate insertStickersForCategories:initCategories];
    }
    // 贴纸重新排序
    if ([self.delegate respondsToSelector:@selector(resetStickersForCategories:)]) {
        [self.delegate resetStickersForCategories:initCategories];
    }
    NSMutableArray *categories = [NSMutableArray array];
    for (int i = 0; i < initCategories.count; i++) {
        IESCategoryModel *category = initCategories[i];
        // 贴纸过滤
        NSMutableArray *stickers = [NSMutableArray array];
        for (IESEffectModel *effect in category.aweStickers) {
            if ([self shouldAddToStickerList:effect]) {
                [stickers addObject:effect];
            }
        }
        category.aweStickers = [stickers copy];
        [categories addObject:category];
    }
    
    self.stickerCategories = [categories copy];
}

- (void)recoverStickersForCategory:(IESCategoryModel *)category
{
    category.aweStickers = [category.effects copy];
}

- (void)updateStickerCategoryAtIndex:(NSInteger)index {
    IESCategoryModel *category = [self.stickerCategories acc_objectAtIndex:index];
    if (!category) {
        return;
    }
    [self recoverStickersForCategory:category];
    // 贴纸强插
    if ([self.delegate respondsToSelector:@selector(insertStickersForCategory:atIndex:)]) {
        [self.delegate insertStickersForCategory:category atIndex:index];
    }
    // 贴纸重新排序
    if ([self.delegate respondsToSelector:@selector(resetStickersForCategory:atIndex:)]) {
        [self.delegate resetStickersForCategory:category atIndex:index];
    }
    // 贴纸过滤
    NSMutableArray *stickers = [NSMutableArray array];
    for (IESEffectModel *effect in category.aweStickers) {
        if ([self shouldAddToStickerList:effect]) {
            [stickers addObject:effect];
        }
    }
    category.aweStickers = [stickers copy];
}

// 贴纸过滤
- (BOOL)shouldAddToStickerList:(IESEffectModel *)effect
{
    if ((self.needFilterStickerType & AWEStickerFilterTypeGame) && ([effect gameType] != ACCGameTypeNone)) {
        return NO;
    }
    
    if ([self.needFilterEffect evaluateWithObject:effect]) {
        return NO;
    }
    
    if (self.effectFilterBlock) {
        return !self.effectFilterBlock(effect);
    }
    
    return YES;
}

- (void)updateCollectionEffectDict {
    if ([self enablePagingStickers]) {
        __block BOOL flag = YES;
        for (IESCategoryModel *category in self.responseModelNew.categories) {
            if (category.collection.count != 0) {
                flag = NO;
                break;
            }
        }
        
        // 收藏夹道具判断是否有子道具
        // check for collection effect
        [self.p_collectionEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull collectionEffect, NSUInteger idx, BOOL * _Nonnull stop) {
            if (collectionEffect.childrenEffects.count > 0) {
                flag = NO;
                *stop = YES;
            }
        }];
        
        if (flag) {
            self.collectionEffectDict = nil;
            return;
        }
    } else {
        if (self.responseModel.collection.count == 0) {
            self.collectionEffectDict = nil;
            return;
        }
    }

    NSMutableDictionary<NSString *, NSMutableArray<IESEffectModel *> *> *tmpCollectionDict =
            [NSMutableDictionary dictionary];
    NSMutableDictionary<NSString *, NSArray<IESEffectModel *> *> *collectionDict = [NSMutableDictionary dictionary];
    
    void(^fillCollectionEffectsDict)(NSArray *, NSArray *) = ^(NSArray *effects, NSArray *collections) {
        for (IESEffectModel *effect in effects) {
            if (effect.effectType != IESEffectModelEffectTypeCollection) {
                continue;
            }
            for (NSString *childID in effect.childrenIds) {
                for (IESEffectModel *childEffect in collections) {
                    if ([childEffect.effectIdentifier isEqual:childID]) {
                        NSMutableArray *collectionArray = tmpCollectionDict[effect.effectIdentifier] ?: [NSMutableArray array];
                        [self addEffect:childEffect toArray:collectionArray];
                        tmpCollectionDict[effect.effectIdentifier] = collectionArray;
                        break;
                    }
                }
            }
            if (tmpCollectionDict[effect.effectIdentifier]) {
                collectionDict[effect.effectIdentifier] = [tmpCollectionDict[effect.effectIdentifier] copy];
            }
        }
    };
    if ([self enablePagingStickers]) {
        NSMutableArray *allEffects = [NSMutableArray array];
        NSMutableArray *allCollections = [NSMutableArray array];
        
        for (IESCategoryModel *category in self.responseModelNew.categories) {
            [allEffects addObjectsFromArray:category.effects];
            [allCollections addObjectsFromArray:category.collection];
        }
        ACCBLOCK_INVOKE(fillCollectionEffectsDict, allEffects, allCollections);
    } else {
        ACCBLOCK_INVOKE(fillCollectionEffectsDict, self.responseModel.effects, self.responseModel.collection);
    }
    [self.p_collectionEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull effect, NSUInteger idx, BOOL * _Nonnull stop) {
        if (effect.childrenEffects.count > 0) {
            collectionDict[effect.effectIdentifier] = effect.childrenEffects.copy;
        }
    }];
    self.collectionEffectDict = [collectionDict copy];
}

- (BOOL)isTypeForCheckCache
{
    switch (self.panelType) {
        case AWEStickerPanelTypeStory:
            return YES;
        case AWEStickerPanelTypeZoom:
            return YES;
        case AWEStickerPanelTypeLive:
            return NO;
        case AWEStickerPanelTypeRecord:
            return NO;
        case AWEStickerPanelTypeCreatorPreview:
            return NO;
    }
}

- (void)addEffect:(IESEffectModel *)effect toArray:(NSMutableArray<IESEffectModel *> *)targetArray
{
    if (!effect || !targetArray) {
        return;
    }
    
    __block BOOL hasEffect = NO;
    [targetArray enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.effectIdentifier isEqualToString:effect.effectIdentifier]) {
            hasEffect = YES;
            *stop = YES;
        }
    }];
    
    if (!hasEffect) {
        [targetArray addObject:effect];
    }
}

- (NSDictionary *)extraParamsBeforeRequest {
    // 透传给后台进行模型训练
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    if (self.referString.length > 0) {
        params[@"shoot_way"] = self.referString;
    }
    if (self.fromPropId.length > 0) {
        params[@"from_prop_id"] = self.fromPropId;
    }
    NSString *musicId = ACCBLOCK_INVOKE(self.currentSelectedMusicHandler);
    if (musicId.length > 0) {
        params[@"music_id"] = musicId;
    }
    return [params copy];
}

#pragma mark - 预加载数据
- (void)preFetchCategoriesAndEffectsForCategoryKey:(NSString *)cateKey {
    if (!ACCConfigBool(kConfigBool_enable_prefetch_effect_list)) {
        self.hasPreFetched = YES;
        return;
    }
    
    NSString *panelName = self.panelName;
    if (panelName.length == 0) {
        return;
    }
    
    /// record data
    self.preCateKey = cateKey;
    
    /// Config location params for effect platform
    ACCBLOCK_INVOKE(self.configExtraParamsBlock);
    NSDictionary *extraParams = [self extraParamsBeforeRequest];
    
    CFTimeInterval stickerListStartTime = CFAbsoluteTimeGetCurrent();
    @weakify(self);
    
    [EffectPlatform fetchCategoriesListWithPanel:panelName
                    isLoadDefaultCategoryEffects:YES
                                 defaultCategory:cateKey ?: @""
                                       pageCount:StickerPageCount
                                          cursor:0
                                       saveCache:YES
                            effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                 extraParameters:extraParams
                                      completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
        @strongify(self);
        self.hasPreFetched = YES;
        BOOL fetchSuccess;
        if (!error && response.categoryEffects.effects.count > 0) {
            /// add track Log
            NSMutableDictionary *params = @{@"api_type":@"effect_category_list",
                                            @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                            @"status":@(0)}.mutableCopy;
            [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
            [ACCTracker() trackEvent:@"tool_performance_api"
                               params:params.copy
                      needStagingFlag:NO];
            self.preFetchResponse = response;
            fetchSuccess = YES;
            
            // Set prop enterance icon with the first prop in the hot category.
            // 使用热门分类第一个道具的icon设置道具面板入口。
            IESEffectModel *firstHotProp = response.categoryEffects.effects.firstObject;
            if (self.firstHotPropBlock && firstHotProp) {
                if (self.effectFilterBlock && self.effectFilterBlock(firstHotProp)) {
                    self.firstHotPropBlock(nil);
                } else {
                    self.firstHotPropBlock(firstHotProp);
                }
            }
        } else {
            /// add track log
            NSMutableDictionary *params = @{@"api_type":@"effect_category_list",
                                            @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                            @"status":@(1),
                                            @"error_domain":error.domain ?: @"",
                                            @"error_code":@(error.code)}.mutableCopy;
            [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
            [ACCTracker() trackEvent:@"tool_performance_api"
                               params:params.copy
                      needStagingFlag:NO];
            fetchSuccess = NO;
        }
        
        /// exect completion blk
        if (self.preFetchCategoriesCompletion) {
            self.preFetchCategoriesCompletion(fetchSuccess);
        }
    }];
}

#pragma mark - 支持分页

- (BOOL)enablePagingStickers;
{
    return (self.panelType == AWEStickerPanelTypeRecord || self.panelType == AWEStickerPanelTypeStory);
}

- (void)fetchCategoriesForRecordStickerWithCompletion:(void(^)(BOOL downloadSuccess))completion
{
    [self fetchCategoriesForRecordStickerWithCompletion:completion loadEffectsForCategoryKey:@""];
}

- (void)fetchCategoriesForRecordStickerWithCompletion:(void (^)(BOOL))completion loadEffectsForCategoryKey:(NSString *)cateKey {
    /// Check request param
    NSString *panelName = self.panelName;
    if (panelName.length == 0) {
        return;
    }
    
    if (completion) {
        [self.comletionArray addObject:[completion copy]];
    }
    
    /// Define complete block
    @weakify(self);
    void(^completionWrapper)(BOOL downloadSuccess, IESEffectPlatformNewResponseModel *response) = ^(BOOL downloadSuccess, IESEffectPlatformNewResponseModel *response) {
        @strongify(self);
        /// update category data
        self.responseNew = response;
        [self.updatedCategoriesSet removeAllObjects]; // 重置已更新分页参数
        self.urlPrefix = response.urlPrefix;
        [self updateCategoryWithResponse:response isLoadMore:NO];
        [self updateCollectionEffectDict];
        [self updateStickerCategories];
        
        /// invoke handler
        NSArray *completionArray = self.comletionArray.copy;
        [completionArray enumerateObjectsUsingBlock:^(void(^obj)(BOOL downloadSuccess), NSUInteger idx, BOOL * _Nonnull stop) {
            ACCBLOCK_INVOKE(obj, downloadSuccess);
        }];
        
        [self.comletionArray removeAllObjects];
        self.isRequestOnAir = NO;
    };
    
    /// Check preFetch response
    if ([cateKey ?: @"" isEqualToString:self.preCateKey]) {
        if (self.hasPreFetched) {
            if (self.preFetchResponse) {
                IESEffectPlatformNewResponseModel *preResponse = self.preFetchResponse;
                self.preFetchResponse = nil;
                
                self.urlPrefix = preResponse.urlPrefix;
                ACCBLOCK_INVOKE(completionWrapper, YES, preResponse);
                return;
            }
        } else { // prefetch request is on air
            self.preFetchCategoriesCompletion = ^(BOOL success) {
                @strongify(self);
                if (success && self.preFetchResponse) {
                    IESEffectPlatformNewResponseModel *preResponse = self.preFetchResponse;
                    self.preFetchResponse = nil;
                    
                    self.urlPrefix = preResponse.urlPrefix;
                    ACCBLOCK_INVOKE(completionWrapper, YES, preResponse);
                } else {
                    [self fetchCategoriesForRecordStickerWithCompletion:completion loadEffectsForCategoryKey:cateKey];
                }
            };
            return;
        }
    }
    
    
    /// Is requesting
    if (self.isRequestOnAir) {
        return;
    }
    self.isRequestOnAir = YES;
    
    void (^fetchCategoriesListBlk)(CFTimeInterval) = ^(CFTimeInterval fetchStartTime) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.configExtraParamsBlock);
        NSDictionary *extraParams = [self extraParamsBeforeRequest];

        CFTimeInterval stickerListStartTime = CFAbsoluteTimeGetCurrent();
        @weakify(self);
        [EffectPlatform fetchCategoriesListWithPanel:panelName
                        isLoadDefaultCategoryEffects:YES
                                     defaultCategory:cateKey ?: @""
                                           pageCount:StickerPageCount
                                              cursor:0
                                           saveCache:YES
                                effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                     extraParameters:extraParams
                                          completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
            @strongify(self);
            if (!error && response.categoryEffects.effects.count > 0) {
                [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:0 extra:@{
                    @"panel" : panelName ?: @"",
                    @"panelType" : @(self.panelType),
                    @"duration" : @((CFAbsoluteTimeGetCurrent() - fetchStartTime) * 1000),
                    @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                    @"needUpdate" : @(YES),
                }];
                
                NSMutableDictionary *params = @{@"api_type":@"effect_category_list",
                                                @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                                @"status":@(0)}.mutableCopy;
                [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                [ACCTracker() trackEvent:@"tool_performance_api"
                                   params:params.copy
                          needStagingFlag:NO];
                
                self.urlPrefix = response.urlPrefix;
                
                ACCBLOCK_INVOKE(completionWrapper, YES, response);
            } else {
                [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:1 extra:@{
                    @"panel" : panelName ?: @"",
                    @"panelType" : @(self.panelType),
                    @"errorDesc":error.description ?: @"",
                    @"errorCode":@(error.code),
                    @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                    @"needUpdate" : @(YES),
                }];
                
                NSMutableDictionary *params = @{@"api_type":@"effect_category_list",
                                                @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                                @"status":@(1),
                                                @"error_domain":error.domain ?: @"",
                                                @"error_code":@(error.code)}.mutableCopy;
                [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                [ACCTracker() trackEvent:@"tool_performance_api"
                                   params:params.copy
                          needStagingFlag:NO];
                
                BOOL usedCachedResponse = NO;
                IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedCategoriesOfPanel:panelName];
                if (cachedResponse.categories.count) {
                    self.responseNew = cachedResponse;
                    usedCachedResponse = YES;
                } else {
                    self.responseNew = [self p_configNewPresetModel];
                }
                
                ACCBLOCK_INVOKE(completionWrapper, usedCachedResponse, self.responseNew);
            }
        }];
    };

    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkPanelUpdateWithPanel:panelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformNewResponseModel *cachedResponse;
        BOOL cacheIsAvailable = NO;
        if (!needUpdate) {
            cachedResponse = [EffectPlatform cachedCategoriesOfPanel:panelName];
            if (cachedResponse.categories.count > 0) {
                cacheIsAvailable = YES;
            }
        }

        if (cacheIsAvailable && cachedResponse != nil) {
            [[AWEStudioMeasureManager sharedMeasureManager] asyncMonitorTrackService:@"aweme_effect_list_error" status:0 extra:@{
                @"panel" : panelName ?: @"",
                @"panelType" : @(self.panelType),
                @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                @"needUpdate" : @(NO),
            }];

            ACCBLOCK_INVOKE(completionWrapper, YES, cachedResponse);
        } else {
            fetchCategoriesListBlk(startTime);
        }
    }];
}

/**
 获取对应分类下的道具数据，有两次失败重试的机会

 @param category 请求的分类名称
 */
- (void)fetchCategoryStickersWith2RetryTimesForCategory:(IESCategoryModel *)category {
    NSString *categoryKey = category.categoryKey;
    NSString *panelName = self.panelName;
    if (self.categoryReqRetryTimesDic[categoryKey] && [self.categoryReqRetryTimesDic[categoryKey] intValue] > 2) {
        // 已经重试了两次了没有结果
        dispatch_group_leave(self.categoryReqGroup);
        return;
    }
    @weakify(self);
    NSDictionary *extraParams = [self extraParamsBeforeRequest];
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();

    [EffectPlatform downloadEffectListWithPanel:panelName
                                       category:categoryKey
                                      pageCount:StickerPageCount
                                         cursor:0
                                sortingPosition:0
                                        version:nil
                                      saveCache:YES
                           effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                extraParameters:extraParams
                                     completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
        @strongify(self);
        if (error || response.categoryEffects.effects.count == 0) {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                             status:1
                              extra:@{
                                      @"panel" : panelName ?: @"",
                                      @"panelType" : @(self.panelType),
                                      @"errorDesc":error.description ?: @"",
                                      @"errorCode":@(error.code),
                                      @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                      @"needUpdate" : @(YES)
                                      }];
            NSMutableDictionary *params = @{@"api_type":@"effect_list",
                                            @"duration":@((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                            @"status":@(1),
                                            @"error_domain":error.domain ?: @"",
                                            @"error_code":@(error.code)}.mutableCopy;
            [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
            [ACCTracker() trackEvent:@"tool_performance_api"
                     params:params.copy
            needStagingFlag:NO];
            
            if (!self.categoryReqRetryTimesDic[categoryKey]) {
                [self.categoryReqRetryTimesDic setValue:@1 forKey:categoryKey];
            } else {
                NSInteger val = self.categoryReqRetryTimesDic[categoryKey].intValue;
                [self.categoryReqRetryTimesDic setValue:@(++val) forKey:categoryKey];
            }
            [self fetchCategoryStickersWith2RetryTimesForCategory:category];
        } else {
            // success
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                             status:0
                              extra:@{
                                      @"panel" : panelName ?: @"",
                                      @"panelType" : @(self.panelType),
                                      @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                      @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                      @"needUpdate" : @(YES)
                                      }];
            NSMutableDictionary *params = @{@"api_type":@"effect_list",
                                            @"duration":@((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                            @"status":@(0)}.mutableCopy;
            [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
            [ACCTracker() trackEvent:@"tool_performance_api"
                     params:params.copy
            needStagingFlag:NO];
            
            NSArray *collection = category.collection ? : [NSArray new];
            [category updateEffects:response.categoryEffects.effects collection:collection];
            dispatch_group_leave(self.categoryReqGroup);
        }
    }];
}

- (void)fetchStickersForIndex:(NSInteger)index completion:(void(^)(BOOL downloadSuccess, NSInteger index))completion
{
    if ([self isLoadingStickersForIndex:index]) {
        return;
    }
    
    if (completion) {
        [self.comletionDictionary setObject:[completion copy] forKey:@(index)];
    }
    
    IESCategoryModel *category = [self.stickerCategories objectAtIndex:index];
    @weakify(self);
    void(^completionWrapper)(BOOL, IESEffectPlatformNewResponseModel *) = ^(BOOL downloadSuccess, IESEffectPlatformNewResponseModel *response) {
        @strongify(self);
        /// Update category data
        NSInteger successIndex = index;
        if (downloadSuccess) {
            category.aweStickers = nil;
            successIndex = [self updateCategoryWithResponse:response isLoadMore:NO];
            [self updateCollectionEffectDict];
            [self updateStickerCategoryAtIndex:successIndex];
            
            [self addBindEffectModelIfNeed:response.categoryEffects.bindEffects];
        }
        
        FetchStickersSuccessBlockForPaging block = [self.comletionDictionary objectForKey:@(successIndex)];
        ACCBLOCK_INVOKE(block, downloadSuccess, successIndex);
        [self.comletionDictionary removeObjectForKey:@(successIndex)];
    };
    
    if (index < 0 || index >= self.stickerCategories.count) {
        ACCBLOCK_INVOKE(completionWrapper, NO, nil);
        return;
    }
    
    if ([self.updatedCategoriesSet containsObject:@(index)]) {
        ACCBLOCK_INVOKE(completionWrapper, NO, nil);
        return;
    }
    
    NSString *panelName = self.panelName;
    if (panelName.length == 0) {
        ACCBLOCK_INVOKE(completionWrapper, NO, nil);
        return;
    }
    
    void(^downloadFetchEffectListBlk)(CFTimeInterval) = ^(CFTimeInterval startTime) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.configExtraParamsBlock);
        NSDictionary *extraParams = [self extraParamsBeforeRequest];
        
        CFTimeInterval stickerListStartTime = CFAbsoluteTimeGetCurrent();
        @weakify(self);
        [EffectPlatform downloadEffectListWithPanel:panelName
                                           category:category.categoryKey
                                          pageCount:StickerPageCount
                                             cursor:0
                                    sortingPosition:0
                                            version:nil
                                          saveCache:YES
                               effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                    extraParameters:extraParams
                                         completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
            @strongify(self);
            if (error || response.categoryEffects.effects.count == 0) {
                [ACCMonitor() trackService:@"aweme_effect_list_error"
                                         status:1
                                          extra:@{
                                              @"panel" : panelName ?: @"",
                                              @"panelType" : @(self.panelType),
                                              @"errorDesc":error.description ?: @"",
                                              @"errorCode":@(error.code),
                                              @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                              @"needUpdate" : @(YES),
                                          }];
                NSMutableDictionary *params = @{@"api_type":@"effect_list",
                                                @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                                @"status":@(1),
                                                @"error_domain":error.domain ?: @"",
                                                @"error_code":@(error.code)}.mutableCopy;
                [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                [ACCTracker() trackEvent:@"tool_performance_api"
                                   params:params.copy
                          needStagingFlag:NO];
                
                ACCBLOCK_INVOKE(completionWrapper, NO, nil);
                return;
            }
            
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                                     status:0
                                      extra:@{
                                          @"panel" : panelName ?: @"",
                                          @"panelType" : @(self.panelType),
                                          @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                          @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                          @"needUpdate" : @(YES),
                                      }];
            
            NSMutableDictionary *params = @{@"api_type":@"effect_list",
                                            @"duration":@((CFAbsoluteTimeGetCurrent() - stickerListStartTime) * 1000),
                                            @"status":@(0)}.mutableCopy;
            [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
            [ACCTracker() trackEvent:@"tool_performance_api"
                               params:params.copy
                      needStagingFlag:NO];
            
            ACCBLOCK_INVOKE(completionWrapper, YES, response);
        }];
    };
    
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkEffectUpdateWithPanel:panelName category:category.categoryKey effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        IESEffectPlatformNewResponseModel *cachedResponse;
        BOOL cacheIsAvaliable = NO;
        if (!needUpdate) {
            cachedResponse = [EffectPlatform cachedEffectsOfPanel:panelName category:category.categoryKey];
            if (cachedResponse.categoryEffects.effects.count > 0) {
                cacheIsAvaliable = YES;
            }
        }

        if (cacheIsAvaliable && cachedResponse != nil) {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                                     status:0
                                      extra:@{
                                          @"panel" : panelName ?: @"",
                                          @"panelType" : @(self.panelType),
                                          @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                          @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                          @"needUpdate" : @(NO),
                                      }];
            ACCBLOCK_INVOKE(completionWrapper, YES, cachedResponse);
        } else {
            downloadFetchEffectListBlk(startTime);
        }
    }];
}

#pragma mark - Utils

- (NSString *)getPanelNameForType:(AWEStickerPanelType)panelType
{
    if(ACCConfigBool(kConfigBool_use_effect_cam_key)){
        return [self getEffectCamPanelNameWithType:panelType];
    }
    NSString *panel = @"default";
    switch (panelType) {
        case AWEStickerPanelTypeRecord:
            panel = @"default";
            break;
        case AWEStickerPanelTypeLive:
            panel = @"livestreaming";
            break;
        case AWEStickerPanelTypeStory:
            panel = @"springfestival";
            break;
        case AWEStickerPanelTypeZoom:
            panel = @"zoomin";
            break;
        case AWEStickerPanelTypeCreatorPreview:
            panel = @"";
            break;
    }
    
    return panel;
}

- (NSString *)getEffectCamPanelNameWithType:(AWEStickerPanelType)panelType
{
    NSString *panelName = @"default";
    if(panelType == AWEStickerPanelTypeRecord){
        ACCStickerSortOption stickerOption = ACCConfigEnum(kConfigInt_effect_stickers_panel_option, ACCStickerSortOption);
        switch (stickerOption) {
            case ACCStickerSortOptionRD:
                panelName = @"record-effect-rd";
                break;
            case ACCStickerSortOptionIntegration:
                panelName = @"record-effect-integration-test";
                break;
            case ACCStickerSortOptionAmaizing:
                panelName = @"record-effect-amazing-engine";
                break;
            case ACCStickerSortOptionCreator:
                panelName = @"record-effect-creator-test";
                break;
            default:
                break;
        }
    }
    return panelName;
}

- (BOOL)isLoadingStickersForIndex:(NSInteger)currentIndex
{
    if ([self.comletionDictionary objectForKey:@(currentIndex)]) {
        return YES;
    }
    
    return NO;
}

- (NSInteger)successIndexForResponse:(IESEffectPlatformNewResponseModel *)response
{
    __block NSInteger index = -1;
    [self.stickerCategories enumerateObjectsUsingBlock:^(IESCategoryModel *category, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([category.categoryKey isEqualToString:response.categoryEffects.categoryKey]) {
            index = idx;
            *stop = YES;
        }
    }];
    
    return index;
}

- (NSInteger)updateCategoryWithResponse:(IESEffectPlatformNewResponseModel *)model isLoadMore:(BOOL)isLoadMore
{
    NSInteger currentIndex = [self successIndexForResponse:model];
    if (currentIndex < 0 || currentIndex >= self.stickerCategories.count) {
        return currentIndex;
    }
    IESCategoryModel *category = [self.stickerCategories objectAtIndex:currentIndex];
    [category updateCategoryWithResponse:model isLoadMore:NO];

    // filter stickers 
    NSMutableArray *effectModelArray = [NSMutableArray array];
    for (IESEffectModel *effect in model.categoryEffects.effects) {
        if ([self shouldAddToStickerList:effect]) {
         [effectModelArray addObject:effect];
        }
    };
    category.aweStickers = effectModelArray;
    if (![self.updatedCategoriesSet containsObject:@(currentIndex)]) {
        [self.updatedCategoriesSet addObject:@(currentIndex)];
    }
    
    return currentIndex;
}

#pragma mark - Getter

- (NSMutableSet<NSString *> *)downloadingEffects {
    if (!_downloadingEffects) {
        _downloadingEffects = [NSMutableSet set];
    }
    return _downloadingEffects;
}

#pragma mark - Setter

- (void)setResponseNew:(IESEffectPlatformNewResponseModel *)responseNew {
    _responseNew = responseNew;
    [self addBindEffectModelIfNeed:responseNew.categoryEffects.bindEffects];
}

#pragma mark - 关联特效

- (void)addBindEffectModelIfNeed:(NSArray<IESEffectModel *> *)bindEffects {
    @synchronized (self.bindEffectsMap) {
        [bindEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.effectIdentifier.length > 0) {
                self.bindEffectsMap[obj.effectIdentifier] = obj;
            }
        }];
    }
}

- (nullable NSArray<IESEffectModel *> *)bindEffectsForEffect:(IESEffectModel *)effect {
    if (!effect) {
        return nil;
    }
    
    @synchronized (self.bindEffectsMap) {
        NSMutableArray<IESEffectModel *> *bindEffects = [NSMutableArray arrayWithObject:effect];
        [effect.bindIDs enumerateObjectsUsingBlock:^(NSString * _Nonnull effectIdentifier, NSUInteger idx, BOOL * _Nonnull stop) {
            [bindEffects acc_addObject:self.bindEffectsMap[effectIdentifier]];
        }];
        
        return bindEffects.copy;
    }
}

// TODO: 因为没法通过 effect_id 来判断同一个道具的下载状态，当2个不同的 IESEffectModel 对象，即使 effect_id 相同，可能下载状态是不同步的
- (void)updateBindEffectDownloadStatus:(AWEEffectDownloadStatus)status effectIdentifier:(NSString *)effectIdentifier {
    NSAssert(effectIdentifier.length, @"effectIdentifier is invalid !!!");
    @synchronized (self.bindEffectsMap) {
        if (self.bindEffectsMap[effectIdentifier]) {
            self.bindEffectsMap[effectIdentifier].downloadStatus = status;
        }
    }
}

- (void)downloadBindingMusicIfNeeded:(IESEffectModel *)sticker completion:(void(^)(NSError * _Nullable error))completion {
    if (sticker.musicIDs.count > 0) {
        NSString *musicID = sticker.musicIDs.firstObject;
        if ([musicID isKindOfClass:NSString.class] && musicID.length > 0) {
            BOOL musicIsForceBind = [AWEStickerMusicManager musicIsForceBindStickerWithExtra:sticker.extra];
            if (musicIsForceBind) {
                // Check if it need to download music.
                if ([AWEStickerMusicManager needToDownloadMusicWithEffectModel:sticker]) {
                    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:musicID completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
                        if (model && !error && !model.isOffLine) {
                            [ACCVideoMusic() fetchLocalURLForMusic:model withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
                                if (localURL && !error) {
                                    
                                    // 缓存起来，应用道具时根据音乐ID查询musicModel，再根据本地音乐路径查询规则查找音乐地址。
                                    // 示例代码：musicModel = [AWEStickerMusicManager fetchtMusicModelFromCache:musicID];
                                    // 示例代码: NSURL *url = [AWEStickerMusicManager localURLForMusic:musicModel];
                                    [AWEStickerMusicManager insertMusicModelToCache:model];
                                    
                                    if (completion) {
                                        completion(nil);
                                    }
                                } else {
                                    // Download music file failed.
                                    NSError *err = error;
                                    if (error == nil) {
                                        err = [NSError errorWithDomain:kStickerDataManagerTaskErrorDomain
                                                                  code:-1
                                                              userInfo:@{NSLocalizedFailureReasonErrorKey:@"localURL is empty!"}];
                                    }
                                    
                                    if (completion) {
                                        completion(err);
                                    }
                                }
                            }];
                        } else {
                            // Download music model failed or offline
                            NSError *err = [NSError errorWithDomain:kStickerDataManagerTaskErrorDomain
                                                               code:-1
                                                           userInfo:@{NSLocalizedFailureReasonErrorKey:@"Download music model failed or offline!"}];
                            if (completion) {
                                completion(err);
                            }
                        }
                    }];
                    
                    return;
                }
            }
        }
    }
    
    // call back as success if no bind music or music has downloaded before
    if (completion) {
        completion(nil);
    }
}

- (ACCGroupedPredicate<IESEffectModel *,id> *)needFilterEffect
{
    if (!_needFilterEffect) {
        _needFilterEffect = [[ACCGroupedPredicate alloc] initWithOperand:(ACCGroupedPredicateOperandOr)];
    }
    return _needFilterEffect;
}

@end
