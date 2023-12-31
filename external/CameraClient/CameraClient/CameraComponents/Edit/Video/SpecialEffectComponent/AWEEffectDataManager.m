//
//  AWEEffectDataManager.m
//  CameraClient
//
//  Created by xulei on 2020/2/28.
//

#import "AWEEffectDataManager.h"

@interface AWEEffectDataManager()

@property (nonatomic, strong) AWEEffectFilterDataManager *effectFilterDataManager;//All special effects except time effects
@property (nonatomic, strong) HTSVideoSepcialEffect *timeEffectManager;

@end

@implementation AWEEffectDataManager

- (HTSVideoSepcialEffect *)timeEffectManager {
    return  [[HTSVideoSepcialEffect alloc] init];
}

- (AWEEffectFilterDataManager *)effectFilterDataManager {
    return [AWEEffectFilterDataManager defaultManager];
}

- (NSArray *)allTimeEffects {
    return [[self timeEffectManager] allEffects];
}

- (void)resetTimeForbiddenStyle {
    [self.timeEffectManager resetForbid];
}

- (HTSVideoSepcialEffect *)timeEffectWithType:(HTSPlayerTimeMachineType)type {
    return [self.timeEffectManager effectWithType:type];
}

- (UIColor *)timeEffectColorWithType:(HTSPlayerTimeMachineType)type {
    return [self.timeEffectManager effectColorWithType:type];
}

- (NSString *)timeEffectDescriptionWithType:(HTSPlayerTimeMachineType)type{
    return [self.timeEffectManager descriptionWithType:type];
}

- (BOOL)isFetching {
    return self.effectFilterDataManager.isFetching;
}

- (AWEEffectDownloadStatus)downloadStatusOfEffect:(IESEffectModel *)effect{
    return [self.effectFilterDataManager downloadStatusOfEffect:effect];
}

- (void)addEffectToDownloadQueue:(IESEffectModel *)effectModel{
    [self.effectFilterDataManager addEffectToDownloadQueue:effectModel];
}

- (AWEEffectFilterPathBlock)effectFilterPathBlock {
    return [self.effectFilterDataManager pathConvertBlock];
}

- (IESEffectModel *)normalEffectWithID:(NSString *)effectPathID {
    return [self.effectFilterDataManager effectWithID:effectPathID];
}

- (NSArray<IESEffectModel *> *)builtinNormalEffects{
    return [self.effectFilterDataManager builtinEffects];
}

- (IESEffectPlatformResponseModel *)normalEffectPlatformModel {
    return [self.effectFilterDataManager effectPlatformModel];
}

- (CGFloat)effectDurationForNormalEffect:(IESEffectModel *)effect{
    return [self.effectFilterDataManager effectDurationForEffect:effect];
}

- (UIColor *)maskColorForNormalEffect:(IESEffectModel *)effect{
    return [self.effectFilterDataManager maskColorForEffect:effect];
}

- (void)updateNormalEffects {
    [self.effectFilterDataManager updateEffectFilters];
}

- (NSString *)effectIdWithType:(IESEffectFilterType)effectType {
    return [self.effectFilterDataManager effectIdWithType:effectType];
}

@end
