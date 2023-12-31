//
//  NLEDiffCalculator_OC.hpp
//  NLEPlatform
//
//  Created by bytedance on 2021/1/18.
//

#ifndef NLEDiffCalculator_OC_hpp
#define NLEDiffCalculator_OC_hpp

#include "NLENode.h"
#import "NLESequenceNode.h"
#include <stdio.h>

enum class NodeType {
    track = 0,
    slot = 1,
    filter = 2,
};

enum class NodeChangeType {
    CHANGE_TYPE_UPDATE = 0,
    CHANGE_TYPE_ADD = 1,
    CHANGE_TYPE_DELETE = 2
};


class NodeChangeInfo {
public:
    int idx;
    NodeChangeType changeType;
    std::shared_ptr<cut::model::NLENode> oriNode;
    std::shared_ptr<cut::model::NLENode> newNode;
};


class SlotChangeInfo {
public:
    NodeChangeInfo nodeChangeInfo;
    std::shared_ptr<cut::model::NLETrack> track;
};

class SlotChangeGroupInfo {
public:
    std::vector<SlotChangeInfo> deleteInfos;
    std::vector<SlotChangeInfo> addAndUpdateInfos;
};


class NLEDiffCalculator_OC {
    
public:
    static std::vector<NodeChangeInfo>
    diffNodes(const std::map<int , std::shared_ptr<cut::model::NLENode>> oriNodes, const std::map<int , std::shared_ptr<cut::model::NLENode>> newNodes);

    static std::vector<NodeChangeInfo>
    diffSimpleNodes(const std::vector<std::shared_ptr<cut::model::NLENode>> &oriNodes, const std::vector<std::shared_ptr<cut::model::NLENode>> &newNodes);
    
    static std::vector<NodeChangeInfo>
    diffModel(const std::shared_ptr<const cut::model::NLEModel> curModel, const std::shared_ptr<const cut::model::NLEModel> prevModel);
    
    static std::vector<NodeChangeInfo>
    diffTrack(const std::map<int , std::shared_ptr<cut::model::NLETrack>> oriNodes, const std::map<int, std::shared_ptr<cut::model::NLETrack>> newNodes);
    
    static std::vector<NodeChangeInfo>
    diffKeyFrame(std::shared_ptr<const cut::model::NLETrackSlot> prevSlot, std::shared_ptr<const cut::model::NLETrackSlot> curSlot, std::shared_ptr<const cut::model::NLETrack> track);
    
    static std::vector<NodeChangeInfo>
    diffPartialVideoEffect(const std::shared_ptr<const cut::model::NLETrackSlot> prevSlot, const std::shared_ptr<const cut::model::NLETrackSlot> curSlot);
    
    static std::vector<SlotChangeInfo>
    flatDiffTracks(const std::vector<NodeChangeInfo> &changeTracks, cut::model::NLETrackType trackType);

    static std::shared_ptr<SlotChangeGroupInfo>
    flatDiffTracksGrouped(const std::vector<NodeChangeInfo> &changeTracks, cut::model::NLETrackType trackType);
    
    static std::vector<NodeChangeInfo>
    diffCoverModel(const std::shared_ptr<const cut::model::NLEVideoFrameModel> prevCoverModel, const std::shared_ptr<const cut::model::NLEVideoFrameModel> curCoverModel);

};



#endif /* NLEDiffCalculator_OC_hpp */
