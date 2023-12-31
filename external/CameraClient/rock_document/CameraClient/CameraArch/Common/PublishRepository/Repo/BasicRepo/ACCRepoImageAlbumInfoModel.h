//
//  ACCRepoImageAlbumInfoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by imqiuhang on 2020/12/9.
//  图片集编辑发布模式下的图片数据

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <Mantle/MTLModel.h>
#import "ACCImageAlbumEditorDefine.h"

@class ACCImageAlbumData, ACCImageAlbumEditImageInputInfo;
@class ACCImageEditItemCoverInfo, ACCRepoImageAlbumTransformContext;
@class ACCRepoImageAlbumBatchStoryPublishContext;

@interface ACCRepoImageAlbumInfoModel : NSObject

/// 图片编辑主数据，类似HTSVideoData，只保存图片编辑信息，用于image player的消费和恢复
/// 虽然这个model定义在我们自己业务里，但还是看做VE层的数据，和编辑无关的内容不要加进去，类似下面的封面信息的保存放在repo里
@property (nonatomic, strong, nullable) ACCImageAlbumData *imageAlbumData;

- (NSInteger)imageCount;

/// 封面index
@property (nonatomic, assign) NSInteger dynamicCoverIndex;

/// 封面编辑信息
@property (nonatomic, copy, nullable) NSDictionary <NSString *, ACCImageEditItemCoverInfo *> *imageItemsCoverInfoMapping;
- (void)updateImageItemCoverCropOffsetsValue:(CGPoint)offsets withItemIdentify:(nonnull NSString *)itemIdentify;
- (CGPoint)imageItemCoverCropOffsetsWithIdentify:(nonnull NSString *)itemIdentify;

/// 原图
@property (nonatomic, copy, nullable) NSArray <ACCImageAlbumEditImageInputInfo *> *imageEditOriginalImages;
- (UIImage *_Nullable)originalImageAtIndex:(NSInteger)index;

/// 备份图（因为图片裁切是直接在原图上进行的，而重新进入裁切页需要显示原图）
@property (nonatomic, copy, nullable) NSArray <ACCImageAlbumEditImageInputInfo *> *imageEditBackupImages;

/// 压缩过的审核图
@property (nonatomic, copy, nullable) NSArray <ACCImageAlbumEditImageInputInfo *> *imageEditCompressedFramsImages;

/// 是否是编辑图片的模式，类似于isStory的判断，即videoType == AWEVideoTypeImageAlbum
- (BOOL)isImageAlbumEdit;

/// 当前是视频模式，且视频是由图集转化而成的，从场景上场景来讲像backup恢复的逻辑
/// @warning 首次进入编辑页如果是MV视频则return NO，  只有从图集切换过去的才为YES，另外从草稿恢复后由于无法切换，恒定为NO
/// @seealso .transformContext.isImageAlbumTransformContext
- (BOOL)isTransformedFromImageAlbumMVVideoEditMode;

/// 视频/图集 转换的runtime的一些信息，不需要存草稿
@property (nonatomic, strong, nullable) ACCRepoImageAlbumTransformContext *transformContext;

/// 批量发日常相关的数据，不需要存草稿
@property (nonatomic, strong) ACCRepoImageAlbumBatchStoryPublishContext *_Nullable batchStoryPublishContext;

/// 发布时存本地导出的图片本地文件信息，不会存草稿, 一般用于保存到本地相册
/// @note 存储路径是在草稿目录下，清理草稿会清除文件，注意判断文件存在
@property (nonatomic, copy) NSArray <NSURL *> *_Nullable runtimeExportedLocalImageFilePaths;
/**
 * track info for tags, should move to repoTagsModel if there is one
 **/
- (nullable NSDictionary *)tagsTrackInfo;
/**
 * track info for crop, should merge with other image album track info
 **/
- (NSDictionary *)cropTrackInfo;

@end

@interface ACCRepoImageAlbumInfoModel (ResourceModify)
 
/// 修改图片顺序
/// @param fromIndex fromIndex
/// @param toIndex toIndex
- (void)moveImageFromIndex:(NSInteger)fromIndex
                   toIndex:(NSInteger)toIndex;

/// 比较奇怪的需求，将一个图集分裂成多个publish model去发布成多个作品
/// 根据imageIndex重组所有图集相关数据 .e.g. imageAlbumData、imageEditOriginalImages、imageEditCompressedFramsImages
- (void)amazingDivideImageAlbumDataFromTargetImageIndex:(NSInteger)imageIndex;

/// 比较奇怪的需求，将一个图集分裂成多个publish model去发布成多个作品，所以资源都需要进行迁移
/// 得益于之前存储的是文件名称并且继承了统一的资源基类，我们将所有带草稿资源的model进行资源自动copy
/// 迁移的有 imageAlbumData、imageEditOriginalImages、imageEditCompressedFramsImages
- (void)amazingMigrateResourceToNewDraftWithTaskId:(NSString *)taskId;
 
@end

@interface ACCRepoImageAlbumTransformContext : MTLModel

ACCImageEditModeObjUsingCustomerInitOnly;

/// 初始化为图集Context 即isImageAlbumTransformContext = YES
- (instancetype)initForImageAlbumEditContext;

/// 当前编辑页是否能够图集和视频之间的切换，即当时可能是图集或者MV视频，且允许这两者之间切换
/// 图集现在默认land的编辑页有可能是视频，也return YES，如果两者能够切换的话
@property (nonatomic, assign, readonly) BOOL isImageAlbumTransformContext;

/// 是否已经切换过一次图片转视频，切生成了对应的videoData，不能通过是否有videodata判断 因为生成过fake videodata用于存草稿的逻辑
@property (nonatomic, assign) BOOL didHandleImageAlbum2MVVideo;

/// 图集 / 视频 是否转换过一次，目前和'didHandleImageAlbum2MVVideo'其实是一致的，但是避免以后留坑还是另起一个字段
@property (nonatomic, assign) BOOL didTransformedOnce;

@end

/// 图集批量发日常相关
@interface ACCRepoImageAlbumBatchStoryPublishContext : MTLModel

ACCImageEditModeObjUsingCustomerInitOnly;

- (instancetype)initWithAssociationId:(nullable NSString *)associationId
                       totalTaskCount:(NSInteger)totalTaskCount
                     currentTaskIndex:(NSInteger)currentTaskIndex;

/// 图集批量发布日常的本地关联ID，用于标识是同一批发布的数据
/// 该字段不是最终传给服务端的，而是用与获取服务端回传的sectionId相关联，该字段不存草稿
/// 逻辑是 批量发布 第一个成功的作品服务端会透传一个sectionId，客户端端将后续的批量发布的sectionId字段填入
/// 如果有任何一个失败了，包括第一个失败了，那么这个作品会被剥离出批量组，点击重试后或者草稿重发都将不再是该批量组
@property (nonatomic, copy, readonly) NSString *_Nullable associationId;

/// 通过associationId获取服务端回传的sectionId
- (NSString *_Nullable)sectionId;

/// 是否是批量发布组的一个数据，associationId.length >  0
- (BOOL)isStoryBatchPublish;

- (BOOL)isLastBatchPublishTask;
- (BOOL)isFirstBatchPublishTask;
@property (nonatomic, assign, readonly) NSInteger totalTaskCount;
@property (nonatomic, assign, readonly) NSInteger currentTaskIndex;

/// 存取服务端返回的sectionId
+ (void)storeSectionId:(NSString *)sectionId withAssociationId:(NSString *)associationId;
+ (NSString *_Nullable)getSectionIdWithAssociationId:(NSString *)associationId;

/// 发布失败后清除这张图片的批量发布信息
- (void)clearBatchContext;

@end

@interface AWEVideoPublishViewModel (RepoImageAlbumInfo)
 
@property (nonatomic, strong, nullable, readonly) ACCRepoImageAlbumInfoModel *repoImageAlbumInfo;
 
@end
