//
//  ACCEditCompileSession.h
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2021/4/14.
//

#import <Foundation/Foundation.h>
#import "ACCEditVideoData.h"
#import <TTVideoEditor/IESMMTransProcessData.h>
#import <TTVideoEditor/IESMMTranscodeRes.h>
#import <TTVideoEditor/IVEEffectProcess.h>

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel,
ACCVEVideoData;

@interface ACCEditCompileSession : NSObject

/// set before transcode
@property (nonatomic, copy, class, nullable) void(^encodeDataCallback)(NSData *data, int64_t offset, int size, BOOL isFinish);

/// set before transcode
@property (nonatomic, strong, class, nullable) void (^progressBlock)(CGFloat progress);

+ (void)checkCompileSessionReady:(void (^)(void))completion;

// 转码，返回一个文件路径
// 返回为 task 实例，必须被持有，否则 task 会中断
+ (id)transcodeWithVideoData:(ACCEditVideoData *)videoData
                        size:(CGSize)targetSize
                     bitrate:(int)bitrate
             completionBlock:(nonnull void (^)(IESMMTranscodeRes * _Nullable))completionBlock;

// 转码，返回一个文件路径
+ (void)transcodeWithVideoData:(ACCEditVideoData *)videoData
               completionBlock:(nonnull void (^)(IESMMTranscodeRes * _Nullable))completionBlock;

/// 转码导出
/// @param videoData 转码资源videodata，编辑导出可以直接使用编辑的videodata
/// @param transConfig 转码配置
/// @param videoProcess 编辑时的videodata
/// @param completeBlock 转码完成回调
+ (void)transWithVideoData:(ACCVEVideoData *)videoData
               transConfig:(IESMMTransProcessData *)transConfig
              videoProcess:(id<IVEEffectProcess> _Nullable)videoProcess
             completeBlock:(nonnull void (^)(IESMMTranscodeRes * _Nullable))completeBlock;

// 根据 videoData 获取 IVEEffectProcess
+ (id<IVEEffectProcess>)effectProcessWithVideoData:(ACCEditVideoData *)videoData;

// 获取 MV videoData
+ (ACCVEVideoData *)getMVExportData:(id<IVEEffectProcess>)effectProcess
                       publishModel:(AWEVideoPublishViewModel *)videoData;

/// 暂停转码
+ (void)pause;

/// 继续转码
+ (void)resume;

/// YES 慢速， NO， 快速
+ (void)enableDynamicSpeed:(BOOL)constrainedMode;

// 发布打点
+ (void)postTrack;

// 取消转码，该方法会立即返回，但不会完全cancle成功，需要等merge的completeblock回调
+ (void)cancelTranscode;

- (instancetype)initWithVideoData:(ACCEditVideoData *)videoData
                           config:(IESMMTransProcessData *)config;

- (instancetype)initWithVideoData:(ACCEditVideoData *)videoData
                           config:(IESMMTransProcessData *)config
                       effectUnit:(id<IVEEffectProcess> _Nullable)effectUnit;

@property (nonatomic, strong) void (^_Nullable progressBlock)(CGFloat progress);

/// 视频转码
- (void)transcodeWithCompleteBlock:(nullable void (^)(IESMMTranscodeRes *_Nullable result))completeBlock;

/// 取消转码或者水印
- (void)cancel:(void (^_Nullable)(void))completion;

/**
 取消转码，该方法会立即返回，但不会完全cancle成功，需要等merge的completeblock回调
 
 注意：此方法适用于 VECompileSession，Transcoder 系列类请调用 -cancel: 接口
 */
- (void)cancelTranscode;

/**
 * @brief 判断是否支持预上传,具体参考https://bytedance.feishu.cn/docs/doccne7bQWFwlaUhQPoIa8hJGoe
 */
+ (BOOL)isPreUploadable:(ACCVEVideoData *)videoData transConfig:(IESMMTransProcessData *)transConfig videoProcess:(id<IVEEffectProcess>)videoProcess;

@end

NS_ASSUME_NONNULL_END
