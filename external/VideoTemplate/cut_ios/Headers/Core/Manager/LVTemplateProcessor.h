//
//  LVTemplateProcessor.h
//  LVTemplate
//
//  Created by luochaojing on 2020/2/29.
//

#import <Foundation/Foundation.h>
#import "LVTemplateDataManager.h"

NS_ASSUME_NONNULL_BEGIN

@protocol LVTemplateFragment <NSObject>

@property (nonatomic, copy) NSString *payloadID; // 替换资源ID
@property (nonatomic, copy) NSString *resourceID; // 用来生成文件名
@property (nonatomic, assign) CMTimeRange sourceTimeRange; // 片段原始资源时间范围
@property (nonatomic, copy) NSArray<NSValue *> *cropPoints; // 该资源显示的范围，归一化坐标，4个CGPoint
@property (nonatomic, assign) CGSize videoSzie; // 原始视频的大小
@end

@protocol LVTemplateVideoFragment <LVTemplateFragment>

@property (nonatomic, copy) NSString *videoPath; // 视频路径
@property (nonatomic, assign) LVTemplateCartoonOutputType cartoonOutputType;// 漫画文件类型
@property (nonatomic, strong, nullable) NSString *cartoonFilePath; // 漫画文件路径

@end

@protocol LVTemplateImageFragment <LVTemplateFragment>

@property (nonatomic, strong) NSData *imageData; // 图片数据

@property (nonatomic, assign) CGSize imageSize; // 图片Size

@property (nonatomic, assign) LVTemplateCartoonOutputType cartoonOutputType;// 漫画文件类型
@property (nonatomic, strong, nullable) NSString *cartoonFilePath; // 漫画文件路径

@end

@protocol LVTemplateURLImageFragment <LVTemplateFragment>

@property (nonatomic, copy) NSString *filePath; // 图片路径
@property (nonatomic, assign) CGSize imageSize; // 图片size

@end


typedef NS_ENUM(NSUInteger, LVTemplateProccessorErrorCode) {
    LVTemplateProccessorErrorCodeDownloadZipFailed,      // 下载zip包失败
    LVTemplateProccessorErrorCodeUnzipFailed,            // 解压zip失败
    LVTemplateProccessorErrorCodeParseDraftFailed,       // 解析模压板失败
    LVTemplateProccessorErrorCodeReplaceAssetFailed,     // 替换素材失败
    LVTemplateProccessorErrorCodeFetchEffectFailed,      // 下载特效资源失败
    LVTemplateProccessorErrorCodeReverseVideoFailed,     // 倒放视频失败
    LVTemplateProccessorErrorCodeVersionNotSupported,    // 模板版本不支持（当前模板版本过高）
    LVTemplateProccessorErrorCodePlatformNotSupported,   // 模板平台不支持（不支持安卓平台的资源）
};

typedef NS_ENUM(NSUInteger, LVTemplateProccessorStatus) {
    LVTemplateProccessorStatusPending,
    LVTemplateProccessorStatusExecuting,
    LVTemplateProccessorStatusCancelled,
    LVTemplateProccessorStatusCompleted,
    LVTemplateProccessorStatusFailed,
};

typedef NS_ENUM(NSUInteger, LVTemplateProccessorScene) {
    LVTemplateProccessorSceneNormal,
    LVTemplateProccessorSceneCover,
};

@protocol LVTemplateZipDowndoader <NSObject>

- (void)downloadFile:(NSURL *)fileURL
            progress:(void(^)(CGFloat progress))progress
          completion:(void(^)( NSString * _Nullable path, NSError * _Nullable error))completion;
- (void)cancel;
- (void)removeCache;

@end

@class LVTemplateProcessor;

@protocol LVTemplateProcessorDelegate <NSObject>

@optional
- (void)templateProcessor:(LVTemplateProcessor *)processor didChangeProgress:(CGFloat)progress;

/// 模版解析和模版对应的Effect资源下载已完成
/// @param processor LVTemplateProcessor
/// @param dataManager LVTemplateDataManager 可以拿到 LVMediaDraft
- (void)templateProcessor:(LVTemplateProcessor *)processor
       didPrepareResource:(LVTemplateDataManager *)dataManager;
- (void)templateProcessor:(LVTemplateProcessor *)processor didFailWithErrorCode:(LVTemplateProccessorErrorCode)code withSubCode:(NSError  * _Nullable)subCode;
- (void)templateProcessor:(LVTemplateProcessor *)processor didCompleteWithDataManager:(LVTemplateDataManager *)dataManager;

@end

@interface LVTemplateProcessor : NSObject


@property (nonatomic, assign, readonly) LVTemplateProccessorStatus status; // 处理器当前状态
@property (nonatomic, weak) id<LVTemplateProcessorDelegate> delegate; // 代理

@property (nonatomic, copy, readonly) NSString *templateID;
/**
 初始化

 @param templateID 模板ID
 @param templateURL 模板zip包URL
 @param alignMode 对齐方式
 @param domain 文件夹名称
 @param downloader zip包下载器
 */
- (instancetype)initWithTemplateID:(NSString *)templateID
                       templateURL:(NSString *)templateURL
                         alignMode:(LVMutableConfigAlignMode)alignMode
                            domain:(NSString *)domain
                        downloader:(id<LVTemplateZipDowndoader>)downloader;


- (instancetype)initWithTemplateID:(NSString *)templateID
                       templateURL:(NSString *)templateURL
                             draft:(LVMediaDraft *)draft
                        downloader:(id<LVTemplateZipDowndoader>)downloader;

/**
 开始处理
 */
- (void)startProcess;

/**
 取消处理
 */
- (void)cancelProcess;

/**
  清理操作
 */
- (void)clearWorkspace;

/**
 替换素材

 @param fragments 需要替换的资源
 */
- (void)replaceFragments:(NSArray<id<LVTemplateFragment >> *)fragments;


/**
 是否能够执行替换操作
 */
- (BOOL)replaceIsEnable;

- (void)configSpecialTemplate:(LVTemplateProccessorScene)scene;
- (LVMediaDraft *)draft;

@end

NS_ASSUME_NONNULL_END
