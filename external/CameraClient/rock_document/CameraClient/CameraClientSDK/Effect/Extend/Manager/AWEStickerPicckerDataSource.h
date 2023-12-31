//
//  AWEStickerPicckerDataSource.h
//  CameraClient-Pods-Aweme
//
//  Created by Chipengliu on 2020/11/5.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerPickerController.h>
#import <CameraClient/AWEStickerPickerDataContainerProtocol.h>

NS_ASSUME_NONNULL_BEGIN

@class IESEffectModel;
@class AWEDouyinStickerCategoryModel;

@interface AWEStickerPicckerDataSource : NSObject <AWEStickerPickerControllerDataSource>

@property (nonatomic, strong, readonly) dispatch_queue_t dataHanleQueue;
@property (nonatomic, assign, readonly) BOOL categoryListIsLoading;
// 是否显示收藏夹数据
@property (nonatomic, assign) BOOL needFavorite;

//是否在拍摄页
@property (nonatomic, assign) BOOL isOnRecordingPage;

@property (nonatomic, strong, readonly) id<AWEStickerPickerDataContainerProtocol> dataContainer;
@property (nonatomic, copy, readonly) NSArray<AWEDouyinStickerCategoryModel *> *categoryArray;

@property (nonatomic, copy) void(^tabSizeUpdateHandler)(NSInteger tabIndex);

@property (nonatomic, copy) BOOL (^stickerCategoryFilterBlock)(AWEStickerCategoryModel *category); // 道具分类过滤block

@property (nonatomic, copy) BOOL (^stickerFilterBlock)(IESEffectModel *sticker, AWEStickerCategoryModel *category); // 道具显示过滤block

- (void)useDataContainer:(NSString *)identifier;
- (void)setupDataContainers:(NSArray<id<AWEStickerPickerDataContainerProtocol>> *)containers;

- (IESEffectModel *)effectFromMapForId:(NSString *)identifier;

- (void)addEffectsToMap:(NSArray<IESEffectModel *> *)effectArray;

- (CGSize)cellSizeForTabIndex:(NSInteger)index;

- (void)insertPrioritizedStickers:(NSArray<IESEffectModel *> *)prioritizedStickers;

@end

NS_ASSUME_NONNULL_END
