//
//  ARTManifestManager.h
//  ArtistOpenPlatformSDK
//
//  Created by wuweixin on 2020/11/1.
//

#import <Foundation/Foundation.h>

@class ARTEffectConfig;
@class ARTEffectRecord;
@protocol ARTEffectPrototype;


typedef void(^art_effect_result_block_t)(BOOL success, NSError * _Nullable error);

NS_ASSUME_NONNULL_BEGIN

@interface ARTManifestManager : NSObject

@property(nonatomic, strong, readonly) ARTEffectConfig *config;

-(instancetype)initWithConfig:(ARTEffectConfig *)config;

-(instancetype)init NS_UNAVAILABLE;

/**
 * Set up database.
 * Create tables and load the data to memory cache.
 */
- (void)setupDatabaseCompletion:(art_effect_result_block_t _Nullable)completion;

/**
 * Insert an effect model.
 */
- (void)insertEffectModel:(id<ARTEffectPrototype>)effectModel
               effectSize:(unsigned long long)effectSize
                   NSData:(NSData * _Nullable)effectModelData
               completion:(art_effect_result_block_t _Nullable)completion;

/**
 * Get effect download record.
 */
- (ARTEffectRecord * __nullable)effectRecordForEffectMD5:(NSString *)effectMD5;

/**
 * Remove all effects
 */
- (void)removeAllEffectsWithCompletion:(art_effect_result_block_t _Nullable)completion;

/**
 * Remove all effects except current using by others
 */
- (void)removeAllEffectsNotLockedWithCompletion:(void (^)(BOOL success, NSError * _Nullable error, NSArray<NSString *> * _Nullable effectMD5s))completion;

/**
 * Compute total bytes all the effects allocated.
 */
- (unsigned long long)totalSizeOfEffectsAllocated;

@end

@interface ARTManifestManager (Statistic)

- (void)updateUseCountForEffect:(id<ARTEffectPrototype>)effectModel byValue:(NSInteger)value;

- (void)updateRefCountForEffect:(id<ARTEffectPrototype>)effectModel byValue:(NSInteger)value;

@end

NS_ASSUME_NONNULL_END
