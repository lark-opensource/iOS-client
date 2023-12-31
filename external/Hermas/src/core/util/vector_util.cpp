//
//  vector_util.cpp
//  Hermas
//
//  Created by liuhan on 2022/5/25.
//

#include "vector_util.h"

namespace hermas {
std::string VectorToString(std::vector<std::string>& vec, const std::string& delimiter) {
    std::string str;
    for (std::string& piece : vec) {
        str += piece + delimiter;
    }
    str = str.substr(0, str.size() - 1);
    return str;
}

bool IsVectorHasAssignedKey(std::vector<std::string>& vec, const std::string& key) {
    if ((std::find(vec.begin(), vec.end(), key)) != vec.end()) {
        return true;
    } else {
        return false;
    }
}
}

