//
//  ACCVoiceEffectManager.h
//  Pods
//
//  Created by Shen Chen on 2020/8/10.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/ACCCommonDefine.h>

NS_ASSUME_NONNULL_BEGIN

@protocol ACCEditServiceProtocol;

@interface ACCVoiceEffectManager : NSObject
@property (nonatomic, assign) AWELogToolTag logTag;
@property (nonatomic, assign) BOOL shouldShowToast;
@property (nonatomic, weak) UIView *toastReferenceView;
@property (nonatomic, assign, readonly) BOOL voiceHadRecovered;
- (void)recoverVoiceEffectsToEditService:(id<ACCEditServiceProtocol>)editService withPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel completion:(void (^_Nullable)(BOOL recovered, NSError *error))completion;
+ (nullable IESEffectModel *)voiceEffectForEffectID:(NSString *)effectID;
- (void)clearVoiceEffectToEditService:(id<ACCEditServiceProtocol>)editService withPublishViewModel:(AWEVideoPublishViewModel *)publishViewModel  completion:(void(^_Nullable)(void))completion;

@end

NS_ASSUME_NONNULL_END
