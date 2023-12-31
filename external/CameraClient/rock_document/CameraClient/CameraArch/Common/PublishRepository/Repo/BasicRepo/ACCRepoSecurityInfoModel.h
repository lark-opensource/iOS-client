//
//  ACCRepoSecurityInfoModel.h
//  CameraClient-Pods-Aweme
//
//  Created by lixingdong on 2021/1/18.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/ACCPublishRepositoryElementProtocols.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>

NS_ASSUME_NONNULL_BEGIN
@class RACSignal;

@interface ACCRepoSecurityInfoModel : NSObject<NSCopying>

/**
 * 带道具拍照时，需要使用原始照片（即不带道具效果的照片）上传送审。
 * security : { shoot_photo_frame_path : xxxx }
 */
@property (nonatomic, copy, nullable) NSString *shootPhotoFramePath;

// Green Screen
@property (nonatomic, copy, readonly) NSArray *bgStickerVideoAssests;
@property (nonatomic, copy, readonly) NSArray *bgStickerImageAssests;
@property (nonatomic, strong, readonly) NSMutableArray<NSNumber *> *bgStickerVideoAssetsClipDuration;

@property (nonatomic, weak) RACSignal *shootPhotoFrameSignal;

- (BOOL)needUploadOriginAudio;
- (BOOL)needUploadOriginFrame;

// 判断feedType类型是否是抽帧已经识别的，如果新增加的，在抽帧环节以及测试期间会弹窗
- (void)checkVideoFeedType;

// 单图中是否有发布成图集需要送审的元素
- (BOOL)hasCanvansPublishAsImageAlbumFrame;

// 拍摄路径, 且有需要送审的道具素材
- (BOOL)isSourceTakePhotoAndHasAnyPropFrames;

@end

@interface AWEVideoPublishViewModel (RepoSecurityInfo)
 
@property (nonatomic, strong, readwrite) ACCRepoSecurityInfoModel *repoSecurityInfo;
 
@end

NS_ASSUME_NONNULL_END
