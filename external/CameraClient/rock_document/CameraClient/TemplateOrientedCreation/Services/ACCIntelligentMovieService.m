//
//  ACCIntelligentMovieService.m
//  CameraClient-Pods-Aweme
//
//  Created by Lemonior on 2020/11/20.
//

#import "ACCIntelligentMovieService.h"
#import "ACCIntelligentMovieBIMManager.h"
#import "ACCIntelligentMovieTIMManager.h"
#import "ACCIntelligentMovieAIMManager.h"
#import "ACCMomentIntelligentMovieTIMManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import "ACCAlgorithmService.h"
#import <EffectSDK_iOS/RequirementDefine.h>
#import "ACCMomentAIMomentModel.h"
#import <CreationKitInfra/ACCLogProtocol.h>

static const NSInteger ACCDefaultFrameGeneratorFPS = 50;

@interface ACCIntelligentMovieService () 

// 输入源
@property (nonatomic, strong) NSArray<PHAsset *> *assets;
@property (nonatomic, strong) ACCAlgorithmService *algorithmService;

// 抽帧间隔(单位为s)
@property (nonatomic, assign) NSInteger frameGeneratorFPS;
@property (nonatomic, strong) ACCIntelligentMovieBIMManager *bimManager;

// task
@property (nonatomic, assign) ACCTemplateRecomendTaskStep curTaskStep;
@property (nonatomic, copy) ACCRecommendTaskProgress taskProgress;
@property (nonatomic, copy) ACCRecommendTaskCompletion taskCompletion;


// for Log
@property (nonatomic, assign) NSInteger taskStartTime;

@end

@implementation ACCIntelligentMovieService

- (void)startRecommendTaskWithAssets:(NSArray<PHAsset *> *)assets
                        taskProgress:(ACCRecommendTaskProgress)taskProgress
                          completion:(ACCRecommendTaskCompletion)completion {
    NSAssert(assets.count, @"没有输入assets, 无法启动任务");
 
    self.assets = assets;
    self.taskProgress = taskProgress;
    self.taskCompletion = completion;
    
    [self startIntelligentTask];
}

#pragma mark - recommendTask

- (void)startIntelligentTask {
    self.taskStartTime = CFAbsoluteTimeGetCurrent(); // config task startTime
    AWELogToolInfo(AWELogToolTagMoment, @"智能模板推荐任务启动，传入素材数是%lu", (unsigned long)self.assets.count);
    
    [self materailAnalysis];
}

// material analysis
- (void)materailAnalysis {
    self.curTaskStep = ACCTemplateRecomendTaskStep_Analyse;
    [self recommendTaskProgressUpdate:0];
    
    @weakify(self);
    if (self.isMomentMode) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @strongify(self);
            [self recommendTaskSuccess];
            [self matchValidMoment];
        });
    } else {
        // analysis
        self.bimManager.selectedAssets = self.assets;
        [self.bimManager startAnalyseSelecteAssetsFeature:^(BOOL success) {
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                if (success) {
                    [self recommendTaskSuccess];
                    [self matchValidMoment];
                } else {
                    [self recommendTaskFailedWithDetail:nil];
                }
            });
        }];
    }
}

// template matching
- (void)matchValidMoment {
    self.curTaskStep = ACCTemplateRecomendTaskStep_Match;
    [self recommendTaskProgressUpdate:0];
    
    // analysis
    NSMutableArray *selectedLocalIDArr = [NSMutableArray array];
    for (PHAsset *selectedAsset in self.assets) {
        [selectedLocalIDArr acc_addObject:selectedAsset.localIdentifier];
    }
    
    if (selectedLocalIDArr.count == 0) {
        [self recommendTaskFailedWithDetail:nil];
        return;
    }
    
    ACCMomentAIMomentModel *moment = [ACCIntelligentMovieAIMManager generateAMomentWithAssetsID:[selectedLocalIDArr copy]];
    if (moment && moment.materialIds.count > 0) {
        [self recommendTaskSuccess];
        [self fetchTemplateWithMoment:moment];
    } else {
        [self recommendTaskFailedWithDetail:nil];
    }
}

// template pull
- (void)fetchTemplateWithMoment:(ACCMomentAIMomentModel *)moment {
    self.curTaskStep = ACCTemplateRecomendTaskStep_Fetch;
    [self recommendTaskProgressUpdate:0];
    
    Class timManager = ACCIntelligentMovieTIMManager.class;
    if (self.isMomentMode) {
        timManager = ACCMomentIntelligentMovieTIMManager.class;
    }
    
    @weakify(self);
    [timManager fetchTemplateWithMoment:moment
                              musicInfo:self.selectedMusicInfo
                             completion:^(ACCTemplateRecommendModel * _Nullable templatesModel,
                                          NSError * _Nullable error) {
        @strongify(self);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error == nil) {
                [self recommendTaskSuccess];
                if (self.taskCompletion) {
                    self.taskCompletion(nil, templatesModel);
                }
            } else {
                [self recommendTaskFailedWithDetail:error];
            }
        });
    }];
}

- (void)recommendTaskProgressUpdate:(CGFloat)progress {
    self.taskProgress(self.curTaskStep, progress);
    NSString *stepName = nil;
    switch (self.curTaskStep) {
        case ACCTemplateRecomendTaskStep_Analyse:
            stepName = @"过bim";
            break;
        case ACCTemplateRecomendTaskStep_Match:
            stepName = @"自然聚合";
            break;
        case ACCTemplateRecomendTaskStep_Fetch:
            stepName = @"请求模板列表";
            break;
        default:
            stepName = @"未知步骤";
            NSAssert(NO, @"未知步骤，请确认");
            break;
    }
    AWELogToolInfo(AWELogToolTagMoment, @"TOC recommend task progress update, step: %@, progress: %f", stepName, progress);
}

- (void)recommendTaskSuccess {
    [self recommendTaskProgressUpdate:1];
    NSInteger taskEndTime = CFAbsoluteTimeGetCurrent(); // config task endTime
    [ACCMonitor() trackService:@"toc_recommendTask_complete"
                        status: 0
                         extra: @{
                             @"task_step": @(self.curTaskStep),
                             @"duration": @((taskEndTime - self.taskStartTime) * 1000),
                         }];
}

// failed
- (void)recommendTaskFailedWithDetail:(NSError *)error {
    [self recommendTaskProgressUpdate:1];
    NSInteger taskEndTime = CFAbsoluteTimeGetCurrent(); // config task endTime
    NSError *analyseErr = error;
    if (analyseErr == nil) {
        analyseErr = [NSError errorWithDomain:ACCTOCMVDomain
                                         code:self.curTaskStep
                                     userInfo:nil];
    }
    [ACCMonitor() trackService:@"toc_recommendTask_complete"
                        status: 1
                         extra: @{
                             @"task_step": @(self.curTaskStep),
                             @"error": analyseErr,
                             @"duration": @((taskEndTime - self.taskStartTime) * 1000),
                         }];
    if (self.taskCompletion) {
        self.taskCompletion(analyseErr, nil);
    }
}

#pragma mark - lazy

- (ACCIntelligentMovieBIMManager *)bimManager {
    if (_bimManager == nil) {
        _bimManager = [[ACCIntelligentMovieBIMManager alloc] initWithAlgorithmService:self.algorithmService];
        _bimManager.frameGeneratorFPS = self.frameGeneratorFPS;
    }
    return _bimManager;
}

- (ACCAlgorithmService *)algorithmService {
    if (!_algorithmService) {
        _algorithmService = [[ACCAlgorithmService alloc] init];
        
        // configAllAlgorithm
        _algorithmService.bimAlgorithm = @[@REQUIREMENT_INTELLIGENT_TEMPLATE_TAG];
    }
    return _algorithmService;
}

#pragma mark - config

- (NSInteger)frameGeneratorFPS {
    if (self.serviceDelegate && [self.serviceDelegate respondsToSelector:@selector(movieFrameGeneratorFPS)]) {
        return  [self.serviceDelegate movieFrameGeneratorFPS];
    }
    return ACCDefaultFrameGeneratorFPS;
}

@end
