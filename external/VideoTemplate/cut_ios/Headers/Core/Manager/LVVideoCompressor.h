//
//  LVVideoCompressor.h
//  LVTemplate
//
//  Created by haoxian on 2020/3/4.
//

#import <AVFoundation/AVFoundation.h>
#import "LVMediaDefinition.h"

NS_ASSUME_NONNULL_BEGIN

extern NSString *const LVVideoCompressorDomain;

typedef void(^LVVideoCompressProgress)(CGFloat);
typedef void(^LVVideoCompressCompletion)(AVURLAsset  *_Nullable, NSError *_Nullable);

// MARK: - LVVideoCompressErrorCode
typedef NS_ENUM(NSUInteger, LVVideoCompressErrorCode) {
    LVVideoCompressErrorCodeVideoTrackMissing = 10000, // 视频轨道不存在
    LVVideoCompressErrorCodeSizeOrFpsInvalid,          // 视频size或fps无效值
    LVVideoCompressErrorCodeOutputURLEmpty,            // 压缩成功后视频路径不存在
    LVVideoCompressErrorCodeCreateExportSessionFail,   // 创建AVAssetExportSession失败
    LVVideoCompressErrorCodeCancelled,                 // 压缩取消
    LVVideoCompressErrorCodeFailed,                    // 压缩失败
    LVVideoCompressErrorExportSessionError,            // Export Session 导出失败
};

typedef NS_ENUM(NSUInteger, LVVideoCompressorPreferentTool) {
    LVVideoCompressorPreferentToolExportSession = 0,   // 系统导出工具
    LVVideoCompressorPreferentToolVECompile            // VE 导出
};

// MARK:- LVVideoCompressConfig
@interface LVVideoCompressConfig : NSObject
/**
 最大的FPS
 */
@property (nonatomic, assign) LVExportFPS maxFps;

/**
 最大的分辨率
 */
@property (nonatomic, assign) LVExportResolution maxResolution;

/**
 为YES时，不压缩直接返回。
 为NO时，判断FPS和分辨率。
 */
@property (nonatomic, assign, getter=isIgnore) BOOL ignore;

/**
 为YES时，不转换格式
 为NO时，忽略不处理，默认为NO
 */
@property (nonatomic, assign) BOOL transcodeHDR10Bit;

/**
 导出时，指定优先使用的工具，默认为 exportSession
 指定使用 ve 压缩时，只有 asset 为 hdr 才生效
 */
@property (nonatomic, assign) LVVideoCompressorPreferentTool preference;

/**
 FPS 30   分辨率1080p  不忽略压缩
 */
+ (instancetype)defaultConfig;

/**
 初始化
 @param fps 最大的FPS
 @param resolution 最大的分辨率
 @param transcodeHDR10Bit = NO
 */
- (instancetype)initWithFps:(NSInteger)fps resolution:(LVExportResolution)resolution;

- (instancetype)initWithFps:(NSInteger)fps resolution:(LVExportResolution)resolution transcodeHDR10Bit:(BOOL)transcodeHDR10Bit;

- (instancetype)initWithFps:(NSInteger)fps resolution:(LVExportResolution)resolution transcodeHDR10Bit:(BOOL)transcodeHDR10Bit preference:(LVVideoCompressorPreferentTool)preference;
@end


// MARK:- LVVideoCompressor
@interface LVVideoCompressor : NSObject

@property (class, readonly, strong) LVVideoCompressor *shared;

/**
 取消当前压缩队列里所有的任务
 */
- (void)cancelAllTasks;

/**
 压缩视频
 @param asset 视频
 @param config 压缩策略
 @param progressHandler 进度回调
 @param completion 完成回调
 */
- (void)compressWtihAsset:(AVURLAsset *)asset
                   config:(LVVideoCompressConfig *)config
          progressHandler:(LVVideoCompressProgress _Nullable)progressHandler
               completion:(LVVideoCompressCompletion _Nullable)completion;

/**
判断视频是否需要压缩
@param asset 视频
@param config 压缩策略
*/
- (BOOL)shouldCompressWithAsset:(AVURLAsset *)asset
                         config:(LVVideoCompressConfig *)config;

@end


@interface AVAsset (HDRChecker)

- (BOOL)isBT2020HDR10Bit;

@end

NS_ASSUME_NONNULL_END
