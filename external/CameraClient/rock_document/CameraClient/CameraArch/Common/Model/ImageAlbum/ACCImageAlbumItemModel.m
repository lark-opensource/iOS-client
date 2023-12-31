//
//  ACCImageAlbumItemModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/9.
//

#import "ACCImageAlbumItemModel.h"
#import <CreativeKit/ACCMacros.h>

#define ACCImageAlbumEditInfoPropertyLazyLoad(ClassName, property)\
@synthesize property = _##property; \
- (ClassName *)property \
{ \
    if (!_##property) { \
        _##property = [[ClassName alloc] initWithTaskId:self.taskId]; \
    } \
    return _##property; \
}

@implementation ACCImageAlbumItemModel

- (instancetype)initWithTaskId:(NSString *)taskId index:(NSInteger)index
{
    if (self = [ super initWithTaskId:taskId]) {
        _itemIdentify = [NSString stringWithFormat:@"%@:%@", @(index), [[NSUUID UUID] UUIDString]];
    }
    return self;
}

ACCImageAlbumEditInfoPropertyLazyLoad(ACCImageAlbumItemOriginalImageInfo, originalImageInfo)
ACCImageAlbumEditInfoPropertyLazyLoad(ACCImageAlbumItemBackupImageInfo, backupImageInfo)
ACCImageAlbumEditInfoPropertyLazyLoad(ACCImageAlbumItemHDRInfo, HDRInfo)
ACCImageAlbumEditInfoPropertyLazyLoad(ACCImageAlbumItemStickerInfo, stickerInfo)
ACCImageAlbumEditInfoPropertyLazyLoad(ACCImageAlbumItemFilterInfo, filterInfo)
ACCImageAlbumEditInfoPropertyLazyLoad(ACCImageAlbumItemCropInfo, cropInfo)

- (void)updateRecoveredEffectIfNeedWithIdentifier:(NSString *)resourceId filePath:(NSString *)filePath
{
    [self.originalImageInfo updateRecoveredEffectIfNeedWithIdentifier:resourceId filePath:filePath];
    [self.HDRInfo updateRecoveredEffectIfNeedWithIdentifier:resourceId filePath:filePath];
    [self.filterInfo updateRecoveredEffectIfNeedWithIdentifier:resourceId filePath:filePath];
    [self.stickerInfo updateRecoveredEffectIfNeedWithIdentifier:resourceId filePath:filePath];
    [self.cropInfo updateRecoveredEffectIfNeedWithIdentifier:resourceId filePath:filePath];
}

- (void)deepCopyValuesIfNeedFromTarget:(ACCImageAlbumItemModel *)target
{
    [super deepCopyValuesIfNeedFromTarget:target];
    
    if (![target isKindOfClass:[ACCImageAlbumItemModel class]]) {
        NSAssert(NO, @"check");
        return;
    }
    _originalImageInfo = [target.originalImageInfo copy];
    _HDRInfo = [target.HDRInfo copy];
    _stickerInfo = [target.stickerInfo copy];
    _filterInfo = [target.filterInfo copy];
    _cropInfo = [target.cropInfo copy];
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    [super amazingMigrateResourceToNewDraftWithTaskId:taskId];
    [self.originalImageInfo amazingMigrateResourceToNewDraftWithTaskId:taskId];
    [self.HDRInfo amazingMigrateResourceToNewDraftWithTaskId:taskId];
    [self.stickerInfo amazingMigrateResourceToNewDraftWithTaskId:taskId];
    [self.filterInfo amazingMigrateResourceToNewDraftWithTaskId:taskId];
    [self.cropInfo amazingMigrateResourceToNewDraftWithTaskId:taskId];
}

@end

@implementation ACCImageAlbumItemOriginalImageInfo

- (void)resetImageWithAbsoluteFilePath:(NSString *)filePath imageSize:(CGSize)imageSize imageScale:(CGFloat)imageScale
{
    [self setAbsoluteFilePath:filePath];
    self.width = imageSize.width;
    self.height = imageSize.height;
    self.scale = imageScale;
}

- (CGSize)imageSize
{
    CGSize ret = CGSizeMake(self.width, self.height);
    if (CGSizeEqualToSize(CGSizeZero, ret)) {
        NSAssert(NO, @"check");
        ret = CGSizeZero;
        NSString *filePath = [self getAbsoluteFilePath];
        if (!ACC_isEmptyString(filePath)) {
            ret = [UIImage imageWithContentsOfFile:filePath].size;
        }
    }
    return ret;
}

@end

@implementation ACCImageAlbumItemBackupImageInfo

@end

@interface ACCImageAlbumItemHDRInfo ()

@end


@implementation ACCImageAlbumItemHDRInfo

- (void)updateLensHDRModelWithFilePath:(NSString *)filePath
{
    [self setAbsoluteFilePath:filePath];
}

- (NSString *)lensHDRModelFilePath
{
    return [self getAbsoluteFilePath];
}

- (void)deepCopyValuesIfNeedFromTarget:(id)target
{
    [super deepCopyValuesIfNeedFromTarget:target];
    // just mark, nothing need to copy by manual
}

@end

@implementation ACCImageAlbumItemFilterInfo

- (BOOL)isValidFilter
{
    return (!ACC_isEmptyString(self.effectIdentifier) &&
            !ACC_isEmptyString([self getAbsoluteFilePath]) &&
            self.filterIntensityRatio != nil);
}

- (void)deepCopyValuesIfNeedFromTarget:(id)target
{
    [super deepCopyValuesIfNeedFromTarget:target];
    // just mark, nothing need to copy by manual
}

@end

@implementation ACCImageAlbumItemStickerInfo

- (ACCImageAlbumStickerModel *)stickerWithUniqueId:(NSInteger)uniqueId
{
    __block ACCImageAlbumStickerModel *ret = nil;
    [[self.stickers copy] enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.uniqueId == uniqueId) {
            ret = obj;
            *stop = YES;
        }
    }];
    
    return ret;
}

- (NSArray<ACCImageAlbumStickerModel *> *)orderAscendingStickers
{
    return [[self.stickers copy] sortedArrayUsingComparator:^NSComparisonResult(ACCImageAlbumStickerModel *_Nonnull obj1, ACCImageAlbumStickerModel *_Nonnull obj2) {
        
        if (obj1.param.order > obj2.param.order) {
            return NSOrderedDescending;
        } else if (obj1.param.order < obj2.param.order) {
            return NSOrderedAscending;
        } else {
            return NSOrderedSame;
        }
    }];
}

- (BOOL)containStickerWithUniqueId:(NSInteger)uniqueId
{
    return [self stickerWithUniqueId:uniqueId] != nil;
}

- (void)addStickerWithSticker:(ACCImageAlbumStickerModel *)sticker
{
    if (!sticker) {
        return;
    }
    NSMutableArray *stickers = [NSMutableArray arrayWithArray:self.stickers ?: @[]];
    [stickers addObject:sticker];
    self.stickers = [stickers copy];
}

- (void)removeStickerWithUniqueId:(NSInteger)uniqueId
{
    ACCImageAlbumStickerModel *sticker = [self stickerWithUniqueId:uniqueId];
    if (!sticker) {
        return;
    }
    NSMutableArray *stickers = [NSMutableArray arrayWithArray:self.stickers ?: @[]];
    [stickers removeObject:sticker];
    self.stickers = [stickers copy];
}

- (void)removeAllStickers
{
    if (self.stickers.count > 0) {
        self.stickers = @[];
    }
    
    if (self.textStickers.count > 0) {
        self.textStickers = @[];
    }
    
    if (self.interactionStickers.count > 0) {
        self.interactionStickers = @[];
    }
}

- (NSInteger)maxOrder
{
    return [self orderAscendingStickers].lastObject.param.order;
}

- (void)deepCopyValuesIfNeedFromTarget:(ACCImageAlbumItemStickerInfo *)target
{
    [super deepCopyValuesIfNeedFromTarget:target];
    if (![target isKindOfClass:[ACCImageAlbumItemStickerInfo class]]) {
        NSAssert(NO, @"check");
        return;
    }
    
    _stickers = ACCImageAlbumDeepCopyObjectArray(target.stickers);
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    [super amazingMigrateResourceToNewDraftWithTaskId:taskId];
    [[self.stickers copy] enumerateObjectsUsingBlock:^(ACCImageAlbumStickerModel *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj amazingMigrateResourceToNewDraftWithTaskId:taskId];
    }];
}

@end


@implementation ACCImageAlbumStickerSearchResult

@end

@implementation ACCImageAlbumItemCropInfo

- (BOOL)hasCropped
{
    if (self.cropRatio != ACCImageAlbumItemCropRatioOriginal ||
        self.zoomScale != 1.0 ||
        !CGPointEqualToPoint(self.contentOffset, CGPointZero) ||
        !CGRectEqualToRect(self.cropRect, CGRectZero)) {
        return YES;
    }
    
    return NO;
}

- (NSString *)cropRatioString
{
    return [self.class cropRatioString:self.cropRatio];
}

+ (NSString *)cropRatioString:(ACCImageAlbumItemCropRatio)cropRatio
{
    switch (cropRatio) {
        case ACCImageAlbumItemCropRatioOriginal:
            return @"original";
            break;
            
        case ACCImageAlbumItemCropRatio9_16: {
            return @"9:16";
            break;
        }
            
        case ACCImageAlbumItemCropRatio3_4:
            return @"3:4";
            break;
            
        case ACCImageAlbumItemCropRatio1_1:
            return @"1:1";
            break;
            
        case ACCImageAlbumItemCropRatio4_3:
            return @"4:3";
            break;
            
        case ACCImageAlbumItemCropRatio16_9:
            return @"16:9";
            break;
            
        default:
            return @"original";
            break;
    }
}

@end
