//
//  AWEEffectDataManager.h
//  CameraClient
//
//  Created by xulei on 2020/2/28.
//

#import <Foundation/Foundation.h>
#import <CreationKitArch/AWEEffectFilterDataManager.h>
#import <CreationKitArch/HTSVideoSepcialEffect.h>

NS_ASSUME_NONNULL_BEGIN

@interface AWEEffectDataManager : NSObject
//effect except time
@property (nonatomic, assign, readonly) BOOL isFetching;

- (AWEEffectDownloadStatus)downloadStatusOfEffect:(IESEffectModel *)effect;
- (void)addEffectToDownloadQueue:(IESEffectModel *)effectModel;
- (AWEEffectFilterPathBlock)effectFilterPathBlock;
- (IESEffectModel *)normalEffectWithID:(NSString *)effectPathID;
- (NSArray<IESEffectModel *> *)builtinNormalEffects;
- (IESEffectPlatformResponseModel *)normalEffectPlatformModel;
- (CGFloat)effectDurationForNormalEffect:(IESEffectModel *)effect;
- (NSString *)effectIdWithType:(IESEffectFilterType)effectType;
- (UIColor *)maskColorForNormalEffect:(IESEffectModel *)effect;
- (void)updateNormalEffects;

//time effect data
- (NSArray *)allTimeEffects;
- (void)resetTimeForbiddenStyle;
- (HTSVideoSepcialEffect *)timeEffectWithType:(HTSPlayerTimeMachineType)type;
- (UIColor *)timeEffectColorWithType:(HTSPlayerTimeMachineType)type;
- (NSString *)timeEffectDescriptionWithType:(HTSPlayerTimeMachineType)type;

@end

NS_ASSUME_NONNULL_END
