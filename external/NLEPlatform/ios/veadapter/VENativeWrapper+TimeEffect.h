//
//  VENativeWrapper+TimeEffect.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/6/29.
//

#import "VENativeWrapper.h"
#import "NLEMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (TimeEffect)

/// 独立轨道的time effect
/// @param changeInfos std::vector<SlotChangeInfo> &
/// @param completion NLEBaseBlock
- (void)syncTimeEffects:(std::vector<SlotChangeInfo> &)changeInfos
             completion:(NLEBaseBlock)completion;

/// 视频轨道上的时间特效
- (void)syncTimeEffectsInTrack:(std::vector<NodeChangeInfo> &)changeInfos
                    completion:(NLEBaseBlock)completion;

@end

NS_ASSUME_NONNULL_END
