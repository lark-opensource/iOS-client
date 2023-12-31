//
//  AWEVideoEffectPathBlockManager.m
//  Indexer
//
//  Created by Daniel on 2021/11/19.
//

#import "AWEVideoEffectPathBlockManager.h"
#import "AWESpecialEffectSimplifiedABManager.h"
#import "AWEVideoSpecialEffectsDefines.h"

#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/IESEffectModel+ACCSticker.h>
#import <EffectPlatformSDK/EffectPlatform.h>

@implementation AWEVideoEffectPathBlockManager

+ (AWEEffectPlatformPathBlock)pathConvertBlock:(AWEVideoPublishViewModel *)publishModel
{
    BOOL shouldUseSimplifiedPanel = [AWESpecialEffectSimplifiedABManager shouldUseSimplifiedPanel:publishModel];
    if (shouldUseSimplifiedPanel) {
        NSDictionary *effectDic = [AWEVideoEffectPathBlockManager p_getEffectDict];
        AWEEffectPlatformPathBlock block = ^IESMMEffectStickerInfo *(NSString *effectPathId, IESEffectFilterType effectType) {
            IESEffectModel *effectModel = nil;
            if (effectPathId == nil) {
                effectPathId = [self getEffectIdWithType:effectType];
            }
            effectModel = [self getEffectWithID:effectPathId];
            if (effectModel == nil) {
                effectModel = [self getEffectWithEffectName:effectDic[@(effectType)][@"name"]];
            }
            return [effectModel effectStickerInfo];
        };
        
        return block;
    } else {
        return [[AWEEffectFilterDataManager defaultManager] pathConvertBlock];
    }
}

+ (nullable NSString *)getEffectIdWithType:(IESEffectFilterType)effectType
{
    NSDictionary *effectDic = [AWEVideoEffectPathBlockManager p_getEffectDict];
    NSString *effectPathId = effectDic[@(effectType)][@"effectId"];
    return effectPathId;
}

+ (IESEffectModel *)getEffectWithID:(NSString *)effectId
{
    __block IESEffectModel *effectModel = nil;
    NSMutableArray<IESEffectModel *> *downloadedEffects = [NSMutableArray array];
    [downloadedEffects addObjectsFromArray:[EffectPlatform cachedEffectsOfPanel:kSpecialEffectsSimplifiedPanelName].downloadedEffects];
    [downloadedEffects addObjectsFromArray:[EffectPlatform cachedEffectsOfPanel:kSpecialEffectsOldPanelName].downloadedEffects];
    [downloadedEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull tmpEffectModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([tmpEffectModel.effectIdentifier isEqualToString:effectId]) {
            effectModel = tmpEffectModel;
        }
    }];
    
    return effectModel;
}

+ (IESEffectModel *)getEffectWithEffectName:(NSString *)effectName
{
    __block IESEffectModel *effectModel = nil;
    NSArray<IESEffectModel *> *downloadedEffects = [EffectPlatform cachedEffectsOfPanel:kSpecialEffectsSimplifiedPanelName].downloadedEffects;
    [downloadedEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull tmpEffectModel, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([tmpEffectModel.effectName isEqualToString:effectName]) {
            effectModel = tmpEffectModel;
        }
    }];
    return nil;
}

#pragma mark - Private Methods

+ (NSDictionary *)p_getEffectDict
{
    NSDictionary *effectDict = @{
        @(IESEffectFilterFake3D):@{@"name":@"av_filter_effect2",
                                   @"effectId":@"15659",
        },
        @(IESEffectFilterRBVertigo):@{@"name":@"effect_illusion",
                                      @"effectId":@"15660",
        },
        @(IESEffectFilterWhiteEdge):@{@"name":@"Black magic",
                                      @"effectId":@"15661",
        },
        @(IESEffectFilterOldMovie):@{@"name":@"70s",
                                     @"effectId":@"15662",
        },
        @(IESEffectFilterSoulScale):@{@"name":@"av_filter_effect1",
                                      @"effectId":@"15658",
        },
        @(IESEffectFilterSnowFlake):@{@"name":@"X-Signal",
                                      @"effectId":@"15663",
        }
    };
    return effectDict;
}

@end
