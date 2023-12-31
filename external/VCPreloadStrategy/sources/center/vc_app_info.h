//
// Created by 黄清 on 12/19/20.
//

#ifndef VIDEOENGINE_VC_APP_INFO_H
#define VIDEOENGINE_VC_APP_INFO_H
#pragma once

#include "vc_base.h"
#include "vc_define.h"
#include "vc_dynamic_config_handler.h"
#include "vc_info.h"
#include "vc_shared_mutex.h"
#include <mutex>
#include <unordered_map>

VC_NAMESPACE_BEGIN

class VCAppInfo : public VCInfo {
public:
    VCAppInfo();
    ~VCAppInfo() override = default;

public:
    int setIntValue(int key, int value) override;
    int64_t getInt64Value(int key, int64_t dValue = -1) const override;
    int getIntValue(int key, int dValue = -1) const override;
    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const override;
    int setStrValue(int key, const std::string &value) override;

public:
    static bool AppInfo(const std::string &jsonString, VCAppInfo *appInfo);

private:
    std::string mAppId;
    std::string mAppName;
    volatile int mAppState{AppStateForeground};
    int64_t mAppStateUpdateTS{0};

    std::string mSessionId;
    mutable std::mutex mSessionIdMutex;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCAppInfo);
};

class VCSettingInfo : public VCInfo {
public:
    VCSettingInfo();
    ~VCSettingInfo() override;

public:
    void
    startDynamicUpdateCheck(const std::shared_ptr<MessageTaskRunner> &runner,
                            IVCMessageSender *messageSender);
    int setIntValue(int key, int value) override;
    int getIntValue(int key, int dValue = -1) const override;
    int setStrValue(int key, const std::string &value) override;
    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const override;
    void parse(VCStrCRef jsonStr);
    std::string getModuleDynamicConfig(VCKey configKey);

public:
    std::unordered_map<int, VCString> getAlgoString();

private:
    mutable shared_mutex mSharedMutex;
    std::unordered_map<int, VCString> mStringValue;
    std::unordered_map<int, int> mIntValue;

    VCDynamicConfigHandler mDynamicConfigHandler;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCSettingInfo);
};

VC_NAMESPACE_END

#endif // VIDEOENGINE_VC_APP_INFO_H
