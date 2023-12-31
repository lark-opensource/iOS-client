//
//  AWEPhotoPickerModel.m
//  CameraClient
//
//  Created by zhangchengtao on 2020/4/14.
//

#import "AWEPhotoPickerModel.h"
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/RACEXTKeyPathCoding.h>

#import "CAKAlbumAssetModel+Convertor.h"
#import <CreationKitInfra/ACCRACWrapper.h>

@interface AWEDetectAlbumFaceTask : NSOperation

@property (nonatomic, copy) NSArray<AWEAssetModel *> *allAssets;

@property (nonatomic, assign) NSUInteger maxAssetCount;

@property (nonatomic, assign) NSUInteger detectedCount;

@property (nonatomic, copy, nullable) awe_did_update_asset_block_t didUpdatedBlock; // Must call on main thread.

@property (nonatomic, copy, nullable) awe_asset_filter_block_t assetFilterBlock; // Asset filter.

- (instancetype)initWithAssets:(NSArray<AWEAssetModel *> *)assets maxAssetCount:(NSUInteger)maxAssetCount;

- (instancetype)init NS_UNAVAILABLE;

@end

@implementation AWEDetectAlbumFaceTask

+ (NSOperationQueue *)dispatchQueue {
    static NSOperationQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = [[NSOperationQueue alloc] init];
    });
    return queue;
}

- (instancetype)initWithAssets:(NSArray<AWEAssetModel *> *)assets maxAssetCount:(NSUInteger)maxAssetCount {
    if (self = [super init]) {
        _allAssets = [assets copy];
        _maxAssetCount = maxAssetCount;
        _detectedCount = 0;
    }
    return self;
}

- (void)main {
    NSMutableArray<AWEAssetModel *> *bucket = [[NSMutableArray alloc] initWithCapacity:5];
    NSUInteger index = 0;
    NSUInteger lastIndex = 0;
    while (index < self.allAssets.count) {
        // Cancelled.
        if (self.isCancelled) {
            break;
        }
        
        // Finish
        if (self.detectedCount >= self.maxAssetCount) {
            break;
        }
        
        // Filter Assets
        AWEAssetModel *assetModel = self.allAssets[index];
        if (self.assetFilterBlock) {
            AWEAssetModel *filteredAssetModel = self.assetFilterBlock(assetModel);
            if (filteredAssetModel) {
                [bucket addObject:filteredAssetModel];
            }
        }
        
        if (bucket.count > 4 || (bucket.count > 0 && (index - lastIndex > 4))) {
            self.detectedCount += bucket.count;
            lastIndex = index;
            NSArray *faceModels = [bucket copy];
            [bucket removeAllObjects];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.didUpdatedBlock) {
                    self.didUpdatedBlock(faceModels);
                }
            });
        }
        
        index++;
    }
    
    if (bucket.count > 0) {
        NSArray *faceModels = [bucket copy];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.didUpdatedBlock) {
                self.didUpdatedBlock(faceModels);
            }
        });
    }
}

@end

@interface AWEPhotoPickerModel ()

@property (nonatomic, assign) BOOL fetchResultDidChange;
@property (nonatomic, strong, readwrite) NSMutableArray<AWEAssetModel *> *assetModels;

@property (nonatomic, strong) AWEDetectAlbumFaceTask *task;

@property (nonatomic, assign) AWEGetResourceType resourceType;

@end

@implementation AWEPhotoPickerModel

+ (BOOL)automaticallyNotifiesObserversOfSelectedAssetIndexArray
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedAssetModelArray
{
    return NO;
}

@synthesize selectedAssetIndexArray = _selectedAssetIndexArray;
@synthesize selectedAssetModelArray = _selectedAssetModelArray;

- (instancetype)initWithResourceType:(AWEGetResourceType)resourceType {
    if (self = [super init]) {
        _resourceType = resourceType;
        _assetModels = [[NSMutableArray alloc] init];
        _fetchResultDidChange = NO;
        _selectedAssetModelArray = @[];
        _selectedAssetIndexArray = @[];
        PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
        if (authorizationStatus == PHAuthorizationStatusAuthorized) {
            [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(p_applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.task cancel];
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusAuthorized) {
        [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
    }
}

- (void)load {
    // 开始检测前，先清理之前检测的结果
    if (self.assetModels.count > 0) {
        [self.assetModels removeAllObjects];
        if (self.didUpdatedBlock) {
            self.didUpdatedBlock();
        }
    }
    
    @weakify(self);
    AWEGetResourceType resourceType = self.resourceType;
    [CAKPhotoManager getAssetsWithType:resourceType filterBlock:^BOOL(PHAsset *phAsset) {
        if (phAsset.pixelHeight == 0) {
            return NO;
        }
        CGFloat ratio = ((CGFloat)phAsset.pixelWidth) / ((CGFloat)phAsset.pixelHeight);
        return 1.0/2.2 < ratio && ratio < 2.2;
    }
                             sortStyle:ACCConfigInt(kConfigInt_album_asset_sort_style)
                             ascending:YES
                            completion:^(NSArray<CAKAlbumAssetModel *> *assetModelArray, PHFetchResult *result) {
        @strongify(self);
        if (self) {
            if (assetModelArray.count > 0) {
                NSArray<AWEAssetModel *> *studioAssetArray = [CAKAlbumAssetModel convertToStudioArray:assetModelArray];
                NSArray<AWEAssetModel *> *totalAssetModels = [[studioAssetArray reverseObjectEnumerator] allObjects];
                [self handleAssetModels:totalAssetModels];
            }
        }
    }];
}

/**
 * 创建相册照片检测任务，检测符合条件的照片
 * Create a detect task.
 */
- (void)handleAssetModels:(NSArray *)assetModels {
    if (self.task) {
        self.task.didUpdatedBlock = nil;
        [self.task cancel];
        self.task = nil;
    }
    
    // 创建检测任务
    @weakify(self);
    self.task = [[AWEDetectAlbumFaceTask alloc] initWithAssets:assetModels maxAssetCount:50];
    self.task.assetFilterBlock = self.assetFilterBlock;
    self.task.didUpdatedBlock = ^(NSArray<AWEAssetModel *> *faceModels) {
        @strongify(self);
        if (self) {
            if (faceModels.count > 0) {
                [self.assetModels addObjectsFromArray:faceModels];
                if (self.didUpdatedBlock) {
                    self.didUpdatedBlock();
                }
            }
        }
    };
    self.task.completionBlock = ^{
        @strongify(self);
        if (self) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (self) {
                    self.task.didUpdatedBlock = nil;
                    self.task = nil;
                }
            });
        }
    };
    [[AWEDetectAlbumFaceTask dispatchQueue] addOperation:self.task];
}

#pragma mark - PHPhotoLibraryChangeObserver

- (void)photoLibraryDidChange:(PHChange *)changeInstance {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.fetchResultDidChange = YES;
    });
}

- (void)p_applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.fetchResultDidChange) {
        self.fetchResultDidChange = NO;
        
        // Reload data.
        if (self.task) {
            self.task.didUpdatedBlock = nil;
            [self.task cancel];
            self.task = nil;
        }
        
        // reset selected asset model.
        if (self.selectedAssetModelArray.count > 0) {
            [self selectAssetWithLocalIdentifierArray:@[]];
            if (self.didResetSelectedAssetBlock) {
                self.didResetSelectedAssetBlock();
            }
        }
                
        [self load];
    }
}

#pragma mark - Utils

- (void)selectAssetModelAtIndex:(NSInteger)index
{
    if (index >= self.assetModels.count) {
        return;
    }
    NSMutableArray<AWEAssetModel *> *selectedAssetArray = [self.selectedAssetModelArray mutableCopy];
    NSMutableArray<NSNumber *> *selectedAssetIndexArray = [self.selectedAssetIndexArray mutableCopy];
    // if already selected, directly return
    if ([selectedAssetIndexArray indexOfObject:@(index)] != NSNotFound) {
        return;
    }
    [selectedAssetArray acc_addObject:[self.assetModels acc_objectAtIndex:index]];
    [selectedAssetIndexArray acc_addObject:@(index)];
    [self updateSelectedAssetModelArray:selectedAssetArray selectedAssetIndexArray:selectedAssetIndexArray];
}

- (void)deselectAssetModelAtIndex:(NSInteger)index
{
    if (index >= self.assetModels.count) {
        return;
    }
    NSMutableArray<AWEAssetModel *> *selectedAssetArray = [self.selectedAssetModelArray mutableCopy];
    NSMutableArray<NSNumber *> *selectedAssetIndexArray = [self.selectedAssetIndexArray mutableCopy];
    // if not selected, directly return
    NSInteger indexInSelectedArray = [selectedAssetIndexArray indexOfObject:@(index)];
    if (indexInSelectedArray == NSNotFound) {
        return;
    }
    [selectedAssetArray removeObjectAtIndex:indexInSelectedArray];
    [selectedAssetIndexArray removeObjectAtIndex:indexInSelectedArray];
    [self updateSelectedAssetModelArray:selectedAssetArray selectedAssetIndexArray:selectedAssetIndexArray];
}

- (void)selectAssetModelArray:(NSArray<AWEAssetModel *> *)assetArray
{
    NSArray<NSString *> *localIdentifierArray = [assetArray acc_mapObjectsUsingBlock:^id _Nonnull(AWEAssetModel *  _Nonnull obj, NSUInteger idex) {
        return obj.asset.localIdentifier;
    }];
    [self selectAssetWithLocalIdentifierArray:localIdentifierArray];
}

- (void)selectAssetWithLocalIdentifierArray:(NSArray<NSString *> *)localIdentifierArray
{
    NSMutableArray<AWEAssetModel *> *selectedAssetArray = [NSMutableArray arrayWithCapacity:localIdentifierArray.count];
    NSMutableArray<NSNumber *> *selectedAssetIndexArray = [NSMutableArray arrayWithCapacity:localIdentifierArray.count];
    for (NSString *localIdentifier in localIdentifierArray) {
        [[self.assetModels copy] enumerateObjectsUsingBlock:^(AWEAssetModel *  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.asset.localIdentifier isEqualToString:localIdentifier]) {
                [selectedAssetArray acc_addObject:obj];
                [selectedAssetIndexArray acc_addObject:@(idx)];
            }
        }];
    }
    [self updateSelectedAssetModelArray:selectedAssetArray selectedAssetIndexArray:selectedAssetIndexArray];
}

- (void)updateSelectedAssetModelArray:(NSArray<AWEAssetModel *> *)selectedAssetModelArray selectedAssetIndexArray:(NSArray<NSNumber *> *)selectedAssetIndexArray
{
    NSAssert(selectedAssetModelArray.count == selectedAssetIndexArray.count, @"need to update both array simultaneously");
    [self willChangeValueForKey:@keypath(self, selectedAssetIndexArray)];
    [self willChangeValueForKey:@keypath(self, selectedAssetModelArray)];
    _selectedAssetIndexArray = selectedAssetIndexArray;
    for (AWEAssetModel *asset in [_selectedAssetModelArray copy]) {
        asset.selectedNum = nil;
    }
    NSInteger idx = 0;
    for (AWEAssetModel *asset in selectedAssetModelArray) {
        asset.selectedNum = @(++idx);
    }
    _selectedAssetModelArray = [selectedAssetModelArray copy];
    [self didChangeValueForKey:@keypath(self, selectedAssetIndexArray)];
    [self didChangeValueForKey:@keypath(self, selectedAssetModelArray)];
}

@end
