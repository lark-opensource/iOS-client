//
// Created by bytedance on 2021/4/21.
//

#ifndef DAVINCIRESOURCE_ALGORITHMGLOBALSETTINGS_H
#define DAVINCIRESOURCE_ALGORITHMGLOBALSETTINGS_H

#include <string>
#include "IRequirementsPeeker.h"
#include "IBuildInModelFinder.h"

namespace davinci {
    namespace algorithm {

        typedef char* (*resource_finder)(void *, const char*, const char*);

        class AlgorithmResourceGlobalSettings {
        private:
            std::shared_ptr<IRequirementsPeeker> requirementsPeeker = nullptr;
            std::shared_ptr<IBuildInModelFinder> buildInModelFinder = nullptr;
        public:
            static void setRequirementsPeeker(std::shared_ptr<IRequirementsPeeker> requirementsPeeker);

            static void setBuildInModelFinder(std::shared_ptr<IBuildInModelFinder> buildInModelFinder);

            static std::shared_ptr<IRequirementsPeeker> getRequirementsPeeker();

            static std::shared_ptr<IBuildInModelFinder> getBuildInModelFinder();

            static resource_finder getResourceFinder();

            static AlgorithmResourceGlobalSettings *obtain();
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMGLOBALSETTINGS_H
