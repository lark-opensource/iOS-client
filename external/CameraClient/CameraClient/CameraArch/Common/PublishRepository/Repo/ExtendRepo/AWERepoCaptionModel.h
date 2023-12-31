//
//  AWERepoCaptionModel.h
//  CameraClient-Pods-Aweme
//
//  Created by yangying on 2020/10/24.
//

#import <CreationKitArch/ACCRepoCaptionModel.h>
#import <CreationKitArch/AWEStudioCaptionModel.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWERepoCaptionModel : ACCRepoCaptionModel <ACCRepositoryContextProtocol>

//字幕
@property (nonatomic, copy, nullable) AWEStudioCaptionInfoModel *captionInfo;

// only for draft
//字幕
@property (nonatomic, strong, nullable) NSString *captionPath;

// taskId，送审
@property (nonatomic, copy) NSString *taskId;
// vid，送审
@property (nonatomic, copy) NSString *vid;
// 编辑中的caotions
@property (nonatomic, strong, nullable) NSMutableArray<AWEStudioCaptionModel *> *captions;
// 查询状态
@property (nonatomic, assign) AWEStudioCaptionQueryStatus currentStatus;
// 是否被移除
@property (nonatomic, assign) BOOL deleted;
// 文件上传 TOS key
@property (nonatomic, copy, nullable) NSString *tosKey;

- (nullable NSString *)captionWordsForCheck;

// 反馈字幕信息
- (void)feedbackCaptionWithAwemeId:(NSString *)awemeId;

// 查询字幕信息
//- (void)queryCaptionsWithUrl:(NSURL *)audioUrl completion:(AudioQueryCompletion)completion;

@end

@interface AWEVideoPublishViewModel (AWERepoCaption)
 
@property (nonatomic, strong, readonly) AWERepoCaptionModel *repoCaption;
 
@end

NS_ASSUME_NONNULL_END
