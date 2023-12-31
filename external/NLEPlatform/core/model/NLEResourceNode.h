//
// Created by bytedance on 2020/6/7.
//

#ifndef NLEPLATFORM_NLERESOURCENODE_H
#define NLEPLATFORM_NLERESOURCENODE_H

#include "NLENode.h"
#include "nle_export.h"
#include "NLEResType.h"
#include "NLENodeDecoder.h"
#include "NLEResourcePubDefine.h"

namespace cut::model {

    /**
     * Resource Base
     */
    class NLE_EXPORT_CLASS NLEResourceNode : public NLENode {
    NLENODE_RTTI(NLEResourceNode);

    // Loki://emoji/2034

        // if id is empty, means this is local file
    NLE_PROPERTY_DEC(NLEResourceNode, ResourceId, nle::resource::NLEResourceId, std::string(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLEResourceNode, ResourceFile, std::string, std::string(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLEResourceNode, ResourceTag, NLEResTag, NLEResTag::NORMAL, NLEFeature::E)
        
    NLE_PROPERTY_DEC(NLEResourceNode, ResourceType, NLEResType, NLEResType::NONE, NLEFeature::E)

    NLE_PROPERTY_DEC(NLEResourceNode, ResourceName, std::string, std::string(), NLEFeature::E)

    NLE_PROPERTY_DEC(NLEResourceNode, Duration, NLETime, 0, NLEFeature::E) ///<单位 : us微妙

    NLE_PROPERTY_DEC(NLEResourceNode, Width, uint32_t, 0, NLEFeature::E)    ///<音频为 0

    NLE_PROPERTY_DEC(NLEResourceNode, Height, uint32_t, 0, NLEFeature::E)   ///<音频为 0

    public:
        /// 是否是本地文件. id 为空即为本地文件.
        bool isLocal() const;
    };

    /**
     * Audio/Video/Image Resource
     */
    class NLE_EXPORT_CLASS NLEResourceAV : public NLEResourceNode {
    NLENODE_RTTI(NLEResourceAV);

    NLE_PROPERTY_DEC(NLEResourceAV, HasAudio, bool, false, NLEFeature::E) ///<是否有音频轨

    NLE_PROPERTY_DEC(NLEResourceAV, FileInfo, std::string, std::string(), NLEFeature::E) ///<先用string存着，后续再加toJson方法

    NLE_PROPERTY_DEC(NLEResourceNode, ReverseResourceFile, std::string, std::string(), NLEFeature::E) ///<倒放后的视频路径，为了兼容抖音老数据先保留，后续新功能不允许再使用

    };
}

#endif //NLEPLATFORM_NLERESOURCENODE_H
