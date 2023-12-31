//
// Created by 黄清 on 2022/9/20.
//

#ifndef PRELOAD_VC_PLAYER_INFO_H
#define PRELOAD_VC_PLAYER_INFO_H
#pragma once

#include "vc_info.h"
#include "vc_json.h"
#include "vc_shared_mutex.h"
#include "vc_utils.h"
#include <unordered_map>

VC_NAMESPACE_BEGIN

//
enum OnePlayKey : int {
    // - int
    OnePlayKeyValueInt = 50000,
    OnePlayKeyRelatedPreloadFinished = 50001,
    OnePlayKeyHasFirstBlockIOSent = 50002,
    OnePlayKeyHasFirstBlockIOExecuted = 50003,
    OnePlayKeyPreloadFinishedForFirstTime = 50004,
    OnePlayKeyHasRenderStart = 50005,
    // - int64
    OnePlayKeyValueInt64 = 52000,
    OnePlayKeyAudioRangeSize = 52001,
    OnePlayKeyVideoRangeSize = 52002,
    OnePlayKeyHitVideoCacheSize = 52003,
    OnePlayKeyHitAudioCacheSize = 52004,
    OnePlayKeyLastBlockBandwidth = 52005,
    OnePlayKeyFistFrameBandwidth = 52006,

    // - float
    OnePlayKeyValueFloat = 54000,
    // - ptr
    OnePlayKeyValuePtr = 55000,
    // - string
    OnePlayKeyValueString = 56000,
    OnePlayKeyMediaId = 56001,
    OnePlayKeySceneId = 56002,
    OnePlayKeyTag = 56003,
    OnePlayKeyTraceId = 56004,
    OnePlayKeySessionId = 56005,
    // - sharedPtr
    OnePlayKeyValueSharedPtr = 57000,
    OnePlayKeyPlayBufferStatusVars = 57001,
    // - end
    OnePlayKeyValueEnd = 58000,
};

enum BandwidthType {
    BandwidthTotalAvg = 1,
    BandwidthTotalStd = 2,
    BandwidthBlockAvg = 3,
    BandwidthBlockStd = 4,
};

using VoidPtr = std::shared_ptr<void>;

class VCPlayerInfo : IVCPrintable {
public:
    typedef std::shared_ptr<VCPlayerInfo> Ptr;
    VCPlayerInfo() = default;
    ~VCPlayerInfo() override;

public:
    template <typename T>
    int setValue(int key, const T &value) {
        int ret = S_FAIL;
        if (key > OnePlayKeyValueInt && key < OnePlayKeyValueEnd) {
            std::lock_guard<shared_mutex> lockGuard(mMutex);
            mValue[ToString(key)] = value;
            ret = S_OK;
        }
        return ret;
    }

    template <typename T>
    T getValue(int key, const T &dVal) const {
        T retVal = dVal;
        if (key > OnePlayKeyValueInt && key < OnePlayKeyValueEnd) {
            shared_lock<shared_mutex> lock(mMutex);
            if (mValue.contains(ToString(key))) {
                retVal = mValue.template value(ToString(key), retVal);
            }
        }
        return retVal;
    }

    int setSharedPtrValue(int key, VoidPtr value);
    VoidPtr getSharedPtrValue(int key, VoidPtr dVal = nullptr) const;

    void putBandwidthSample(double sample, bool isBlock = false) {
        if (!isBlock) {
            if (getValue(OnePlayKeyHasRenderStart, 0)) {
                std::lock_guard<shared_mutex> lock(mMutex);
                bandTotalStatHelper.putItem(sample);
            }
        } else {
            std::lock_guard<shared_mutex> lock(mMutex);
            bandBlockStatHelper.putItem(sample);
        }
    }

    std::map<BandwidthType, double> getBandwidthSampleRet(void) {
        shared_lock<shared_mutex> lock(mMutex);
        std::map<BandwidthType, double> ret;
        double tmp = bandTotalStatHelper.getAvg();
        ret[BandwidthTotalAvg] = std::isnan(tmp) ? -1 : tmp;
        tmp = bandTotalStatHelper.getStdDev();
        ret[BandwidthTotalStd] = std::isnan(tmp) ? -1 : tmp;
        tmp = bandBlockStatHelper.getAvg();
        ret[BandwidthBlockAvg] = std::isnan(tmp) ? -1 : tmp;
        tmp = bandBlockStatHelper.getStdDev();
        ret[BandwidthBlockStd] = std::isnan(tmp) ? -1 : tmp;
        return ret;
    }

public:
    std::string toString() const override;

protected:
    mutable shared_mutex mMutex;

private:
    VCJson mValue;
    std::unordered_map<int, std::shared_ptr<void>> mSharedPtrValue;

    Utils::StatisticsHelper bandTotalStatHelper;
    Utils::StatisticsHelper bandBlockStatHelper;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPlayerInfo);
};

VC_NAMESPACE_END

#endif // PRELOAD_VC_PLAYER_INFO_H
