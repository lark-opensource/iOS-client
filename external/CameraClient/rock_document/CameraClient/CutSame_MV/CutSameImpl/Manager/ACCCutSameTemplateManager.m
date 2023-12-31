//
//  ACCCutSameTemplateManager.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/3/18.
//

#import "ACCCutSameTemplateManager.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCConfigKeyDefines.h"
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCCutSameTemplateZipDowndoader.h"
#import "ACCDeallocHelper.h"
#import <CreationKitArch/AWEEffectPlatformRequestManager.h>
#import <CreationKitInfra/ACCDeviceInfo.h>

#import <TTNetworkManager/TTHttpResponseChromium.h>
#import <VideoTemplate/LVEffectManager.h>
#import <VideoTemplate/VideoTemplateDevice.h>
#import <VideoTemplate/VideoTemplateLogger.h>
#import "ACCAPPSettingsProtocol.h"
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitArch/ACCModuleConfigProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCNetServiceProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

static void const *ACCCutSameTemplateManagerDeallocKey = &ACCCutSameTemplateManagerDeallocKey;
static NSString *const ACCCutSameTemplateManagerDraftPath = @"com.lemon.drafts";

@interface ACCCutSameTemplateLogger : NSObject<VideoTemplateLoggerDelegate>

@end

@implementation ACCCutSameTemplateLogger

+ (instancetype)shareInstance
{
    static dispatch_once_t onceToken;
    static ACCCutSameTemplateLogger *logger = nil;
    dispatch_once(&onceToken, ^{
        logger = [[ACCCutSameTemplateLogger alloc] init];
    });
    
    return logger;
}

- (void)logger:(VideoTemplateLogger *)logger
           log:(NSString *_Nullable)tag
         level:(VideoTemplateLogLevel)level
          file:(NSString *)file
      function:(NSString *)function
          line:(int)line
       message:(NSString *)message
{
    NSInteger status = (level == VideoTemplateLogLevelError) ? 1 : 0;
    [ACCMonitor() trackService:@"video_template_log"
                        status:status
                         extra:@{
                                @"tag": tag? : @"",
                                @"file": file ?: @"",
                                @"function": function ?: @"",
                                @"line": @(line),
                                @"message": message ?: @"",
                         }
             extraParamsOption:TTMonitorExtraParamsOptionNONE];
}

@end

@interface ACCCutSameTemplateManager ()<LVTemplateProcessorDelegate>

@property (nonatomic, strong) NSPointerArray *allDelegates;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *downloadingProgress; // 当前正在下载素材的进度

@property (nonatomic, strong) NSMutableDictionary<NSString *, LVTemplateProcessor *> *processorSet;
@property (nonatomic, strong) NSMutableDictionary<NSString *, id<ACCMVTemplateModelProtocol> > *templateSet;

@property (nonatomic, assign) NSInteger downloadStartTime;

@end

@implementation ACCCutSameTemplateManager

+ (void)initialize
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        let moduleConfig = IESAutoInline(ACCBaseServiceProvider(), ACCModuleConfigProtocol);
        NSDictionary *commonParams = [ACCNetService() commonParameters];
        NSString *devicePlatForm = [commonParams acc_stringValueForKey:@"device_platform"] ;
        [LVEffectManager setup:[[AWEEffectPlatformRequestManager alloc] init]
                       channel:[ACCDeviceInfo acc_currentChannel]
                        region:[ACCI18NConfig() currentRegion]
                        domain:moduleConfig.effectRequestDomainString
                      language:[ACCI18NConfig() currentLanguage]
                      deviceID:[ACCTracker() deviceID]
                devicePlatform:devicePlatForm
                         appID:[ACCDeviceInfo acc_appID]
                   extraConfig:nil
       autoUpdateAllEffectList:NO
                      isAbroad:NO
                     needCache:NO];
        [LVEffectManager setEnvironment:[ACCAPPSettings() enableBOE]];
        [VideoTemplateDevice registerWorseThanIPhone6sJudger:[^BOOL{
            return [UIDevice acc_isPoorThanIPhone6S];
        } copy]];

        [VideoTemplateLogger registerPerformer:[ACCCutSameTemplateLogger shareInstance]];
    });
}

+ (instancetype)sharedManager
{
    static ACCCutSameTemplateManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[ACCCutSameTemplateManager alloc] init];
        [[NSFileManager defaultManager] removeItemAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:ACCCutSameTemplateManagerDraftPath]
                                                   error:nil];
    });
    
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    
    if (self) {
        _downloadingProgress = [[NSMutableDictionary alloc] init];
        _allDelegates = [NSPointerArray pointerArrayWithOptions:NSPointerFunctionsWeakMemory];
        _processorSet = [[NSMutableDictionary alloc] init];
        _templateSet = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)addDelegate:(id<ACCCutSameTemplateManagerDelegate>)delegate
{
    if ([self.allDelegates.allObjects containsObject:delegate]) {
        return ;
    }
    
    void *p = (__bridge void *)(delegate);
    [ACCDeallocHelper attachToObject:delegate
                                 key:ACCCutSameTemplateManagerDeallocKey
                   whenDeallocDoThis:^{
        [self removeDelegatePointer:p];
    }];
    
    [self.allDelegates addPointer:(__bridge void * _Nullable)(delegate)];
}

- (void)removeDelegate:(id<ACCCutSameTemplateManagerDelegate>)delegate
{
    NSInteger idx = NSNotFound;
    for (NSInteger i = 0; i < self.allDelegates.count; i++) {
        if ([self.allDelegates pointerAtIndex:i] == (__bridge void * _Nullable)(delegate)) {
            idx = i;
            break;
        }
    }
    
    if (idx != NSNotFound) {
        [ACCDeallocHelper dettachObject:delegate key:ACCCutSameTemplateManagerDeallocKey];
        [self.allDelegates removePointerAtIndex:idx];
    }
}

- (void)removeDelegatePointer:(const void *)delegatePointer
{
    NSInteger idx = NSNotFound;
    for (NSInteger i = 0; i < self.allDelegates.count; i++) {
        if ([self.allDelegates pointerAtIndex:i] == delegatePointer) {
            idx = i;
            break;
        }
    }
    
    if (idx != NSNotFound) {
        [self.allDelegates removePointerAtIndex:idx];
    }
}

- (LVTemplateProcessor *)downloadTemplateFromModel:(id<ACCMVTemplateModelProtocol>)model
{
    LVTemplateProcessor *processor = nil;
    if (model.accTemplateType == ACCMVTemplateTypeClassic) {
        IESEffectModel *effectModel = model.effectModel;
        if (effectModel.effectIdentifier) {
            // 已经下载成功
            if (effectModel.downloaded) {
                [self callbackDidFinishDownloadTemplateModel:model];
                return nil;
            }

            // 当前正在下载
            if ([self.downloadingProgress objectForKey:effectModel.effectIdentifier] != nil) {
                return nil;
            }
            
            // 开始下载
            [self.downloadingProgress setObject:@(0) forKey:effectModel.effectIdentifier];
            [self callbackDidStartDownloadTemplateModel:model];
            
            CFTimeInterval singleStickerStartTime = CFAbsoluteTimeGetCurrent();
            [EffectPlatform downloadEffect:effectModel progress:^(CGFloat progress) {
                // 下载进度回调
                [self.downloadingProgress setObject:@(progress) forKey:effectModel.effectIdentifier];
                [self callbackDidDownloadAndProcessTemplateModel:model progress:progress];
                
            } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                [self.downloadingProgress removeObjectForKey:effectModel.effectIdentifier];
                
                NSDictionary *extraInfo = @{
                                            @"effect_id" : effectModel.effectIdentifier ?: @"",
                                            @"effect_name" : effectModel.effectName ?: @"",
                                            @"download_urls" : [effectModel.fileDownloadURLs componentsJoinedByString:@";"] ?: @"",
                                            @"is_ar" : @([effectModel isTypeAR]),
                                            @"is_tt" : @(ACCConfigBool(kConfigBool_use_TTEffect_platform_sdk))
                                            };
                
                if (!error && filePath) {
                    // 下载成功回调
                    [self callbackDidFinishDownloadTemplateModel:model];
                    
                    [ACCMonitor() trackService:@"mv_resource_download_error_state"
                                     status:0
                                      extra:[extraInfo mtl_dictionaryByAddingEntriesFromDictionary:@{
                                                                                                    @"duration" : @((CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000)
                                                                                                     }]];
                    
                    
                    NSInteger duration = (CFAbsoluteTimeGetCurrent() - singleStickerStartTime) * 1000;
                    [ACCTracker() trackEvent:@"tool_performance_resource_download"
                                       params:@{@"resource_type":@"mv",
                                                @"duration":@(duration),
                                                @"status":@(0)}
                              needStagingFlag:NO];
                    
                } else {
                    // 下载失败回调
                    [self callbackDidFailTemplateModel:model withError:error];
                    
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
                    [ACCTracker() trackEvent:@"tool_performance_resource_download"
                                       params:@{@"resource_type":@"mv",
                                                @"duration":@(duration),
                                                @"status":@(1),
                                                @"error_domain":error.domain?:@"",
                                                @"error_code":@(error.code)}
                              needStagingFlag:NO];
                }
            }];
        }
    } else if (model.accTemplateType == ACCMVTemplateTypeCutSame) {
        processor = self.processorSet[@(model.templateID).stringValue];
        [processor cancelProcess];
        
        LVMutableConfigAlignMode alignMode = LVMutableConfigAlignModeCanvas;
        if ([model.extraModel.alignMode isEqualToString:@"align_video"]) {
            alignMode = LVMutableConfigAlignModeVideo;
        } else if ([model.extraModel.alignMode isEqualToString:@"align_canvas"]) {
            alignMode = LVMutableConfigAlignModeCanvas;
        }
        processor = [[LVTemplateProcessor alloc] initWithTemplateID:@(model.templateID).stringValue
                                                                             templateURL:model.templateURL
                                                                               alignMode:alignMode
                                                                                  domain:ACCCutSameTemplateManagerDraftPath
                                                                              downloader:({
            ACCCutSameTemplateZipDowndoader *downloader = [[ACCCutSameTemplateZipDowndoader alloc] init];
            downloader.templateModel = model;
            downloader.delegateCompletion = ^(ACCCutSameTemplateZipDowndoader *downloader, NSString *filePath, NSError *error) {
                [self callbackDidFinishDownloadTemplateModel:model];
            };
            downloader;
        })];
        self.processorSet[@(model.templateID).stringValue] = processor;
        self.templateSet[@(model.templateID).stringValue] = model;
        processor.delegate = self;
        [processor startProcess];
        
        [self callbackDidStartDownloadTemplateModel:model];
    }
    
    return processor;
}

- (void)cancelDownloadAndProcessTemplateFromModel:(id<ACCMVTemplateModelProtocol>)model
{
    if (model.accTemplateType == ACCMVTemplateTypeCutSame) {
        LVTemplateProcessor *processor = self.processorSet[@(model.templateID).stringValue];
        [processor cancelProcess];
        [self.processorSet removeObjectForKey:@(model.templateID).stringValue];
    }
}

- (void)clearAllTemplateDraft
{
    [[NSFileManager defaultManager] removeItemAtPath:[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:ACCCutSameTemplateManagerDraftPath]
                                               error:nil];
}

- (void)clearAllTemplateCache
{
    [ACCCutSameTemplateZipDowndoader clearCache];
}

#pragma mark - Private API
- (void)callbackDidStartDownloadTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    [self.allDelegates.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didStartDownloadTemplateModel:)]) {
            self.downloadStartTime = CFAbsoluteTimeGetCurrent();
            AWELogToolInfo(AWELogToolTagMV, @"【cutsame】start download");
            [obj didStartDownloadTemplateModel:templateModel];
        }
    }];
}

- (void)callbackDidDownloadAndProcessTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                                          progress:(CGFloat)progress
{
    [self.allDelegates.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didDownloadAndProcessTemplateModel:progress:)]) {
            AWELogToolInfo(AWELogToolTagMV, @"【cutsame】callbackDidDownloadAndProcessTemplateModel progress: %f", progress);
            [obj didDownloadAndProcessTemplateModel:templateModel progress:progress];
        }
    }];
}

- (void)callbackDidFinishDownloadTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
{
    [self.allDelegates.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didFinishDownloadTemplateModel:)]) {
            NSInteger duration = (CFAbsoluteTimeGetCurrent() - self.downloadStartTime) * 1000;
            AWELogToolInfo(AWELogToolTagMV, @"【cutsame】callbackDidFinishDownloadTemplateModel duration: %ld", (long)duration);
            [obj didFinishDownloadTemplateModel:templateModel];
        }
    }];
}

- (void)callbackDidFailTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                           withError:(NSError *)error
{
    [self.allDelegates.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didFailTemplateModel:withError:)]) {
            NSInteger duration = (CFAbsoluteTimeGetCurrent() - self.downloadStartTime) * 1000;
            AWELogToolInfo(AWELogToolTagMV, @"【cutsame】callbackDidFailTemplateModel duration: %ld - error: %@", (long)duration, error);
            [obj didFailTemplateModel:templateModel withError:error];
        }
    }];
}

- (void)callbackDidFinishedProcessTemplateModel:(id<ACCMVTemplateModelProtocol>)templateModel
                                    dataManager:(LVTemplateDataManager *)dataManager
                                      withError:(NSError *)error
{
    [self.allDelegates.allObjects enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:@selector(didFinishedProcessTemplateModel:dataManager:withError:)]) {
            [obj didFinishedProcessTemplateModel:templateModel dataManager:dataManager withError:error];
        }
    }];
}

#pragma mark - LVTemplateProcessorDelegate
- (void)templateProcessor:(LVTemplateProcessor *)processor didChangeProgress:(CGFloat)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        id<ACCMVTemplateModelProtocol> templateModel = self.templateSet[processor.templateID];
        [self callbackDidDownloadAndProcessTemplateModel:templateModel progress:progress];
    });
}

- (void)templateProcessor:(LVTemplateProcessor *)processor didFailWithErrorCode:(LVTemplateProccessorErrorCode)code withSubCode:(NSError  * _Nullable)subCode {
    dispatch_async(dispatch_get_main_queue(), ^{
        id<ACCMVTemplateModelProtocol> templateModel = self.templateSet[processor.templateID];
        
        [self.templateSet removeObjectForKey:processor.templateID];
        [self.processorSet removeObjectForKey:processor.templateID];
        
        NSError *error = [NSError errorWithDomain:@"LVTemplateProccessorErrorCode" code:code userInfo:nil];
        [self callbackDidFailTemplateModel:templateModel withError:error];
    });
}

- (void)templateProcessor:(LVTemplateProcessor *)processor didCompleteWithDataManager:(LVTemplateDataManager *)dataManager
{
    dispatch_async(dispatch_get_main_queue(), ^{
        id<ACCMVTemplateModelProtocol> templateModel = self.templateSet[processor.templateID];
        
        [self.templateSet removeObjectForKey:processor.templateID];
        [self.processorSet removeObjectForKey:processor.templateID];
        
        [self callbackDidFinishedProcessTemplateModel:templateModel dataManager:dataManager withError:nil];
    });
}

- (void)templateProcessor:(LVTemplateProcessor *)processor didPrepareResource:(LVTemplateDataManager *)dataManager
{
    
}

@end
