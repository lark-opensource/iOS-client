//
//  CAKAlbumDataModel.m
//  CameraClient
//
//  Created by lixingdong on 2020/6/22.
//

#import "CAKAlbumDataModel.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ReactiveObjC/ReactiveObjC.h>

@interface CAKAlbumAssetModelProvider()
@property (nonatomic, strong) NSMutableDictionary<NSString *, CAKAlbumAssetModel *> *sourceAssetDic;
@property (nonatomic, strong) dispatch_semaphore_t sourceDicSemaphore;
@end

@implementation CAKAlbumAssetModelProvider

- (instancetype)init
{
    self = [super init];
    if (self) {
        _sourceAssetDic = [[NSMutableDictionary alloc] init];
        _sourceDicSemaphore = dispatch_semaphore_create(1);
    }
    return self;
}

- (CAKAlbumAssetModel *)assetModelForPhAsset:(PHAsset *)asset
{
    dispatch_semaphore_wait(self.sourceDicSemaphore, DISPATCH_TIME_FOREVER);
    CAKAlbumAssetModel *assetModel = self.sourceAssetDic[asset.localIdentifier];;
    dispatch_semaphore_signal(self.sourceDicSemaphore);
    //only memory localIdentifier won't update real asset
    BOOL needUpdateSourceAsset = ((assetModel == nil) ||
                                  (asset.favorite != assetModel.phAsset.favorite));
    if (needUpdateSourceAsset && asset.localIdentifier) {
        assetModel = [self p_createAssetModel:asset];
    }
    return assetModel;
}

- (CAKAlbumAssetModel *)p_createAssetModel:(PHAsset *)asset
{
    CAKAlbumAssetModel *assetModel = [CAKAlbumAssetModel createWithPHAsset:asset];
    dispatch_semaphore_wait(self.sourceDicSemaphore, DISPATCH_TIME_FOREVER);
    self.sourceAssetDic[asset.localIdentifier] = assetModel;
    dispatch_semaphore_signal(self.sourceDicSemaphore);
    return assetModel;
}

@end

@interface CAKAlbumAssetModelManager()

@property (nonatomic, weak) CAKAlbumAssetModelProvider *assetModelProvider;
@property (nonatomic, strong) PHFetchResult *fetchResult;

@end

@implementation CAKAlbumAssetModelManager

+ (instancetype)createWithPHFetchResult:(PHFetchResult *)result provider:(CAKAlbumAssetModelProvider *)provider
{
    CAKAlbumAssetModelManager *manager = [CAKAlbumAssetModelManager new];
    manager.assetModelProvider = provider;
    manager.fetchResult = result;
    return manager;
}

- (CAKAlbumAssetModel *)objectIndex:(NSInteger)index
{
    CAKAlbumAssetModel *assetModel = nil;
    if (index < [self.fetchResult count]) {
        PHAsset *asset = [self.fetchResult objectAtIndex:index];
        assetModel = [self assetModelForPhAsset:asset];
    }
    return assetModel;
}

- (CAKAlbumAssetModel *)assetModelForPhAsset:(PHAsset *)asset
{
    return [self.assetModelProvider assetModelForPhAsset:asset];
}

- (BOOL)containsObject:(CAKAlbumAssetModel *)anObject
{
    return [self.fetchResult containsObject:anObject.phAsset];
}

- (NSInteger)indexOfObject:(CAKAlbumAssetModel *)model
{
    NSInteger originIndex = [self.fetchResult indexOfObject:model.phAsset];
    return originIndex;
}

@end

@interface CAKAlbumAssetDataModel ()

//transform the show index to origin fetchResult index
@property (nonatomic, strong) NSMutableArray<NSNumber*> *typeIndexArr;
//transform the preview index to origin fetchResult index
@property (nonatomic, strong) NSMutableArray<NSNumber*> *previewIndexArr;
@property (nonatomic, assign) NSInteger imageCount;
@property (nonatomic, assign) NSInteger videoCount;
@property (nonatomic, copy) BOOL (^filterBlock)(PHAsset *asset);
@property (nonatomic, copy) BOOL (^previewFilterBlock)(PHAsset *asset);

@end

@implementation CAKAlbumAssetDataModel

- (void)setAssetModelManager:(CAKAlbumAssetModelManager *)assetModelManager
{
    _assetModelManager = assetModelManager;
}

- (CAKAlbumAssetModel *)objectIndex:(NSInteger)index
{
    if (self.filterBlock) {
        NSNumber *indexValue = [self.typeIndexArr acc_objectAtIndex:index];
        CAKAlbumAssetModel *assetModel = [self.assetModelManager objectIndex:indexValue.integerValue];
        return assetModel;
    } else {
        CAKAlbumAssetModel *assetModel = [self.assetModelManager objectIndex:index];
        return assetModel;
    }
}

- (NSInteger)numberOfObject
{
    if (self.filterBlock) {
        return self.typeIndexArr.count;
    } else {
        return self.assetModelManager.fetchResult.count;
    }
}

- (void)configShowIndexFilterBlock:(BOOL (^)(PHAsset *asset))filterBlock
{
    if (filterBlock) {
        self.filterBlock = filterBlock;
        self.typeIndexArr = [NSMutableArray array];
        [self.assetModelManager.fetchResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (self.filterBlock(obj)) {
                [self.typeIndexArr acc_addObject:@(idx)];
            }
        }];
    };
}

- (NSInteger)indexOfObject:(CAKAlbumAssetModel *)model
{
    if (![self.assetModelManager.fetchResult containsObject:model.phAsset]) {
        return  0;
    }
    NSInteger originIndex = [self.assetModelManager.fetchResult indexOfObject:model.phAsset];
    if (self.filterBlock) {
        return [self.typeIndexArr indexOfObject:@(originIndex)];
    } else {
        return originIndex;
    }
}

- (BOOL)containsObject:(CAKAlbumAssetModel *)anObject
{
    if (![self.assetModelManager containsObject:anObject]) {
        return  NO;
    }
    if (self.filterBlock) {
        NSInteger originIndex = [self.assetModelManager indexOfObject:anObject];
        return [self.typeIndexArr containsObject:@(originIndex)];
    } else {
        return [self.assetModelManager containsObject:anObject];;
    }
}

#pragma mark - preview

- (void)configDataWithPreviewFilterBlock:(BOOL (^)(PHAsset *asset))filterBlock
{
    self.previewFilterBlock = filterBlock;
    self.previewIndexArr = [NSMutableArray array];
    if (self.filterBlock) {
        [self.previewIndexArr addObjectsFromArray:self.typeIndexArr];
    } else {
        for (NSUInteger i = 0; i < self.assetModelManager.fetchResult.count; i++) {
            [self.previewIndexArr acc_addObject:@(i)];
        }
    }
}

- (CAKAlbumAssetModel *)previewObjectIndex:(NSInteger)index
{
    if (self.previewFilterBlock) {
        CAKAlbumAssetModel *assetModel;
        if (index < self.previewIndexArr.count) {
            NSNumber *indexValue = [self.previewIndexArr acc_objectAtIndex:index];
            assetModel = [self.assetModelManager objectIndex:indexValue.integerValue];
        }
        return assetModel;
    } else {
        CAKAlbumAssetModel *assetModel = [self.assetModelManager objectIndex:index];
        return assetModel;
    }
}

- (NSInteger)previewNumberOfObject
{
    return self.previewIndexArr.count;
}

- (NSInteger)previewIndexOfObject:(CAKAlbumAssetModel *)model
{
    NSInteger index = [self.assetModelManager indexOfObject:model];
    index = [self.previewIndexArr indexOfObject:@(index)];
    return index;
}

- (BOOL)previewContainsObject:(CAKAlbumAssetModel *)anObject
{
    return NSNotFound != [self previewIndexOfObject:anObject];
}

- (BOOL)removePreviewInvalidAssetForPostion:(NSInteger)position
{
    if (!self.previewFilterBlock) {
        return NO;
    }
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSInteger index = position + 1; index < [self previewNumberOfObject]; index += 1) {
        CAKAlbumAssetModel *assetModel = [self previewObjectIndex:index];
        if (![self isValidAspectRatioAssetModel:assetModel]) {
            [indexSet addIndex:index];
        } else {
            break;
        }
    }
    for (NSInteger index = position - 1; index >= 0 && index < [self previewNumberOfObject]; index -= 1) {
        CAKAlbumAssetModel *assetModel = [self previewObjectIndex:index];
        if (![self isValidAspectRatioAssetModel:assetModel]) {
            [indexSet addIndex:index];
        } else {
            break;
        }
    }
    if (indexSet.count > 0) {
        NSMutableIndexSet *removeIndexSet = [NSMutableIndexSet indexSet];
        [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL * _Nonnull stop) {
            if ([self.previewIndexArr containsObject:@(idx)]) {
                [removeIndexSet addIndex:[self.previewIndexArr indexOfObject:@(idx)]];
            }
        }];
        [self.previewIndexArr removeObjectsAtIndexes:removeIndexSet];
        return YES;
    }
    return  NO;
}

- (BOOL)isValidAspectRatioAssetModel:(CAKAlbumAssetModel *)assetModel
{
    if (self.previewFilterBlock) {
        return self.previewFilterBlock(assetModel.phAsset);
    }
    return YES;
}

@end

@interface CAKAlbumDataModel()

@property (nonatomic, strong) CAKAlbumAssetModelProvider *assetModelProvider;

@end

@implementation CAKAlbumDataModel

- (void)dealloc
{
    [self.resultSourceAssetsSubject sendCompleted];
}

#pragma mark - update assets

- (void)addAsset:(CAKAlbumAssetModel *)model forResourceType:(AWEGetResourceType)resourceType
{
    NSString *keyPath = [self selectedAssetModelsKeyWithResourceType:resourceType];
    if (!model || ACC_isEmptyString(keyPath)) {
        return;
    }
    
    self.beforeSelectedPhotoCount = self.mixedSelectAssetsModels.count;
    if (self.addAssetInOrder && model.cellIndexPath) {
        [self p_addAssetInOrder:model forResourceType:resourceType];
    } else {
        [[self mutableArrayValueForKeyPath:keyPath] acc_addObject:model];
    }
}

- (void)removeAsset:(CAKAlbumAssetModel *)model forResourceType:(AWEGetResourceType)resourceType
{
    NSString *keyPath = [self selectedAssetModelsKeyWithResourceType:resourceType];
    if (!model || ACC_isEmptyString(keyPath)) {
        return;
    }
    
    self.beforeSelectedPhotoCount = self.mixedSelectAssetsModels.count;
    if (self.removeAssetInOrder && model.cellIndexPath) {
        [self p_removeAssetInOrder:model forResourceType:resourceType];
    } else {
        [[self mutableArrayValueForKeyPath:keyPath] removeObject:model];
    }
}

- (void)p_addAssetInOrder:(CAKAlbumAssetModel *)model forResourceType:(AWEGetResourceType)resourceType
{
    NSString *keyPath = [self selectedAssetModelsKeyWithResourceType:resourceType];
    NSInteger insertIndex = [self selectedAssetIndex:model.cellIndexPath.item resourceType:resourceType];
    if (insertIndex >= 0 && insertIndex < [self mutableArrayValueForKeyPath:keyPath].count) {
        [[self mutableArrayValueForKeyPath:keyPath] acc_insertObject:model atIndex:insertIndex];
    } else {
        [[self mutableArrayValueForKeyPath:keyPath] acc_addObject:model];
    }
}

- (void)p_removeAssetInOrder:(CAKAlbumAssetModel *)model forResourceType:(AWEGetResourceType)resourceType
{
    NSString *keyPath = [self selectedAssetModelsKeyWithResourceType:resourceType];
    NSInteger removeIndex = [self selectedAssetIndex:model.cellIndexPath.item resourceType:resourceType];
    if (removeIndex >= 0 && removeIndex < [self mutableArrayValueForKeyPath:keyPath].count &&
        [model.phAsset.localIdentifier isEqualToString:((CAKAlbumAssetModel *)[[self mutableArrayValueForKeyPath:keyPath] acc_objectAtIndex:removeIndex]).phAsset.localIdentifier]) {
        [[self mutableArrayValueForKeyPath:keyPath] acc_removeObjectAtIndex:removeIndex];
    } else {
        [[self mutableArrayValueForKeyPath:keyPath] removeObject:model];
    }
}

- (void)removeAllAssetsForResourceType:(AWEGetResourceType)resourceType
{
    NSString *keyPath = [self selectedAssetModelsKeyWithResourceType:resourceType];
    if (ACC_isEmptyString(keyPath)) {
        return;
    }
    
    self.beforeSelectedPhotoCount = self.mixedSelectAssetsModels.count;
    [[self mutableArrayValueForKeyPath:keyPath] removeAllObjects];
}

#pragma mark - assetModel provider

- (void)setupAssetModelProvider
{
    self.assetModelProvider = [[CAKAlbumAssetModelProvider alloc] init];
}

#pragma mark - Getter

- (NSMutableArray<CAKAlbumAssetModel *> *)videoSelectAssetsModels
{
    if (!_videoSelectAssetsModels) {
        _videoSelectAssetsModels = [NSMutableArray array];
    }

    return _videoSelectAssetsModels;
}

- (NSMutableArray<CAKAlbumAssetModel *> *)photoSelectAssetsModels
{
    if (!_photoSelectAssetsModels) {
        _photoSelectAssetsModels = [NSMutableArray array];
    }
    return _photoSelectAssetsModels;
}

- (NSMutableArray<CAKAlbumAssetModel *> *)mixedSelectAssetsModels
{
    if (!_mixedSelectAssetsModels) {
        _mixedSelectAssetsModels = [NSMutableArray array];
    }
    return _mixedSelectAssetsModels;
}


- (RACSubject *)resultSourceAssetsSubject
{
    if (!_resultSourceAssetsSubject) {
        _resultSourceAssetsSubject = [RACSubject subject];
    }
    return _resultSourceAssetsSubject;
}

#pragma mark - Utils

- (NSString *)selectedAssetModelsKeyWithResourceType:(AWEGetResourceType)type
{
    if (type == AWEGetResourceTypeImage) {
        return @keypath(self, photoSelectAssetsModels);
    }
    
    if (type == AWEGetResourceTypeVideo) {
        return @keypath(self, videoSelectAssetsModels);
    }
    
    if (type == AWEGetResourceTypeImageAndVideo) {
        return @keypath(self, mixedSelectAssetsModels);
    }
    
    return @"";
}

- (NSInteger)selectedAssetIndex:(NSInteger)mixedIndex resourceType:(AWEGetResourceType)type
{
    if (type == AWEGetResourceTypeImageAndVideo) {
        return mixedIndex;
    }
    
    // calculate current index in photoSelectAssetsModels
    __block NSInteger separateIndex = mixedIndex;
    if (type == AWEGetResourceTypeImage) {
        [self.mixedSelectAssetsModels enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx < mixedIndex && obj.mediaType != CAKAlbumAssetModelMediaTypePhoto) {
                separateIndex--;
            }
            if (idx >= mixedIndex) {
                *stop = YES;
            }
        }];
        return separateIndex;
    }
    
    // calculate current index in videoSelectAssetsModels
    if (type == AWEGetResourceTypeVideo) {
        [self.mixedSelectAssetsModels enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (idx < mixedIndex && obj.mediaType != CAKAlbumAssetModelMediaTypeVideo) {
                separateIndex--;
            }
            if (idx >= mixedIndex) {
                *stop = YES;
            }
        }];
        return separateIndex;
    }
    
    return separateIndex;
}

- (CAKAlbumAssetModel *)findAssetWithResourceType:(AWEGetResourceType)resourceType localIdentifier:(NSString *)localIdentifier
{
    if (ACC_isEmptyString(localIdentifier)) {
        return nil;
    }
    
    NSString *keyPath = [self selectedAssetModelsKeyWithResourceType:resourceType];
    for (CAKAlbumAssetModel *model in [self mutableArrayValueForKeyPath:keyPath]) {
        if ([model.phAsset.localIdentifier isEqualToString:localIdentifier]) {
            return model;
        }
    }
    
    return nil;
}

@end
