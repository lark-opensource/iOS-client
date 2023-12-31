//
//  TemplateConfig.hpp
//  TemplateConsumer
//
//  Created by Lemonior on 2021/9/23.
//

#ifndef TemplateConfig_hpp
#define TemplateConfig_hpp

#include <vector>
#include <string>
#include <memory>

#include "NLENode.h"
#include "NLENodeDecoder.h"

namespace cut::model {
    /**
     *  模版配置
     */
    class NLE_EXPORT_CLASS TemplateConfig : public NLENode {
        NLENODE_RTTI(TemplateConfig);
        KEY_FUNCTION_DEC_OVERRIDE(TemplateConfig)
        /**
         * 画布比例，默认"16:9"
         * “16:9”,"1:1","3:4","4:3","9:16","original","2:1","2.35:1","1.85:1","1.125:2.436"; "original"表示原始比例
         *
         */
        NLE_PROPERTY_DEC(TemplateConfig, CanvasRatio, std::string, "", NLEFeature::TBASE);

    public:
        TemplateConfig();
        virtual ~TemplateConfig();

    };
}

#endif /* TemplateConfig_hpp */
