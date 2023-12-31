//
//  VENativeWrapper+Effect.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/20.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Effect)

/// 全局特效
/// @param changeInfos std::vector<NodeChangeInfo> &
- (void)syncEffects:(std::vector<SlotChangeInfo> &)changeInfos;

/**
 * 根据Rangid ID获得slotName
 */
- (NSString * _Nullable)slotNameForEffectRangID:(NSString *)rangID;

/**
 * 根据slotName获得rang ID
 */
- (NSString * _Nullable)effectRangIDForSlotName:(NSString *)slotName;

@end

NS_ASSUME_NONNULL_END
