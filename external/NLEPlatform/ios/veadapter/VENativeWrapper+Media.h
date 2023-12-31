//
//  VENativeWrapper+Meida.h
//  NLEPlatform
//
//  Created by bytedance on 2021/1/19.
//

#import "VENativeWrapper.h"
#import "NLEMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Media)

- (void)syncVideos:(std::vector<SlotChangeInfo> &)changeInfos
        completion:(NLEBaseBlock)completion;

@end

NS_ASSUME_NONNULL_END
