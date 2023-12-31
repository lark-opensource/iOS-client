//
// Created by bytedance on 2021/4/21.
//

#ifndef DAVINCIRESOURCE_ALGORITHMBUILDINMODELFINDER_H
#define DAVINCIRESOURCE_ALGORITHMBUILDINMODELFINDER_H

#include <string>

namespace davinci {
    namespace algorithm {

        class IBuildInModelFinder {
        public:
            virtual std::string findModelUri(const std::string &modelName) = 0;

            virtual bool isBuildInModel(const std::string &modelName,
                                        const std::string &version,
                                        long size) = 0;
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMBUILDINMODELFINDER_H
