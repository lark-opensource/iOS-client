//
//  json_util.cpp
//  Hermas
//
//  Created by 崔晓兵 on 11/3/2022.
//

#include "json_util.h"


using namespace hermas::Json;

namespace hermas {

std::unique_ptr<Value> JSONObjectWithString(const std::string& s) {
    Json::CharReaderBuilder readerBuilder;
    Json::String error;
    Json::Value root;

    std::unique_ptr<Json::CharReader> reader(readerBuilder.newCharReader());
    if (reader->parse(s.c_str(), s.c_str() + s.length(), &root, &error)) {
        return std::make_unique<Value>(std::move(root));
    }
    return std::unique_ptr<Value>();
}
    
bool ParseFromJson(const std::string& json, Json::Value& root) {
    Json::CharReaderBuilder readerBuilder;
    Json::String error;
    std::unique_ptr<Json::CharReader> reader_ptr(readerBuilder.newCharReader());
    if (!reader_ptr->parse(json.c_str(), json.c_str() + json.length(), &root, &error)) {
        return false;
    } else {
        return true;
    }
}
}

