//
//  ACCImageAlbumData.h
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by imqiuhang on 2020/12/14.
//

#import <Foundation/Foundation.h>
#import <Mantle/MTLModel.h>
#import "ACCImageAlbumItemModel.h"
#import "ACCImageAlbumEditorDefine.h"

NS_ASSUME_NONNULL_BEGIN

@class ACCImageAlbumEditImageInputInfo, ACCRepoImageAlbumInfoModel;

@interface ACCImageAlbumData : MTLModel

ACCImageEditModeObjUsingCustomerInitOnly;

@property (nonatomic, copy, readonly) NSArray <ACCImageAlbumItemModel *> *imageAlbumItems;

- (instancetype)initWithImageAlbumInfoModel:(ACCRepoImageAlbumInfoModel *)imageAlbumInfoModel
                                     taskId:(NSString *)taskId;

/// 用于草稿路径拼接和替换，这样不用每次主动更新草稿路径
/// 后续可以改成注入一个资源获取的delegate 而不是由image data去做草稿或者VE资源的处理
@property (nonatomic, copy, readonly) NSString *taskId;

@end


@interface ACCImageAlbumData(ResourceUpdate)

- (void)updateLensHDRModelWithFilePath:(NSString *)filePath;
- (void)updateRecoveredEffectIfNeedWithIdentifier:(NSString *)effectIdentifier filePath:(NSString *)filePath;

@end

@interface ACCImageAlbumData (ResourceGetter)


/// 获取贴纸
/// @param uniqueId uniqueId
/// @param preferredImageIndex 最先寻找的index 用于优化搜索效率
- (ACCImageAlbumStickerSearchResult *_Nullable)stickerWithUniqueId:(NSInteger)uniqueId
                                               preferredImageIndex:(NSNumber *_Nullable)preferredImageIndex;

- (NSInteger)maxStickerUniqueId;

- (NSString *_Nullable)itemIdentifyAtIndex:(NSInteger)imageIndex;

@end

@interface ACCImageAlbumData (ResourceModify)


/// 修改图片顺序
/// @param fromIndex fromIndex
/// @param toIndex 修改后被修改的图片的位置是 toIndex
- (void)moveImageFromIndex:(NSInteger)fromIndex
                   toIndex:(NSInteger)toIndex;

/// 将图集数据和资源迁移到新的草稿目录
/// draft目录(继承ACCImageAlbumItemDraftResourceRestorableModel)，将自动做迁移，子类可不处理
/// 非draft资源(继承ACCImageAlbumItemVEResourceRestorableModel)，例如特效滤镜等因为是共用的VE目录-
/// 则并不需要迁移，子类如需处理可按需override自己处理
- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId;

/// 根据imageIndex重组所有图集相关数据 .e.g. iimageAlbumItems
- (void)amazingDivideImageAlbumDataFromTargetImageIndex:(NSInteger)imageIndex;

@end

NS_ASSUME_NONNULL_END
