//
// Created by 黄清 on 3/16/21.
//

#ifndef PRELOAD_VC_SETTINGS_H
#define PRELOAD_VC_SETTINGS_H

#include "vc_base.h"
#include "vc_setting_key.h"
#include "vc_settings_store.h"
#include <map>
#include <memory>

VC_NAMESPACE_BEGIN

class VCSettings {
public:
    static VCSettings &share() {
        [[clang::no_destroy]] static VCSettings s_singleton;
        return s_singleton;
    }

public:
    void storeJson(std::string &module, std::string &jsonString);
    VCJson getJson(int module) const;

public:
    template <typename T>
    T getVodValue(const std::string &key, const T &dValue) const {
        return mStores.at(VCSettingKey::VOD)->template getValue(key, dValue);
    }

    template <typename T>
    T getMDLValue(const std::string &key, const T &dValue) const {
        return mStores.at(VCSettingKey::MDL)->template getValue(key, dValue);
    }

private:
    std::map<int, std::shared_ptr<VCSettingsStore>> mStores;

private:
    VCSettings();
    ~VCSettings();

private:
    VC_DISALLOW_COPY_AND_ASSIGN(VCSettings);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_SETTINGS_H
