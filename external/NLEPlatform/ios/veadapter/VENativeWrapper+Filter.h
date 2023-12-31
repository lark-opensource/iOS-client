//
//  VENativeWrapper+Filter.h
//  NLEPlatform-Pods-Aweme
//
//  Created by bytedance on 2021/3/15.
//

#import "VENativeWrapper.h"
#import "NLEEditorCommitContextProtocol.h"
#import "NLEMacros.h"

NS_ASSUME_NONNULL_BEGIN

@interface VENativeWrapper (Filter)


/// 1、处理 track 里的filters [NLEFilter]：应用于某一轨道，剪同款里暂时还没有这种
/// 2、处理 slot 里的 filters [NLEFilter]：局部滤镜
/// 3、处理 slot 的 main segment 里的filter NLESegmentFilter：全局滤镜
/// @param changeInfos std::vector<NodeChangeInfo>
- (void)syncFilters:(std::vector<NodeChangeInfo> &)changeInfos
           forTrack:(std::shared_ptr<cut::model::NLETrack>)track
         completion:(NLEBaseBlock)completion;

- (void)syncFilters:(std::vector<SlotChangeInfo> &)changeInfos completion:(NLEBaseBlock)completion;

- (NSArray<VEAmazingFeature *> *)getCachedFeaturesForVideoSlot:(std::shared_ptr<cut::model::NLETrackSlot>)videoSlot;

@end

NS_ASSUME_NONNULL_END
