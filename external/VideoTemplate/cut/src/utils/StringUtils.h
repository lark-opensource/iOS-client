//
// Created by zhangyeqi on 2019-12-05.
//

#ifndef CUTSAMEAPP_STRINGUTILS_H
#define CUTSAMEAPP_STRINGUTILS_H

#include <string>
#include <vector>

using std::string;
using std::vector;

namespace asve {
    class StringUtils {
    public:
        static bool startWith(const string& target, const string& prefix);

        /**
         * 根据分割符进行字符串分割
         * @param str exp: "7.0.0"
         * @param delim exp: "."
         * @return {"7", "0", "0"}
         */
        static vector<string> split(const string& str, const string& delim);
    };
}


#endif //CUTSAMEAPP_STRINGUTILS_H
