//
//  ACCImageAlbumExportManager.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/21.
//

#import "ACCImageAlbumExportManager.h"
#import <ReactiveObjC/RACCompoundDisposable.h>
#import <ReactiveObjC/NSObject+RACPropertySubscribing.h>
#import <ReactiveObjC/RACSignal+Operations.h>
#import "ACCImageAlbumItemModel.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCImageAlbumEditor.h"
#import "ACCImageAlbumExportItemModel.h"
#import "ACCImageAlbumExportOperation.h"
#import "ACCImageAlbumEditorExportData.h"
#import <CreationKitInfra/ACCLogHelper.h>

@interface ACCImageAlbumExportManager ()

@property (nonatomic, strong) ACCImageAlbumEditor *imageEditor;

@property (nonatomic, strong) dispatch_semaphore_t exportingLock;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) dispatch_queue_t exportQueue;

@end

@implementation ACCImageAlbumExportManager

+ (instancetype)sharedManager
{
    static ACCImageAlbumExportManager *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[ACCImageAlbumExportManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self p_setup];
    }
    return self;
}

- (void)p_setup
{
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    self.exportQueue = dispatch_queue_create("com.aweme.image.album.exports", DISPATCH_QUEUE_SERIAL);
    
    // 在任务完成后没必要持有，因为进封面等页面毕竟是少数，没必要一直持有
    @weakify(self);
    [[RACObserve(self, operationQueue.operationCount) deliverOnMainThread] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        [self releaseImageEditorIfEnable];
    }];
}

#pragma mark - editor
- (void)releaseImageEditorIfEnable
{
    acc_dispatch_main_async_safe(^{
        
        if (self.operationQueue.operationCount > 0) {
            AWELogToolInfo(AWELogToolTagEdit, @"ExportManager : release image cancel because of operation queue is not empty now");
            return;
        }
        
        if (self.imageEditor) {
            AWELogToolInfo(AWELogToolTagEdit, @"ExportManager : editor lifeCycle : released image editor");
        }
        self.imageEditor = nil; // release after all operations complete
    });
}

- (void)exportImagesWithImageItems:(NSArray <ACCImageAlbumItemModel *> *)imageItems
                     containerSize:(CGSize)containerSize
                          progress:(void(^_Nullable)(NSInteger finishedCount, NSInteger totalCount))progressBlock
                         onSucceed:(void(^_Nullable)(NSArray<ACCImageAlbumExportItemModel *> *exportedItems))succeedBlock
                           onFaild:(void(^_Nullable)(NSInteger faildIndex))faildBlock
{
    if (ACC_isEmptyArray(imageItems)) {
        ACCBLOCK_INVOKE(faildBlock, 0);
    }
    
    if (!self.imageEditor) {
        self.imageEditor = [[ACCImageAlbumEditor alloc] initWithContainerSize:containerSize];
        AWELogToolInfo(AWELogToolTagEdit, @"ExportManager : editor lifeCycle : init image editor");
    }
    
    NSMutableArray <ACCImageAlbumEditorExportInputData *> *inputDatas = [NSMutableArray array];
    [[imageItems copy] enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        NSString *draftFolderPath = [ACCImageAlbumItemBaseResourceModel draftFolderPathWithTaskId:obj.taskId];
        NSString *fileName = [NSString stringWithFormat:@"imageAlbum-export-%@", @(idx)];
        NSString *filePath = [draftFolderPath stringByAppendingPathComponent:fileName];
        
        ACCImageAlbumEditorExportInputData *inputData = [[ACCImageAlbumEditorExportInputData alloc] initWithImageItem:obj index:idx exportTypes:ACCImageAlbumEditorExportTypeFilePath];
        inputData.savePath = filePath;
        [inputDatas addObject:inputData];
    }];
    
    ACCImageAlbumExportOperation *operation = [[ACCImageAlbumExportOperation alloc] initWithEditor:self.imageEditor inputDatas:[inputDatas copy] exportingQueue:self.exportQueue];
    
    [operation setProgressHandler:progressBlock];
    [operation setFaildHandler:faildBlock];
    [operation setSucceedHandler:succeedBlock];
    
    [self.operationQueue addOperation:operation];
}

@end


@interface ACCImageAlbumCaptureManager ()

@property (nonatomic, strong) ACCImageAlbumEditor *imageEditor;
@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, assign) BOOL shouldAlwaysHoldImageEditor;

@end

@implementation ACCImageAlbumCaptureManager

+ (instancetype)sharedManager
{
    static ACCImageAlbumCaptureManager *instance = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        instance = [[ACCImageAlbumCaptureManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [self p_setup];
    }
    return self;
}

- (void)p_setup
{
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    // 在任务完成后没必要持有，因为进封面等页面毕竟是少数，没必要一直持有
    @weakify(self);
    [[RACObserve(self, operationQueue.operationCount) deliverOnMainThread] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        [self releaseImageEditorIfEnable];
    }];
}

#pragma mark - editor
- (void)beginImageAlbumPreviewTaskExportItemRetainAndReuse
{
    self.shouldAlwaysHoldImageEditor = YES;
}

- (void)endImageAlbumPreviewTaskExportItemRetainAndReuse
{
    self.shouldAlwaysHoldImageEditor = NO;
    [self releaseImageEditorIfEnable];
}

- (void)releaseImageEditorIfEnable
{
    acc_dispatch_main_async_safe(^{
        
        if (self.shouldAlwaysHoldImageEditor) {
            AWELogToolInfo(AWELogToolTagEdit, @"CaptureManager : release image cancel because of should always hold image editor is true");
            return;
        }
        
        if (self.operationQueue.operationCount > 0) {
            AWELogToolInfo(AWELogToolTagEdit, @"CaptureManager : release image cancel because of operation queue is not empty now");
            return;
        }
        
        if (self.imageEditor) {
            AWELogToolInfo(AWELogToolTagEdit, @"CaptureManager : editor lifeCycle : released image editor");
        }
        self.imageEditor = nil; // release after all operations complete
    });
}

- (void)fetchPreviewImageAtIndex:(NSInteger)index
                       imageItem:(ACCImageAlbumItemModel *)imageItem
                   containerSize:(CGSize)containerSize
                   preferredSize:(CGSize)size
              usingOriginalImage:(BOOL)usingOriginalImage
                     compeletion:(void (^_Nullable)(UIImage *_Nullable image, NSInteger index))compeletion
{
    if (!imageItem) {
        ACCBLOCK_INVOKE(compeletion, nil, index);
        AWELogToolError(AWELogToolTagEdit, @"CaptureManager : fetch preview faild because of null image item at index: %@", @(index));
        return;
    }
    
    /// 确保至少在一个runloop里调用的editor是复用的，因为在封面等页面 在一个runloopl里可能批量调用，内存吃紧
    if (!self.imageEditor) {
        self.imageEditor = [[ACCImageAlbumEditor alloc] initWithContainerSize:containerSize];
        AWELogToolInfo(AWELogToolTagEdit, @"CaptureManager : editor lifeCycle : init image editor");
    }
    
    ACCImageAlbumEditorExportInputData *inputData = [[ACCImageAlbumEditorExportInputData alloc] initWithImageItem:imageItem index:index exportTypes:AACCImageAlbumEditorExportTypeImage];
    inputData.targetSize = size;
    inputData.usingOriginalImage = usingOriginalImage;
    
    ACCImageAlbumCaptureOperation *operation = [[ACCImageAlbumCaptureOperation alloc] initWithEditor:self.imageEditor inputData:inputData];
    
    [operation setCompleteHandler:^(UIImage * _Nullable image, BOOL succeed) {
        ACCBLOCK_INVOKE(compeletion, image, index);
    }];
    
    [self.operationQueue addOperation:operation];
}

@end
