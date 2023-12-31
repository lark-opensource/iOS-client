//
//  MaterialsUtils.hpp
//  LVTemplate
//
//  Created by ZhangYuanming on 2020/2/13.
//

#ifndef MaterialsUtils_hpp
#define MaterialsUtils_hpp

#include <stdio.h>
#include <vector>
#include <TemplateConsumer/Materials.h>
#include <TemplateConsumer/Material.h>
#include <cdom/ModelType.h>

namespace cut {

    struct MaterialsUtils {
        
    public:
        
        static std::vector<std::shared_ptr<CutSame::Material>> getAllMaterials(std::shared_ptr<CutSame::Materials> materials);

        static cdom::MaterialType getMaterialType(const std::shared_ptr<CutSame::Material> &material);
        
        static cdom::MaterialType getMaterialTypeForString(const std::string &typeString);
        
        static std::string getMaterailTypeString(cdom::MaterialType type);
        
    private:        
        template<typename T>
        static void __append(std::vector<std::shared_ptr<CutSame::Material>> &list, const std::vector<T> &materials) {
            for (auto &material: materials) {
                if (material != nullptr) {
                    list.push_back(material);
                }
            }
        };
    };
}

#endif /* MaterialsUtils_hpp */
