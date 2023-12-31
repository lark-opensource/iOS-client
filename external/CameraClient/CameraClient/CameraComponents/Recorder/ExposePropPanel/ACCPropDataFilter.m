//
//  ACCPropDataFilter.m
//  CameraClient
//
//  Created by Shen Chen on 2020/5/15.
//

#import "ACCPropDataFilter.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "IESEffectModel+ACCRedpacket.h"
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import "AWEStickerDataManager.h"

@implementation ACCPropDataFilter

- (instancetype)initWithInputData:(ACCRecordViewControllerInputData *)inputData
{
    self = [super init];
    if (self) {
        self.inputData = inputData;
    }
    return self;
}

- (BOOL)allowEffect:(IESEffectModel *)effect {
    // 商业化贴纸过滤
    // 如果开启了过滤商业化道具开关（filterBusiness），那么过滤不显示所有的商业化道具（localSticker除外）
    if ((self.inputData.filterBusiness || self.filterCommerce) &&
        effect.isCommerce &&
        ![effect.effectIdentifier isEqualToString:self.inputData.localSticker.effectIdentifier]) {
        return NO;
    }
    
    // 根据 needFilterStickerType 过滤道具面板
    if (((self.effectFilterType | self.inputData.needsFilterStickerType) & AWEStickerFilterTypeGame) && ([effect gameType] != ACCGameTypeNone)) {
        return NO;
    }
    
    // 道具面板过滤规则
    if (self.inputData.publishModel.repoDuet.isDuet) {
        if ([effect acc_isTC21Redpacket]) { return NO; }
        if ([effect isVideoBGPixaloopSticker]) { return NO; }
        if ([effect isTypeMusicBeat]) { return NO; }
        if ([effect acc_isTypeSlowMotion]) { return NO; }
        if ([effect isTypeVoiceRecognization]) { return NO; }
        if (effect.isMultiSegProp) { return NO; }
        if ([effect.tags containsObject:@"audio_effect"]) { return NO; }
        if ([effect.tags containsObject:@"forbid_for_all_duet"]) { return NO; }
    } else if (self.inputData.publishModel.repoReshoot.isReshoot) {
        if ([effect isVideoBGPixaloopSticker]) { return NO; }
        if ([effect gameType] != ACCGameTypeNone) {
            return NO;
        }
    }
    
    // 道具外露屏蔽多段道具
    if (effect.isMultiSegProp) {
        return NO;
    }
    
    return YES;
}

- (NSArray<IESEffectModel *> *)filteredEffects:(NSArray<IESEffectModel *> *)effects
{
    NSMutableArray<IESEffectModel *> *filtered = [NSMutableArray new];
    for (IESEffectModel *effect in effects) {
        if ([self allowEffect:effect]) {
            [filtered addObject:effect];
        }
    }
    return filtered.copy;
}

@end
