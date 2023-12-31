//
//  AWEEffectPlatformDataManager.m
//  Indexer
//
//  Created by Daniel on 2021/11/15.
//

#import "AWEEffectPlatformDataManager.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitArch/CKConfigKeysDefines.h>
#import <CreationKitArch/AWEEffectPlatformTrackModel.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitArch/AWEEffectPlatformManageable.h>
#import <EffectPlatformSDK/EffectPlatform.h>

static NSUInteger const kMaxConcurrentOperationCount = 1;

@interface AWEEffectPlatformDataManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation AWEEffectPlatformDataManager

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self p_setupOperationQueue];
    }
    return self;
}

- (void)dealloc
{
    [self.operationQueue cancelAllOperations];
}

#pragma mark - Public Methods

- (IESEffectPlatformResponseModel *)getCachedEffectsInPanel:(NSString *)panelName
{
    IESEffectPlatformResponseModel *result = [EffectPlatform cachedEffectsOfPanel:panelName]; // get cached info
    AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"p_getCachedEffectsInPanel panelName: %@, result count %@", panelName ?: @"", @(result.effects.count));
    return result;
}

- (void)getEffectsInPanel:(NSString *)panelName
               completion:(void (^)(IESEffectPlatformResponseModel *))completion
{
    [self.operationQueue cancelAllOperations];
    
    @weakify(self);
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        @strongify(self);
        IESEffectPlatformResponseModel *responseModel = [self getEffectsSynchronicallyInPanel:panelName];
        ACCBLOCK_INVOKE(completion, responseModel);
    }];
    [self.operationQueue addOperation:operation];
}

- (void)downloadFilesOfEffect:(IESEffectModel *)effectModel
                   completion:(void (^)(BOOL, IESEffectModel *))completion
{
    @weakify(self);
    NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        @strongify(self);
        BOOL result = [self p_downloadFilesOfModel:effectModel];
        ACCBLOCK_INVOKE(completion, result, effectModel);
    }];
    [self.operationQueue addOperation:operation];
}

+ (NSArray<IESEffectModel *> *)getCachedEffectsOfPanel:(NSString *)panelName
{
    NSArray *downloadedEffects = [EffectPlatform cachedEffectsOfPanel:panelName].downloadedEffects;
    return downloadedEffects;
}

- (IESEffectPlatformResponseModel *)getEffectsSynchronicallyInPanel:(NSString *)panelName
{
    AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"p_getEffectsInPanel started panelName:%@", panelName ?: @"");
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    /* 1. Check if the EffectPlatform needs update */
    __block BOOL shouldUpdate = YES;
    [EffectPlatform checkEffectUpdateWithPanel:panelName
                          effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                    completion:^(BOOL needUpdate) {
        shouldUpdate = needUpdate;
        AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"checkEffectUpdateWithPanel needUpdate:%@", needUpdate ? @"YES" : @"NO");
        dispatch_semaphore_signal(semaphore);
    }];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    /* 2. Get all effects of a panel */
    __block IESEffectPlatformResponseModel *result = [EffectPlatform cachedEffectsOfPanel:panelName]; // get cached info
    if (shouldUpdate || result == nil) {
        AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"downloadEffectListWithPanel started");
        [EffectPlatform setAutoDownloadEffects:NO];
        [EffectPlatform downloadEffectListWithPanel:panelName
                               effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                         completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
            if (error || ACC_isEmptyArray(response.effects)) {
                [self p_monitorWithPanelName:panelName startTime:startTime isFailed:YES error:error needUpdate:YES];
            } else {
                [self p_monitorWithPanelName:panelName startTime:startTime isFailed:NO error:nil needUpdate:YES];
            }
            result = response;
            AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"downloadEffectListWithPanel finished");
            dispatch_semaphore_signal(semaphore);
        }];
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    } else {
        [self p_monitorWithPanelName:panelName startTime:startTime isFailed:NO error:nil needUpdate:NO];
    }
    AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"p_getEffectsInPanel result count %@", @(result.effects.count));
    return result;
}

#pragma mark - Private Methods

- (void)p_setupOperationQueue
{
    _operationQueue = [[NSOperationQueue alloc] init];
    _operationQueue.name = NSStringFromClass([AWEEffectPlatformDataManager class]);
    _operationQueue.maxConcurrentOperationCount = kMaxConcurrentOperationCount;
}

- (BOOL)p_downloadFilesOfModel:(IESEffectModel *)effectModel
{
    __block BOOL result = NO;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    AWEEffectPlatformTrackModel *trackModel = [AWEEffectPlatformTrackModel modernStickerTrackModel];
    trackModel.successStatus = @10;
    trackModel.failStatus = @11;
    
    AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"p_downloadFilesOfModel started %@", effectModel.effectIdentifier);
    [IESAutoInline(ACCBaseContainer(), AWEEffectPlatformManageable) downloadEffect:effectModel
                                                                        trackModel:trackModel
                                                             downloadQueuePriority:NSOperationQueuePriorityVeryHigh
                                                          downloadQualityOfService:NSQualityOfServiceBackground
                                                                          progress:^(CGFloat progress) {
        
    } completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
        NSInteger success = !(error || ACC_isEmptyString(filePath));
        if (success) {
            result = YES;
        }
        dispatch_semaphore_signal(semaphore);
    }];
    
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    AWELogToolInfo2(@"effect_platform_data_manager", AWELogToolTagEdit, @"p_downloadFilesOfModel finished %@", effectModel.effectIdentifier);
    return result;
}

- (void)p_monitorWithPanelName:(nullable NSString *)panelName
                     startTime:(CFTimeInterval)startTime
                      isFailed:(BOOL)isFailed
                         error:(nullable NSError *)error
                    needUpdate:(BOOL)needUpdate
{
    if (isFailed) {
        [ACCMonitor() trackService:@"aweme_effect_list_error"
                            status:11
                             extra:@{
            @"panel":panelName ?: @"",
            @"errorDesc":error.description ?: @"",
            @"errorCode":@(error.code),
            @"abParam":@(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
            @"needUpdate":@(needUpdate)
        }];
    } else {
        [ACCMonitor() trackService:@"aweme_effect_list_error"
                            status:10
                             extra:@{
            @"panel":panelName ?: @"",
            @"duration":@((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
            @"abParam":@(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
            @"needUpdate":@(needUpdate)
        }];
    }
}

@end
