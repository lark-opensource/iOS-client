//
//  VENativeWrapper+MV.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/5/10.
//

#import "VENativeWrapper.h"
#import "NLEEditorCommitContextProtocol.h"
#import "NLEMacros.h"

@class IESMMMVModel;

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (MV)

// 针对MV的音视频轨道
- (void)asyncMVAudioAndVideoChangeInfos:(std::vector<NodeChangeInfo> &)allTrackChangeInfos
                             completion:(NLEBaseBlock)completion;

// 获取mvmodel
- (IESMMMVModel *)currentMVModel;

@end

NS_ASSUME_NONNULL_END
