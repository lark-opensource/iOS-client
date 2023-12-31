//
//  ACCImageAlbumPlayerPreviewExportManager.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/19.
//

#import <Foundation/Foundation.h>

@class ACCImageAlbumItemModel, ACCImageAlbumEditor;

@interface ACCImageAlbumPlayerPreviewExportManager : NSObject

- (instancetype)initWithEditor:(ACCImageAlbumEditor *_Nonnull)editor;

/// export target image from VEImage
- (void)addExportOperationWithItemModel:(ACCImageAlbumItemModel *_Nonnull)imageItem
                                  index:(NSInteger)index;

/// just reload image data
- (void)addReloadOperationWithItemModel:(ACCImageAlbumItemModel *_Nonnull)imageItem
                                  index:(NSInteger)index;


@property (nonatomic, copy) void (^onOperationWillStart)(ACCImageAlbumItemModel *_Nonnull targetItemModel, NSInteger index, BOOL isReloadOperation);

@property (nonatomic, copy) void (^onReloadCompleteHandler)(ACCImageAlbumItemModel *_Nonnull targetItemModel, NSInteger index);

@property (nonatomic, copy) void (^onExportCompleteHandler)(UIImage *_Nullable image, ACCImageAlbumItemModel *_Nonnull itemModel, NSInteger index);


@property (nonatomic, copy) void (^onOperationsCountChanged)(NSInteger count);

@property (nonatomic, copy) void (^onAllOperationsCompleteHandler)(void);

- (NSInteger)currentOperationCount;

/// cancel all operations,  no callback
- (void)releaseAllOperations;

// 取消除itemIdList内的所有任务，适用于低端机优化
- (void)cancelOperationsExcludeWithItemIdList:(NSArray<NSString *> *_Nullable)itemIdList;

@end

