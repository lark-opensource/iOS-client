//
// Created by ByteDance on 2022/9/6.
//

#ifndef VIDEOENGINE_VC_DYNAMIC_CONFIG_HANDLER_H
#define VIDEOENGINE_VC_DYNAMIC_CONFIG_HANDLER_H

#include "vc_base.h"
#include "vc_define.h"
#include "vc_imodule.h"
#include "vc_json.h"
#include "vc_keys.h"
#include "vc_shared_mutex.h"
#include "vc_time_util.h"

#include <set>

VC_NAMESPACE_BEGIN

class VCPeriodTimeInfo : public IVCPrintable {
public:
    typedef std::shared_ptr<VCPeriodTimeInfo> Ptr;

public:
    VCPeriodTimeInfo() = default;
    ~VCPeriodTimeInfo() override = default;

    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCPeriodTimeInfo);

public:
    std::string toString() const override;

public:
    inline bool operator<(const VCPeriodTimeInfo &o) const {
        return this->mStartTime != o.mStartTime ?
                       this->mStartTime < o.mStartTime :
                       this->mEndTime > o.mEndTime;
    }

    inline bool operator>(const VCPeriodTimeInfo &o) const {
        return this->mStartTime != o.mStartTime ?
                       this->mStartTime > o.mStartTime :
                       this->mEndTime < o.mEndTime;
    }

    inline bool operator<=(const VCPeriodTimeInfo &o) const {
        return !(*this > o);
    }

    inline bool operator>=(const VCPeriodTimeInfo &o) const {
        return !(*this < o);
    }

public:
    HourMinute mStartTime;
    HourMinute mEndTime;
    std::string label;
};

class VCDynamicConfigHandler final : public IVCRunner {
public:
    VCDynamicConfigHandler() = default;

    virtual ~VCDynamicConfigHandler();

public:
    void
    startDynamicUpdateCheck(const std::shared_ptr<MessageTaskRunner> &runner,
                            IVCMessageSender *messageSender);
    bool parseDynamicTimeConfig(const std::string &json);
    bool parseModuleDynamicConfig(VCKey type, const std::string &json);
    bool getModuleNeedUpdateDynamic(std::vector<VCKey> &config);
    VCJson getModuleDynamicConfig(VCKey type);
    bool isNeedUpdate();

private:
    void _checkDynamicUpdate(int intervalMilliSecond);

private:
    const static int DYNAMIC_CHECK_INTERVAL_MS = 500;

private:
    std::pair<std::map<VCKey, std::string>, bool>
    getCurrentTimeInfo(const HourMinute &now) const;

private:
    IVCMessageSender *mMessageSender;

    mutable shared_mutex mMutex;
    std::vector<VCPeriodTimeInfo::Ptr> mPeriodTimeLabel;
    std::map<VCKey, std::map<std::string, VCJson>> mModuleLabelConfig;
    std::map<VCKey, std::string> mModuleCurrentLabel;
    // std::string mModuleCurrLabel;
};

VC_NAMESPACE_END
#endif // VIDEOENGINE_VC_DYNAMIC_CONFIG_HANDLER_H
