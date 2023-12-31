//
//  ACCVoiceChangerViewModel.h
//  Pods
//
//  Created by haoyipeng on 2020/8/9.
//

#import <CreationKitInfra/ACCRACWrapper.h>
#import "ACCEditVoiceChangerServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@class AWEVideoPublishViewModel;

@interface ACCVoiceChangerViewModel : NSObject <ACCEditVoiceChangerServiceProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@property (nonatomic, strong, readonly) RACSignal *cleanVoiceEffectSignal;

- (void)setNeedCheckChangeVoiceButtonDisplay;

- (void)forceCleanVoiceEffect;

- (void)cleanVoiceEffectIfNeeded;

@end

NS_ASSUME_NONNULL_END
