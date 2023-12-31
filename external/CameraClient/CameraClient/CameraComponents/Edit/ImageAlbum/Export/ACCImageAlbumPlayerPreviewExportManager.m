//
//  ACCImageAlbumPlayerPreviewExportManager.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2021/8/19.
//

#import "ACCImageAlbumPlayerPreviewExportManager.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumEditor.h"
#import "ACCImageAlbumExportOperation.h"
#import "ACCImageAlbumEditorExportData.h"
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/ACCLogHelper.h>

@interface ACCImageAlbumPlayerPreviewExportManager ()

@property (nonatomic, strong) ACCImageAlbumEditor *editor;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation ACCImageAlbumPlayerPreviewExportManager

- (instancetype)initWithEditor:(ACCImageAlbumEditor *)editor
{
    if (self = [super init]) {
        _editor = editor;
        [self p_setup];
    }
    return self;
}

- (void)p_setup
{
    self.operationQueue = [[NSOperationQueue alloc] init];
    self.operationQueue.maxConcurrentOperationCount = 1;
    
    @weakify(self);
    [[[RACObserve(self, operationQueue.operationCount) takeUntil:self.rac_willDeallocSignal] deliverOnMainThread] subscribeNext:^(NSNumber *x) {
        @strongify(self);
        NSInteger operationCount = self.operationQueue.operationCount;
        if (operationCount <= 0) {
            ACCBLOCK_INVOKE(self.onAllOperationsCompleteHandler);
        }
        ACCBLOCK_INVOKE(self.onOperationsCountChanged, operationCount);
    }];
}

- (NSInteger)currentOperationCount
{
    return self.operationQueue.operationCount;
}

- (void)addExportOperationWithItemModel:(ACCImageAlbumItemModel *)imageItem
                                  index:(NSInteger)index
{
    if (!imageItem) {
        NSAssert(NO, @"invalid image item model");
        AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"ImageAlbumPalyerExportManager : fetch preview faild because of null image item at index: %@", @(index)]);
        return;
    }

    if (!self.editor) {
        NSAssert(NO, @"no editor can be use");
        AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"ImageAlbumPalyerExportManager : fetch preview faild because of editor is nil"]);
        return;
    }
    
    ACCImageAlbumEditorExportInputData *inputData = [[ACCImageAlbumEditorExportInputData alloc] initWithImageItem:imageItem index:index exportTypes:AACCImageAlbumEditorExportTypeImage];
    
    ACCImageAlbumPlayerPreviewOperation *operation = [[ACCImageAlbumPlayerPreviewOperation alloc] initWithEditor:self.editor inputData:inputData];
    
    @weakify(self);
    [operation setCompleteHandler:^(UIImage * _Nullable image, BOOL succeed) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(self.onExportCompleteHandler, image, imageItem, index);
        });
    }];
    
    [operation setWillStartHandler:^(ACCImageAlbumEditorExportInputData * _Nonnull inputData, BOOL isReloadOperation) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(self.onOperationWillStart, inputData.imageItem, index, isReloadOperation);
        });
    }];
    
    [self.operationQueue addOperation:operation];
}

- (void)addReloadOperationWithItemModel:(ACCImageAlbumItemModel *)imageItem
                                  index:(NSInteger)index
{
    if (!imageItem) {
        NSAssert(NO, @"invalid image item model");
        AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"ImageAlbumPalyerExportManager : reload preview faild because of null image item at index: %@", @(index)]);
        return;
    }
    
    if (!self.editor) {
        NSAssert(NO, @"no editor can be use");
        AWELogToolError(AWELogToolTagEdit, [NSString stringWithFormat:@"ImageAlbumPalyerExportManager : reload preview faild because of editor is nil"]);
        return;
    }

    ACCImageAlbumPlayerPreviewOperation *operation = [[ACCImageAlbumPlayerPreviewOperation alloc] initForReloadWithEditor:self.editor imageItem:imageItem index:index];
    
    @weakify(self);
    [operation setCompleteHandler:^(UIImage * _Nullable image, BOOL succeed) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(self.onReloadCompleteHandler, imageItem, index);
        });
    }];
    
    [operation setWillStartHandler:^(ACCImageAlbumEditorExportInputData * _Nonnull inputData, BOOL isReloadOperation) {
        @strongify(self);
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(self.onOperationWillStart, inputData.imageItem, index, isReloadOperation);
        });
    }];
    
    [self.operationQueue addOperation:operation];
    
}

- (void)cancelOperationsExcludeWithItemIdList:(NSArray<NSString *> *)itemIdList
{
    [self.operationQueue.operations.copy enumerateObjectsUsingBlock:^(ACCImageAlbumPlayerPreviewOperation *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (![obj isKindOfClass:[ACCImageAlbumPlayerPreviewOperation class]]) {
            NSAssert(NO, @"check");
            return;
        }
        
        NSString *itemId = obj.imageItemId;
        
        if (itemId && ![itemIdList containsObject:itemId] && [obj enableCancel]) {
            [obj cancel];
        }
    }];
}

- (void)releaseAllOperations
{
    [self cancelOperationsExcludeWithItemIdList:@[]];
    [self.operationQueue cancelAllOperations];
}


@end

