//
//  EffectTypeHelper.hpp
//  VideoTemplate
//
//  Created by lxp on 2020/2/12.
//

#ifndef EffectTypeHelper_hpp
#define EffectTypeHelper_hpp
#include <TemplateConsumer/TemplateModel.h>
#include <cdom/ModelType.h>
#include <TemplateConsumer/MaterialEffect.h>


namespace cut {

class EffectPlatformHelper {
public:
    // Loki剪映业务线有一个 panel="integration" 的栏目，存放了我们要的"内置的资源"
    static const std::string InnerPanelName;
    static const std::string EFFECT_VERSION_V1;
    static std::string getResourceIdForInnerType(cdom::MaterialType type, const std::string &version = "");
    
    static std::string getAnimtionPanelName(const std::shared_ptr<CutSame::TemplateModel>& project, const std::string &animMaterialId);
    static std::string getEffectPlatformPanelName(cdom::MaterialType materialType);
    static cdom::MaterialType getMaterialType(std::string panel);
    static std::string getStickerPanelName(const std::string &stickerCategoryId);
    static std::string getFolderName(const cdom::MaterialType &type);
    static bool isOriginalFilter(std::shared_ptr<CutSame::MaterialEffect> effect);
    
    static cdom::EffectSourcePlatformType getEffectSourcePlatformType(const int64_t rawValue);
    static std::string getEffectSourcePlatformTypeName(const cdom::EffectSourcePlatformType type);
    
    static void updateEnvironment(bool isBOE);

private:
    static std::string _getBOEResourceIdForInnerType(cdom::MaterialType type);
};

}

#endif /* EffectTypeHelper_hpp */
