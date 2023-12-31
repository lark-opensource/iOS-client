//
//  AWECutSameWorksManager.m
//  AWEStudio-Pods-Aweme
//
//  Created by Pinka on 2020/3/25.
//

#import "ACCCutSameWorksManager.h"
#import "ACCCutSameMaterialImportManagerProtocol.h"
#import "ACCCutSameLVTemplateUtils.h"
#import "ACCCutSameTemplateManager.h"
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCMacrosTool.h>
#import "ACCCutSameWorksManagerProtocol.h"
#import "ACCDealWithServerPhotoManagerProtocol.h"
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import "ACCCutSameError.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCLogger.h>
#import <CreationKitInfra/ACCRACWrapper.h>
#import <VideoTemplate/LVExporterManager.h>
#import "ACCCutSameLogger.h"
#import <CreationKitInfra/ACCRACWrapper.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import <VideoTemplate/LVDraftMigrationContext.h>
#import <CameraClient/ACCCutSameGamePlayConfigFetcherProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#import <VideoTemplate/GamePlayManager.h>
#import <VideoTemplate/GPServiceFactory.h>
#import "ACCGamePlayServiceContainer.h"

static CGFloat kAWECutSameWorksManagerDownloadTempletePercent = 0.2;
static CGFloat kAWECutSameWorksManagerProcessTempletePercent = 0.3;
static CGFloat kAWECutSameWorksManagerImportPercent = 0.5;

@interface ACCCutSameWorksManager ()<ACCCutSameTemplateManagerDelegate>

@property (nonatomic, strong) NSError *processError;

@property (nonatomic, strong) NSArray<AWECutSameMaterialAssetModel *> *lastMaterials;

@property (nonatomic, strong) NSMutableDictionary<NSString *, AWECutSameMaterialAssetModel *> *lastIndexMaterialsDict;

@property (nonatomic, strong) LVTemplateDataManager *currentTemplateDataManager;

@property (nonatomic, strong) LVTemplateProcessor *currentTemplateProcessor;

@property (nonatomic, assign) CGFloat importProgress;

@property (nonatomic, assign) CGFloat downloadTemplateProgress;

@property (nonatomic, assign) CGFloat processTemplateProgress;

@property (nonatomic, copy) ACCCutSameWorksManagerProgress progressAction;

@property (nonatomic, copy) ACCCutSameWorksManagerCompletion completionAction;

@property (nonatomic, assign) BOOL isReplacing;

@property (nonatomic, strong) dispatch_queue_t progressQueue;

// manager to handle pic which needs server procession for CartoonFace template in CutSame
@property (nonatomic, strong) id<ACCDealWithServerPhotoManagerProtocol> manager;

@property (nonatomic, strong) GamePlayManager *gameplayManager;

@end

@implementation ACCCutSameWorksManager

@synthesize currrentTemplate = _currrentTemplate;
@synthesize downloadCompletion = _downloadCompletion;

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        [[ACCCutSameTemplateManager sharedManager] addDelegate:self];
        id<ACCCutSameGamePlayConfigFetcherProtocol> configFetcher = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameGamePlayConfigFetcherProtocol);
        NSDictionary *reshapeConfig = [configFetcher reshapeConfig];
        [LVDraftMigrationContext setGameplayReshapeFechter:^NSNumber * _Nullable(NSString * _Nonnull gameplayAlgorithm) {
            return [reshapeConfig acc_objectForKey:gameplayAlgorithm];
        }];
        GPServiceFactory.sharedInstance.serviceContainer = [[ACCGamePlayServiceContainer alloc] init];
        self.progressQueue = dispatch_queue_create("progress_rw_queue", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

- (id<ACCDealWithServerPhotoManagerProtocol>)manager
{
    if (_manager == nil) {
        _manager = IESAutoInline(ACCBaseServiceProvider(), ACCDealWithServerPhotoManagerProtocol);
    }
    return _manager;
}

- (GamePlayManager *)gameplayManager {
    if (!_gameplayManager) {
        _gameplayManager = [[GamePlayManager alloc] init];
    }
    return _gameplayManager;
}

- (void)setCurrrentTemplate:(id<ACCMVTemplateModelProtocol>)currrentTemplate
{
    if (_currrentTemplate != currrentTemplate) {
        if (_currrentTemplate) {
            [[ACCCutSameTemplateManager sharedManager] cancelDownloadAndProcessTemplateFromModel:_currrentTemplate];
            dispatch_async(self.progressQueue, ^{
                self.downloadTemplateProgress = 0.0;
                self.processTemplateProgress = 0.0;
            });
        }
        
        _currrentTemplate = currrentTemplate;
        
        LogCutSameTemplateDownloadStart(currrentTemplate);
        
        if (currrentTemplate) {
            self.processError = nil;
            self.currentTemplateProcessor = [[ACCCutSameTemplateManager sharedManager] downloadTemplateFromModel:currrentTemplate];
        } else {
            self.currentTemplateProcessor = nil;
        }
    }
}

- (void)importMaterial:(NSArray<AWEAssetModel *> *)assets
       progressHandler:(ACCCutSameWorksManagerProgress)progressHandler
            completion:(ACCCutSameWorksManagerCompletion)completion
{
    [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol) cancelAll];
    dispatch_async(self.progressQueue, ^{
        self.importProgress = 0.0;
    });
    
    LogCutSameImportStart(self.currrentTemplate);
    
    self.progressAction = progressHandler;
    self.completionAction = completion;
    if (self.isReplacing || self.processError) {
        self.isReplacing = NO;
        [self reprocessTemplate];
    }
    
    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    [assets enumerateObjectsUsingBlock:^(AWEAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWECutSameMaterialAssetModel *m = nil;
        BOOL isCartoonTemplate = !ACC_isEmptyString([self fragmentOfIndex:idx].gameplayAlgorithm);
        // No cache used for cartoon template
        if (obj.asset.localIdentifier && !isCartoonTemplate) {
            m = self.lastIndexMaterialsDict[obj.asset.localIdentifier];
        }
        if (!m) {
            m = [[AWECutSameMaterialAssetModel alloc] init];
            m.aweAssetModel = [obj copy];
        }
        [newArray addObject:m];
        if (obj.asset.localIdentifier) {
            newDict[obj.asset.localIdentifier] = m;
        }
    }];
    self.lastMaterials = newArray;
    self.lastIndexMaterialsDict = newDict;
    
    LVTemplateProcessor __weak *curProcessor = self.currentTemplateProcessor;
    id<ACCCutSameMaterialImportManagerProtocol> importManager = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol);
    importManager.compressor = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameVideoCompressorProtocol);
    importManager.config = [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameVideoCompressConfigProtocol) class];
    @weakify(self);
    [importManager importMaterials:newArray
                   progressHandler:^(CGFloat importProgress) {
        @strongify(self);
        dispatch_async(self.progressQueue, ^{
            self.importProgress = importProgress;
            [self callbackProgress];
        });
    }
                        completion:^(NSArray<AWECutSameMaterialAssetModel *> * _Nonnull importAssets,
                                     NSError * _Nonnull error) {
        @strongify(self);
        if (curProcessor == self.currentTemplateProcessor) {
            if (error) {
                [self callbackForCompletionAction:error canClearAction:YES];
            } else {
                NSArray *videoPayloads = curProcessor.draft.payloadPool.videoPayloads;
                NSDictionary *idToGameplayMap = [self p_generateIDToGameplayAlgorithmMap:videoPayloads];
                NSArray<GPMaterialModel *> *needProcessAsset = [self selectPicToProcessForGamePlayFromAssets:importAssets withMap:idToGameplayMap];

                @weakify(self);
                [self.gameplayManager processForCutSameWithResourceModels:needProcessAsset completion:^(NSArray<GPMaterialOutputModel *> * _Nonnull outputModels) {
                    __block NSInteger failCount = 0;
                    __block NSMutableDictionary *outputDict = [NSMutableDictionary dictionary];
                    [outputModels enumerateObjectsUsingBlock:^(GPMaterialOutputModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                        if (obj.error) {
                            failCount ++;
                        }
                        [outputDict acc_setObject:obj forKey:obj.originURL.path];
                    }];

                    @strongify(self);
                    if (failCount > 0) {
                        NSDictionary *userInfo = @{
                            ACCCutSameErrorUserInfoCartoonFaceFailCount: @(failCount)
                        };
                        NSError *error = [[NSError alloc] initWithDomain:ACCCutSameErrorDomain code:ACCCutSameErrorCodeUploadToServerFailedForCartoonFace userInfo:userInfo];

                        NSString *errorMessage = [NSString stringWithFormat:ACCLocalizedCurrentString(@"creation_jianyingmv_comic_alert"), failCount];     // "%d"个素材效果应用失败，请重试或更换素材
                        [ACCAlert() showAlertWithTitle:ACCLocalizedCurrentString(@"tip")
                                              description:errorMessage
                                                    image:nil
                                        actionButtonTitle:ACCLocalizedString(@"creation_jianyingmv_comic_retry", @"重试")
                                        cancelButtonTitle:ACCLocalizedString(@"creation_jianyingmv_comic_ignore", @"忽略")
                                              actionBlock:^{
                            // stay at album view, do nothing
                            NSError *cancelError = [[NSError alloc] initWithDomain:ACCCutSameErrorDomain
                                                                              code:ACCCutSameErrorCodeCancelProcessCartoonFaceByUser
                                                                          userInfo:nil];
                            [self callbackForCompletionAction:cancelError canClearAction:YES];
                        }
                                              cancelBlock:^{
                            // process with origin pics
                            [self updateLastMaterials:outputDict];
                            [self replaceFragments];
                        }];
                        [self callbackForCompletionAction:error canClearAction:NO];
                    } else {
                        [self updateLastMaterials:outputDict];
                        [self replaceFragments];
                    }
                    LogCutSameImportEnd(self.currrentTemplate);
                }];
            }
        }
    }];
    [self callbackProgress];
}

- (NSDictionary *)p_generateIDToGameplayAlgorithmMap:(NSArray *)videoPayloads
{
    NSMutableDictionary *idToGameplayMap = [[NSMutableDictionary alloc] init];
    [videoPayloads enumerateObjectsUsingBlock:^(LVDraftVideoPayload * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString * gameplayAlgorithm = obj.gameplay.algorithm ?: obj.gameplayAlgorithm;
        if (!ACC_isEmptyString(gameplayAlgorithm) && !ACC_isEmptyString(obj.payloadID)) {
            [idToGameplayMap acc_setObject:gameplayAlgorithm forKey:obj.payloadID];
        }
    }];
    return idToGameplayMap.copy;
}

- (void)importWorksAssetModel:(NSArray<ACCCutSameWorksAssetModel *> *)assets
              progressHandler:(ACCCutSameWorksManagerProgress)progressHandler
                   completion:(ACCCutSameWorksManagerCompletion)completion {
    
    [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol) cancelAll];
    dispatch_async(self.progressQueue, ^{
        self.importProgress = 0.0;
    });
    
    LogCutSameImportStart(self.currrentTemplate);
    
    self.progressAction = progressHandler;
    self.completionAction = completion;
    if (self.isReplacing || self.processError) {
       self.isReplacing = NO;
       [self reprocessTemplate];
    }

    NSMutableArray *newArray = [[NSMutableArray alloc] init];
    NSMutableDictionary *newDict = [[NSMutableDictionary alloc] init];
    [assets enumerateObjectsUsingBlock:^(ACCCutSameWorksAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWECutSameMaterialAssetModel *m = nil;
        if (obj.assetModel.asset.localIdentifier) {
            m = self.lastIndexMaterialsDict[obj.assetModel.asset.localIdentifier];
        }
        if (!m) {
            m = [[AWECutSameMaterialAssetModel alloc] init];
            m.aweAssetModel = obj.assetModel;
        }
        [newArray addObject:m];
        if (obj.assetModel.asset.localIdentifier) {
            newDict[obj.assetModel.asset.localIdentifier] = m;
        }
    }];
     
    self.lastMaterials = newArray;
    self.lastIndexMaterialsDict = newDict;

    LVTemplateProcessor __weak *curProcessor = self.currentTemplateProcessor;
    id<ACCCutSameMaterialImportManagerProtocol> importManager = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol);
    importManager.compressor = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameVideoCompressorProtocol);
    importManager.config = [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameVideoCompressConfigProtocol) class];
    @weakify(self);
    [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol)
        importMaterials:newArray
        progressHandler:^(CGFloat importProgress) {
           @strongify(self);
            dispatch_async(self.progressQueue, ^{
                self.importProgress = importProgress;
            });
           [self callbackProgress];
        }
        completion:^(NSArray<AWECutSameMaterialAssetModel *> * _Nonnull importAssets, NSError * _Nonnull error) {
           @strongify(self);
           if (curProcessor == self.currentTemplateProcessor) {
               if (error) {
                   [self callbackForCompletionAction:error canClearAction:YES];
               } else {
                   [self replaceFragmentsWithWorksAssetModels:assets];
               }
           }
        
        LogCutSameImportEnd(self.currrentTemplate);

    }];
    [self callbackProgress];
}


- (void)reprocessTemplate
{
    if (self.currrentTemplate) {
        dispatch_async(self.progressQueue, ^{
            self.downloadTemplateProgress = 0.0;
        });
        [[ACCCutSameTemplateManager sharedManager] cancelDownloadAndProcessTemplateFromModel:_currrentTemplate];
        self.processError = nil;
        self.currentTemplateProcessor = [[ACCCutSameTemplateManager sharedManager] downloadTemplateFromModel:self.currrentTemplate];
    }
}

- (void)cancelCurrentTask
{
    LogCutSameCancel(self.currrentTemplate);
    
    dispatch_async(self.progressQueue, ^{
        self.downloadTemplateProgress = 0.0;
    });
    [[ACCCutSameTemplateManager sharedManager] cancelDownloadAndProcessTemplateFromModel:self.currrentTemplate];
    [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol) cancelAll];
    self.currrentTemplate = nil;
}

- (void)clearCache
{
    [self cancelCurrentTask];
    self.processError = nil;
    
    self.lastMaterials = nil;
    self.lastIndexMaterialsDict = nil;
    [[ACCCutSameTemplateManager sharedManager] clearAllTemplateDraft];
    [IESAutoInline(ACCBaseServiceProvider(), ACCCutSameMaterialImportManagerProtocol) clearCache];
    AWELogToolInfo(AWELogToolTagMV, @"【cutsame】清除缓存");
}

- (void)clearTemplateZip
{
    [[ACCCutSameTemplateManager sharedManager] clearAllTemplateCache];
}

- (void)callbackProgress
{
    dispatch_barrier_async(self.progressQueue, ^{
        CGFloat total = kAWECutSameWorksManagerDownloadTempletePercent*self.downloadTemplateProgress;
        total += kAWECutSameWorksManagerProcessTempletePercent*self.processTemplateProgress;
        total += kAWECutSameWorksManagerImportPercent*self.importProgress;
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.progressAction) {
                AWELogToolInfo(AWELogToolTagMV,
                               @"【cutsame】progress: %f = download: %f + process: %f + import: %f",
                               total,
                               self.downloadTemplateProgress,
                               self.processTemplateProgress,
                               self.importProgress);
               self.progressAction(total);
            }
        });
    });
}

// clearAction: 触发会将completionAction置空，后续操作需要外部重新传入
- (void)callbackForCompletionAction:(NSError *)error
                     canClearAction:(BOOL)clearAction
{
    dispatch_barrier_async(self.progressQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.completionAction) {
                self.completionAction(self.lastMaterials, self.currentTemplateDataManager, error);
            }
            if (clearAction) {
                self.completionAction = nil;
            }
            AWELogToolInfo(AWELogToolTagMV, @"【cutsame】callback finish: %@", error);
        });
    });
}

- (void)updateLastMaterials:(NSDictionary *)outputDict
{
    [self.lastMaterials enumerateObjectsUsingBlock:^(AWECutSameMaterialAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        GPMaterialOutputModel *outputModel = [outputDict acc_objectForKey:obj.processedImageFileURL.path];
        if (outputModel && !outputModel.error) {
            if (outputModel.outputType == GPMaterialFileTypeVideo) {
                obj.processAsset = outputModel.processAsset;
            } else if (outputModel.outputType == GPMaterialFileTypePhoto) {
                obj.processedImage = outputModel.processedImage;
                obj.processedImageFileURL = outputModel.processedImageFileURL;
                obj.processedImageName = outputModel.processedImageName;
                obj.processedImageSize = outputModel.processedImageSize;
            }
        }
    }];
}

- (void)replaceFragments
{
    self.isReplacing = YES;
    NSMutableArray *realFragments = [[NSMutableArray alloc] init];
    [self.lastMaterials enumerateObjectsUsingBlock:^(AWECutSameMaterialAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<ACCCutSameFragmentModelProtocol> info = [self fragmentOfIndex:idx];
    
        // asset from shared file path
        if (!obj.aweAssetModel.asset && obj.aweAssetModel.avAsset) {
            AVURLAsset *urlAsset = (id)obj.processAsset;
            id<LVTemplateVideoFragment> fragment = [ACCCutSameLVTemplateUtils createVideoTemplateWithFragment:info];
            fragment.videoPath = urlAsset.URL.path;
            if (fragment) {
                [realFragments addObject:fragment];
            }
            return;
        }
        
        // asset from album
        if (obj.aweAssetModel.asset.mediaType == PHAssetMediaTypeImage) {
            id<LVTemplateImageFragment> fragment = [ACCCutSameLVTemplateUtils createImageTemplateWithFragment:info];
            // 配置原图路径
            if (obj.currentImageFileURL) {
                NSData *imageData = [NSData dataWithContentsOfURL:obj.currentImageFileURL];
                fragment.imageData = imageData;
                if (!CGSizeEqualToSize(obj.processedImageSize, CGSizeZero)) {
                    fragment.imageSize = obj.processedImageSize;
                } else {
                    fragment.imageSize = obj.currentImageSize;
                }
            }
            // 配置算法类的替换路径
            if (obj.processAsset) {
                fragment.cartoonFilePath = obj.processAsset.URL.path;
                fragment.cartoonOutputType = LVTemplateCartoonOutputTypeVideo;
            } else if (obj.processedImageFileURL) {
                fragment.cartoonFilePath = obj.processedImageFileURL.relativePath;
                fragment.cartoonOutputType = LVTemplateCartoonOutputTypeImage;
            }
            if (fragment) {
                [realFragments addObject:fragment];
            }
        } else if (obj.aweAssetModel.asset.mediaType == PHAssetMediaTypeVideo) {
            if ([obj.processAsset isKindOfClass:AVURLAsset.class]) {
                AVURLAsset *urlAsset = (id)obj.processAsset;
                id<LVTemplateVideoFragment> fragment = [ACCCutSameLVTemplateUtils createVideoTemplateWithFragment:info];
                fragment.videoPath = urlAsset.URL.path;
                if (fragment) {
                    [realFragments addObject:fragment];
                }
            }
        }
    }];
    
    [self.currentTemplateProcessor replaceFragments:realFragments];
    self.currentTemplateProcessor = nil;
}

- (void)replaceFragmentsWithWorksAssetModels:(NSArray<ACCCutSameWorksAssetModel *> *)assets
{
    self.isReplacing = YES;
    NSMutableArray *realFragments = [[NSMutableArray alloc] init];
    [self.lastMaterials enumerateObjectsUsingBlock:^(AWECutSameMaterialAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<ACCCutSameFragmentModelProtocol> info = [self fragmentOfIndex:idx];
        if (obj.aweAssetModel.asset.mediaType == PHAssetMediaTypeImage) {
            id<LVTemplateImageFragment> fragment = [ACCCutSameLVTemplateUtils createImageTemplateWithFragment:info];
            // 配置原图路径
            if (obj.currentImageFileURL) {
                NSData *imageData = [NSData dataWithContentsOfURL:obj.currentImageFileURL];
                fragment.imageData = imageData;
                fragment.imageSize = obj.currentImageSize;
            }
            // 配置算法类的替换路径
            if (obj.processAsset) {
                fragment.cartoonFilePath = obj.processAsset.URL.path;
                fragment.cartoonOutputType = LVTemplateCartoonOutputTypeVideo;
            } else if (obj.processedImageFileURL) {
                fragment.cartoonFilePath = obj.processedImageFileURL.relativePath;
                fragment.cartoonOutputType = LVTemplateCartoonOutputTypeImage;
            }

            if (assets && [assets acc_objectAtIndex:idx]) {
                // 由于算法返回来的素材裁剪区域不一定是对的，这里做一个兜底计算
                CGFloat width = [info.videoWidth floatValue];
                CGFloat height = [info.videoHeight floatValue];
                NSArray<NSValue *> *crops = [self calculateCorrectCrops:assets[idx].cropPoints
                                                              imageSize:fragment.imageSize
                                                               withSize:CGSizeMake(width, height)];
                fragment.cropPoints = crops;
            }
            if (fragment) {
                [realFragments addObject:fragment];
            }
        } else if (obj.aweAssetModel.asset.mediaType == PHAssetMediaTypeVideo) {
            if ([obj.processAsset isKindOfClass:AVURLAsset.class]) {
                AVURLAsset *urlAsset = (id)obj.processAsset;
                id<LVTemplateVideoFragment> fragment = [ACCCutSameLVTemplateUtils createVideoTemplateWithFragment:info];
                fragment.videoPath = urlAsset.URL.path;
                if (assets && [assets acc_objectAtIndex:idx]) {
                    CMTimeRange timeRange = assets[idx].sourceTimeRange;
                    if (CMTIME_IS_VALID(timeRange.duration)) {
                        fragment.sourceTimeRange = timeRange;
                    }
//                    fragment.cropPoints = assets[idx].cropPoints;
                }
                if (fragment) {
                    [realFragments addObject:fragment];
                }
            }
        }
    }];
    
    [self.currentTemplateProcessor replaceFragments:realFragments];
    self.currentTemplateProcessor = nil;
}


/// size 的比例应该和裁剪的比例一致，如果不一致，这里返回空，剪同款会计算默认裁剪区域
/// @param cropPoints NSArray<NSValue *> *
/// @param size CGSize
- (nullable NSArray<NSValue *> *)calculateCorrectCrops:(NSArray<NSValue *> *)cropPoints
                                             imageSize:(CGSize)imageSize
                                              withSize:(CGSize)size
{
    if (cropPoints.count != 4) {
        return nil;
    }
    
    // 判断计算的比例是否相等
    CGPoint upperLeftPoint = [cropPoints[0] CGPointValue];
    CGPoint lowerRightPoint = [cropPoints[3] CGPointValue];
    CGFloat cropWidth = (lowerRightPoint.x - upperLeftPoint.x) * imageSize.width;
    CGFloat cropHeight = (lowerRightPoint.y - upperLeftPoint.y) * imageSize.height;
    if (cropHeight != 0 && size.height != 0) {
        CGFloat cropRatio = cropWidth / cropHeight;
        CGFloat imageRatio = size.width / size.height;
        // 目前用0.01的精度来比较
        if (fabs(cropRatio - imageRatio) <= 0.01) {
            return cropPoints;
        }
    }
    
    return nil;
}

// https://bytedance.feishu.cn/docs/doccnsMh8f0fhiNl6ysvrwbMtwp#oogddP
- (LVExporterConfig *)defaultConfigForLVExport {
    LVExporterConfig *config = [[LVExporterConfig alloc] init];
    NSString *bitrateSetting = ACCConfigBool(kConfigBool_enable_1080p_cut_same_video) ?
                                ACCConfigString(kConfigString_cut_same_1080p_bitrate) :
                                ACCConfigString(kConfigString_cut_same_720p_bitrate);
    if (bitrateSetting.length > 0) {
        config.bitrateSetting = bitrateSetting;
    } else {
        config.bitrate = 2500 * 1024;
    }
    return config;
}

#pragma mark - ACCCutSameTemplateManagerDelegate
- (void)didDownloadAndProcessTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                                  progress:(CGFloat)progress
{
    if (templateModel == self.currrentTemplate) {
        dispatch_async(self.progressQueue, ^{
            self.processTemplateProgress = progress;
            [self callbackProgress];
        });
    }
}

- (void)didFinishDownloadTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    dispatch_async(self.progressQueue, ^{
        self.downloadTemplateProgress = 1.0;
    });
    [self callbackProgress];
    self.downloadCompletion ? self.downloadCompletion() : 0;
        
    LogCutSameTemplateDownloadEnd(self.currrentTemplate);
}

- (void)didFailTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                   withError:(NSError *)error
{
    if (templateModel == self.currrentTemplate) {
        self.processError = error;
        [self callbackForCompletionAction:error canClearAction:YES];
        AWELogToolInfo(AWELogToolTagMV, @"【cutsame】didFailTemplateModel - currrentTemplate - %lu", (unsigned long)templateModel.templateID);
    } else {
        AWELogToolInfo(AWELogToolTagMV, @"【cutsame】didFailTemplateModel - not currrentTemplate - %lu", (unsigned long)templateModel.templateID);
    }
}

- (void)didFinishedProcessTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                            dataManager:(LVTemplateDataManager *)dataManager
                              withError:(NSError *)error
{
    if (templateModel == self.currrentTemplate) {
        self.currentTemplateDataManager = dataManager;
        self.isReplacing = NO;
        [self callbackForCompletionAction:error canClearAction:YES];
        AWELogToolInfo(AWELogToolTagMV, @"【cutsame】didFinishedProcessTemplateModel - currrentTemplate");
        
        LogCutSameTemplateProcessEnd(self.currrentTemplate);

    } else {
        AWELogToolInfo(AWELogToolTagMV, @"【cutsame】didFinishedProcessTemplateModel - not currrentTemplate");
    }
}

# pragma mark - CatoonFace method

- (NSArray<ACCCutsameMaterialModel *> *)selectPicToProcessForCartoonFromAssets:(NSArray<AWECutSameMaterialAssetModel *> *)importAssets
                                                                       withMap:(NSDictionary *)idToGameplayMap
{
    NSMutableArray *needProcessAsset = [NSMutableArray array];
    [importAssets enumerateObjectsUsingBlock:^(AWECutSameMaterialAssetModel * _Nonnull obj,
                                               NSUInteger idx,
                                               BOOL * _Nonnull stop) {
        id<ACCCutSameFragmentModelProtocol> info = [self fragmentOfIndex:idx];
        NSString *gameplayAlgorithm = [idToGameplayMap valueForKey:info.materialId] ? : @"";
        if (obj.aweAssetModel.mediaType == AWEAssetModelMediaTypePhoto && !ACC_isEmptyString(gameplayAlgorithm)) {
            ACCCutsameMaterialModel *materailModel = [[ACCCutsameMaterialModel alloc] init];
            materailModel.assetModel = obj;
            materailModel.gameplayAlgorithm = gameplayAlgorithm;
            [needProcessAsset addObject:materailModel];
        }
    }];
    return needProcessAsset.copy;
}

- (NSArray<GPMaterialModel *> *)selectPicToProcessForGamePlayFromAssets:(NSArray<AWECutSameMaterialAssetModel *> *)importAssets withMap:(NSDictionary *)idToGameplayMap {
    NSMutableArray<GPMaterialModel *> *resultArray = [NSMutableArray array];
    [importAssets enumerateObjectsUsingBlock:^(AWECutSameMaterialAssetModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        id<ACCCutSameFragmentModelProtocol> info = [self fragmentOfIndex:idx];
        NSString *gameplayAlgorithm = [idToGameplayMap valueForKey:info.materialId] ? : @"";
        if (obj.aweAssetModel.mediaType == AWEAssetModelMediaTypePhoto && !ACC_isEmptyString(gameplayAlgorithm)) {
            
            GPMaterialModel *materialModel = [[GPMaterialModel alloc] init];
            materialModel.fileType = GPMaterialFileTypePhoto;
            materialModel.fileURL = obj.processedImageFileURL;
            materialModel.gameplayAlgorithm = gameplayAlgorithm;
            
            id<ACCCutSameGamePlayConfigFetcherProtocol> configFetcher = IESAutoInline(ACCBaseServiceProvider(), ACCCutSameGamePlayConfigFetcherProtocol);
            id<ACCCutSameGamePlayConfigProtocol> config = [configFetcher getGameplayConfigWithAlgorithm:materialModel.gameplayAlgorithm];
            if (config) {
                materialModel.algorithmConfig = config.config;
                if (config.outputType == ACCCutSameGamePlayOutputTypePhoto) {
                    materialModel.outputType = GPMaterialFileTypePhoto;
                } else {
                    materialModel.outputType = GPMaterialFileTypeVideo;
                }
                [resultArray acc_addObject:materialModel];
            }
            
        }
    }];
    return resultArray.copy;
}

- (id<ACCCutSameFragmentModelProtocol>)fragmentOfIndex:(NSInteger)idx
{
    if (idx < 0 || idx >= [self.currrentTemplate.extraModel.fragments count]) {
        ACC_LogError(@"Invalid index: %ld, check caller plz.", (long)idx);
        return nil;
    }
    
    return self.currrentTemplate.extraModel.fragments[idx];
}

@end
