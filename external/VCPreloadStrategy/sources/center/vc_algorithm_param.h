//
// Created by 黄清 on 1/15/21.
//

#ifndef VC_ALGORITHM_PARAM_H
#define VC_ALGORITHM_PARAM_H

#pragma once

#include "vc_base.h"
#include "vc_json.h"

VC_NAMESPACE_BEGIN

namespace VCAlgorithmParam {

namespace Key {
extern const char *COMMON_CONFIG;
extern const char *PRELOAD_CONFIG;
extern const char *PLAY_CONTROL;
extern const char *ABR;
extern const char *PRELOAD;
extern const char *MODULE;
extern const char *PLAY_LOAD;
extern const char *BANDWIDTH;
extern const char *SELECT_BITRATE;
} // namespace Key

enum class Type : int {
    Preload = 0,
    PlayControl = 1,
    ABR = 2,
};

extern const char *ENGINE_DEFAULT_SCENE_ID;

bool ParseJson(const VCJson &json,
               const std::string &sceneId,
               Type type,
               std::string &resultJson);
bool ParseName(const std::string &json, std::string &resultName);

bool _parseModuleKey(VCJson &json, const std::string &key, VCJson &resultValue);

template <typename T>
bool ParseModuleKey(const std::string &json,
                    const std::string &key,
                    T &resultValue) {
    VCJson outValue;
    VCJson root = VCJson::parse(json);
    if (root.isInvalid()) {
        LOGE("[center] parse module key failed, json is invalid: %s",
             json.c_str());
        return false;
    }
    bool ret = _parseModuleKey(root, key, outValue);
    ret = ret && outValue.template getTo(resultValue);
    return ret;
}

template <typename T>
bool ParseModuleKey(VCJson &json, const std::string &key, T &resultValue) {
    VCJson outValue;
    bool ret = _parseModuleKey(json, key, outValue);
    ret = ret && outValue.template getTo(resultValue);
    return ret;
}

} // namespace VCAlgorithmParam

VC_NAMESPACE_END

#endif // VC_ALGORITHM_PARAM_H
