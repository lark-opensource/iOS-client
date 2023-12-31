//
//  json_util.h
//  Hermas
//
//  Created by 崔晓兵 on 11/3/2022.
//

#ifndef json_util_hpp
#define json_util_hpp

#include <memory>
#include "json.h"

namespace hermas {
std::unique_ptr<Json::Value> JSONObjectWithString(const std::string& s);

bool ParseFromJson(const std::string& json, Json::Value& root);
}

#endif /* json_util_hpp */
