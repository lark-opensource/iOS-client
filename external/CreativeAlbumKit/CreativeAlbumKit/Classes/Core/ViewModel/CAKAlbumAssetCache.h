//
//  CAKAlbumAsssetCache.h
//  CreativeAlbumKit-Pods-Aweme
//
//  Created by Liyingpeng on 2021/7/13.
//

#import <Foundation/Foundation.h>
#import "CAKPhotoManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface CAKAlbumAssetCacheKey : NSObject <NSCopying>

@property (nonatomic, assign) BOOL ascending;
@property (nonatomic, assign) AWEGetResourceType resourceType;
@property (nonatomic, copy, nullable) NSString *collectionLocalizedTitle;

+ (instancetype)keyWithAscending:(BOOL)ascending type:(AWEGetResourceType)resourceType localizedTitle:(nullable NSString *)localizedTitle;

@end

@interface CAKAlbumAssetCache : NSObject

@property (nonatomic, assign) BOOL useQueueOpt;

- (instancetype)initWithPrefetchData:(NSDictionary *)prefetchData;

- (dispatch_queue_t)loadingQueue;

- (void)loadCollectionDataWithType:(AWEGetResourceType)type
                         sortStyle:(CAKAlbumAssetSortStyle)sortStyle
                         ascending:(BOOL)ascending
                    fromAlbumModel:(nullable CAKAlbumModel *)albumModel
                         isCurrent:(BOOL)isCurrent
                          useCache:(BOOL)useCache
                        completion:(nullable void (^)(PHFetchResult *))completion;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
