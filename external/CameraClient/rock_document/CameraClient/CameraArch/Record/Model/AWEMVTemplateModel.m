//
//  AWEMVTemplateModel.m
//  Pods
//
//  Created by zhangchengtao on 2019/3/14.
//

#import "AWEMVTemplateModel.h"

// TTMonitor
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <TTNetworkManager/TTHttpResponseChromium.h>

#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/NSString+ACCAdditions.h>
#import <CreationKitArch/ACCStudioServiceProtocol.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import <CreationKitArch/CKConfigKeysDefines.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCCommerceServiceProtocol.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import "ACCVideoMusicProtocol.h"
#import <CameraClient/AWEEffectPlatformManager.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import "ACCVideoMusicListResponse.h"
#import "ACCConfigKeyDefines.h"

//photo to video monitor: https://bytedance.feishu.cn/docs/doccnA7uuV3yGobQXJFbjRArVZg#
typedef NS_ENUM(NSUInteger, AWEPhotoToVideoMonitorStatus) {
    AWEPhotoToVideoMonitorStatusSucced = 0,
    AWEPhotoToVideoMonitorStatusMVListFailed = 1,
    AWEPhotoToVideoMonitorStatusMVListTimeOut = 2,
    AWEPhotoToVideoMonitorStatusMVFailed = 3,
    AWEPhotoToVideoMonitorStatusMVTimeOut = 4,
    AWEPhotoToVideoMonitorStatusMusicListFailed = 5,
    AWEPhotoToVideoMonitorStatusMusicListTimeOut = 6,
    AWEPhotoToVideoMonitorStatusMusicFailed = 7,
    AWEPhotoToVideoMonitorStatusMusicTimeOut = 8,
};


static NSString *const photoMoviePannel = @"mv";
static NSString *const kSinglePhotoToVideoPannel = @"singlepiceffect";
static NSString *const kMultiplePhotoToVideoPannel = @"slideshoweffect";
static NSString *const kTextPhotoToVideoPanel = @"textmode";
static NSString *const kPhotoToVideoDefaultMusicListNameKey = @"acc.photo_to_video_template.music_list_id";
static NSString *const kMVCategoryAll = @"";
static NSInteger kACCPhotoToVideoMusicCount = 5;

static NSInteger kACCMVDownloadMaxWaitDurationInSeconds = 5;

@implementation AWEPhotoMovieTemplateInfo
@end

@interface AWEPhotoToVideoMonitorInfo : NSObject

@property (nonatomic, assign) CFAbsoluteTime singleMVListEndTime;
@property (nonatomic, assign) BOOL singleMVListFailed;

@property (nonatomic, assign) CFAbsoluteTime multiMVListEndTime;
@property (nonatomic, assign) BOOL multiMVListFailed;

@property (nonatomic, assign) CFAbsoluteTime singleMVEndTime;
@property (nonatomic, assign) BOOL singleMVFailed;

@property (nonatomic, assign) CFAbsoluteTime multiMVEndTime;
@property (nonatomic, assign) BOOL multiMVFailed;

@property (nonatomic, assign) CFAbsoluteTime musicListEndTime;
@property (nonatomic, assign) BOOL musicListFailed;

@property (nonatomic, assign) CFAbsoluteTime musicEndTime;
@property (nonatomic, assign) BOOL musicFailed;

@property (nonatomic, assign) NSInteger musicCount;

@property (nonatomic, assign) CFAbsoluteTime textVideoEndTime;
@property (nonatomic, assign) BOOL textVideoFailed;

@end

@implementation AWEPhotoToVideoMonitorInfo

- (void)updateTemplateListSuccess:(BOOL)success panel:(NSString *)pannel
{
    if ([pannel isEqualToString:kSinglePhotoToVideoPannel]) {
        if (success) {
            self.singleMVListEndTime = CFAbsoluteTimeGetCurrent();
            self.singleMVListFailed = NO;
        } else {
            self.singleMVListFailed = YES;
        }
    } else if ([pannel isEqualToString:kMultiplePhotoToVideoPannel]) {
        if (success) {
            self.multiMVListEndTime = CFAbsoluteTimeGetCurrent();
            self.multiMVListFailed = NO;
        } else {
            self.multiMVListFailed = YES;
        }
    } else if ([pannel isEqualToString:kTextPhotoToVideoPanel]) {
        if (success) {
            self.textVideoEndTime = CFAbsoluteTimeGetCurrent();
            self.textVideoFailed = NO;
        } else {
            self.textVideoFailed = YES;
        }
    }
}

- (void)updateTemplateWithSuccess:(BOOL)success panel:(NSString *)pannel
{
    if ([pannel isEqualToString:kSinglePhotoToVideoPannel]) {
        if (success) {
            self.singleMVEndTime = CFAbsoluteTimeGetCurrent();
            self.singleMVFailed = NO;
        } else {
            self.singleMVFailed = YES;
        }
    } else if ([pannel isEqualToString:kMultiplePhotoToVideoPannel]) {
        if (success) {
            self.multiMVEndTime = CFAbsoluteTimeGetCurrent();
            self.multiMVFailed = NO;
        } else {
            self.multiMVFailed = YES;
        }
    } else if ([pannel isEqualToString:kTextPhotoToVideoPanel]) {
        if (success) {
            self.textVideoEndTime = CFAbsoluteTimeGetCurrent();
            self.textVideoFailed = NO;
        } else {
            self.textVideoFailed = YES;
        }
    }
}

- (void)updateMusicInfoWithIsList:(BOOL)isList success:(BOOL)success
{
    if (isList) {
        if (success) {
            self.musicListEndTime = CFAbsoluteTimeGetCurrent();
            self.musicListFailed = NO;
        } else {
            self.musicListFailed = YES;
        }
    } else {
        if (success) {
            self.musicEndTime = CFAbsoluteTimeGetCurrent();
            self.musicFailed = NO;
        } else {
            self.musicFailed = YES;
        }
    }
}

@end

@interface AWEMVTemplateModel ()

//@property (nonatomic, strong, readwrite) NSMutableDictionary *mvChallengeNameDict;
@property (nonatomic, strong) NSMutableDictionary<NSString*, NSArray<id<ACCChallengeModelProtocol>>*> *mvChallengeArrayDict;

@property (nonatomic, copy, readwrite, setter=setTemplateModels:) NSArray<IESEffectModel *> *templateModels;

@property (nonatomic, copy) NSArray<NSString *> *urlPrefix; // 模板预览视频 url 前缀

@property (nonatomic, strong) NSMutableDictionary<NSString *, AWEPhotoMovieTemplateInfo *> *effectModelTemplateInfos; // 模板的信息

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadingProgress; // 当前正在下载素材的进度

@property (nonatomic, copy, readwrite) NSArray<IESCategoryModel *> *categories;
@property (nonatomic, strong) IESCategoryEffectsModel *categoryEffects;
@property (nonatomic, assign, readwrite) NSInteger loadCursor;
@property (nonatomic, assign, readwrite) NSInteger sortingPosition;
@property (nonatomic, assign, readwrite) BOOL isLoadingData;
@property (nonatomic, assign, readwrite) BOOL didLoadedFirstPageData;

@property (nonatomic, strong, readwrite) IESEffectModel* sameMVModel;

//11.2.0 photo to video using mv templates:
@property (nonatomic, strong) IESEffectModel* singlePhotoToVideoModel;
@property (nonatomic, strong) IESEffectModel* multiplePhotoToVideoModel;
@property (nonatomic, strong) IESEffectModel *textPhotoToVideoModel; // used in record text tab

@property (nonatomic, strong) IESEffectModel *feedPhotoToVideoModel;
@property (nonatomic, strong) NSArray<id<ACCMusicModelProtocol>> *musicList;
@property (nonatomic, strong) id<ACCMusicModelProtocol> musicModel;
@property (nonatomic, strong) id<ACCMusicModelProtocol> presentedMusicModel;
@property (nonatomic, strong) id<ACCMusicModelProtocol> lastMusicModel;
@property (nonatomic, strong) id<ACCMusicModelProtocol> feedMusicModel;

@property (nonatomic, copy) AWEDownloadMVModelResult singlePhotoTemplateCompletion;
@property (nonatomic, copy) AWEDownloadMVModelResult multiplePhotoTemplateCompletion;
@property (nonatomic, copy) AWEDownloadMVModelResult textTemplateCompletion;

@property (nonatomic, assign) BOOL isSinglePhotoTemplateDownloading;
@property (nonatomic, assign) BOOL isMultiplePhotoTemplateDownloading;
@property (nonatomic, assign) BOOL isTextPhotoTemplateDownloading;

@property (nonatomic, assign) BOOL isTemplateMusicDownloading;
@property (nonatomic, copy) NSString *feedPhotoTemplateDownloadingModelId;
@property (nonatomic, assign) AWEPhotoToVideoPhotoCountType feedVideoPhotoCountType;

@property (nonatomic, strong) AWEPhotoToVideoMonitorInfo *photoToVideoMonitorInfo;

@end

@implementation AWEMVTemplateModel

+ (instancetype)sharedManager
{
    static AWEMVTemplateModel *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[AWEMVTemplateModel alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        [IESAutoInline(ACCBaseServiceProvider(), ACCStudioServiceProtocol) preloadInitializationEffectPlatformManager];
        
        _effectModelTemplateInfos = [[NSMutableDictionary alloc] init];
        _downloadingProgress = [[NSMutableDictionary alloc] init];
        _templateModels = [[NSArray alloc] init];
        _mvChallengeArrayDict = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public

- (void)checkAndUpdatePhotoMovieTemplate
{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    NSString *panel = photoMoviePannel;
    NSString *category = kMVCategoryAll;
    @weakify(self);
    [EffectPlatform checkPanelUpdateWithPanel:panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
         IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:panel category:category];
        if (needUpdate || cachedResponse.categoryEffects.effects.count <= 0) {
            [EffectPlatform fetchCategoriesListWithPanel:panel isLoadDefaultCategoryEffects:YES defaultCategory:category pageCount:0 cursor:0 effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformNewResponseModel * _Nullable response) {
                @strongify(self);
                if (!error && response.categoryEffects.effects.count > 0) {
                    self.templateModels = response.categoryEffects.effects;
                    self.urlPrefix = response.urlPrefix;
                    if ([self.delegate respondsToSelector:@selector(modelDidUpdate:)]) {
                        [self.delegate modelDidUpdate:self];
                    }
                    if ([self.delegate respondsToSelector:@selector(modelDidFinishLoad:)]) {
                        [self.delegate modelDidFinishLoad:self];
                    }
                    
                    NSInteger duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                    NSMutableDictionary *params = @{@"api_type":@"mv_list",
                                                    @"duration":@(duration),
                                                    @"status":@(0)}.mutableCopy;
                    [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                    [ACCTracker() trackEvent:@"tool_performance_api" params:params.copy needStagingFlag:NO];
                    
                    [ACCMonitor() trackService:@"aweme_mv_list_error"
                                     status:0
                                      extra:@{
                                              @"panel" : panel ?: @"",
                                              @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                              @"needUpdate" : @(YES)
                                              }];
                } else {
                    if ([self.delegate respondsToSelector:@selector(model:didFailLoadWithError:)]) {
                        [self.delegate model:self didFailLoadWithError:error];
                    }
                    
                    NSInteger duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000;
                    NSMutableDictionary *params = @{@"api_type":@"mv_list",
                                                    @"duration":@(duration),
                                                    @"status":@(1),
                                                    @"error_domain":error.domain?:@"",
                                                    @"error_code":@(error.code)}.mutableCopy;
                    [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                    [ACCTracker() trackEvent:@"tool_performance_api"
                                       params:params.copy
                              needStagingFlag:NO];
                    
                    [ACCMonitor() trackService:@"aweme_mv_list_error"
                                     status:1
                                      extra:@{
                                              @"panel" : panel ?: @"",
                                              @"errorDesc":error.description ?: @"",
                                              @"errorCode":@(error.code),
                                              @"needUpdate" : @(YES)
                                              }];
                }
            }];
        } else {
            if (cachedResponse.categoryEffects.effects.count > 0) {
                self.templateModels = [cachedResponse.categoryEffects.effects copy];
            }
            self.urlPrefix = [cachedResponse.urlPrefix copy];

            if ([self.delegate respondsToSelector:@selector(modelDidUpdate:)]) {
                [self.delegate modelDidUpdate:self];
            }
            
            if ([self.delegate respondsToSelector:@selector(modelDidFinishLoad:)]) {
                [self.delegate modelDidFinishLoad:self];
            }
            
            [ACCMonitor() trackService:@"aweme_mv_list_error"
                             status:0
                              extra:@{
                                      @"panel" : panel ?: @"",
                                      @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                      @"needUpdate" : @(NO)
                                      }];
        }
    }];
}

-(void)p_reset {
    self.didLoadedFirstPageData = NO;
    self.isLoadingData = NO;
    self.templateModels = @[];
}

-(void)p_updatePageInfo:(IESEffectPlatformNewResponseModel*)response isLoadMore:(BOOL)loadMore {
    self.categoryEffects = [response.categoryEffects copy];
    self.loadCursor = response.categoryEffects.cursor;
    self.hasMore = response.categoryEffects.hasMore;
    self.sortingPosition = response.categoryEffects.sortingPosition;
    self.urlPrefix = [response.urlPrefix copy];
    if (loadMore) {
        NSMutableArray* array = [(self.templateModels ?: @[]) mutableCopy] ;
        NSArray* toAddArr = response.categoryEffects.effects;
        if (!self.sameMVModel) {
            toAddArr = [toAddArr filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IESEffectModel*  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
                if ([evaluatedObject.effectIdentifier isEqualToString:self.sameMVModel.effectIdentifier]) {
                    return NO;
                }
                return YES;
            }]];
        }
        [array addObjectsFromArray:toAddArr];
        self.templateModels = array;
    } else {
        self.templateModels = [[response.categoryEffects.effects mutableCopy] copy];
    }
}

- (void)reloadDataFromCache
{
    IESEffectPlatformNewResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:photoMoviePannel category:kMVCategoryAll];
    self.templateModels = [cachedResponse.categoryEffects.effects copy];
    self.urlPrefix = [cachedResponse.urlPrefix copy];
}

- (IESEffectModel *)effectForPublishModel:(AWEVideoPublishViewModel *)publishModel
{
    if (publishModel.repoContext.isMVVideo) {
        return [self templateModelWithEffectId:publishModel.repoMV.templateModelId];
    } else if (publishModel.repoContext.videoType == AWEVideoTypePhotoToVideo) {
        if ([publishModel.repoMV.slideshowMVID isEqualToString:self.singlePhotoToVideoModel.effectIdentifier]) {
            return self.singlePhotoToVideoModel;
        } else if ([publishModel.repoMV.slideshowMVID isEqualToString:self.multiplePhotoToVideoModel.effectIdentifier]) {
            return self.multiplePhotoToVideoModel;
        } else if ([publishModel.repoMV.slideshowMVID isEqualToString:self.feedPhotoToVideoModel.effectIdentifier]) {
            return self.feedPhotoToVideoModel;
        } else if ([publishModel.repoMV.slideshowMVID isEqualToString:self.textPhotoToVideoModel.effectIdentifier]) {
            return self.textPhotoToVideoModel;
        }
    }
    return nil;
}

- (void)updateTemplateModels:(NSArray<IESEffectModel *> *)templateModels
{
    self.templateModels = templateModels;
}

- (void)setUpPlaceholderData
{
    if (self.templateModels.count == 0) {
        NSMutableArray *tmp = [[NSMutableArray alloc] init];
        for (NSInteger index = 0; index < 3; index++) {
            IESEffectModel *placeholderModel = [[IESEffectModel alloc] init];
            [tmp addObject:placeholderModel];
        }
        self.templateModels = tmp;
    }
}

+ (void)addEffectModelToManagerIfNeeds:(IESEffectModel *)model
{
    BOOL finded = NO;
    for (IESEffectModel *effectModel in [AWEMVTemplateModel sharedManager].templateModels) {
        if ([effectModel.effectIdentifier isEqualToString:model.effectIdentifier ?: @""]) {
            finded = YES;
            break;
        }
    }
    if (!finded) {
        NSMutableArray<IESEffectModel *> *templates = @[].mutableCopy;
        if ([AWEMVTemplateModel sharedManager].templateModels.count) {
            [templates addObjectsFromArray:[AWEMVTemplateModel sharedManager].templateModels];
        }
        [templates addObject:model];
        [[AWEMVTemplateModel sharedManager] updateTemplateModels:templates.copy];
    }
}

- (IESEffectModel *)templateModelWithEffectId:(NSString *)effectId {
    if (!effectId) {
        return nil;
    }
    
    NSArray *effectModels = self.templateModels;
    if (!effectModels) {
        [self reloadDataFromCache];
        effectModels = self.templateModels;
    }
    
    IESEffectModel *effectModel = nil;
    for (IESEffectModel *model in effectModels) {
        if ([effectId isEqualToString:model.effectIdentifier]) {
            effectModel = model;
            break;
        }
    }
    return effectModel;
}

- (NSArray<NSString *> * _Nullable)templateVideoCoverURLForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templateVideoCoverURL;
    }
    
    return nil;
}

- (NSArray<NSString *> * _Nullable)templatePictureCoverURLForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templatePictureCoverURL;
    }
    return nil;
}

- (NSInteger)templateMinMaterialForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templateMinMaterial;
    }
    
    return 0;
}

- (NSInteger)templateMaxMaterialForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templateMaxMaterial;
    }
    
    return 0;
}

- (NSInteger)templatePicInputWidth:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templatePicInputWidth;
    }
    
    return 0;
}

- (NSInteger)templatePicInputHeight:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templatePicInputHeight;
    }
    
    return 0;
}

- (NSString * _Nullable)templatePicFillMode:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templatePicFillMode;
    }
    
    return nil;
}

- (AWEMVTemplateType)templateTypeForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        AWEPhotoMovieTemplateInfo *templateInfo = [self.effectModelTemplateInfos objectForKey:model.effectIdentifier];
        if (!templateInfo) {
            templateInfo = [self templateInfoForModel:model];
            if (templateInfo) {
                [self.effectModelTemplateInfos setObject:templateInfo forKey:model.effectIdentifier];
            }
        }
        return templateInfo.templateType;
    }
    
    return AWEMVTemplateTypeNormal;
}

- (NSNumber * _Nullable)downloadProgressForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        return [self.downloadingProgress objectForKey:model.effectIdentifier];
    }
    return nil;
}

- (void)downloadMaterialWithEffectId:(NSString *)effectId completion:(nonnull AWEDownloadMVModelResult)completion {
    if (!effectId) {
        return;
    }
    
    [EffectPlatform downloadEffectListWithEffectIDS:@[effectId] completion:^(NSError * _Nullable error, NSArray<IESEffectModel *> * _Nullable effects) {
        if (effects.count > 0) {
            IESEffectModel *mvEffectModel = effects.firstObject;
            if (mvEffectModel.downloaded) {
                if (completion) {
                    completion(mvEffectModel);
                }
            } else {
                [EffectPlatform downloadEffect:mvEffectModel progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    if (!error && filePath) {
                        if (completion) {
                            completion(mvEffectModel);
                        }
                    } else {
                        if (completion) {
                            completion(nil);
                        }
                    }
                }];
            }
        } else {
            if (completion) {
                completion(nil);
            }
        }
    }];
}

- (void)downloadMaterialForModel:(IESEffectModel *)model
{
    if (model.effectIdentifier) {
        // 已经下载成功
        if (model.downloaded) {
            return;
        }
        
        // 当前正在下载
        if ([self.downloadingProgress objectForKey:model.effectIdentifier]) {
            return;
        }
        
        // 开始下载
        [self.downloadingProgress setObject:@(0) forKey:model.effectIdentifier];
        if ([self.delegate respondsToSelector:@selector(model:didStartDownloadTemplateModel:)]) {
            [self.delegate model:self didStartDownloadTemplateModel:model];
        }
        
        CFTimeInterval singleStickerStartTime = CFAbsoluteTimeGetCurrent();
        [EffectPlatform downloadEffect:model progress:^(CGFloat progress) {
            // 下载进度回调
            [self.downloadingProgress setObject:@(progress) forKey:model.effectIdentifier];
            if ([self.delegate respondsToSelector:@selector(model:didDownloadTemplateModel:progress:)]) {
                [self.delegate model:self didDownloadTemplateModel:model progress:progress];
            }
            
        } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            [self.downloadingProgress removeObjectForKey:model.effectIdentifier];
            
            NSDictionary *extraInfo = @{
                                        @"effect_id" : model.effectIdentifier ?: @"",
                                        @"effect_name" : model.effectName ?: @"",
                                        @"download_urls" : [model.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
                                        @"is_ar" : @([model isTypeAR]),
                                        @"is_tt" : @(ACCConfigBool(kConfigBool_use_TTEffect_platform_sdk))
                                        };
            
            if (!error && filePath) {
                // 下载成功回调
                if ([self.delegate respondsToSelector:@selector(model:didFinishDownloadTemplateModel:)]) {
                    [self.delegate model:self didFinishDownloadTemplateModel:model];
                }
                
                [ACCMonitor() trackService:@"mv_resource_download_error_state"
                                 status:0
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                                @"duration" : @((CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000)
                                                                                                 }]];
                
                
                NSInteger duration = (CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000;
                NSMutableDictionary *params = @{@"resource_type":@"mv",
                                                @"duration":@(duration),
                                                @"status":@(0)}.mutableCopy;
                [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                [ACCTracker() trackEvent:@"tool_performance_resource_download"
                                   params:params.copy
                          needStagingFlag:NO];
                
            } else {
                // 下载失败回调
                if ([self.delegate respondsToSelector:@selector(model:didFailDownloadTemplateModel:withError:)]) {
                    [self.delegate model:self didFailDownloadTemplateModel:model withError:error];
                }
                
                id networkResponse = error.userInfo[IESEffectNetworkResponse];
                if ([networkResponse isKindOfClass:[TTHttpResponse class]]) {
                    TTHttpResponse *ttResponse = (TTHttpResponse *)networkResponse;
                    extraInfo = [extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                         @"httpStatus" : @(ttResponse.statusCode),
                                                                                         @"httpHeaderFields":
                                                                                             ttResponse.allHeaderFields.description ?: @""
                                                                                         }];
                    if ([ttResponse isKindOfClass:[TTHttpResponseChromium class]]) {
                        TTHttpResponseChromium *chromiumResponse = (TTHttpResponseChromium *)ttResponse;
                        NSString *requestLog = chromiumResponse.requestLog;
                        extraInfo = [extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                             @"ttRequestLog" : requestLog ?: @""}];
                    }
                } else if ([networkResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)networkResponse;
                    extraInfo = [extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                         @"httpStatus" : @(httpResponse.statusCode),
                                                                                         @"httpHeaderFields":
                                                                                             httpResponse.allHeaderFields.description ?: @""
                                                                                         }];
                }
                [ACCMonitor() trackService:@"mv_resource_download_error_state"
                                 status:1
                                  extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                                 @"errorCode" : @(error.code),
                                                                                                 @"errorDesc" : error.localizedDescription ?: @""
                                                                                                 }]
                      extraParamsOption:TTMonitorExtraParamsOptionDNS];
                
                NSInteger duration = (CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000;
                NSMutableDictionary *params = @{@"resource_type":@"mv",
                                                @"duration":@(duration),
                                                @"status":@(1),
                                                @"error_domain":error.domain?:@"",
                                                @"error_code":@(error.code)}.mutableCopy;
                [params addEntriesFromDictionary:self.trackExtraDic?:@{}];
                [ACCTracker() trackEvent:@"tool_performance_resource_download"
                                   params:params.copy
                          needStagingFlag:NO];
            }
        }];
    }
}

- (void)downloadMaterialWithEffect:(IESEffectModel *)effect completion:(nonnull AWEDownloadMVModelResult)completion {
    if (!effect) {
        ACCBLOCK_INVOKE(completion, nil);
        return;
    }
    if (effect.downloaded) {
        ACCBLOCK_INVOKE(completion, effect);
    } else {
        [EffectPlatform downloadEffect:effect progress:nil completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
            if (!error && filePath) {
                ACCBLOCK_INVOKE(completion, effect);
            } else {
                ACCBLOCK_INVOKE(completion, nil);
            }
        }];
    }
}

- (void)p_makeMVModelFirst:(IESEffectModel *)mv
{
    if (!mv) {
        return;
    }
    if (self.templateModels.count > 0) {
        self.sameMVModel = mv;
        NSMutableArray* arr = [[self.templateModels filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IESEffectModel*  _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
           if ([evaluatedObject.effectIdentifier isEqualToString:mv.effectIdentifier]) {
               return  NO;
           }
           return YES;
        }]] mutableCopy];
        [arr insertObject:self.sameMVModel atIndex:0];
        self.templateModels = arr;
    }
}

- (void)setTemplateModels:(NSArray<IESEffectModel *> *)templateModels
{
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) shouldUseCommerceMusic]) {
        _templateModels = templateModels;
        return;
    }
    NSArray *models = [templateModels filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IESEffectModel * _Nullable evaluatedObject, NSDictionary<NSString *,id> * _Nullable bindings) {
        NSDictionary *dict = [evaluatedObject.extra acc_jsonValueDecoded];
        return [dict acc_boolValueForKey:@"is_commerce_music"];
    }]];
    _templateModels = models;
}

- (void)addMVChallengeArray:(NSArray<id<ACCChallengeModelProtocol>> *)mvChallengeArray
                 mvEffectId:(NSString *)mvEffectId
{
    if (mvEffectId.length > 0) {
        @synchronized (self) {
            NSArray *existChallengeNames = [self.mvChallengeArrayDict[mvEffectId] copy];
            NSMutableOrderedSet *toUpdateSet = [[NSMutableOrderedSet alloc] init];
            
            for (id<ACCChallengeModelProtocol> challenge in existChallengeNames) {
                if (!ACC_isEmptyString(challenge.challengeName)) {
                    [toUpdateSet addObject:challenge];
                }
            }
            
            for (id<ACCChallengeModelProtocol> challenge in [mvChallengeArray copy]) {
                if (!ACC_isEmptyString(challenge.challengeName)) {
                    [toUpdateSet addObject:challenge];
                }
            }
            NSArray *toUpdateArray = [toUpdateSet array];;
            
            _mvChallengeArrayDict[mvEffectId] = [toUpdateArray copy];
            AWELogToolInfo(AWELogToolTagNone, @"addMVChallengeArray|to update count=%zi|toUpdateArray=%@", toUpdateArray.count, toUpdateArray);
        }
    }
    AWELogToolDebug(AWELogToolTagNone, @"_mvChallengeArrayDict=%@", _mvChallengeArrayDict);
}

#pragma mark - Private

/**
 * 解析 model 的 extra 字段中的信息，mv pannel 的 extra 字段包含: template_video_cover (预览视频的 md5 值)，
 * template_min_material（素材最少个数）, template_max_material（素材最多个数）
 */
- (AWEPhotoMovieTemplateInfo *)templateInfoForModel:(IESEffectModel *)model {
    NSArray<NSString *> *urlPrefix = self.urlPrefix;
    NSData *jsonData = [model.extra dataUsingEncoding:NSUTF8StringEncoding];
    if (jsonData) {
        NSError *error = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
        if ([jsonObject isKindOfClass:[NSDictionary class]]) {
            NSString *templateVideoCover = [jsonObject acc_stringValueForKey:@"template_video_cover"];
            NSString *templatePictureCover = [jsonObject acc_stringValueForKey:@"template_picture_cover"];
            NSInteger templateMinMaterial = [jsonObject acc_integerValueForKey:@"template_min_material"];
            NSInteger templateMaxMaterial = [jsonObject acc_integerValueForKey:@"template_max_material"];
            NSInteger templatePicInputWidth = [jsonObject acc_integerValueForKey:@"template_pic_input_width"];
            NSInteger templatePicInputHeight = [jsonObject acc_integerValueForKey:@"template_pic_input_height"];
            NSString *templatePicFillMode = [jsonObject acc_stringValueForKey:@"template_pic_fill_mode"];
            NSInteger templateType = [jsonObject acc_integerValueForKey:@"template_type"];
            AWEPhotoMovieTemplateInfo *templateInfo = [[AWEPhotoMovieTemplateInfo alloc] init];
            if (templateVideoCover) {
                NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:urlPrefix.count];
                for (NSString *prefix in urlPrefix) {
                    NSString *url = [prefix stringByAppendingString:templateVideoCover];
                    [urls addObject:url];
                }
                templateInfo.templateVideoCoverURL = urls;
            }
            if (templatePictureCover) {
                NSMutableArray *urls = [[NSMutableArray alloc] initWithCapacity:urlPrefix.count];
                for (NSString *prefix in urlPrefix) {
                    NSString *url = [prefix stringByAppendingString:templatePictureCover];
                    [urls addObject:url];
                }
                templateInfo.templatePictureCoverURL = urls;
            }
            templateInfo.templateMinMaterial = templateMinMaterial;
            templateInfo.templateMaxMaterial = templateMaxMaterial;
            templateInfo.templatePicInputWidth = templatePicInputWidth;
            templateInfo.templatePicInputHeight = templatePicInputHeight;
            templateInfo.templatePicFillMode = templatePicFillMode;
            templateInfo.templateType = templateType;
            return templateInfo;
        }
    }
    return nil;
}

@end

@implementation AWEMVTemplateModel (PhotoToVideo)

- (void)cleanPhotoToVideoMusic
{
    self.musicModel = nil;
    self.lastMusicModel = nil;
    self.musicList = nil;
}

- (IESEffectModel *)photoToVideoTemplateWithIsSinglePhoto:(BOOL)isSinglePhoto
{
    return isSinglePhoto ? self.singlePhotoToVideoModel : self.multiplePhotoToVideoModel;
}

- (id<ACCMusicModelProtocol>)defaultMusicForPhotoToVideoTemplate
{
    return self.musicModel;
}

- (void)prefetchPhotoToVideoTemplates
{
    if (!self.isSinglePhotoTemplateDownloading) {
        self.isSinglePhotoTemplateDownloading = YES;
        [self prefetchMVTemplatesForPanel:kSinglePhotoToVideoPannel];
    }
    if (!self.isMultiplePhotoTemplateDownloading) {
        self.isMultiplePhotoTemplateDownloading = YES;
        [self prefetchMVTemplatesForPanel:kMultiplePhotoToVideoPannel];
    }
}

- (void)prefetchTextToVideoTemplates
{
    if (!self.isTextPhotoTemplateDownloading) {
        self.isTextPhotoTemplateDownloading = YES;
        [self prefetchMVTemplatesForPanel:kTextPhotoToVideoPanel];
    }
}

- (BOOL)support1080P
{
    return ACCConfigBool(kConfigBool_enable_1080p_photo_to_video);
}

- (IESEffectModel *)chooseEffectModelFrom:(NSArray *)effects
{
    NSInteger photoWidth = [self support1080P] ? 1080 : 720;
    for (IESEffectModel *effect in effects) {
        ACCMVTemplateInfo *templateInfo = [ACCMVTemplateInfo MVTemplateInfoFromEffect:effect coverURLPrefixs:nil];
        if (templateInfo.photoInputWidth == photoWidth) {
            return effect;
        }
    }
    return [effects firstObject];
}

- (void)updatePhotoVideoModel:(IESEffectModel *)model forPanel:(NSString *)panel
{
    [self.photoToVideoMonitorInfo updateTemplateWithSuccess:model.downloaded panel:panel];
    if (!model.downloaded) {
        return;
    }
    if ([panel isEqualToString:kSinglePhotoToVideoPannel]) {
        self.singlePhotoToVideoModel = model;
    } else if ([panel isEqualToString:kMultiplePhotoToVideoPannel]) {
        self.multiplePhotoToVideoModel = model;
    } else if ([panel isEqualToString:kTextPhotoToVideoPanel]) {
        self.textPhotoToVideoModel = model;
    }
    [self finishCompletion];
}

- (void)prefetchCachedPhotoToVideoTemplates
{
    if (!self.singlePhotoToVideoModel) {
        NSArray *singleEffects = [EffectPlatform cachedEffectsOfPanel:kSinglePhotoToVideoPannel].effects;
        IESEffectModel *model = [self chooseEffectModelFrom:singleEffects];
        [self updatePhotoVideoModel:model forPanel:kSinglePhotoToVideoPannel];
    }
    if (!self.multiplePhotoToVideoModel) {
        NSArray *multiEffects = [EffectPlatform cachedEffectsOfPanel:kMultiplePhotoToVideoPannel].effects;
        IESEffectModel *model = [self chooseEffectModelFrom:multiEffects];
        [self updatePhotoVideoModel:model forPanel:kMultiplePhotoToVideoPannel];
    }
    if (!self.textPhotoToVideoModel) {
        NSArray *effects = [EffectPlatform cachedEffectsOfPanel:kTextPhotoToVideoPanel].effects;
        IESEffectModel *model = [self chooseEffectModelFrom:effects];
        [self updatePhotoVideoModel:model forPanel:kTextPhotoToVideoPanel];
    }
}

- (void)finishPhotoToVideoTemplateDownloadFor:(NSString *)panel
{
    if ([panel isEqualToString:kSinglePhotoToVideoPannel]) {
        self.isSinglePhotoTemplateDownloading = NO;
    } else if ([panel isEqualToString:kMultiplePhotoToVideoPannel]) {
        self.isMultiplePhotoTemplateDownloading = NO;
    } else if ([panel isEqualToString:kTextPhotoToVideoPanel]) {
        self.isTextPhotoTemplateDownloading = NO;
    }
}

- (void)prefetchMVTemplatesForPanel:(NSString *)panel
{
    @weakify(self);
    [AWEEffectPlatformManager configEffectPlatform];
    [EffectPlatform checkEffectUpdateWithPanel:panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:panel];
        if (needUpdate || cachedResponse.effects.count <= 0) {
            [EffectPlatform downloadEffectListWithPanel:panel effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
                @strongify(self);
                if (!error && response.effects.count > 0) {//succeed
                    [self.photoToVideoMonitorInfo updateTemplateListSuccess:YES panel:panel];
                    IESEffectModel *model = [self chooseEffectModelFrom:response.effects];
                    @weakify(self);
                    [self downloadMaterialWithEffect:model completion:^(IESEffectModel * _Nullable mvEffectModel) {
                        @strongify(self);
                        [self updatePhotoVideoModel:model forPanel:panel];
                        [self finishPhotoToVideoTemplateDownloadFor:panel];
                    }];
                } else {
                    [self finishPhotoToVideoTemplateDownloadFor:panel];
                    AWELogToolInfo2(@"photoToVideo", AWELogToolTagImport|AWELogToolTagMV, @"download %@ failed", panel);
                }
            }];
        } else {
            IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:panel];
            if (cachedResponse.effects.count > 0) {
                [self.photoToVideoMonitorInfo updateTemplateListSuccess:YES panel:panel];
                @strongify(self);
                IESEffectModel *model = [self chooseEffectModelFrom:cachedResponse.effects];
                if (model.downloaded) {
                    [self updatePhotoVideoModel:model forPanel:panel];
                    [self finishPhotoToVideoTemplateDownloadFor:panel];
                } else {
                    [self downloadMaterialWithEffect:model completion:^(IESEffectModel * _Nullable mvEffectModel) {
                        @strongify(self);
                        [self updatePhotoVideoModel:model forPanel:panel];
                        [self finishPhotoToVideoTemplateDownloadFor:panel];
                    }];
                }
            } else {
                [self.photoToVideoMonitorInfo updateTemplateListSuccess:NO panel:panel];
                [self finishPhotoToVideoTemplateDownloadFor:panel];
                AWELogToolInfo2(@"photoToVideo", AWELogToolTagImport|AWELogToolTagMV, @"load from cache for %@ failed", panel);
            }
        }
    }];
}

- (void)prefetchMVTemplateForSlideShowMVId:(NSString *)mvId photoCountType:(AWEPhotoToVideoPhotoCountType)photoCountType
{
    self.feedVideoPhotoCountType = photoCountType;
    if ([self.feedPhotoToVideoModel.effectIdentifier isEqualToString:mvId] && self.feedPhotoToVideoModel.downloaded) {
        return;
    }
    self.feedPhotoToVideoModel = nil;
    if (mvId.length > 0) {
        @weakify(self);
        self.feedPhotoTemplateDownloadingModelId = mvId;
        [self downloadMaterialWithEffectId:mvId completion:^(IESEffectModel * _Nullable effectModel) {
            @strongify(self);
            if ([effectModel.effectIdentifier isEqualToString:self.feedPhotoTemplateDownloadingModelId]) {
                self.feedPhotoTemplateDownloadingModelId = @"";
                if (effectModel.downloaded) {
                    self.feedPhotoToVideoModel = effectModel;
                    acc_dispatch_main_async_safe(^{
                        [self finishCompletion];
                    });
                } else {
                    acc_dispatch_main_async_safe(^{
                        [self finishCompletion];
                    });
                }
            }
        }];
    }
}

- (void)preFetchPhotoToVideoFeedMusicWithMusicId:(NSString *)musicID
{
    if ([self.feedMusicModel.musicID isEqualToString:musicID] && self.feedMusicModel.loaclAssetUrl) {
        return;
    }
    void (^downloadMusic)(id<ACCMusicModelProtocol> model) = ^(id<ACCMusicModelProtocol> model){
        @weakify(self);
        [ACCVideoMusic() fetchLocalURLForMusic:model withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
            @strongify(self);
            if (localURL) {
                model.loaclAssetUrl = localURL;
                self.feedMusicModel = model;
            }
            acc_dispatch_main_async_safe(^{
                [self finishCompletion];
            });
        }];
    };
    if ([self.feedMusicModel.musicID isEqualToString:musicID]) {
        downloadMusic(self.feedMusicModel);
        return;
    }
    self.feedMusicModel = nil;
    if (musicID.length > 0) {
        @weakify(self);
        [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestMusicItemWithID:musicID completion:^(id<ACCMusicModelProtocol> model, NSError *error) {
            @strongify(self);
            if (model && [model.musicID isEqualToString:musicID] && [self enableUseMusicWithMusic:model]) {
                downloadMusic(model);
            } else {
                acc_dispatch_main_async_safe(^{
                    [self finishCompletion];
                });
            }
        }];
    }
}

- (id<ACCMusicModelProtocol>)feedVideoMusicModelForType:(AWEPhotoToVideoPhotoCountType)type;
{
    if (type != AWEPhotoToVideoPhotoCountTypeNone) {
        return self.feedMusicModel;
    }
    return nil;
}

- (id<ACCMusicModelProtocol>)videoMusicModelWithType:(AWEPhotoToVideoPhotoCountType)type
{
    if (type != AWEPhotoToVideoPhotoCountTypeNone) {
        return self.feedMusicModel;
    } else {
        return self.musicModel;
    }
}

- (void)resetFeedPhotoCountType
{
    self.feedVideoPhotoCountType = AWEPhotoToVideoPhotoCountTypeNone;
}

- (void)switchMusicModel
{
    if (!self.musicList.count) {
        return;
    }
    self.lastMusicModel = self.musicModel;
    self.musicModel = nil;
    NSUInteger index = [self.musicList indexOfObject:self.lastMusicModel];
    if (index == NSNotFound) {
        index = 0;
    } else {
        index += 1;
        index = index % self.musicList.count;
    }
    id<ACCMusicModelProtocol> musicModel = [self.musicList objectAtIndex:index];
    @weakify(self);
    [ACCVideoMusic() fetchLocalURLForMusic:musicModel withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
        @strongify(self);
        if (localURL) {
            self.musicModel = musicModel;
            musicModel.loaclAssetUrl = localURL;
        }
    }];
}

- (BOOL)enableUseMusicWithMusic:(id<ACCMusicModelProtocol>)musicModel
{
    if (!musicModel.isCommerceMusic && [IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) shouldUseCommerceMusic]) {
        return NO;
    }
    return YES;
}

//called when music downloading succeed or mv template downloading succeed
// and only really running when all things are ready(model/music/completionBlock,
//otherwise goes to backup logic(waiting 5 seconds and failed:single photo failed
//by toasting and multiple photo failed by enter into old photo-movie model)
- (void)finishCompletion
{
    if ([self finishCompletionForSameModel]) {
        return;
    }
    //Single & multiple completion couldn't exist at the same time actually, they are exclusively.
    if (self.singlePhotoTemplateCompletion && self.singlePhotoToVideoModel) {
        self.singlePhotoTemplateCompletion(self.singlePhotoToVideoModel);
        self.singlePhotoTemplateCompletion = nil;
    }

    if (self.multiplePhotoTemplateCompletion && self.multiplePhotoToVideoModel && self.musicModel) {
        self.multiplePhotoTemplateCompletion(self.multiplePhotoToVideoModel);
        self.multiplePhotoTemplateCompletion = nil;
    }
    
    if (self.textTemplateCompletion && self.textPhotoToVideoModel) {
        self.textTemplateCompletion(self.textPhotoToVideoModel);
        self.textTemplateCompletion = nil;
    }
}

- (BOOL)finishCompletionForSameModel
{
    if (self.feedPhotoToVideoModel && AWEPhotoToVideoPhotoCountTypeNone != self.feedVideoPhotoCountType) {
        if (self.singlePhotoTemplateCompletion && AWEPhotoToVideoPhotoCountTypeSingle == self.feedVideoPhotoCountType) {
            self.singlePhotoTemplateCompletion(self.feedPhotoToVideoModel);
            self.singlePhotoTemplateCompletion = nil;
            return YES;
        } else if (self.multiplePhotoTemplateCompletion && AWEPhotoToVideoPhotoCountTypeMulti == self.feedVideoPhotoCountType) {
            self.multiplePhotoTemplateCompletion(self.feedPhotoToVideoModel);
            self.multiplePhotoTemplateCompletion = nil;
            return YES;
        }
    }
    return self.feedPhotoTemplateDownloadingModelId.length > 0;
}

- (void)preFetchPhotoToVideoMusicList
{
    if (!self.isTemplateMusicDownloading) {
        [self fetchPhotoToVideoMusicList];
    }
}

- (void)fetchPhotoToVideoMusicList
{
    @weakify(self);
    [self fetchPhotoToVideoMusicWithRetryBlock:^{
        @strongify(self);
        [self fetchPhotoToVideoMusicWithRetryBlock:nil];
    }];
}

- (void)fetchPhotoToVideoMusicWithRetryBlock:(void (^)(void))retryBlock
{
    [self fetchPhotoToVideoMusicWithRetryBlock:retryBlock completionBlock:nil];
}

- (void)fetchPhotoToVideoMusicWithRetryBlock:(void (^)(void))retryBlock completionBlock:(void (^)(BOOL success))completionBlock
{
    [self fetchPhotoToVideoMusicWithRetryBlock:retryBlock isCommercialScene:NO completionBlock:completionBlock];
}

- (void)fetchPhotoToVideoMusicWithRetryBlock:(void (^)(void))retryBlock isCommercialScene:(BOOL)isCommercialScene completionBlock:(void (^)(BOOL))completionBlock
{
    self.isTemplateMusicDownloading = YES;
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCMusicNetServiceProtocol) requestWithMusicClassId:nil
                                                                                          cursor:nil
                                                                                           count:@(kACCPhotoToVideoMusicCount)
                                                                                     noDuplicate:@(YES)
                                                                                     otherParams:(isCommercialScene ? @{@"scene" : @2} : nil)
                                                                                      completion:^(ACCVideoMusicListResponse *_Nullable response, NSError * _Nullable error) {
            if (response.musicList.count > 0 && !error) {
                self.musicList = response.musicList;
                self.photoToVideoMonitorInfo.musicCount = response.musicList.count;
                [self.photoToVideoMonitorInfo updateMusicInfoWithIsList:YES success:YES];
                id<ACCMusicModelProtocol> musicModel = [response.musicList firstObject];
                [ACCVideoMusic() fetchLocalURLForMusic:musicModel withProgress:nil completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
                    if (localURL) {
                        @strongify(self);
                        [self.photoToVideoMonitorInfo updateMusicInfoWithIsList:NO success:YES];
                        self.musicModel = musicModel;
                        musicModel.loaclAssetUrl = localURL;
                        musicModel.originLocalAssetUrl = localURL;
                        self.isTemplateMusicDownloading = NO;
                        [self finishCompletion];
                        ACCBLOCK_INVOKE(completionBlock, YES);
                    } else {
                        [self.photoToVideoMonitorInfo updateMusicInfoWithIsList:NO success:NO];
                        ACCBLOCK_INVOKE(completionBlock, NO);
                    }
                }];
            } else {
                if (!retryBlock) {
                    [self.photoToVideoMonitorInfo updateMusicInfoWithIsList:YES success:NO];
                    self.isTemplateMusicDownloading = NO;
                    ACCBLOCK_INVOKE(completionBlock, NO);
                }
                ACCBLOCK_INVOKE(retryBlock);
            }
        }];
}

- (void)asyncFetchTextToVideoTemplateWithCompletion:(AWEDownloadMVModelResult)completion
{
    self.textTemplateCompletion = completion;

    IESEffectModel *model = self.textPhotoToVideoModel;
    if (!model.downloaded) {
        [self prefetchTextToVideoTemplates];
    }
    if (!self.isTemplateMusicDownloading && self.musicList == nil && self.musicModel == nil) {
        [self fetchPhotoToVideoMusicList];
    }
    [self finishCompletion];
}

- (void)asyncFetchPhotoToVideoTemplateWithIsSinglePhoto:(BOOL)isSinglePhoto completion:(AWEDownloadMVModelResult)completion
{
    if (isSinglePhoto) {
        self.singlePhotoTemplateCompletion = completion;
    } else {
        self.multiplePhotoTemplateCompletion = completion;
    }

    IESEffectModel *model = [self photoToVideoTemplateWithIsSinglePhoto:isSinglePhoto];
    if (!model.downloaded) {
        [self prefetchPhotoToVideoTemplates];
    }
    if (!self.isTemplateMusicDownloading && self.musicList == nil && self.musicModel == nil) {
        [self fetchPhotoToVideoMusicList];
    }
    [self finishCompletion];
    if (isSinglePhoto) {
        return;
    }
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kACCMVDownloadMaxWaitDurationInSeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        if (!self.musicModel) {
            self.musicModel = self.lastMusicModel;
        }
        [self finishCompletionForSameModel];
        if (!isSinglePhoto && self.multiplePhotoTemplateCompletion) {
            ACCBLOCK_INVOKE(self.multiplePhotoTemplateCompletion, self.multiplePhotoToVideoModel);
            self.multiplePhotoTemplateCompletion = nil;
        }
    });
}

- (NSDictionary *)textToVideoMoniterInfoSucceeed:(BOOL)succeeed startTime:(CFAbsoluteTime)startTime
{
    return [self photoToVideoMoniterInfoSucceeed:succeeed isSinglePhoto:NO isTextMode:YES startTime:startTime];
}

- (NSDictionary *)photoToVideoMoniterInfoSucceeed:(BOOL)succeeed isSinglePhoto:(BOOL)isSinglePhoto startTime:(CFAbsoluteTime)startTime
{
    return [self photoToVideoMoniterInfoSucceeed:succeeed isSinglePhoto:isSinglePhoto isTextMode:NO startTime:startTime];
}

- (NSDictionary *)photoToVideoMoniterInfoSucceeed:(BOOL)succeeed isSinglePhoto:(BOOL)isSinglePhoto isTextMode:(BOOL)isTextMode startTime:(CFAbsoluteTime)startTime
{
    NSMutableDictionary *temp = [NSMutableDictionary dictionary];
    if (isTextMode) {
        temp[@"photo_import_mode"] = @"text";
        temp[@"from"] = @"text";
    } else {
        temp[@"photo_import_mode"] = isSinglePhoto ? @"single" : @"multi";
    }

    AWEPhotoToVideoMonitorInfo *info = self.photoToVideoMonitorInfo;
    NSInteger failedStep = AWEPhotoToVideoMonitorStatusSucced;
    if (succeeed) {
        if (isTextMode) {
            CFAbsoluteTime modelEndTime = info.textVideoEndTime;
            temp[@"mvtemplate_download_time"] = [self timeDiffForStart:startTime end:modelEndTime];
            temp[@"mvtemplate_use_predownload"] = modelEndTime < startTime ? @(0) : @(1);
        } else {
            CFAbsoluteTime modelListEndTime = isSinglePhoto ? info.singleMVListEndTime : info.multiMVListEndTime;
            CFAbsoluteTime modelEndTime = isSinglePhoto ? info.singleMVEndTime : info.multiMVEndTime;
            temp[@"mvtemplate_list_download_time"] = [self timeDiffForStart:startTime end:modelListEndTime];
            temp[@"mvtemplate_download_time"] = [self timeDiffForStart:startTime end:modelEndTime];
            temp[@"mvtemplate_use_predownload"] = modelEndTime < startTime ? @(0) : @(1);
        }
        
        if (self.musicModel) {
            temp[@"hot_music_list_download_time"] = [self timeDiffForStart:startTime end:info.musicListEndTime];
            temp[@"music_download_time"] = [self timeDiffForStart:startTime end:info.musicEndTime];
            temp[@"hot_music_list_list_size"] = @(info.musicCount);
        } else {
            if (info.musicFailed) {
                failedStep = AWEPhotoToVideoMonitorStatusMusicFailed;
            } else if (info.musicListFailed) {
                failedStep = AWEPhotoToVideoMonitorStatusMusicListFailed;
            } else if (info.musicCount > 0) {
                failedStep = AWEPhotoToVideoMonitorStatusMusicTimeOut;
            } else {
                failedStep = AWEPhotoToVideoMonitorStatusMVListTimeOut;
            }
        }
    } else {
        BOOL listFailed = isSinglePhoto ? info.singleMVListFailed : info.multiMVListFailed;
        BOOL modelFailed = isSinglePhoto ? info.singleMVFailed : info.multiMVFailed;
        BOOL modelTimeOut = isSinglePhoto ? (info.singleMVListEndTime > 0) : (info.multiMVListEndTime > 0);
        if (isTextMode) {
            listFailed = NO;
            modelFailed = info.textVideoFailed;
            modelTimeOut = info.textVideoEndTime > 0;
        }
        if (listFailed) {
            failedStep = AWEPhotoToVideoMonitorStatusMVListFailed;
        } else if (modelFailed) {
            failedStep = AWEPhotoToVideoMonitorStatusMVFailed;
        } else if (modelTimeOut) {
            failedStep = AWEPhotoToVideoMonitorStatusMVTimeOut;
        } else {
            failedStep = AWEPhotoToVideoMonitorStatusMVListTimeOut;
        }
    }
    temp[@"failed_step"] = @(failedStep);
    return temp.copy;
}

- (NSNumber *)timeDiffForStart:(CFAbsoluteTime)start end:(CFAbsoluteTime)end
{
    return end < start ? @(0) : @((end - start) * 1000);
}

- (AWEPhotoToVideoMonitorInfo *)photoToVideoMonitorInfo
{
    if (!_photoToVideoMonitorInfo) {
        _photoToVideoMonitorInfo = [AWEPhotoToVideoMonitorInfo new];
    }
    return _photoToVideoMonitorInfo;
}

@end
