//
//  vector_util.hpp
//  Hermas
//
//  Created by liuhan on 2022/5/25.
//

#ifndef vector_util_h
#define vector_util_h

#include <stdio.h>
#include <string>
#include <vector>

namespace hermas {

std::string VectorToString(std::vector<std::string>& vec, const std::string& delimiter);

bool IsVectorHasAssignedKey(std::vector<std::string>& vec, const std::string& key);

}

#endif /* vector_util_hpp */
