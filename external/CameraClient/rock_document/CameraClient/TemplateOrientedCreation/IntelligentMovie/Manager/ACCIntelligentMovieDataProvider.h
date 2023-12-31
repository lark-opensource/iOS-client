//
//  ACCIntelligentMovieDataProvider.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/22.
//

#import <Foundation/Foundation.h>

#import <Photos/Photos.h>

#import "ACCMomentMediaAsset.h"
#import "ACCMomentBIMResult.h"

@class WCTSelect;

typedef void(^ACCMovieMediaDataProviderCompletion)(NSError * _Nullable error);

@interface ACCIntelligentMovieDataProvider : NSObject

@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;

- (void)cleanAllTable;

#pragma mark - Prepare

- (void)updateAssetResult:(NSArray<PHAsset *> *)result
                 scanDate:(NSUInteger)scanDate
               completion:(nonnull ACCMovieMediaDataProviderCompletion)completion;

- (void)loadPrepareAssetsWithLimit:(NSInteger)limit
                         pageIndex:(NSInteger)pageIndex
                       resultBlock:(void(^)(NSArray<ACCMomentMediaAsset *> * _Nullable result, NSUInteger allTotalCount, BOOL endFlag))resultBlock;

- (void)cleanPrepareAssetsWithCompletion:(nullable ACCMovieMediaDataProviderCompletion)completion;

#pragma mark - BIM
- (void)updateBIMResult:(NSArray<ACCMomentBIMResult *> *)result
             completion:(ACCMovieMediaDataProviderCompletion)completion;

- (void)loadBIMResultWithLimit:(NSInteger)limit
                     pageIndex:(NSInteger)pageIndex
                   resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable result, BOOL endFlag, NSError * _Nullable error))resultBlock;

- (void)loadBIMResultToSelectObj:(void(^)(WCTSelect *select, NSError * _Nullable error))completion;

- (void)loadBIMWithLocalIdentifiers:(NSArray<NSString *> *)localIdentifiers
            resultBlock:(void(^)(NSArray<ACCMomentBIMResult *> * _Nullable results, NSError * _Nullable error))resultBlock;

- (void)cleanBIMWhichNotExistInAssetResult:(NSArray<PHAsset *> *)result
                                  scanDate:(NSUInteger)scanDate
                                completion:(ACCMovieMediaDataProviderCompletion)completion;


@end
