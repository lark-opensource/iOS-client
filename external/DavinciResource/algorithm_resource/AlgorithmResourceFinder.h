//
// Created by bytedance on 2021/4/21.
//

#ifndef DAVINCIRESOURCE_ALGORITHMFINDER_H
#define DAVINCIRESOURCE_ALGORITHMFINDER_H

#include <string>
#include <unordered_set>
#include <mutex>
#include "IBuildInModelFinder.h"

namespace davinci {
    namespace algorithm {

        class AlgorithmResourceFinder {
        public:
            static char *resourceFinder(void *handle, const char *dir, const char *name);
        };
    }
}


#endif //DAVINCIRESOURCE_ALGORITHMFINDER_H
