//
// Created by bytedance.1 on 2021/4/11.
//

#ifndef NLEPLATFORM_RESOURCE_NLEPUBLICUTIL_H
#define NLEPLATFORM_RESOURCE_NLEPUBLICUTIL_H

#include "NLEResourcePubDefine.h"
#include <vector>
#include <unordered_map>
#include "nle_export.h"

namespace nle {
    namespace resource {
        class NLE_EXPORT_CLASS NLEResourceUtil {
        private:
            static void hexChar(unsigned char c, unsigned char &hex1, unsigned char &hex2);

            static std::string urlEncode(const std::string& s);

        public:
            static std::string map_to_query_params(const std::unordered_map<std::string, std::string> &map, bool withEncode = true);

            static std::vector<std::string> split(const std::string &str, const std::string &delim);

            static std::unordered_map<std::string, std::string> query_params_to_map(const std::string &queryString);

            static std::string
            vector_join_to_string(const std::vector<std::string> &vecString, const std::string &delim,
                                  const std::string &start = "", const std::string &end = "");
        };
    }
}
#endif //NLEPLATFORM_RESOURCE_NLEPUBLICUTIL_H
