//
//  LVProject+Query.hpp
//  VideoTemplate
//
//  Created by luochaojing on 2020/1/17.
//

#ifndef LVProject_Query_hpp
#define LVProject_Query_hpp

#include <stdio.h>
#include <TemplateConsumer/TemplateModel.h>
#include <TemplateConsumer/Segment.h>
#include <TemplateConsumer/MaterialEffect.h>
#include <TemplateConsumer/MaterialCanvas.h>
#include <cdom/ModelType.h>
#include <utils/ProjectUtils.h>
#include <utils/MaterialsUtils.h>

using namespace CutSame;

namespace cut {

struct SegmentQuery {
public:
    static const int DefaultVolume = 1.0;
    static const int MaxVolume = 10.0;
    static const int VEDefaultVolume = 1;
    constexpr static float VEMaxVolume = {10.0};
    
    static float actualVolume(std::shared_ptr<Segment> &segment);
    
    static cdom::MaterialType segmentType(std::shared_ptr<Segment> &segment);
    
    static std::shared_ptr<Material> mainMaterial(std::shared_ptr<Segment> &segment);
    
    static std::shared_ptr<Material> materialForType(std::shared_ptr<Segment> &segment, cdom::MaterialType type);
    
    template<typename M>
    static std::shared_ptr<M> actualMainMaterial(std::shared_ptr<Segment> &segment) {
        auto material = segment->get_main_material();
        auto _matrial = std::dynamic_pointer_cast<M>(material);
        if (_matrial == nullptr) {
            return nullptr;
        }
        return _matrial;
    }
    
    template<typename M>
    static std::shared_ptr<M> extraMaterialOfType(std::shared_ptr<Segment> &segment, cdom::MaterialType type) {
        for (auto &material: segment->get_extra_materials()) {
            if (material == nullptr) {
                continue;
            }
            if (MaterialsUtils::getMaterialType(material) != type) {
                continue;
            }
            auto _material = std::dynamic_pointer_cast<M>(material);
            if (_material == nullptr) {
                continue;
            }
            return _material;
        }
        return nullptr;
    };
    
    template<typename M>
    static std::vector<std::shared_ptr<M>> extraMaterialsOfType(std::shared_ptr<Segment> &segment, cdom::MaterialType type) {
        std::vector<std::shared_ptr<M>> list;
        auto materials = segment->get_extra_materials();
        for (auto &material: materials) {
            if (material == nullptr) {
                continue;
            }
            if (MaterialsUtils::getMaterialType(material) != type) {
                continue;
            }
            auto _material = std::dynamic_pointer_cast<M>(material);
            if (_material == nullptr) {
                continue;
            }
            list.push_back(_material);
        }
        return list;
    };
    
    template<typename M>
    static std::vector<std::shared_ptr<M>> extraMaterials(std::shared_ptr<Segment> &segment) {
        std::vector<std::shared_ptr<M>> list;
        auto materials = segment->get_extra_materials();
        
        for (auto &material: materials) {
            if (material == nullptr) {
                continue;
            }
            auto _material = std::dynamic_pointer_cast<M>(material);
            if (_material == nullptr) {
                continue;
            }
            list.push_back(_material);
        }
        return list;
    }
    
    template<typename M>
    static std::shared_ptr<M> firstMaterial(std::shared_ptr<Segment> &segment) {
        auto list = SegmentQuery::extraMaterials<M>(segment);
        if (list.size() >= 1) {
            return list[0];
        }
        return nullptr;
    }
    
    static std::vector<std::shared_ptr<CutSame::MaterialEffect>> adjustsMaterials(std::shared_ptr<Segment> &segment) {
        std::vector<std::shared_ptr<CutSame::MaterialEffect>> list;
        auto materials = segment->get_extra_materials();
        for (auto &material: materials) {
            if (material == nullptr) {
                continue;
            }
            auto _material = std::dynamic_pointer_cast<MaterialEffect>(material);
            if (_material == nullptr) {
                continue;
            }
            auto type = MaterialsUtils::getMaterialType(_material);
            if (type >= cdom::MaterialTypeBrightness && type <= cdom::MaterialTypeParticle) {
                list.push_back(_material);
            }
        }
        return list;
    }
    
    static std::shared_ptr<MaterialCanvas> canvasMaterial(std::shared_ptr<Segment> &segment) {
        auto extraMaterials = segment->get_extra_materials();
        for (auto &material: extraMaterials) {
            if (material == nullptr) { continue; }
            auto type = MaterialsUtils::getMaterialType(material);
            if (SegmentQuery::__isCanvasMaterialType(type)) {
                return std::dynamic_pointer_cast<MaterialCanvas>(material);
            }
        }
        return nullptr;
    }
    
private:
    static bool __isCanvasMaterialType(cdom::MaterialType type) {
        if (type == cdom::MaterialTypeSegmentCanvas ||
            type == cdom::MaterialTypeCanvasColor ||
            type == cdom::MaterialTypeCanvasImage ||
            type == cdom::MaterialTypeCanvasBlur) {
            return true;
        }
        return false;
    }
};
}

#endif /* LVProject_Query_hpp */
