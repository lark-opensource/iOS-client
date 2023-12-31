//
//  ACCVoiceEffectEditSession.h
//  Pods
//
//  Created by Shen Chen on 2020/7/20.
//

#import <Foundation/Foundation.h>
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreationKitArch/ACCVoiceEffectSegment.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ACCVoiceEffectEditSessionState) {
    ACCVoiceEffectEditSessionStateIdle = 0,
    ACCVoiceEffectEditSessionStateInPreview,
    ACCVoiceEffectEditSessionStateApplying
};


@protocol ACCEditServiceProtocol;
@class AWEVideoPublishViewModel;

@interface ACCVoiceEffectEditSession : NSObject
@property (nonatomic, assign, readonly) NSTimeInterval applyStartTime;
@property (nonatomic, assign, readonly) ACCVoiceEffectEditSessionState state;

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
                   publishViewModel:(AWEVideoPublishViewModel *)publishViewModel;
- (NSArray<ACCVoiceEffectSegment *> *)currentSegments;
- (NSArray<ACCVoiceEffectSegment *> *)currentNonOverlappingSegments;
- (void)loadSegments:(NSArray<ACCVoiceEffectSegment *> *)segments;
- (void)startPreviewEffect:(IESEffectModel *)effect duration:(NSTimeInterval)duration completion:(void (^_Nullable)(void))completion;
- (void)startApplyEffect:(IESEffectModel *)effect;
- (void)stopApplyEffectWithCompletion:(void (^_Nullable)(void))completion;
- (void)updateVoiceEffectsWithCompletion:(void (^_Nullable)(void))completion;
- (void)cancelActionsAndSeekBackCompletion:(void (^_Nullable)(void))completion;
- (void)revokeLastEffect;
- (BOOL)hasNewEdits;
@end

NS_ASSUME_NONNULL_END
