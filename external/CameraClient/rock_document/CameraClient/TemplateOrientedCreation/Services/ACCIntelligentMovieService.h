//
//  ACCIntelligentMovieService.h
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#import <Foundation/Foundation.h>
#import "ACCIntelligentMovieServiceProtocol.h"
#import "ACCTemplateDetailModel.h"
#import <Photos/PHAsset.h>

@class LVTemplateDataManager;

// 错误信息
static NSString *const ACCTOCMVDomain = @"com.toc.template.recommend";

/*
 * ACCTemplateRecomendTaskStep_Analyse: This step is to calculate the material through the algorithm, the more material the longer time
 * ACCTemplateRecomendTaskStep_Match: This step is relatively short
 * ACCTemplateRecomendTaskStep_Fetch: This step depends on the network request duration
 */
typedef NS_ENUM(NSUInteger, ACCTemplateRecomendTaskStep) {
    ACCTemplateRecomendTaskStep_Analyse, // material analysis
    ACCTemplateRecomendTaskStep_Match,   // template matching
    ACCTemplateRecomendTaskStep_Fetch,   // template pull
};

// Task processing callback
typedef void(^ACCRecommendTaskProgress)(ACCTemplateRecomendTaskStep step, float progress);

// task finished callback
typedef void(^ACCRecommendTaskCompletion)(NSError *error,
                                          ACCTemplateRecommendModel *templateRecommendModel);

@interface ACCIntelligentMovieService : NSObject

@property (nonatomic, weak) id<ACCIntelligentMovieServiceProtocol> serviceDelegate;

// optional
@property (nonatomic, strong) ACCMusicInfo *selectedMusicInfo; // 用户选择的音乐信息(用于拉取背景音乐相似的模板)

@property (nonatomic, assign) BOOL isMomentMode;

/* 启动推荐任务(分析素材 + 匹配模板 + 拉取模板)
 * recommendTask
 * Including: material analysis, template matching, template pull
 */
- (void)startRecommendTaskWithAssets:(NSArray<PHAsset *> *)assets
                        taskProgress:(ACCRecommendTaskProgress)taskProgress
                          completion:(ACCRecommendTaskCompletion)completion;

@end
