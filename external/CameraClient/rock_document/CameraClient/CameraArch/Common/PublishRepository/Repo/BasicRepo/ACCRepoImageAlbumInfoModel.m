//
//  ACCRepoImageAlbumInfoModel.m
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/9.
//

#import "ACCRepoImageAlbumInfoModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import "ACCImageAlbumData.h"
#import "ACCImageEditItemCoverInfo.h"
#import <CreativeKit/ACCMacros.h>
#import "ACCImageAlbumItemBaseResourceModel.h"
#import "ACCImageAlbumEditImageInputInfo.h"
#import "AWEInteractionStickerModel+DAddition.h"
#import "AWEInteractionEditTagStickerModel.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/AWEInteractionStickerModel.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CameraClient/AWERepoContextModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#pragma mark - ACCRepositoryElementRegisterCategoryProtocol
@interface AWEVideoPublishViewModel (RepoImageAlbumInfo) <ACCRepositoryElementRegisterCategoryProtocol>

@end

@implementation AWEVideoPublishViewModel (RepoImageAlbumInfo)

- (ACCRepositoryRegisterInfo *)repoRegisterInfo {
    ACCRepositoryRegisterInfo *info = [[ACCRepositoryRegisterInfo alloc] initWithClassInfo:ACCRepoImageAlbumInfoModel.class];
    return info;
}

- (ACCRepoImageAlbumInfoModel *)repoImageAlbumInfo
{
    ACCRepoImageAlbumInfoModel *model = [self extensionModelOfClass:[ACCRepoImageAlbumInfoModel class]];
    NSParameterAssert(model != nil);
    return model;
}

@end

#pragma mark - ACCRepoImageAlbumInfoModel
@interface ACCRepoImageAlbumInfoModel() <NSCopying, ACCRepositoryContextProtocol, ACCRepositoryRequestParamsProtocol>

@end

@implementation ACCRepoImageAlbumInfoModel
@synthesize repository;

#pragma mark - NSCopying
- (id)copyWithZone:(NSZone *)zone
{
    ACCRepoImageAlbumInfoModel *model = [[[self class] alloc] init];
    model.imageAlbumData = [self.imageAlbumData copy];
    model.imageEditOriginalImages = ACCImageAlbumDeepCopyObjectArray(self.imageEditOriginalImages);
    model.imageEditBackupImages = ACCImageAlbumDeepCopyObjectArray(self.imageEditBackupImages);
    model.imageEditCompressedFramsImages =  ACCImageAlbumDeepCopyObjectArray(self.imageEditCompressedFramsImages);;
    model.dynamicCoverIndex = self.dynamicCoverIndex;
    model.imageItemsCoverInfoMapping = ACCImageAlbumDeepCopyObjectDictionary(self.imageItemsCoverInfoMapping);
    model.transformContext = [self.transformContext copy];
    model.batchStoryPublishContext = self.batchStoryPublishContext;
    model.runtimeExportedLocalImageFilePaths = [self.runtimeExportedLocalImageFilePaths copy];

    return model;
}

- (NSInteger)imageCount
{
    return self.imageAlbumData.imageAlbumItems.count;
}

- (void)updateImageItemCoverCropOffsetsValue:(CGPoint)offsets withItemIdentify:(NSString *)itemIdentify
{
    if (ACC_isEmptyString(itemIdentify)) {
        return;
    }
    
    ACCImageEditItemCoverInfo *coverInfo = self.imageItemsCoverInfoMapping[itemIdentify];
    if (!coverInfo) {
        coverInfo = [[ACCImageEditItemCoverInfo alloc] init];
    }
    coverInfo.cropOffsetX = offsets.x;
    coverInfo.cropOffsetY = offsets.y;
    NSMutableDictionary <NSString *, ACCImageEditItemCoverInfo *> *tmps = [NSMutableDictionary dictionaryWithDictionary:self.imageItemsCoverInfoMapping ?: @{}];
    tmps[itemIdentify] = coverInfo;
    _imageItemsCoverInfoMapping = [tmps copy];
}

- (UIImage *)originalImageAtIndex:(NSInteger)index
{
    NSString *imageFile = [[self.imageEditOriginalImages acc_objectAtIndex:index] getAbsoluteFilePath];
    
    if (!ACC_isEmptyString(imageFile) && [[NSFileManager defaultManager] fileExistsAtPath:imageFile]) {
        return [UIImage imageWithContentsOfFile:imageFile];
    }
    return nil;
}

- (CGPoint)imageItemCoverCropOffsetsWithIdentify:(NSString *)itemIdentify
{
    if (ACC_isEmptyString(itemIdentify)) {
        return CGPointZero;
    }
    ACCImageEditItemCoverInfo *coverInfo = self.imageItemsCoverInfoMapping[itemIdentify];
    return CGPointMake(coverInfo.cropOffsetX, coverInfo.cropOffsetY);
}

- (BOOL)isImageAlbumEdit
{
    ACCRepoContextModel *context = [self.repository extensionModelOfClass:ACCRepoContextModel.class];
    return context.videoType == AWEVideoTypeImageAlbum;
}

- (BOOL)isTransformedFromImageAlbumMVVideoEditMode
{
    return (!self.isImageAlbumEdit && self.transformContext.isImageAlbumTransformContext && self.transformContext.didTransformedOnce);
}

- (NSDictionary *)acc_publishRequestParams:(AWEVideoPublishViewModel *)publishViewModel
{
    NSMutableDictionary *ret = [NSMutableDictionary dictionary];
    
    if ([self isImageAlbumEdit] && [self.batchStoryPublishContext isStoryBatchPublish]) {
        // 批量日常发布标志
        [ret setObject:@(YES) forKey:@"in_story_section"];
        // 批量任务的首个是没有sectionId的 而是发布成功后服务端回传，用于后续同一批发布任务的透传
        NSString *sectionId = [self.batchStoryPublishContext sectionId];
        if (!ACC_isEmptyString(sectionId)) {
            [ret setObject:sectionId forKey:@"story_section_id"];
        }
    }
    
    if ([self isImageAlbumEdit]) {
        NSMutableArray<AWEInteractionStickerModel *> *interactionStickers = [[NSMutableArray alloc] init];
        [self.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            CGSize actualSize = obj.stickerInfo.mediaActualSize;
            [obj.stickerInfo.interactionStickers enumerateObjectsUsingBlock:^(AWEInteractionStickerModel * _Nonnull obj, NSUInteger index, BOOL * _Nonnull stop) {
                obj.imageIndex = idx;
                AWEInteractionStickerModel *model = [self p_handleInteractionStickerBeforePublish:obj actualSize:actualSize];
                [interactionStickers acc_addObject:model];
            }];
        }];
        if (interactionStickers.count) {
            NSError *error = nil;
            NSArray *stickers = [MTLJSONAdapter JSONArrayFromModels:[interactionStickers copy] error:&error];
            NSData *arrJsonData = [NSJSONSerialization dataWithJSONObject:stickers options:kNilOptions error:&error];
            NSString *stickersStr = [[NSString alloc] initWithData:arrJsonData encoding:NSUTF8StringEncoding];
            ret[@"interaction_stickers"] = stickersStr;
        }
    }
    
    return [ret copy];
}

- (AWEInteractionStickerModel *)p_handleInteractionStickerBeforePublish:(AWEInteractionStickerModel *)model actualSize:(CGSize)actualSize{
    if (model.type == AWEInteractionStickerTypeEditTag && [model isKindOfClass:AWEInteractionEditTagStickerModel.class]) {
        // iOS默认计算的是中心点，需要转换到实际的锚点位置
        AWEInteractionEditTagStickerModel *editTagModel = [model copy];
        ACCEditTagOrientation orientation = editTagModel.editTagInfo.orientation;
        AWEInteractionStickerLocationModel *location = [editTagModel generateLocationModel];
        CGFloat offset = actualSize.width > 0 ? 3.f / actualSize.width : 0.f;
        if (orientation == ACCEditTagOrientationRight) {
            location.x = [NSDecimalNumber decimalNumberWithString:@(location.x.floatValue + location.width.floatValue/2.f - offset).stringValue];
        } else {
            location.x = [NSDecimalNumber decimalNumberWithString:@(location.x.floatValue - location.width.floatValue/2.f + offset).stringValue];
        }
        [editTagModel updateLocationInfo:location];
        return editTagModel;
    }
    return model;
}

- (NSDictionary *)tagsTrackInfo
{
    if ([self isImageAlbumEdit]) {
        __block NSUInteger POITagsCount = 0, userTagsCount = 0, goodsTagsCount = 0, brandTagsCount = 0, customTagsCount = 0;
        NSMutableString *tagString = [NSMutableString string];
        [self.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NSMutableArray *oneImageTags = [[NSMutableArray alloc] init];
            [[obj.stickerInfo.interactionStickers acc_filter:^BOOL(AWEInteractionStickerModel * _Nonnull item) {
                return [item isKindOfClass:[AWEInteractionEditTagStickerModel class]];
            }] enumerateObjectsUsingBlock:^(AWEInteractionEditTagStickerModel * _Nonnull oneSticker, NSUInteger idx, BOOL * _Nonnull stop) {
                [oneImageTags acc_addObject:[oneSticker.editTagInfo tagId]];
                if (oneSticker.editTagInfo.type == ACCEditTagTypeUser) {
                    userTagsCount++;
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypePOI) {
                    POITagsCount++;
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypeCommodity) {
                    goodsTagsCount++;
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypeBrand) {
                    brandTagsCount++;
                } else if (oneSticker.editTagInfo.type == ACCEditTagTypeSelfDefine) {
                    customTagsCount++;
                }
            }];
            if (tagString.length > 0) {
                [tagString appendString:@";"];
            }
            if (oneImageTags.count > 0) {
                [tagString appendFormat:@"%@:%@", @(idx + 1), [oneImageTags componentsJoinedByString:@","]];
            } else {
                [tagString appendFormat:@"%@:null", @(idx + 1)];
            }
        }];

        return @{
            @"tag_list": tagString?:@"",
            @"tag_cnt": @(POITagsCount + userTagsCount + goodsTagsCount + brandTagsCount + customTagsCount),
            @"user_tag_cnt": @(userTagsCount),
            @"poi_tag_cnt": @(POITagsCount),
            @"goods_tag_cnt": @(goodsTagsCount),
            @"brand_tag_cnt": @(brandTagsCount),
            @"custom_tag_cnt": @(customTagsCount)
        };
    }
    return nil;
}

- (NSDictionary *)cropTrackInfo
{
    if ([self isImageAlbumEdit] && ACCConfigBool(kConfigBool_enable_image_multi_crop)) {
        __block NSUInteger changedRatioCount = 0, changedZoomScaleCount = 0;
        NSMutableString *imageRatioStrings = [NSMutableString string];
        [self.imageAlbumData.imageAlbumItems enumerateObjectsUsingBlock:^(ACCImageAlbumItemModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            
            NSString *cropRatioString;
            if (obj.cropInfo.cropRatio != ACCImageAlbumItemCropRatioOriginal) {
                changedRatioCount += 1;
                cropRatioString = obj.cropInfo.cropRatioString;
            } else {
                cropRatioString = [self p_originalCropRatio:CGSizeMake(obj.originalImageInfo.width, obj.originalImageInfo.height)];
            }
            
            if (obj.cropInfo.zoomScale > 1.0) {
                changedZoomScaleCount += 1;
            }
            
            if (idx == self.imageAlbumData.imageAlbumItems.count - 1) {
                [imageRatioStrings appendFormat:@"%@", cropRatioString];
            } else {
                [imageRatioStrings appendFormat:@"%@,", cropRatioString];
            }
        }];

        return @{
            @"change_photo_ratio_cnt": @(changedRatioCount),
            @"pinch_photo_cnt": @(changedZoomScaleCount),
            @"pic_ratio": imageRatioStrings
        };
    }
    return nil;
}

// 辗转相除法/欧几里得算法、求最大公约数
NSInteger p_gcd(NSInteger n, NSInteger m) {
    return m == 0 ? n : p_gcd(m, n % m);
}

- (NSString *)p_originalCropRatio:(CGSize)imageSize
{
    if (imageSize.height <= 0.0) {
        return @"null";
    }
    
    CGFloat ratio9_14 = 9.0 / 14.0;  // 9:16=0.5625，9:15=0.6
    CGFloat ratio3_4 = 3.0 / 4.0;
    CGFloat imageRatio = imageSize.width / imageSize.height;
    if (imageRatio <= ratio9_14) {
        return @"9:16";
    } else if (imageRatio <= ratio3_4) {
        return @"3:4";
    } else {
        NSInteger width = (NSInteger)imageSize.width;
        NSInteger height = (NSInteger)imageSize.height;
        NSInteger gcd = p_gcd(width, height);
        if (gcd > 1) {
            return [NSString stringWithFormat:@"%@:%@", @(width / gcd), @(height / gcd)];
        } else {
            return [NSString stringWithFormat:@"%@:%@", @(width), @(height)];
        }
    }
}

@end

@implementation ACCRepoImageAlbumInfoModel (ResourceModify)

- (void)moveImageFromIndex:(NSInteger)fromIndex
                   toIndex:(NSInteger)toIndex
{
    NSMutableArray *tmpImageEditOriginalImages = self.imageEditOriginalImages.mutableCopy;
    [tmpImageEditOriginalImages acc_moveObjectFromIndex:fromIndex toIndex:toIndex];
    self.imageEditOriginalImages = tmpImageEditOriginalImages.copy;
    
    NSMutableArray *tmpImageEditBackupImages = self.imageEditBackupImages.mutableCopy;
    [tmpImageEditBackupImages acc_moveObjectFromIndex:fromIndex toIndex:toIndex];
    self.imageEditBackupImages = tmpImageEditBackupImages.copy;
    
    NSMutableArray *tmpImageEditCompressedFramsImages = self.imageEditCompressedFramsImages.mutableCopy;
    [tmpImageEditCompressedFramsImages acc_moveObjectFromIndex:fromIndex toIndex:toIndex];
    self.imageEditCompressedFramsImages = tmpImageEditCompressedFramsImages.copy;
    
    [self.imageAlbumData moveImageFromIndex:fromIndex toIndex:toIndex];
}

- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId
{
    [self.imageAlbumData amazingMigrateResourceToNewDraftWithTaskId:taskId];
    
    [[self.imageEditOriginalImages copy] enumerateObjectsUsingBlock:^(ACCImageAlbumEditImageInputInfo *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj amazingMigrateResourceToNewDraftWithTaskId:taskId];
    }];
    
    [[self.imageEditBackupImages copy] enumerateObjectsUsingBlock:^(ACCImageAlbumEditImageInputInfo *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj amazingMigrateResourceToNewDraftWithTaskId:taskId];
    }];
    
    [[self.imageEditCompressedFramsImages copy] enumerateObjectsUsingBlock:^(ACCImageAlbumEditImageInputInfo *_Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [obj amazingMigrateResourceToNewDraftWithTaskId:taskId];
    }];
}

- (void)amazingDivideImageAlbumDataFromTargetImageIndex:(NSInteger)imageIndex
{
    [self.imageAlbumData amazingDivideImageAlbumDataFromTargetImageIndex:imageIndex];
    
    ACCImageAlbumEditImageInputInfo *originalImage = [self.imageEditOriginalImages acc_objectAtIndex:imageIndex];
    
    /// original image
    if (originalImage) {
        self.imageEditOriginalImages = @[originalImage];
    }
    
    ACCImageAlbumEditImageInputInfo *backupImage = [self.imageEditBackupImages acc_objectAtIndex:imageIndex];
    
    /// backup image
    if (backupImage) {
        self.imageEditBackupImages = @[backupImage];
    }
    
    /// compressed image
    ACCImageAlbumEditImageInputInfo *compressedImage = [self.imageEditCompressedFramsImages acc_objectAtIndex:imageIndex];
    
    if (compressedImage) {
        self.imageEditCompressedFramsImages = @[compressedImage];
    }
    
    /// context
    self.transformContext.didHandleImageAlbum2MVVideo = NO;
    self.dynamicCoverIndex = 0; // 分裂后重置
    
    /// track info
    ACCRepoUploadInfomationModel *repoUploadInfo = [self.repository extensionModelOfClass:[ACCRepoUploadInfomationModel class]];
    
    /// upload info
    AWEAssetModel *assetModel = [repoUploadInfo.selectedUploadAssets acc_objectAtIndex:imageIndex];
    if (assetModel) {
        repoUploadInfo.selectedUploadAssets = @[assetModel];
    }
    repoUploadInfo.originUploadPhotoCount = @(1);
    
    
    if (!originalImage || !compressedImage) {
        NSAssert(NO, @"image index is out of items's bounce");
    }
}
 
@end

@implementation ACCRepoImageAlbumTransformContext

- (instancetype)initForImageAlbumEditContext
{
    if (self = [super init]) {
        _isImageAlbumTransformContext = YES;
    }
    return self;
}

@end


@implementation ACCRepoImageAlbumBatchStoryPublishContext

- (instancetype)initWithAssociationId:(NSString *)associationId
                       totalTaskCount:(NSInteger)totalTaskCount
                     currentTaskIndex:(NSInteger)currentTaskIndex
{
    if (self = [super init]) {
        _associationId = [associationId copy];
        _totalTaskCount = totalTaskCount;
        _currentTaskIndex = currentTaskIndex;
    }
    return self;
}

- (BOOL)isStoryBatchPublish
{
    return self.associationId.length > 0;
}

- (NSString *)sectionId
{
    if (ACC_isEmptyString(self.associationId)) {
        return nil;
    }
    
    return [ACCRepoImageAlbumBatchStoryPublishContext getSectionIdWithAssociationId:self.associationId];
}

- (BOOL)isLastBatchPublishTask
{
    return self.currentTaskIndex == (self.totalTaskCount - 1);
}

- (BOOL)isFirstBatchPublishTask
{
    return self.currentTaskIndex == 0;
}

- (void)clearBatchContext
{
    _associationId = nil;
}

+ (void)storeSectionId:(NSString *)sectionId withAssociationId:(NSString *)associationId
{
    if (!ACC_isEmptyString(sectionId) && !ACC_isEmptyString(associationId)) {
        [[self p_sectionIdAssociationIdMap] setObject:sectionId forKey:associationId];
    }
}

+ (NSString *)getSectionIdWithAssociationId:(NSString *)associationId
{
    if (!ACC_isEmptyString(associationId)) {
        return  [[self p_sectionIdAssociationIdMap] objectForKey:associationId];
    }
    
    return nil;
}

+ (NSMutableDictionary <NSString*, NSString *> *)p_sectionIdAssociationIdMap
{
    static dispatch_once_t onceToken;
    static NSMutableDictionary *map;
    dispatch_once(&onceToken, ^{
        map = [NSMutableDictionary dictionary];
    });
    return map;
}

@end
