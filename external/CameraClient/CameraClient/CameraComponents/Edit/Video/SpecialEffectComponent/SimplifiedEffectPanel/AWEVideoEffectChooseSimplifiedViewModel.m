//
//  AWEVideoEffectChooseSimplifiedViewModel.m
//  Indexer
//
//  Created by Daniel on 2021/11/8.
//

#import "AWEVideoEffectChooseSimplifiedViewModel.h"
#import "AWEEffectPlatformDataManager.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCEditPreviewProtocolD.h"
#import "AWEVideoEffectChooseSimplifiedCellModel.h"
#import "AWEVideoEffectPathBlockManager.h"
#import "AWEVideoSpecialEffectsDefines.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <EffectPlatformSDK/IESEffectPlatformResponseModel.h>
#import <EffectPlatformSDK/IESEffectModel.h>

@interface AWEVideoEffectChooseSimplifiedViewModel ()

@property (nonatomic, copy, readwrite, nullable) NSArray<AWEVideoEffectChooseSimplifiedCellModel *> *cellModels;
@property (nonatomic, copy, nullable) NSDictionary<NSString *, NSNumber *> *effectIndexDict; // 根据effectId快速找到其在effects中的index
@property (nonatomic, strong, nullable) AWEEffectPlatformDataManager *effectsManager;
@property (nonatomic, weak, nullable) id<ACCEditServiceProtocol> editService;

@end

@implementation AWEVideoEffectChooseSimplifiedViewModel

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)publishModel editService:(id<ACCEditServiceProtocol>)editService
{
    self = [super init];
    if (self) {
        self.selectedIndex = NSNotFound;
        _publishModel = publishModel;
        self.editService = editService;
        self.effectsManager = [[AWEEffectPlatformDataManager alloc] init];
        if (!publishModel.repoVideoInfo.video.effectFilterPathBlock) {
            publishModel.repoVideoInfo.video.effectFilterPathBlock = [AWEVideoEffectPathBlockManager pathConvertBlock:publishModel];
        }
    }
    return self;
}

#pragma mark - Public Methods

- (void)updateCellModelsWithCachedEffects
{
    IESEffectPlatformResponseModel *responseModel = [self.effectsManager getCachedEffectsInPanel:kSpecialEffectsSimplifiedPanelName];
    [self p_updateCellModels:responseModel];
}

- (void)getEffectsInPanel:(void (^)(void))completion
{
    @weakify(self);
    [self.effectsManager getEffectsInPanel:kSpecialEffectsSimplifiedPanelName
                                completion:^(IESEffectPlatformResponseModel *responseModel) {
        @strongify(self);
        [self p_updateCellModels:responseModel];
        dispatch_async(dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(completion);
        });
    }];
}

- (void)downloadEffectAtIndex:(NSUInteger)index completion:(void (^)(BOOL))completion
{
    if (index >= self.cellModels.count) {
        return;
    }
    AWEVideoEffectChooseSimplifiedCellModel *cellModel = self.cellModels[index];
    @weakify(cellModel);
    [self.effectsManager downloadFilesOfEffect:cellModel.effectModel
                                    completion:^(BOOL success, IESEffectModel * _Nullable effectModel0) {
        @strongify(cellModel);
        cellModel.downloadStatus = AWEEffectDownloadStatusDownloaded;
        ACCBLOCK_INVOKE(completion, success);
    }];
}

- (void)applyEffectWholeRange:(NSString *)effectId
{
    [self.editService.effect removeAllEffect];
    CGFloat startTime = 0.f;
    CGFloat endTime = self.publishModel.repoVideoInfo.video.totalVideoDuration;
    [self.editService.effect setEffectWidthPathID:effectId withStartTime:startTime andStopTime:endTime];
}

- (void)removeAllEffects
{
    [self.editService.effect removeAllEffect];
}

#pragma mark - Private Methods

- (void)p_updateCellModels:(IESEffectPlatformResponseModel *)responseModel
{
    NSMutableArray *mutableArr = [NSMutableArray array];
    NSMutableDictionary<NSString *, NSNumber *> *mutableDict = [NSMutableDictionary dictionary];
    [responseModel.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull effectModel, NSUInteger effectIndex, BOOL * _Nonnull stop) {
        if (!ACC_isEmptyString(effectModel.effectIdentifier)) {
            mutableDict[effectModel.effectIdentifier] = @(effectIndex);
        }
        
        AWEVideoEffectChooseSimplifiedCellModel *cellModel = [[AWEVideoEffectChooseSimplifiedCellModel alloc] init];
        cellModel.effectModel = effectModel;
        if (effectModel.downloaded) {
            cellModel.downloadStatus = AWEEffectDownloadStatusDownloaded;
        } else {
            cellModel.downloadStatus = AWEEffectDownloadStatusUndownloaded;
        }
        [mutableArr acc_addObject:cellModel];
    }];
    self.cellModels = [mutableArr copy];
    self.effectIndexDict = [mutableDict copy];
    
    self.selectedIndex = NSNotFound;
    [self.publishModel.repoVideoInfo.video.effect_operationTimeRange enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(IESMMEffectTimeRange * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *effectId = obj.effectPathId;
        if (ACC_isEmptyString(effectId)) {
            return;
        }
        id idxId = [mutableDict objectForKey:effectId];
        if ([idxId isKindOfClass:[NSNumber class]]) {
            NSInteger effectIndex = ((NSNumber *)idxId).integerValue;
            self.selectedIndex = effectIndex;
            *stop = YES;
        }
    }];
}

@end
