//
//  ACCImageAlbumExportOperation.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/1/21.
//

#import "ACCImageAlbumExportOperation.h"
#import "ACCImageAlbumEditor.h"
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumExportItemModel.h"
#import "ACCImageAlbumEditorExportData.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

@interface ACCImageAlbumExportBaseOperation ()

@property (readonly, getter=isCancelled) BOOL cancelled;
@property (readwrite, getter=isExecuting) BOOL executing;
@property (readwrite, getter=isFinished) BOOL finished;
@property (nonatomic, strong) NSRecursiveLock *stateLock;

- (void)updateExecutingStatus:(BOOL)isExecuting;
- (void)updateFinishedStatus:(BOOL)isFinished;
- (void)markAsFinished;

@end

@implementation ACCImageAlbumExportBaseOperation
@synthesize executing = _executing, finished = _finished, cancelled = _cancelled;

- (instancetype)init
{
    if (self = [super init]) {
        _stateLock = [[NSRecursiveLock alloc] init];
        AWELogToolInfo(AWELogToolTagEdit, @"ExportBaseOperation : %s", __func__);
    }
    
    return self;
}

- (void)dealloc
{
    AWELogToolInfo(AWELogToolTagEdit, @"ExportBaseOperation : %s", __func__);
}

- (void)updateFinishedStatus:(BOOL)isFinished
{
    self.finished = isFinished;
}

- (void)updateExecutingStatus:(BOOL)isExecuting
{
    self.executing = isExecuting;
}

- (void)markAsFinished
{
    [self updateExecutingStatus:NO];
    [self updateFinishedStatus:YES];
}

- (void)cancel
{
    [self setCancelled:YES];
}

- (BOOL)isCancelled
{
    [_stateLock lock];
    BOOL flag = _cancelled;
    [_stateLock unlock];
    
    return flag;
}

- (void)setCancelled:(BOOL)cancelled
{
    [_stateLock lock];
    
    if (_cancelled != cancelled) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isCancelled))];
        _cancelled = cancelled;
        [self willChangeValueForKey:NSStringFromSelector(@selector(isCancelled))];
    }
    
    [_stateLock unlock];
    
    AWELogToolInfo(AWELogToolTagEdit, @"ExportBaseOperation : %s,%@", __func__,@(cancelled));
}

- (BOOL)isExecuting
{
    [_stateLock lock];
    BOOL flag = _executing;
    [_stateLock unlock];
    
    return flag;
}

- (void)setExecuting:(BOOL)executing
{
    [_stateLock lock];
    
    if (_executing != executing) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
        _executing = executing;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isExecuting))];
    }
    
    [_stateLock unlock];
    
    AWELogToolInfo(AWELogToolTagEdit, @"ExportBaseOperation : %s,%@", __func__,@(executing));
}

- (BOOL)isFinished
{
    [_stateLock lock];
    BOOL flag = _finished;
    [_stateLock unlock];
    
    return flag;
}

- (void)setFinished:(BOOL)finished
{
    [_stateLock lock];
    
    if (_finished != finished) {
        [self willChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
        _finished = finished;
        [self didChangeValueForKey:NSStringFromSelector(@selector(isFinished))];
    }
    
    [_stateLock unlock];
    
    AWELogToolInfo(AWELogToolTagEdit, @"ExportBaseOperation : %s,%@", __func__,@(finished));
}

- (BOOL)isReady
{
    return YES;
}

- (BOOL)isAsynchronous
{
    return YES;
}

- (BOOL)isConcurrent
{
    return YES;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key
{
    if ([key isEqualToString:@"isExecuting"] ||
        [key isEqualToString:@"isFinished"] ||
        [key isEqualToString:@"isCancelled"]) {
        return NO;
    }
    return [super automaticallyNotifiesObserversForKey:key];
}

@end


@interface ACCImageAlbumCaptureOperation ()

@property (nonatomic, strong) ACCImageAlbumEditor *editor;
@property (nonatomic, strong) ACCImageAlbumEditorExportInputData *inputData;

@end


@implementation ACCImageAlbumCaptureOperation


- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
                     inputData:(ACCImageAlbumEditorExportInputData *)inputData
{
    if (self = [super init]) {
        _editor = editor;
        _inputData = inputData;
    }
    
    return self;
}

- (void)start
{
    
    [self updateExecutingStatus:YES];
    
    if (!self.editor || !self.inputData) {
        
        if (!self.editor) {
            AWELogToolError(AWELogToolTagEdit, @"CaptureOperation : start faild because of null image editor");
        }
        if (!self.inputData) {
            AWELogToolError(AWELogToolTagEdit, @"CaptureOperation : start faild because of null image data");
        }
        
        NSParameterAssert(self.editor != nil);
        ACCBLOCK_INVOKE(self.completeHandler, nil, NO);
        self.editor = nil;
        [self markAsFinished];
        return;
    }
    
    @weakify(self);
    [self.editor runExportWithInputData:self.inputData
                               complete:^(ACCImageAlbumEditorExportOutputData * _Nullable outputData,
                                          ACCImageAlbumEditorExportResult exportResult) {
        
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            BOOL succeed = (exportResult == ACCImageAlbumEditorExportResultSucceed);
            ACCBLOCK_INVOKE(self.completeHandler, outputData.image, succeed);
            self.editor = nil; // 避免循环，但是开始前确实需要持有下 防止外面释放了
            [self markAsFinished];
            AWELogToolInfo(AWELogToolTagEdit, @"CaptureOperation : export finished at index:%@, succeed:%@", @(outputData.index), @(succeed));
            
        });
    }];
}

@end

@interface ACCImageAlbumExportOperation ()

@property (nonatomic, strong) ACCImageAlbumEditor *editor;
@property (nonatomic, strong) NSArray<ACCImageAlbumEditorExportInputData *> *inputDatas;
@property (nonatomic, strong) dispatch_queue_t exportingQueue;

@end

@implementation ACCImageAlbumExportOperation

- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
                    inputDatas:(NSArray<ACCImageAlbumEditorExportInputData *> *)inputDatas
                exportingQueue:(dispatch_queue_t)exportingQueue
{
    
    if (self = [super init]) {
        _editor = editor;
        _inputDatas = [inputDatas copy];
        _exportingQueue = exportingQueue;
    }
    return self;
}

- (void)start
{
    
    [self updateExecutingStatus:YES];
    
    if (!self.editor || !self.inputDatas.count) {
        
        if (!self.editor) {
            AWELogToolError(AWELogToolTagEdit, @"ExportOperation : start faild because of null image editor");
        }
        if (!self.inputDatas.count) {
            AWELogToolError(AWELogToolTagEdit, @"ExportOperation : start faild because of null image inputDatas");
        }
        
        NSParameterAssert(self.editor != nil);
        ACCBLOCK_INVOKE(self.faildHandler, 0);
        self.editor = nil;
        [self markAsFinished];
        return;
    }

    @weakify(self);
    
    dispatch_sync(self.exportingQueue, ^{
        
        @strongify(self);
        
        NSInteger totalCount = self.inputDatas.count;
        NSMutableArray <ACCImageAlbumExportItemModel *> *exportedItems = [NSMutableArray arrayWithCapacity:totalCount];
        
        __block BOOL hasError = NO;
        __block NSInteger currentExportIndex = 0;
        
        // 注意 这是是后置的锁, 别在任务开始前锁了...
        dispatch_semaphore_t lock = dispatch_semaphore_create(0);
        
        for (ACCImageAlbumEditorExportInputData *inputData in self.inputDatas) {
            
            if (hasError) {
                break;
            }
            
            [self p_runExportWithIndex:currentExportIndex
                             inputData:inputData
                                editor:self.editor
                              complete:^(ACCImageAlbumExportItemModel *exportItem, BOOL succeed) {

                @strongify(self);
                if (!self || !succeed || ACC_isEmptyString(exportItem.filePath)) {
                    hasError = YES;
                    dispatch_semaphore_signal(lock);
                } else {
                    acc_dispatch_main_async_safe(^{
                        // 注意如果这里后面不在主线程的 记得上锁，避免并发index值不对
                        [exportedItems addObject:exportItem];
                        currentExportIndex ++;
                        ACCBLOCK_INVOKE(self.progressHandler, currentExportIndex, totalCount);
                        dispatch_semaphore_signal(lock);
                    });
                }
            }];
            
            // 注意semaphore初始是0，所以不要移到任务开始前
            // 后置lock目的是不用在循环里去处理结果,如果有任务失败方便提前break
            dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
        }
        
        acc_dispatch_main_async_safe(^{
            
            BOOL isResultMatched = (totalCount == [exportedItems count]);
            
            if (hasError || !isResultMatched) {
                if (!hasError && !isResultMatched) {
                    NSAssert(NO, @"bad case, check synchronized");
                    AWELogToolError(AWELogToolTagEdit, @"ExportOperation : fatal error when export, result count is not matched, check synchronized, totalcount:%@, exported item count:%@", @(totalCount), @(exportedItems.count));
                }
                ACCBLOCK_INVOKE(self.faildHandler, currentExportIndex);
                AWELogToolInfo(AWELogToolTagEdit, @"ExportOperation : export faild, faild index:%@", @(currentExportIndex));
            } else {
                ACCBLOCK_INVOKE(self.succeedHandler, [exportedItems copy]);
                AWELogToolInfo(AWELogToolTagEdit, @"ExportOperation : export succeed");
            }
            self.editor = nil;
            [self markAsFinished];
        });
    });
}

- (void)p_runExportWithIndex:(NSInteger)index
                   inputData:(ACCImageAlbumEditorExportInputData *)inputData
                      editor:(ACCImageAlbumEditor *)editor
                    complete:(void (^)(ACCImageAlbumExportItemModel *imageItem, BOOL succeed))completeBlock
{
    [editor runExportWithInputData:inputData
                          complete:^(ACCImageAlbumEditorExportOutputData * _Nullable outputData,
                                     ACCImageAlbumEditorExportResult exportResult) {
        
        if (ACC_isEmptyString(outputData.filePath) || exportResult != ACCImageAlbumEditorExportResultSucceed) {
            ACCBLOCK_INVOKE(completeBlock, nil, NO);
        } else {
            ACCImageAlbumExportItemModel *exportImageItem = [[ACCImageAlbumExportItemModel alloc] init];
            exportImageItem.filePath = outputData.filePath;
            exportImageItem.imageSize = outputData.imageSize;
            exportImageItem.imageScale = outputData.imageScale;
            ACCBLOCK_INVOKE(completeBlock, exportImageItem, YES);
        }
    }];
}

@end

#import "ACCImageAlbumItemModel.h"

@interface ACCImageAlbumPlayerPreviewOperation ()

@property (nonatomic, strong) ACCImageAlbumEditor *editor;
@property (nonatomic, strong) ACCImageAlbumEditorExportInputData *inputData;

@end

@implementation ACCImageAlbumPlayerPreviewOperation


- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
                     inputData:(ACCImageAlbumEditorExportInputData *)inputData
{
    if (self = [super init]) {
        _editor = editor;
        _inputData = inputData;
    }
    
    return self;
}

- (instancetype)initForReloadWithEditor:(ACCImageAlbumEditor *)editor
                              imageItem:(ACCImageAlbumItemModel *)imageItem
                                  index:(NSInteger)index
{
    if (self = [super init]) {
        _editor = editor;
        _isReloadOperation = YES;
        _reloadIndex = index;
        _reloadItemModel = imageItem;
    }
    
    return self;
}

- (void)start
{
    if (self.isCancelled) {
        AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"\nPlayerPreviewOperation cancel: ignore start because of  cancelled isreload:%@", @(self.isReloadOperation)]);
        [self markAsFinished];
        return;
    }

    if (self.isReloadOperation) {
        [self p_startForReloadOperation];
        return;
    }
    
    [self updateExecutingStatus:YES];
    
    if (!self.editor || !self.inputData) {
        ACCBLOCK_INVOKE(self.completeHandler, nil, NO);
        self.editor = nil;
        [self markAsFinished];
        return;
    }
    
    ACCBLOCK_INVOKE(self.willStartHandler, self.inputData, NO);
    
    @weakify(self);
    
    [self.editor runExportWithInputData:self.inputData
                               complete:^(ACCImageAlbumEditorExportOutputData * _Nullable outputData,
                                          ACCImageAlbumEditorExportResult exportResult) {
        
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            BOOL succeed = (exportResult == ACCImageAlbumEditorExportResultSucceed);
            ACCBLOCK_INVOKE(self.completeHandler, outputData.image, succeed);
            self.editor = nil; // 避免循环，但是开始前确实需要持有下 防止外面释放了
            [self markAsFinished];
            AWELogToolInfo(AWELogToolTagEdit, [NSString stringWithFormat:@"CaptureOperation : export finished at index:%@, succeed:%@", @(outputData.index), @(succeed)]);
            
        });
    }];
}

- (void)p_startForReloadOperation
{
    if (self.isCancelled) {
        AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"\nPlayerPreviewOperation reload cancel: ignore start because of  cancelled"]);
        [self markAsFinished];
        return;
    }
    
    [self updateExecutingStatus:YES];
    
    if (!self.editor || !self.reloadItemModel) {
        
        ACCBLOCK_INVOKE(self.completeHandler, nil, NO);
        self.editor = nil;
        [self markAsFinished];
        return;
    }
    
    ACCBLOCK_INVOKE(self.willStartHandler, self.inputData, YES);
    
    @weakify(self);
    [self.editor reloadWithImageItem:self.reloadItemModel index:self.reloadIndex complete:^(BOOL didAddImage) {
        
        acc_dispatch_main_async_safe(^{
            @strongify(self);
            
            ACCBLOCK_INVOKE(self.completeHandler, nil, didAddImage);
            self.editor = nil; // 避免循环，但是开始前确实需要持有下 防止外面释放了
            [self markAsFinished];
            AWELogToolInfo(AWELogToolTagEdit, [NSString stringWithFormat:@"CaptureOperation : reload finished at index:%@, succeed:%@", @(self.reloadIndex), @(didAddImage)]);
        });
    }];
}

- (NSString *)imageItemId
{
    if (self.isReloadOperation) {
        return self.reloadItemModel.itemIdentify;
    } else {
        return self.inputData.imageItem.itemIdentify;
    }
}

- (BOOL)enableCancel
{
    return !(self.isCancelled || self.isExecuting || self.finished);
}

- (void)cancel
{
    [super cancel];
    self.editor = nil;
    AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"\nPlayerPreviewOperation cancel: cancelled"]);
}

@end
