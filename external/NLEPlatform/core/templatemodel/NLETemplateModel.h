//
//  NLETemplateModel.hpp
//  TemplateConsumer
//
//  Created by Charles on 2021/9/5.
//

#ifndef NLETemplateModel_hpp
#define NLETemplateModel_hpp

//#include <stdio.h>
//#ifdef __V_IPHONE_PLATFORM__
//#include <NLEPlatform/NLENodeDecoder.h>
//#include <NLEPlatform/NLENode.h>
//#include <NLEPlatform/NLESequenceNode.h>
//#include <NLEPlatform/NLEError.h>
//#else
//#include <NLENodeDecoder.h>
//#include <NLENode.h>
//#include <NLESequenceNode.h>
//#include <NLEError.h>
//#endif

#include "TemplateInfo.h"
#include "NLENodeDecoder.h"
#include "NLENode.h"
#include "NLESequenceNode.h"
#include "NLEError.h"
#include "NLETemplateZipProgressHandler.h"

#include <vector>
#include <string>

static const std::string NLE_TEMPLATE_JSON_FILENAME = "NLETemplate.json";

using cut::model::NLENode;
using cut::model::NLEModel;
using cut::model::NLENodeDecoder;
using cut::model::NLEValueProperty;
using cut::model::NLEObjectListProperty;
using cut::model::NLEObjectProperty;

namespace cut::model {
    /**
     *  模版的统一数据模型
     */
    class NLE_EXPORT_CLASS NLETemplateModel : public NLEModel {
    NLENODE_RTTI(NLETemplateModel);
    KEY_FUNCTION_DEC_OVERRIDE(NLETemplateModel)

        /**
         * 模板基础信息
         */
        NLE_PROPERTY_OBJECT(TemplateInfo, TemplateInfo, TemplateInfo, NLEFeature::TBASE)

    protected:

    private:

        void findNode(const std::map<std::string, std::shared_ptr<NLENode>>& children, const std::vector<std::string> &uuids, std::vector<std::shared_ptr<cut::model::NLENode>> &allNode) const;

        std::vector<std::shared_ptr<cut::model::NLESegment>> getAllSegmentsInNode(std::shared_ptr<cut::model::NLENode> &node) const;

        /// 获取所有可变信息的UUID
        std::vector<std::string> allMutableItemUUIDs() const;

        /// 生成UUID
        std::string generateUUID();
        
    public:
        NLETemplateModel();
        virtual ~NLETemplateModel();

        /*
         * 序列化
         * zipFolder为生成zip包的目录，resourceFolder为未上云资源所在的资源包目录
         * zip包以templateInfo中的templateID命名，没有则以UUID为准
         */
        std::string storeToZip(const std::string &zipFolder, const std::string &resourceFolder, std::shared_ptr<NLEBaseTemplateZipProgressHandler> progressHandler);
        std::string store();

        static std::shared_ptr<NLETemplateModel> restore(const std::string &source);

        /// 从某个json路径恢复草稿模型
        static std::shared_ptr<NLETemplateModel> restoreFromPath(const std::string &jsonPath);

        static std::shared_ptr<NLETemplateModel> createFromDraft(const std::shared_ptr<NLEModel> &draft);
        
        /// 获取当前的featureList
        static std::unordered_set<TNLEFeature> featureListInTemplateModel(const std::string &templateJSON);

        static std::vector<uint32_t> getSupportFeatureBits();

        static int getFeatureIndex(const TNLEFeature &feature);

        /// 获取可变素材
        std::vector<std::shared_ptr<cut::model::NLETrackSlot>> getMutableAssetItems() const;
        std::vector<std::shared_ptr<cut::model::NLETrackSlot>> getMutableTextItems() const;
        std::vector<std::shared_ptr<cut::model::NLENode>> getAllMutableItems() const;
        
        std::shared_ptr<cut::model::NLEMappingNode> convertNLEMappingNode(std::shared_ptr<cut::model::NLENode> &segment);

        /// 获取文字模板槽位内所有可变文本
        std::vector<std::shared_ptr<cut::model::NLETextTemplateClip>> getAllMutableTextClipsFromSlot(std::shared_ptr<cut::model::NLETrackSlot> slot) const;

        /// 获取画幅比
        NLESize getTemplateCanvasSize() const;
        
        /// 替换素材路径
        void updateResourcePath(const std::string &slotUUID, const std::string &resourceURS) const;
    };
}


#endif /* NLETemplateModel_hpp */
