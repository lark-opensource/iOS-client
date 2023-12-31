//
//  vc_device_info.h

#ifndef vc_device_info_h
#define vc_device_info_h
#pragma once

#include "vc_info.h"
#include <mutex>

VC_NAMESPACE_BEGIN

class VCDeviceInfo : public VCInfo {
public:
    VCDeviceInfo();
    ~VCDeviceInfo() override;

public: /// Info
    int setIntValue(int key, int value) override;
    int getIntValue(int key, int dValue = -1) const override;

    VCString getStrValue(int key, VCStrCRef dValue = VCString()) const override;
    int setStrValue(int key, const std::string &value) override;

public:
    static bool DeviceInfo(const std::string &jsonString,
                           VCDeviceInfo *deviceInfo);

public:
    int mMachineCapability{0};
    int mHDRInfo{0};
    int mScreenWidth{0};
    int mScreenHeight{0};

private:
    mutable std::mutex mMutex;
    std::string mDeviceId;
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCDeviceInfo);
};

VC_NAMESPACE_END

#endif /* vc_device_info_h */
