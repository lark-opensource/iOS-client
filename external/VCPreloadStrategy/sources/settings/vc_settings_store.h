//
// Created by 黄清 on 3/16/21.
//

#ifndef PRELOAD_VC_SETTINGS_STORE_H
#define PRELOAD_VC_SETTINGS_STORE_H

#include "vc_base.h"
#include <mutex>

#include "vc_json.h"

VC_NAMESPACE_BEGIN

class VCSettingsStore {
public:
    VCSettingsStore(const std::string &jsonString);
    ~VCSettingsStore();

public:
    void updateJson(const std::string &jsonString);
    VCJson getJsonObject() const;

public:
    template <typename T>
    T getValue(const std::string &key, const T &dValue) const {
        std::lock_guard<std::mutex> guard(mMutex);
        return mJsonObject.template value(key, dValue);
    }

private:
    void _updateJson(const std::string &jsonString);

private:
    VCJson mJsonObject;
    mutable std::mutex mMutex;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCSettingsStore);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_SETTINGS_STORE_H
