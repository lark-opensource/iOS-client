//
//  AWEStickerPickerDataContainer.h
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/9/28.
//

#import <Foundation/Foundation.h>
#import <CameraClient/AWEStickerPickerDataContainerProtocol.h>

@interface AWEStickerPickerDataContainer : NSObject<AWEStickerPickerDataContainerProtocol>

@property (nonatomic, copy, readonly, nonnull) NSString *identifier;
@property (nonatomic, assign, readonly) BOOL loading;
@property (nonatomic, assign, readonly) BOOL enableSearch;
@property (nonatomic, assign, readonly) BOOL effectListUseCache;

@property (atomic, copy, nullable) NSArray<AWEDouyinStickerCategoryModel *> *categoryArray;
/// <categoryKey, effectArray>
@property (nonatomic, strong, nonnull) NSMutableDictionary<NSString*, NSArray<IESEffectModel *>*> *effectArrayMap;

@property (nonatomic, strong, nullable) AWEDouyinStickerCategoryModel *favoriteCategoryModel;
@property (nonatomic, copy, nullable) NSArray<IESEffectModel *> *favoriteEffectArray;

@property (nonatomic, strong, nullable) AWEDouyinStickerCategoryModel *searchCategoryModel;

@property (nonatomic, copy, nullable) NSArray<IESEffectModel *> *insertStickers;

/// 串行队列
@property (nonatomic, strong, nonnull) dispatch_queue_t dataHanleQueue;

- (void)fetchCategoryListForPanelName:(NSString * _Nonnull)panelName
                    completionHandler:(EffectPlatformFetchCategoryListCompletionBlock _Nullable)completionHandler;

@end
