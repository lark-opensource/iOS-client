//
//  IESManifestManager.h
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/2/25.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/IESEffectConfig.h>
#import <EffectPlatformSDK/IESEffectUtil.h>

@class IESEffectModel;
@class IESEffectAlgorithmModel;
@class IESEffectRecord;
@class IESAlgorithmRecord;

NS_ASSUME_NONNULL_BEGIN

@interface IESManifestManager : NSObject

@property (nonatomic, strong, readonly) IESEffectConfig *config;

- (instancetype)initWithConfig:(IESEffectConfig *)config;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Set up database.
 * Create tables and load the data to memory cache.
 */
- (void)setupDatabaseCompletion:(ies_effect_result_block_t _Nullable)completion;

/**
 * Fetch builtin model list from builtin bundle ${EffectSDKResource.bundle}.
 */
- (void)loadBuiltinAlgorithmRecordsWithCompletion:(ies_effect_result_block_t _Nullable)completion;

/**
 * Fetch online model list from ${domain}/model/api/arithmetics".
 */
- (void)loadOnlineAlgorithmModelsWithCompletion:(ies_effect_result_block_t _Nullable)completion;

/**
 * Insert an effect model.
 */
- (void)insertEffectModel:(IESEffectModel *)effectModel
               effectSize:(unsigned long long)effectSize
                   NSData:(NSData *)effectModelData
               completion:(ies_effect_result_block_t _Nullable)completion;

/**
 * Insert an algorithm model.
 */
- (void)insertAlgorithmModel:(IESEffectAlgorithmModel *)model
                        size:(unsigned long long)size
                  completion:(ies_effect_result_block_t _Nullable)completion;

/**
 * Get effect download record.
 */
- (IESEffectRecord * __nullable)effectRecordForEffectMD5:(NSString *)effectMD5;

/**
 * Get algorithm download record.
 */
- (IESAlgorithmRecord * __nullable)downloadedAlgorithmRecordForName:(NSString *)name version:(NSString *)version traceLog:(NSMutableString * _Nullable)traceLog;

/**
 * Get algorithm download record when check model update 
 */
- (IESAlgorithmRecord * __nullable)downloadedAlgorithmRecrodForCheckUpdateWithName:(NSString *)name version:(NSString *)version;

/**
 * Get builtin algorithm record.
 */
- (IESAlgorithmRecord * __nullable)builtinAlgorithmRecordForName:(NSString *)name;

/**
 * Get online algorithm model.
 */
- (IESEffectAlgorithmModel * __nullable)onlineAlgorithmRecordForName:(NSString *)name;

/*
 * update online algorithm model list
 */
- (void)updateOnlineAlgorithmModels:(NSArray<IESEffectAlgorithmModel *> *)onlineModel;
 
/**
 * fetch single online model info 
 */
- (void)fetchOnlineAlgorithmModelWithModelInfos:(NSDictionary *)modelInfos
                                     completion:(nonnull void (^)(IESEffectAlgorithmModel * _Nullable algorithmModel, NSError * _Nullable error))completion;

/**
 * Check if the online algorithm list has been loaded.
 */
- (BOOL)isOnlineAlgorithmModelsLoaded;

/**
 * Remove all effects
 */
- (void)removeAllEffectsWithCompletion:(ies_effect_result_block_t _Nullable)completion;

/*
 * Remove effects with allow unclean panel list
 */
- (void)removeEffectsWithAllowUnCleanList:(NSArray<NSString *> *)uncleanList
                               completion:(void(^)(NSError * _Nullable error, NSArray<NSString *> * _Nullable uncleanMD5s))completion;

/**
 * Remove all effects except current using by others
 */
- (void)removeAllEffectsNotLockedWithCompletion:(void (^)(BOOL success, NSError * _Nullable error, NSArray<NSString *> * _Nullable effectMD5s))completion;

/**
 * Remove a specific alogrithm model.
 */
- (void)removeAlgorithmRecordsWithName:(NSString *)name completion:(ies_effect_result_block_t)completion;

/**
 * Remove all algorithm models.
 */
- (void)removeAllAlgorithmsWithCompletion:(void(^)(NSError * _Nullable error))completion;

/**
 * vacuum the sqlite file.
 */
- (void)vacuumDatabaseFileWithCompletion:(ies_effect_result_block_t _Nullable)completion;

/**
 * Compute total bytes all the effects allocated.
 */
- (unsigned long long)totalSizeOfEffectsAllocated;

/**
 * Compute total bytes all the effects allocated except with effect in allow panel list
 */
- (unsigned long long)totalSizeOfEffectsAllocatedExceptWith:(NSArray<NSString *> *)panels;

/**
 * Compute total bytes all the algorithm allocated.
 */
- (unsigned long long)totalSizeOfAlgorithmAllocated;

@end

@interface IESManifestManager (Statistic)

- (void)updateUseCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value;

- (void)updateRefCountForEffect:(IESEffectModel *)effectModel byValue:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
