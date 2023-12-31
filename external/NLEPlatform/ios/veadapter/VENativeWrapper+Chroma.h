//
//  VENativeWrapper+Chroma.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/2/13.
//

#import "VENativeWrapper.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Chroma)

/// 色度抠图
/// @param changeInfos std::vector<SlotChangeInfo>
- (void)syncChroma:(std::vector<SlotChangeInfo> &)changeInfos;

@end

NS_ASSUME_NONNULL_END
