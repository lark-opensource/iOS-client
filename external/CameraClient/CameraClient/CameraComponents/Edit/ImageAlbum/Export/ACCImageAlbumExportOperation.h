//
//  ACCImageAlbumExportOperation.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/21.
//

#import <Foundation/Foundation.h>
#import "ACCImageAlbumEditorDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCImageAlbumEditor, ACCImageAlbumEditorExportInputData;
@class ACCImageAlbumExportItemModel;

@interface ACCImageAlbumExportBaseOperation : NSOperation

@end

@interface ACCImageAlbumCaptureOperation : ACCImageAlbumExportBaseOperation

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
                     inputData:(ACCImageAlbumEditorExportInputData *)inputData;

@property (nonatomic, copy) void(^completeHandler)(UIImage *_Nullable image, BOOL succeed);

@end

@interface ACCImageAlbumExportOperation : ACCImageAlbumExportBaseOperation

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
                    inputDatas:(NSArray <ACCImageAlbumEditorExportInputData *>*)inputDatas
                exportingQueue:(dispatch_queue_t)exportingQueue;

@property (nonatomic, copy) void(^succeedHandler)(NSArray<ACCImageAlbumExportItemModel *> * _Nullable exportItems);
@property (nonatomic, copy) void(^faildHandler)(NSInteger faildIndex);
@property (nonatomic, copy) void(^progressHandler)(NSInteger finishedCount, NSInteger totalCount);

@end

@interface ACCImageAlbumPlayerPreviewOperation : ACCImageAlbumExportBaseOperation

ACCImageEditModeObjUsingCustomerInitOnly;

/// for reload only
@property (nonatomic, strong, readonly) ACCImageAlbumItemModel *reloadItemModel;
@property (nonatomic, assign, readonly) NSInteger reloadIndex;
@property (nonatomic, assign, readonly) BOOL isReloadOperation;

/// @return export operation
- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
                     inputData:(ACCImageAlbumEditorExportInputData *)inputData;

/// @return reload operation
- (instancetype)initForReloadWithEditor:(ACCImageAlbumEditor *)editor
                              imageItem:(ACCImageAlbumItemModel *)imageItem
                                  index:(NSInteger)index;

- (NSString *)imageItemId;

- (BOOL)enableCancel;

/// image is nil if is reload operation
@property (nonatomic, copy) void(^completeHandler)(UIImage *_Nullable image, BOOL succeed);

/// inputData is nil if is reload operation
@property (nonatomic, copy) void(^willStartHandler)(ACCImageAlbumEditorExportInputData *inputData, BOOL isReloadOperation);

@end

NS_ASSUME_NONNULL_END
