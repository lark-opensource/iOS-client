//
//  AWEAIMusicRecommendManager.h
//  AWEStudio
//
//  Created by Bytedance on 2019/1/9.
//  Copyright © 2019 Bytedance. All rights reserved.
//  https://wiki.bytedance.net/pages/viewpage.action?pageId=217625944

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "AWEAIMusicRecommendTask.h"
#import "ACCEditVideoData.h"
#import <CreationKitRTProtocol/ACCCameraDefine.h>

@protocol ACCEditServiceProtocol, ACCMusicModelProtocol;

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXTERN NSString *const kAWEAIMusicRecommendCacheURIKey;

typedef NS_ENUM(NSUInteger, AWEAIRecordFrameType) {
    AWEAIRecordFrameTypeOriginal,      // 拍摄原有贴纸抽帧逻辑
    AWEAIRecordFrameTypeRecord,        // 拍摄时专门为了AI推荐去抽帧
    AWEAIRecordFrameTypeSegmentedClip, // 相册视频文件抽帧
};

typedef void (^AWEAIMusicRecommendFetchCompletion)(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSError * _Nullable error);
typedef void (^AWEAIMusicRecommendFetchLoadMoreCompletion)(NSArray<id<ACCMusicModelProtocol>> * _Nullable musicList, NSNumber *hasMore, NSNumber *cursor, NSError * _Nullable error);
typedef void (^AWEAIMusicURIFetchCompletion)(NSString * _Nullable URI, AWEAIRecommendStrategy recommendStrategyType, BOOL videoChanged, NSError * _Nullable error);


@interface AWEAIMusicRecommendManager : NSObject

//上传的帧数
@property(nonatomic, readonly) NSInteger maxNumForUpload;

//帧的分辨率
@property(nonatomic, readonly) NSInteger frameSizeForUpload;

//抽帧的方式
@property(nonatomic, readonly) AWEAIRecordFrameType recordFrameType;

//AI推荐音乐列表，settings兜底、曲库、AILab接口请求获得，因为会重新赋值建议深拷贝或者逆序遍历
@property(nonatomic, readonly) NSArray<id<ACCMusicModelProtocol>> *recommedMusicList;
@property (nonatomic, assign, readonly) BOOL usedAIRecommendDefaultMusicList; // 是否正在使用兜底的推荐音乐

//AI推荐音乐列表获取的方式，settings兜底、曲库、AILab接口请求获得
@property(nonatomic, readonly) AWEAIMusicFetchType musicFetchType;

//请求状态
@property(nonatomic, readonly) BOOL isRequesting;

//请求的ID
@property(nonatomic, readonly) NSString *requestID;

@property(nonatomic, assign) BOOL clipVideoModified;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

+ (instancetype)sharedInstance;

/*
 * AI 推荐音乐功能是否可用
 */
- (BOOL)serviceOnWithModel:(nullable AWEVideoPublishViewModel *)model;

/// AI 推荐音乐功能是否可用
/// @param enterFrom 从哪个界面来的
/// @param referString 发布路径来源
- (BOOL)serviceOnWithEnterFrom:(nullable NSString *)enterFrom referString:(nullable NSString *)referString;

/*
 * 抽帧的类型
 */
- (void)setFrameRecordType:(AWEAIRecordFrameType)frameType;

/*
 * 再次编辑上传视频文件更新状态
 */
- (void)updateClipVideoStatusWithModel:(nullable AWEVideoPublishViewModel *)model
                            rotateType:(NSInteger)rotateType
                                 range:(CMTimeRange)clipRange;

/*
 * 再次编辑上传视频文件更新状态
 */
- (void)updateClipVideoStatusWithVideo:(ACCEditVideoData *)video
                              createId:(NSString *)createId
                            rotateType:(NSInteger)rotateType
                                 range:(CMTimeRange)clipRange;

/*
 * 添加抽的帧
 */
- (void)appendFramePaths:(nullable NSArray<NSString *> *)framePaths;

/*
 *  使用bach推荐uri场景，并用抽帧上传uri兜底
 */
+ (NSString * _Nullable)recommendedBachZipUriWithPublishViewModel:(AWEVideoPublishViewModel * _Nonnull)model;

/*
 * 抽帧上传获取zip_uri
 */
- (void)startFetchFramsAndUploadWithPublishModel:(nullable AWEVideoPublishViewModel *)model callback:(nullable AWEAIMusicURIFetchCompletion)completion;

/*
 * 获取 AI 推荐音乐列表（抽好帧后直接通过zip_uri获取）
 */
- (void)fetchAIRecommendMusicWithURI:(nullable NSString *)URI callback:(nullable AWEAIMusicRecommendFetchCompletion)completion;
- (void)fetchAIRecommendMusicWithURI:(nullable NSString *)URI otherParam:(nullable NSDictionary *)param laodMoreCallback:(AWEAIMusicRecommendFetchLoadMoreCompletion)completion;

/*
 * 获取 settings 兜底音乐列表
 */
- (void)fetchDefaultMusicListFromTOSWithURLGoup:(nullable NSArray<NSString *> *)urlGroup
                                       callback:(nullable AWEAIMusicRecommendFetchCompletion)completion;


/*
 * 返回对应的publishViewModel是否开启ai音乐推荐
 */
- (BOOL)aiRecommendMusicEnabledForModel:(nullable AWEVideoPublishViewModel *)model;

/*
 * jarvis 平台埋点，https://bytedance.feishu.cn/space/sheet/shtcnH3FOjKELZeduLn0cG#801d24
 */
- (void)jarvisTrackWithEvent:(NSString *)event params:(NSDictionary *)params publishModel:(AWEVideoPublishViewModel *)publishModel;

/*
 * 未开启预发布时候，需要清空 AI推荐音乐列表（包含settings兜底缓存）
 */
- (void)cleanRecommedMusicList;

@end

NS_ASSUME_NONNULL_END
