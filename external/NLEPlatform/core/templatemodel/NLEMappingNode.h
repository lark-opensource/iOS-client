//
//  NLEMappingNode.hpp
//  TemplateConsumer
//
//  Created by Lemonior on 2021/9/24.
//

#ifndef NLEMappingNode_hpp
#define NLEMappingNode_hpp

#include <vector>
#include <string>
#include <memory>

#include "NLENode.h"
#include "NLENodeDecoder.h"
#include "nle_export.h"

namespace cut::model {
    /**
     *  模版的统一数据模型
     */
    class NLE_EXPORT_CLASS NLEMappingNode : public NLENode {
        NLENODE_RTTI(NLEMappingNode);
        KEY_FUNCTION_DEC_OVERRIDE(NLEMappingNode)

        /**
         * map的类名
         */
        NLE_PROPERTY_DEC(NLEMappingNode, KeyClassName, std::string, "", NLEFeature::TBASE)
        /**
         * map的uuid
         */
        NLE_PROPERTY_DEC(NLEMappingNode, KeyUUID, std::string, "", NLEFeature::TBASE)


    public:
        NLEMappingNode();
        virtual ~NLEMappingNode();
    };
}

#endif /* NLEMappingNode_hpp */
