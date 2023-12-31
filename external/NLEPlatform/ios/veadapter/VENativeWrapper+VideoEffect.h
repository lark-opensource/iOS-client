//
//  VENativeWrapper+VideoEffect.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/16.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (VideoEffect)

/// 同步 track 和 slot 里的Video Effects，都是局部视频特效，添加到具体 asset 上
/// @param changeInfos std::vector<NodeChangeInfo>
- (void)syncVideoEffects:(std::vector<NodeChangeInfo> &)changeInfos;

- (void)syncVideoEffectsWithSlotChangeInfo:(std::vector<SlotChangeInfo> &)changeInfos;

@end

NS_ASSUME_NONNULL_END
