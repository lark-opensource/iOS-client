//
// Created by bytedance on 2021/4/21.
//

#ifndef DAVINCIRESOURCE_ALGORITHMIREQUIREMENTSPEEKER_H
#define DAVINCIRESOURCE_ALGORITHMIREQUIREMENTSPEEKER_H

#include <string>
#include <vector>
#include <memory>

namespace davinci {
    namespace algorithm {

        class IRequirementsPeeker {
        public:
            virtual std::vector<std::string> peekRequirements(const std::vector<std::string> &requirements) = 0;
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMIREQUIREMENTSPEEKER_H
