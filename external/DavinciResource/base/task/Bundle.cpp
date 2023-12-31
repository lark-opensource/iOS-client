//
// Created by wangchengyi.1 on 2021/5/10.
//

#include "Bundle.h"

using davinci::task::BaseModel;
using davinci::task::Bundle;

Bundle::Bundle() {

}

void Bundle::putString(const std::string &key, const std::string &value) {
    std::unique_lock<std::recursive_mutex> lock(mutex);
    stringMap[key] = value;
}

std::string Bundle::getString(const std::string &key, const std::string &defaultValue) const {
    if (stringMap.find(key) != stringMap.end()) {
        return stringMap.at(key);
    }
    return defaultValue;
}

void Bundle::putModel(const std::string &key, const std::shared_ptr<BaseModel> &value) {
    std::unique_lock<std::recursive_mutex> lock(mutex);
    modelMap[key] = value;
}

std::shared_ptr<BaseModel> Bundle::getModel(const std::string &key, const std::shared_ptr<BaseModel> &defaultValue) const {
    if (modelMap.find(key) != modelMap.end()) {
        return modelMap.at(key);
    }
    return defaultValue;
}
