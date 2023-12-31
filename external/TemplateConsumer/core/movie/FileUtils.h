//
// Created by 天 on 2019-12-09.
//

#ifndef CUTSAMEAPP_FILEUTILS_H
#define CUTSAMEAPP_FILEUTILS_H

#include <string>

namespace TemplateConsumer {
    namespace utils {

        class FileUtils {
        public:
            static bool isFileExist(const std::string &filePath);
        };

    }
}


#endif //CUTSAMEAPP_FILEUTILS_H
