//
//  AWEMVTemplateModel.h
//  Pods
//
//  Created by zhangchengtao on 2019/3/14.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <EffectPlatformSDK/IESEffectModel.h>

#import <CreationKitArch/ACCMVTemplateInfo.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitArch/ACCMusicModelProtocol.h>

typedef NS_ENUM(NSUInteger, AWEPhotoToVideoPhotoCountType) {
    AWEPhotoToVideoPhotoCountTypeNone = 0,
    AWEPhotoToVideoPhotoCountTypeSingle,
    AWEPhotoToVideoPhotoCountTypeMulti,
};

NS_ASSUME_NONNULL_BEGIN

typedef void(^AWEDownloadMVModelResult)(IESEffectModel * __nullable mvEffectModel);

@protocol AWEMVTemplateModelDelegate;

@interface AWEPhotoMovieTemplateInfo : NSObject

@property (nonatomic, copy) NSArray<NSString *> *templateVideoCoverURL;

@property (nonatomic, copy) NSArray<NSString *> *templatePictureCoverURL;

@property (nonatomic, assign) NSInteger templateMinMaterial;

@property (nonatomic, assign) NSInteger templateMaxMaterial;

@property (nonatomic, assign) NSInteger templatePicInputWidth;

@property (nonatomic, assign) NSInteger templatePicInputHeight;

@property (nonatomic, copy) NSString *templatePicFillMode;

@property (nonatomic, assign) AWEMVTemplateType templateType; // mv模板类型，0表示普通mv，1表示音乐动效mv

@end

@interface AWEMVTemplateModel : NSObject

//@property (nonatomic, strong, readonly) NSMutableDictionary *mvChallengeNameDict;
// 支持多话题，<effectId, [challengeName]>
@property (nonatomic, strong, readonly) NSDictionary<NSString*, NSArray<id<ACCChallengeModelProtocol>>*> *mvChallengeArrayDict;

@property (nonatomic, weak) id<AWEMVTemplateModelDelegate> delegate;

@property (nonatomic, assign, readwrite) BOOL hasMore;

// 主题模板数组
@property (nonatomic, copy, readonly) NSArray<IESEffectModel *> *templateModels;

@property (nonatomic, copy) NSDictionary *trackExtraDic;

+ (instancetype)sharedManager;

- (void)checkAndUpdatePhotoMovieTemplate;

- (void)setUpPlaceholderData;

/**
 * 根据mv的id查询IESEffectModel对象
 */
- (IESEffectModel *)templateModelWithEffectId:(NSString *)effectId;

/**
 * 获取 extra 字段中的预览视频的播放地址，素材最小和最大张数
 */
- (NSArray<NSString *> * _Nullable)templateVideoCoverURLForModel:(IESEffectModel *)model;
- (NSArray<NSString *> * _Nullable)templatePictureCoverURLForModel:(IESEffectModel *)model;
- (NSInteger)templateMinMaterialForModel:(IESEffectModel *)model;
- (NSInteger)templateMaxMaterialForModel:(IESEffectModel *)model;
- (NSInteger)templatePicInputWidth:(IESEffectModel *)model;
- (NSInteger)templatePicInputHeight:(IESEffectModel *)model;
- (NSString * _Nullable)templatePicFillMode:(IESEffectModel *)model;
- (AWEMVTemplateType)templateTypeForModel:(IESEffectModel *)model;

/**
 * 获取mv模板素材的下载进度，如果返回nil，表示当前没有下载
 */
- (NSNumber * _Nullable)downloadProgressForModel:(IESEffectModel *)model;

/**
 * 启动下载 mv 模板的素材
 */
- (void)downloadMaterialWithEffectId:(NSString *)effectId
                          completion:(AWEDownloadMVModelResult)completion;
- (void)downloadMaterialForModel:(IESEffectModel *)model;
- (void)downloadMaterialWithEffect:(IESEffectModel *)effect
                        completion:( AWEDownloadMVModelResult)completion;

- (void)p_makeMVModelFirst:(IESEffectModel *)mv;

- (void)reloadDataFromCache;

- (IESEffectModel * _Nullable)effectForPublishModel:(AWEVideoPublishViewModel *)publishModel;
- (void)updateTemplateModels:(NSArray<IESEffectModel *> *)templateModels;

// 支持多话题
- (void)addMVChallengeArray:(NSArray<id<ACCChallengeModelProtocol>> *)mvChallengeArray
                 mvEffectId:(NSString *)mvEffectId;


+ (void)addEffectModelToManagerIfNeeds:(IESEffectModel *)model;

@end

@protocol AWEMVTemplateModelDelegate <NSObject>

@optional

- (void)modelDidUpdate:(AWEMVTemplateModel *)model;

- (void)modelDidFinishLoad:(AWEMVTemplateModel *)model;

- (void)modelDidBeginLoadMore:(AWEMVTemplateModel *)model;

- (void)model:(AWEMVTemplateModel *)model didFailLoadWithError:(NSError *)error;

- (void)model:(AWEMVTemplateModel *)model didFailLoadMoreWithError:(NSError *)error;

// mv模板开始下载回调
- (void)model:(AWEMVTemplateModel *)model didStartDownloadTemplateModel:(IESEffectModel *)templateModel;

// mv模板下载进度
- (void)model:(AWEMVTemplateModel *)model didDownloadTemplateModel:(IESEffectModel *)templateModel progress:(CGFloat)progress;

// mv模板下载成功回调
- (void)model:(AWEMVTemplateModel *)model didFinishDownloadTemplateModel:(IESEffectModel *)templateModel;

// mv模板下载失败回调
- (void)model:(AWEMVTemplateModel *)model didFailDownloadTemplateModel:(IESEffectModel *)templateModel withError:(NSError *)error;

@end

@interface AWEMVTemplateModel (PhotoToVideo)

- (void)prefetchPhotoToVideoTemplates;
- (void)prefetchCachedPhotoToVideoTemplates;
- (void)preFetchPhotoToVideoMusicList;
- (void)fetchPhotoToVideoMusicWithRetryBlock:(void (^ _Nullable)(void))retryBlock completionBlock:(void (^ _Nullable)(BOOL success))completionBlock;
- (void)fetchPhotoToVideoMusicWithRetryBlock:(void (^ _Nullable)(void))retryBlock
                           isCommercialScene:(BOOL)isCommercialScene
                             completionBlock:(void (^ _Nullable)(BOOL success))completionBlock;

@property (nonatomic, strong, readonly) id<ACCMusicModelProtocol> musicModel;
@property (nonatomic, strong) id<ACCMusicModelProtocol> presentedMusicModel;

- (void)prefetchMVTemplateForSlideShowMVId:(NSString * _Nullable)mvId photoCountType:(AWEPhotoToVideoPhotoCountType)photoCountType;
- (void)preFetchPhotoToVideoFeedMusicWithMusicId:(NSString *_Nullable)musicID;
- (id<ACCMusicModelProtocol>)feedVideoMusicModelForType:(AWEPhotoToVideoPhotoCountType)type;
- (id<ACCMusicModelProtocol>)videoMusicModelWithType:(AWEPhotoToVideoPhotoCountType)type;
- (void)resetFeedPhotoCountType;
- (void)switchMusicModel;

- (void)cleanPhotoToVideoMusic;

- (IESEffectModel * _Nullable)photoToVideoTemplateWithIsSinglePhoto:(BOOL)isSinglePhoto;
- (id<ACCMusicModelProtocol>)defaultMusicForPhotoToVideoTemplate;
- (void)asyncFetchPhotoToVideoTemplateWithIsSinglePhoto:(BOOL)isSinglePhoto completion:(AWEDownloadMVModelResult)completion;
- (NSDictionary *)photoToVideoMoniterInfoSucceeed:(BOOL)succeeed isSinglePhoto:(BOOL)isSinglePhoto startTime:(CFAbsoluteTime)startTime;

- (NSDictionary *)textToVideoMoniterInfoSucceeed:(BOOL)succeeed startTime:(CFAbsoluteTime)startTime;

// Text To Video; Template method separately, shared music method
- (void)prefetchTextToVideoTemplates;
- (void)asyncFetchTextToVideoTemplateWithCompletion:(AWEDownloadMVModelResult)completion;

@end

NS_ASSUME_NONNULL_END
