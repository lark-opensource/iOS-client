//
// Created by wangchengyi.1 on 2021/4/11.
//

#ifndef DAVINCIRESOURCEDEMO_DAVPUBLICUTIL_H
#define DAVINCIRESOURCEDEMO_DAVPUBLICUTIL_H

#include "DAVPubDefine.h"
#include <vector>
#include <unordered_map>

namespace davinci {
    namespace resource {
        class DAV_EXPORT DAVPublicUtil {
        private:
            static void hexChar(unsigned char c, unsigned char &hex1, unsigned char &hex2);

            static char fromHex(char ch);

        public:
            static std::string urlEncode(const std::string& s);

            static std::string urlDecode(const std::string &s);

            static std::string map_to_query_params(const std::unordered_map<std::string, std::string> &map, bool withEncode = true);

            static std::vector<std::string> split(const std::string &str, const std::string &delim);

            static std::unordered_map<std::string, std::string> query_params_to_map(const std::string &queryString);

            static std::string
            vector_join_to_string(const std::vector<std::string> &vecString, const std::string &delim,
                                  const std::string &start = "", const std::string &end = "");
        };
    }
}
#endif //DAVINCIRESOURCEDEMO_DAVPUBLICUTIL_H
