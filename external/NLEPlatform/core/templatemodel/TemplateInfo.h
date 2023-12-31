//
//  TemplateInfo.hpp
//  TemplateConsumer
//
//  Created by Lemonior on 2021/9/23.
//

#ifndef TemplateInfo_hpp
#define TemplateInfo_hpp

#include <vector>
#include <string>
#include <memory>

#include "TemplateConfig.h"
#include "NLEMappingNode.h"
#include "NLENode.h"
#include "NLESequenceNode.h"

namespace cut::model {
    /**
     *  模版的统一数据模型
     */
    class NLE_EXPORT_CLASS TemplateInfo: public NLENode {
        NLENODE_RTTI(TemplateInfo);
        KEY_FUNCTION_DEC_OVERRIDE(TemplateInfo)

        /**
         * 模板ID
         */
        NLE_PROPERTY_DEC(TemplateInfo, TemplateId, std::string, "", NLEFeature::TBASE)
        /**
         * 模板名
         */
//        这里 override 了 NLENode基类中的Name成员，直接使用 NLENode Name 成员就可以
//        NLE_PROPERTY_DEC(TemplateInfo, Name, std::string, "", NLEFeature::TBASE)

        /**
         * 关键字
         */
         NLE_PROPERTY_DEC(TemplateInfo, Tag, std::string, "", NLEFeature::TBASE)
        /**
         * 模板封面
         */
        NLE_PROPERTY_OBJECT(TemplateInfo, CoverModel, NLEVideoFrameModel, NLEFeature::TBASE)

        /**
         * 模板描述
         */
        NLE_PROPERTY_DEC(NLETemplaTemplateInfoteModel, Desc, std::string, "", NLEFeature::TBASE)
        /**
         * 模板标题
         */
        NLE_PROPERTY_DEC(TemplateInfo, Title, std::string, "", NLEFeature::TBASE)
        /**
         * 配置
         */
        NLE_PROPERTY_OBJECT(TemplateInfo, Config, TemplateConfig, NLEFeature::TBASE)
        /**
         * 可变信息
         */
        NLE_PROPERTY_OBJECT_LIST(TemplateInfo, MutableItems, NLEMappingNode, NLEFeature::TBASE)


    public:
        TemplateInfo();
        virtual ~TemplateInfo();

        /**
         *  提供templateinfo序列化反序列化能力
         */
        std::string store();
        static std::shared_ptr<TemplateInfo> restore(const std::string &source);

        /**
         *  读写封面素材，实际指向CoverModel中的CoverMaterial->Image
         *  set时会创建新的CoverModel，覆盖原有的数据
         */
        void setCoverRes(const std::shared_ptr<cut::model::NLEResourceNode> &node);
        std::shared_ptr<cut::model::NLEResourceNode> getCoverRes() const;
    };
}

#endif /* TemplateInfo_hpp */

