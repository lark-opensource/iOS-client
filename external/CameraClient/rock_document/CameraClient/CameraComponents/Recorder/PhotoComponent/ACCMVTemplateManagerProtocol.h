//
//  ACCMVTemplateManagerProtocol.h
//  CameraClient
//
//  Created by 李辉 on 2020/4/22.
//

@class AWEVideoPublishViewModel;
@class AWEAssetModel;
@class IESEffectModel;

typedef void(^ACCPhotoToVideoFailedBlock)(void);
typedef void(^ACCPhotoToVideoSuccessBlock)(void);
typedef void(^ACCPhotoToVideoCustomerTransferBlock)(BOOL isCanceled, AWEVideoPublishViewModel *_Nullable result); // 如果isCanceled = YES, result在SmartMovie场景会是nil

@protocol ACCMVTemplateManagerProtocol <NSObject>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;
@property (nonatomic, strong) dispatch_block_t cancelBlock;
@property (nonatomic, copy) ACCPhotoToVideoCustomerTransferBlock customerTransferHandler;

- (void)configPublishModel:(AWEVideoPublishViewModel *)publishModel;

- (void)exportMVVideoWithImage:(UIImage *)image doneBlock:(void (^)(UIViewController *editor))doneBlock failedBlock:(ACCPhotoToVideoFailedBlock)failedBlock;

- (void)exportMVVideoWithImage:(UIImage *)image
                       musicId:(NSString *)musicId
                   needLoading:(BOOL)needLoading
                     doneBlock:(void (^)(UIViewController *editor))done
                   failedBlock:(ACCPhotoToVideoFailedBlock)failedBlock;

- (void)exportMVVideoWithAssetModels:(NSArray <AWEAssetModel *>*)assetModels failedBlock:(ACCPhotoToVideoFailedBlock)failedBlock successBlock:(ACCPhotoToVideoSuccessBlock)successBlock;

- (void)exportMVVideoWithAssetModels:(NSArray <AWEAssetModel *> *_Nullable)assetModels
                        needsLoading:(BOOL)needsLoading
                         failedBlock:(ACCPhotoToVideoFailedBlock _Nullable)failedBlock
                        successBlock:(ACCPhotoToVideoSuccessBlock _Nullable)successBlock;

- (void)exportMVVideoWithFilePaths:(NSArray <NSString *>*)filePaths failedBlock:(ACCPhotoToVideoFailedBlock)failedBlock successBlock:(ACCPhotoToVideoSuccessBlock)successBlock;

- (void)exportTextVideoWithImage:(UIImage *)image failedBlock:(ACCPhotoToVideoFailedBlock)failedBlock successBlock:(ACCPhotoToVideoSuccessBlock)successBlock;

// 智照
- (void)exportSmartMovieWithAssetModels:(NSArray<AWEAssetModel *> *_Nullable)assetModels
                            failedBlock:(ACCPhotoToVideoFailedBlock _Nullable)failedBlock
                           successBlock:(ACCPhotoToVideoSuccessBlock _Nullable)successBlock;

- (void)exportSmartMovieWithAssetModels:(NSArray<AWEAssetModel *> *_Nullable)assetModels
                                musicID:(NSString *_Nullable)musicID
                           needsLoading:(BOOL)needsLoading
                            failedBlock:(ACCPhotoToVideoFailedBlock _Nullable)failedBlock
                           successBlock:(ACCPhotoToVideoSuccessBlock _Nullable)successBlock;

- (void)handleLocationInfosForQuickAlbumPhoto:(NSMutableArray *)locationInfos;

@end
