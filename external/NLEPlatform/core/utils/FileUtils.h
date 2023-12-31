//
// Created by bytedance on 2019-12-09.
//

#ifndef CUTSAMEAPP_FILEUTILS_H
#define CUTSAMEAPP_FILEUTILS_H

#include <string>
#include "nle_export.h"

namespace cut {
    namespace utils {

        class NLE_EXPORT_CLASS FileUtils {
        public:
            static std::string getFileNameFromPath(const std::string &filePath);

            static std::string getParentFilePath(const std::string &filePath);

            static bool isFileExist(const std::string &filePath);

            static std::string joinFileSeparator(const std::string &filePath);

            static bool copyFile(const std::string& src, const std::string& dst);

            static bool writeToFile(const std::string& content, const std::string& dest);

            static std::string readFile(const std::string& src);

            static const char * readFileContent(const std::string &path, long &size);

            static std::string getFontPath(const std::string &fontDir);
        };

    }
}


#endif //CUTSAMEAPP_FILEUTILS_H
