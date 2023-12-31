//
//  ACCEditMVModel.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"
#import <TTVideoEditor/IESMMMVModel.h>

@class AWEVideoPublishViewModel, ACCNLEEditVideoData;

typedef void (^ACCMVModelBlock)(BOOL result, NSError *error, ACCEditVideoData *info);
typedef void (^ACCSmartMovieModelBlock)(BOOL isCanceled, ACCEditVideoData *info, NSError *error, BOOL isNleRenderError);

NS_ASSUME_NONNULL_BEGIN

@interface ACCEditMVModel : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDraftFolder:(NSString *)draftFolder;

// 临时暴露出来
@property (nonatomic, strong, readonly) IESMMMVModel *veMVModel;

/**
 * 获取MV模板用户选择资源类型和长度
 *
 * @param modelPath 模板地址
 * @return 资源信息
*/
+ (NSArray<IESMMMVResource *> *)getMVResourceInfo:(NSString *)modelPath;

/**
 * 音频长度是否自动适应视频长度，短则循环扩充长则截断
 */
@property (nonatomic, assign) BOOL isAudioFitVideoDuration;

/**
 * 用户选择资源
 */
@property (strong, nonatomic, readonly) NSArray<IESMMMVResource *> *resources;

- (void)setResolution:(CGSize)resolution;
- (void)setVariableDuration:(float)duration;
- (void)setResourceDurations:(NSArray *)durations;

/// 设置服务端的算法结果
- (void)setServerAlgorithmResults:(NSArray<VEMVAlgorithmResult *> *)results;

/**
 * 设定BeatTracking算法结果
 * @param results BeatTracking算法结果
 */
- (void)setBeatTrackingAlgorithmData:(IESMMAudioBeatTracking *)beatTracking;

/// 生成 MV
/// @param modelPath MV 路径
/// @param repository 发布信息
/// @param resources MV 资源
/// @param completion 成功回调
- (void)generateMVWithPath:(NSString *)modelPath
                repository:(AWEVideoPublishViewModel *)repository
             userResourses:(NSArray<IESMMMVResource *> *)resources
                completion:(ACCMVModelBlock)completion;

/// 生成 MV，兼容草稿恢复场景
/// @param modelPath MV 路径
/// @param repository 发布信息
/// @param resources MV 资源
/// @param videoData 编辑数据
/// @param completion 成功回调
- (void)generateMVWithPath:(NSString *)modelPath
                repository:(nullable AWEVideoPublishViewModel *)repository
             userResourses:(NSArray<IESMMMVResource *> *)resources
                 videoData:(ACCEditVideoData *)videoData
                completion:(ACCMVModelBlock)completion;

// 智照场景 生成智照视频
- (void)generateSmartMovieWithRepository:(AWEVideoPublishViewModel *_Nonnull)repository
                                  assets:(NSArray<NSString *> *_Nonnull)assets
                                 musicID:(NSString *_Nullable)musicID
                           isSwitchMusic:(BOOL)isSwitchMusic
                              completion:(ACCSmartMovieModelBlock _Nullable)completion;

- (void)generateMVWithPath:(NSString *)modelPath
                repository:(nullable AWEVideoPublishViewModel *)repository
             userResourses:(NSArray<IESMMMVResource *> *)resources
         resourcesDuration:(nullable NSArray *)resourcesDuration
                 videoData:(ACCEditVideoData *)videoData
                completion:(ACCMVModelBlock)completion;

- (void)userChangePictures:(ACCEditVideoData *)videoData
            newPictureUrls:(NSArray<NSURL *> *)newPictureUrls
                completion:(ACCMVModelBlock)completion;

- (void)userChangeMusic:(ACCEditVideoData *)videoData
             completion:(ACCMVModelBlock)completion;

/// 生成 MV 后需要使用特定方法替换 BGM
- (void)clearAndAddBGMWithVideoData:(ACCEditVideoData *)videoData
                           bgmAsset:(AVAsset *)bgmAsset
                         repository:(AWEVideoPublishViewModel *)repository;

/// 替换音频
- (void)replaceAudioWithVideoData:(ACCEditVideoData *)videoData
                       repository:(AWEVideoPublishViewModel *)repository;

/// 草稿恢复 MV BGM 特殊处理
- (void)addBGMForDraftWithRepository:(AWEVideoPublishViewModel *)repository;

/// 获取用户选择的素材【不包括图片】
+ (NSArray<AVAsset *> *)videoAssetsSelectedByUserFromVideoData:(HTSVideoData *)videoData;

@end

NS_ASSUME_NONNULL_END
