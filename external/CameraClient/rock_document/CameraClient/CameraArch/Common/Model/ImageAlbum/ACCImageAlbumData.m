//
//  ACCImageAlbumData.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import "ACCImageAlbumData.h"
#import "ACCImageAlbumItemModel.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCImageAlbumEditImageInputInfo.h"
#import "ACCImageAlbumItemBaseResourceModel.h"
#import "ACCRepoImageAlbumInfoModel.h"

@implementation ACCImageAlbumData

- (instancetype)initWithImageAlbumInfoModel:(ACCRepoImageAlbumInfoModel *)imageAlbumInfoModel
                                     taskId:(nonnull NSString *)taskId
{
    if (self = [super init]) {
        
        NSParameterAssert(taskId != nil);
        // 发布后编辑要求在进发布后再下载数据，所以一开始肯定要命中这个assert
//        NSParameterAssert(originalImages.count > 0);
        
        _taskId = [taskId copy];
        
        NSMutableArray <ACCImageAlbumItemModel *> * albumItemModels = [NSMutableArray array];
        [[imageAlbumInfoModel.imageEditOriginalImages copy] enumerateObjectsUsingBlock:^(ACCImageAlbumEditImageInputInfo *_Nonnull imageInfo, NSUInteger idx, BOOL * _Nonnull stop) {
            
            ACCImageAlbumItemModel *model = [[ACCImageAlbumItemModel alloc] initWithTaskId:taskId index:idx];
            [model.originalImageInfo setAbsoluteFilePath:[imageInfo getAbsoluteFilePath]];
            model.originalImageInfo.width = imageInfo.imageSize.width;
            model.originalImageInfo.height = imageInfo.imageSize.height;
            model.originalImageInfo.scale = imageInfo.imageScale;
            
            ACCImageAlbumItemDraftResourceRestorableModel *placeHolderImageInfo = [[ACCImageAlbumItemDraftResourceRestorableModel alloc] initWithTaskId:taskId];
            [placeHolderImageInfo setAbsoluteFilePath:imageInfo.placeholderImageFilePath];
            model.originalImageInfo.placeHolderImageInfo = placeHolderImageInfo;
            
            ACCImageAlbumEditImageInputInfo *backupImageInfo = (ACCImageAlbumEditImageInputInfo *)[imageAlbumInfoModel.imageEditBackupImages acc_objectAtIndex:idx];
            model.cropInfo.cropRatio = ACCImageAlbumItemCropRatioOriginal;
            model.cropInfo.zoomScale = 1.0;
            model.cropInfo.contentOffset = CGPointZero;
            model.cropInfo.cropRect = CGRectZero;
            
            [model.backupImageInfo setAbsoluteFilePath:[backupImageInfo getAbsoluteFilePath]];
            model.backupImageInfo.width = imageInfo.imageSize.width;
            model.backupImageInfo.height = imageInfo.imageSize.height;
            
            [albumItemModels addObject:model];
        }];
        _imageAlbumItems = [albumItemModels copy];
    }
    return self;
}

- (instancetype)initForCopyWithTarget:(ACCImageAlbumData *)target
{
    if (self = [super init]) {
        _taskId = [target.taskId copy];
        _imageAlbumItems = ACCImageAlbumDeepCopyObjectArray(target.imageAlbumItems);
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[ACCImageAlbumData allocWithZone:zone] initForCopyWithTarget:self];
}

@end


@implementation ACCImageAlbumData(ResourceUpdate)

- (void)updateRecoveredEffectIfNeedWithIdentifier:(NSString *)effectIdentifier filePath:(NSString *)filePath
{
    [[self.imageAlbumItems copy] enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj updateRecoveredEffectIfNeedWithIdentifier:effectIdentifier filePath:filePath];
    }];
}

- (void)updateLensHDRModelWithFilePath:(NSString *)filePath
{
    [[self.imageAlbumItems copy] enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj.HDRInfo updateLensHDRModelWithFilePath:filePath];
    }];
}

@end


@implementation ACCImageAlbumData (ResourceGetter)

- (ACCImageAlbumStickerSearchResult *)stickerWithUniqueId:(NSInteger)uniqueId
                                      preferredImageIndex:(NSNumber * _Nullable)preferredImageIndex
{
    __block ACCImageAlbumStickerModel *sticker = nil;
    __block NSInteger imageIndex = 0;
    
    if (preferredImageIndex != nil) {
        
        ACCImageAlbumItemModel *itemModel = [self.imageAlbumItems acc_objectAtIndex:preferredImageIndex.integerValue];
        sticker = [itemModel.stickerInfo stickerWithUniqueId:uniqueId];
        imageIndex = [preferredImageIndex integerValue];
    }
    
    if (!sticker) {
        
        [self.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            sticker = [obj.stickerInfo stickerWithUniqueId:uniqueId];
            if (sticker) {
                imageIndex = idx;
                *stop = YES;
            }
        }];
    }

    if (!sticker) {
        return nil;
    }
    
    ACCImageAlbumStickerSearchResult *ret = [[ACCImageAlbumStickerSearchResult alloc] init];
    ret.sticker = sticker;
    ret.imageIndex = imageIndex;
    
    return ret;
}

- (NSInteger)maxStickerUniqueId;
{
    __block NSInteger ret = 0;
    
    [self.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        [item.stickerInfo.stickers enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull sticker, NSUInteger idx, BOOL * _Nonnull stop) {
            if (sticker.uniqueId > ret) {
                ret = sticker.uniqueId;
            }
        }];
    }];
    
    return ret;
}

- (NSString *)itemIdentifyAtIndex:(NSInteger)imageIndex
{
    return [self.imageAlbumItems acc_objectAtIndex:imageIndex].itemIdentify;
}

@end

@implementation ACCImageAlbumData (ResourceModify)

- (void)moveImageFromIndex:(NSInteger)fromIndex
                   toIndex:(NSInteger)toIndex
{
    NSMutableArray *tmpImageAlbumItems = _imageAlbumItems.mutableCopy;
    [tmpImageAlbumItems acc_moveObjectFromIndex:fromIndex toIndex:toIndex];
    _imageAlbumItems = tmpImageAlbumItems.copy;
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    _taskId = [taskId copy];
    [[self.imageAlbumItems copy] enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj amazingMigrateResourceToNewDraftWithTaskId:taskId];
    }];
    
}

- (void)amazingDivideImageAlbumDataFromTargetImageIndex:(NSInteger)imageIndex
{
    ACCImageAlbumItemModel *itemModel = [self.imageAlbumItems acc_objectAtIndex:imageIndex];
    
    if (!itemModel) {
        NSAssert(NO, @"imageIndex out of image items's bounce");
        return;
    }
    _imageAlbumItems = @[itemModel];
}

@end
