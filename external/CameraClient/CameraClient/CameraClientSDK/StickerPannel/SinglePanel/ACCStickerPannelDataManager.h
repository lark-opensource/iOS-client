//
//  ACCStickerPannelDataManager.h
//  CameraClient-Pods-Aweme
//
//  Created by liyingpeng on 2020/8/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import "ACCStickerPannelLogger.h"

NS_ASSUME_NONNULL_BEGIN

@interface ACCStickerPannelDataPagination : NSObject

@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) NSInteger cursor;
@property (nonatomic, assign) NSInteger sortingPosition;

@end

@interface ACCStickerPannelDataManager : NSObject <ACCUserServiceMessage>

@property (nonatomic, copy) NSString *pannelName;
@property (nonatomic, assign) NSInteger pageCount;
@property (nonatomic, weak, nullable) id<ACCStickerPannelLogger> logger;

- (void)fetchPanelCategories:(void(^)(BOOL downloadSuccess, NSArray<IESCategoryModel *> *stickerCategories))completion;

- (void)fetchCategoryStickers:(NSString *)categoryKey
                   completion:(void(^)(BOOL downloadSuccess, NSArray<IESEffectModel *> *effects, ACCStickerPannelDataPagination *pagination))completion;

- (void)loadMoreStckerWithCategory:(NSString *)category
                              page:(ACCStickerPannelDataPagination *)page
                        completion:(void(^)(BOOL downloadSuccess, NSArray<IESEffectModel *> *effects, ACCStickerPannelDataPagination *pagination))completion;

@end

NS_ASSUME_NONNULL_END
