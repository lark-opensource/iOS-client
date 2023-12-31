//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_ALGORITHMRESOURCE_H
#define DAVINCIRESOURCE_ALGORITHMRESOURCE_H

#include <string>
#include <vector>
#include "DAVResourceProtocol.h"

namespace davinci {
    namespace algorithm {

        // dav://algorithm_resource?requirements=xxx&model_names=xxxx&busi_id(可选)
        class DAV_EXPORT AlgorithmResourceProtocol : public davinci::resource::DAVResourceProtocol {

        public:
            ENUM_STR_INTERFACE(PLATFORM_STRING)
            ENUM_STR_INTERFACE(PARAM_REQUIREMENTS);
            ENUM_STR_INTERFACE(PARAM_MODEL_NAME_MAP_STRING);
            ENUM_STR_INTERFACE(PARAM_MODEL_NAME);
            ENUM_STR_INTERFACE(PARAM_BUSI_ID);

            AlgorithmResourceProtocol(std::vector<std::string> requirements, std::string modelNameMapString);

            AlgorithmResourceProtocol(std::string modelName);

            std::string getSourceFrom() override;

            std::unordered_map<std::string, std::string> getParameters() override;

            static bool isAlgorithmResource(const davinci::resource::DavinciResourceId &resourceId);

        private:
            std::vector<std::string> requirements;
            std::string modelName;
            std::string modelNameMapString;
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMRESOURCE_H
