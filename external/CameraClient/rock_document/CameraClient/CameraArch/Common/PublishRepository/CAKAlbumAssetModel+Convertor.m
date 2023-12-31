//
//  CAKAlbumAssetModel+Convertor.m
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/12/30.
//

#import <CreativeKit/NSArray+ACCAdditions.h>
#import <objc/runtime.h>
#import "CAKAlbumAssetModel+Convertor.h"

@interface CAKAlbumAssetModel (Convertor)

@property (nonatomic, strong) AWEAssetModel *originalStudioAssetModel;

@end


@implementation CAKAlbumAssetModel (Convertor)

+ (instancetype)createWithStudioAsset:(AWEAssetModel *)assetModel
{
    if (!assetModel) {
        return nil;
    }
    NSAssert([assetModel isKindOfClass:[AWEAssetModel class]], @"model class type wrong");
    
    CAKAlbumAssetModel *result = [[CAKAlbumAssetModel alloc] init];
    result.phAsset = assetModel.asset;
    result.avAsset = assetModel.avAsset;
    result.mediaType = [CAKAlbumAssetModel cakMediaTypeWithAWEMediaType:assetModel.mediaType];
    result.mediaSubType = [CAKAlbumAssetModel cakMediaSubtypeWithAWEMediaSubtype:assetModel.mediaSubType];
    result.allCellIndex = assetModel.allCellIndex;
    result.categoriedCellIndex = assetModel.categoriedCellIndex;
    result.selectedNum = assetModel.selectedNum;
    result.videoDuration = assetModel.videoDuration;
    result.cellIndexPath = assetModel.cellIndexPath;
    result.coverImage = assetModel.coverImage;
    result.isFromICloud = assetModel.isFromICloud;
    result.didFailFetchingiCloudAsset = assetModel.didFailFetchingiCloudAsset;
    result.iCloudSyncProgress = assetModel.iCloudSyncProgress;
    result.canUnobserveAssetModel = assetModel.canUnobserveAssetModel;
    result.info = assetModel.info;
    result.isShowingInPreview = assetModel.isShowingInPreview;
    result.isDegraded = assetModel.isDegraded;
    result.UUIDString = assetModel.UUIDString;
    
    result.originalStudioAssetModel = assetModel;
    return result;
}

- (AWEAssetModel *)convertToStudioAsset
{
    AWEAssetModel *studioAsset = self.originalStudioAssetModel ?: [[AWEAssetModel alloc] init];
    studioAsset.asset = self.phAsset;
    studioAsset.avAsset = self.avAsset;
    studioAsset.mediaType = [self.class aweMediaTypeWithCAKMediaType:self.mediaType];
    studioAsset.mediaSubType = [self.class aweMediaSubtypeWithCAKMediaSubtype:self.mediaSubType];
    studioAsset.allCellIndex = self.allCellIndex;
    studioAsset.selectedNum = self.selectedNum;
    studioAsset.videoDuration = self.videoDuration;
    studioAsset.cellIndexPath = self.cellIndexPath;
    studioAsset.coverImage = self.coverImage;
    studioAsset.isFromICloud = self.isFromICloud;
    studioAsset.didFailFetchingiCloudAsset = self.didFailFetchingiCloudAsset;
    studioAsset.iCloudSyncProgress = self.iCloudSyncProgress;
    studioAsset.canUnobserveAssetModel = self.canUnobserveAssetModel;
    studioAsset.info = self.info;
    studioAsset.isShowingInPreview = self.isShowingInPreview;
    studioAsset.isDegraded = self.isDegraded;
    studioAsset.UUIDString = self.UUIDString;
    return studioAsset;
}

+ (NSArray<CAKAlbumAssetModel *> *)createWithStudioArray:(NSArray<AWEAssetModel *> *)studioAssetsArray
{
    NSMutableArray<CAKAlbumAssetModel *> *result = [NSMutableArray array];
    [studioAssetsArray enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([obj isKindOfClass:[AWEAssetModel class]], @"model type wrong");
        [result acc_addObject:[CAKAlbumAssetModel createWithStudioAsset:obj]];
    }];
    return [NSArray arrayWithArray:result];
}

+ (NSArray<AWEAssetModel *> *)convertToStudioArray:(NSArray<CAKAlbumAssetModel *> *)cakAssetsArray
{
    NSMutableArray<AWEAssetModel *> *result = [NSMutableArray array];
    [cakAssetsArray enumerateObjectsUsingBlock:^(CAKAlbumAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSAssert([obj isKindOfClass:[CAKAlbumAssetModel class]], @"model type wrong");
        [result acc_addObject:[obj convertToStudioAsset]];
    }];
    return [NSArray arrayWithArray:result];
}

+ (CAKAlbumAssetModelMediaType)cakMediaTypeWithAWEMediaType:(AWEAssetModelMediaType)aweMediaType
{
    CAKAlbumAssetModelMediaType cakMediaType = CAKAlbumAssetModelMediaTypeUnknow;
    switch (aweMediaType) {
        case AWEAssetModelMediaTypeUnknow:
        {
            cakMediaType = CAKAlbumAssetModelMediaTypeUnknow;
            break;
        }
        case AWEAssetModelMediaTypeAudio:
        {
            cakMediaType = CAKAlbumAssetModelMediaTypeAudio;
            break;
        }
        case AWEAssetModelMediaTypePhoto:
        {
            cakMediaType = CAKAlbumAssetModelMediaTypePhoto;
            break;
        }
        case AWEAssetModelMediaTypeVideo:
        {
            cakMediaType = CAKAlbumAssetModelMediaTypeVideo;
            break;
        }
            
        default:
            break;
    }
    return cakMediaType;
}

+ (AWEAssetModelMediaType)aweMediaTypeWithCAKMediaType:(CAKAlbumAssetModelMediaType)cakMediaType
{
    AWEAssetModelMediaType aweMediaType = AWEAssetModelMediaTypeUnknow;
    switch (cakMediaType) {
        case CAKAlbumAssetModelMediaTypeUnknow:
        {
            aweMediaType = AWEAssetModelMediaTypeUnknow;
            break;
        }
        case CAKAlbumAssetModelMediaTypeAudio:
        {
            aweMediaType = AWEAssetModelMediaTypeAudio;
            break;
        }
        case CAKAlbumAssetModelMediaTypePhoto:
        {
            aweMediaType = AWEAssetModelMediaTypePhoto;
            break;
        }
        case CAKAlbumAssetModelMediaTypeVideo:
        {
            aweMediaType = AWEAssetModelMediaTypeVideo;
            break;
        }
            
        default:
            break;
    }
    return aweMediaType;
}

+ (CAKAlbumAssetModelMediaSubType)cakMediaSubtypeWithAWEMediaSubtype:(AWEAssetModelMediaSubType)aweMediaSubtype
{
    CAKAlbumAssetModelMediaSubType cakMediaSubtype = CAKAlbumAssetModelMediaSubTypeUnknow;
    switch (aweMediaSubtype) {
        case AWEAssetModelMediaSubTypeUnknow:
        {
            cakMediaSubtype = CAKAlbumAssetModelMediaSubTypeUnknow;
            break;
        }
        case AWEAssetModelMediaSubTypePhotoGif:
        {
            cakMediaSubtype = CAKAlbumAssetModelMediaSubTypePhotoGif;
            break;
        }
        case AWEAssetModelMediaSubTypePhotoLive:
        {
            cakMediaSubtype = CAKAlbumAssetModelMediaSubTypePhotoLive;
            break;
        }
        case AWEAssetModelMediaSubTypeVideoHighFrameRate:
        {
            cakMediaSubtype = CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate;
            break;
        }
            
        default:
            break;
    }
    return cakMediaSubtype;
}

+ (AWEAssetModelMediaSubType)aweMediaSubtypeWithCAKMediaSubtype:(CAKAlbumAssetModelMediaSubType)cakMediaSubtype
{
    AWEAssetModelMediaSubType aweMediaSubtype = AWEAssetModelMediaSubTypeUnknow;
    switch (cakMediaSubtype) {
        case CAKAlbumAssetModelMediaSubTypeUnknow:
        {
            aweMediaSubtype = AWEAssetModelMediaSubTypeUnknow;
            break;
        }
        case CAKAlbumAssetModelMediaSubTypePhotoGif:
        {
            aweMediaSubtype = AWEAssetModelMediaSubTypePhotoGif;
            break;
        }
        case CAKAlbumAssetModelMediaSubTypePhotoLive:
        {
            aweMediaSubtype = AWEAssetModelMediaSubTypePhotoLive;
            break;
        }
        case CAKAlbumAssetModelMediaSubTypeVideoHighFrameRate:
        {
            aweMediaSubtype = AWEAssetModelMediaSubTypeVideoHighFrameRate;
            break;
        }
            
        default:
            break;
    }
    return aweMediaSubtype;
}

- (AWEAssetModel *)originalStudioAssetModel
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalStudioAssetModel:(AWEAssetModel *)originalStudioAssetModel
{
    objc_setAssociatedObject(self, @selector(originalStudioAssetModel), originalStudioAssetModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
