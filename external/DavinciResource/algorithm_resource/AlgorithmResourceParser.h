//
// Created by wangchengyi.1 on 2021/4/7.
//

#ifndef DAVINCIRESOURCE_ALGORITHMRESOURCEPARSER_H
#define DAVINCIRESOURCE_ALGORITHMRESOURCEPARSER_H

#include <string>
#include <unordered_map>
#include <unordered_set>
#include "IRequirementsPeeker.h"
#include "DAVResourceIdParser.h"
#include <vector>

namespace davinci {
    namespace algorithm {
        class AlgorithmResourceParser : public davinci::resource::DAVResourceIdParser {
        public:
            AlgorithmResourceParser(const std::shared_ptr<IRequirementsPeeker> &peeker,
                                    const resource::DavinciResourceId &resourceId);

            std::unordered_set<std::string> modelNames = {};
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMRESOURCEPARSER_H
