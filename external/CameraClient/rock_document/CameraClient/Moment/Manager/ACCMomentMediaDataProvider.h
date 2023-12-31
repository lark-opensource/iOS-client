//
//  ACCMomentMediaDataProvider.h
//  Pods
//
//  Created by Pinka on 2020/5/18.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

#import "ACCMomentMediaAsset.h"
#import "ACCMomentBIMResult.h"

NS_ASSUME_NONNULL_BEGIN

@class WCTSelect;

typedef NS_ENUM(NSInteger, ACCMomentMediaDataProviderVideoConfig) {
    ACCMomentMediaDataProviderVideoCofig_Default,
    ACCMomentMediaDataProviderVideoCofig_Ignore,
    ACCMomentMediaDataProviderVideoCofig_Descending
};

typedef void(^ACCMomentMediaDataProviderCompletion)(NSError * _Nullable error);
typedef BOOL(^ACCMomentMediaDataProviderUpdateAssetFilter)(PHAsset *asset);

FOUNDATION_EXTERN NSString* ACCMomentMediaRootPath(void);

@interface ACCMomentMediaDataProvider : NSObject

@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;

- (instancetype)init NS_UNAVAILABLE;

+ (instancetype)normalProvider;

- (void)cleanAllTable;

#pragma mark - Upgrade Database
+ (void)setNeedUpgradeDatabase;

+ (void)completeUpgradeDatabase;

+ (instancetype)upgradeProvider;

#pragma mark - Prepare
- (void)updateAsset:(ACCMomentMediaAsset *)asset;

- (void)updateAssetResult:(PHFetchResult<PHAsset *> *)result
                   filter:(ACCMomentMediaDataProviderUpdateAssetFilter)filter
                 scanDate:(NSUInteger)scanDate
               limitCount:(NSUInteger)limitCount
               completion:(ACCMomentMediaDataProviderCompletion)completion;

- (void)loadPrepareAssetsWithLimit:(NSInteger)limit
                         pageIndex:(NSInteger)pageIndex
                   videoLoadConfig:(ACCMomentMediaDataProviderVideoConfig)videoLoadConfig
                       resultBlock:(void(^)(NSArray<ACCMomentMediaAsset *> * _Nullable result, NSUInteger allTotalCount, BOOL endFlag, NSError * _Nullable error))resultBlock;

- (void)cleanPrepareAssetsWithCompletion:(nullable ACCMomentMediaDataProviderCompletion)completion;

#pragma mark - BIM
- (void)updateBIMResult:(NSArray<ACCMomentBIMResult *> *)result
             completion:(ACCMomentMediaDataProviderCompletion)completion;

- (void)loadBIMResultWithLimit:(NSInteger)limit
                     pageIndex:(NSInteger)pageIndex
                   resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error))resultBlock;

- (void)loadBIMResultToSelectObj:(void(^)(WCTSelect *select, NSError * _Nullable error))completion;

- (void)updateCIMSimIds:(NSArray<NSNumber *> *)simIds
                bimUids:(NSArray<NSNumber *> *)bimUids
             completion:(ACCMomentMediaDataProviderCompletion)completion;

- (void)updateCIMPeopleIds:(NSArray<NSArray<NSNumber *> *> *)peopleIds
                   bimUids:(NSArray<NSNumber *> *)bimUids
                completion:(ACCMomentMediaDataProviderCompletion)completion;

- (void)loadLocalIdentifiersWithUids:(NSArray<NSNumber *> *)uids
                         resultBlock:(void(^)(NSDictionary<NSNumber *, NSString *> * _Nullable result, NSError * _Nullable error))resultBlock;

- (void)loadBIMWithUids:(NSArray<NSNumber *> *)uids
            resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error))resultBlock;

- (void)loadBIMWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers
            resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error))resultBlock;

- (void)cleanBIMWhichNotExistInAssetResult:(PHFetchResult<PHAsset *> *)result
                                  scanDate:(NSUInteger)scanDate
                                completion:(ACCMomentMediaDataProviderCompletion)completion;

- (void)allBIMCount:(void(^)(NSUInteger count))resultBlock;

- (void)cleanRedundancyBIMCount:(NSUInteger)count
                     completion:(nullable ACCMomentMediaDataProviderCompletion)completion;

@end

NS_ASSUME_NONNULL_END
