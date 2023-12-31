//
// Created by 黄清 on 4/19/21.
//

#ifndef PRELOAD_VC_LOG_H
#define PRELOAD_VC_LOG_H
#pragma once
#include "vc_base.h"
#include "vc_context.h"
#include "vc_event_listener.h"
#include "vc_json.h"
#include <memory>

VC_NAMESPACE_BEGIN

typedef enum : int {
    PlayTaskOperatePause = 1,
    PlayTaskOperateResume = 2,
    PlayTaskOperateStop = 3,
    PlayTaskOperateRange = 4,
    PlayTaskOperateRangeDuration = 5,
    PlayTaskOperateTargetBuffer = 6,
    PlayTaskOperateSafeFactor = 7,

    PlayTaskOperateSeekLabel = 100,
    PlayTaskOperateFirstBlockSendTime = 101,
    PlayTaskOperateFirstBlockExecTime = 102,
    PlayTaskOperateEstPlayTime = 103,
    PlayTaskOperateSmartLevelUsed = 104,
} VCPlayTaskOperate;

typedef enum : int {
    /// play io task
    EventPlayTaskOperate = 2000, // value is VCPlayTaskOperate
    EventPreloadSwitch = 2001,
    EventReBufferDurationInitial = 2002,
    EventStartupDuration = 2003,
    EventPreloadPersonalizedOption = 2004,
    EventWatchDurationLabel = 2005,
    EventStallLabel = 2006,
    EventFirstFrameLabel = 2007,
    EventAdaptiveRangeEnabled = 2008,
    EventAdaptiveRangeBuffer = 2009,
    EventRemainingBufferDurationAtStop = 2010,
    EventPlayBufferDiffResult = 2011,
    EventPlayRelatedPreloadFinished = 2012,
    EventPlayerRangeDetermined = 2013,
    EventModuleActivated = 2014,
    EventPreloadDecisionInfo = 2015,
    EventLoadControlVersion = 2016,
    EventLoadControlSlidingWindow = 2017,
    EventSceneSwitch = 2018,
    EventSerializedData = 2019,
    EventNetworkStallList = 2020,

    // Event Log will be reserved in Strategy whose Key is bigger than 2020
    EventOnePlayNetSpeed = 2021,

} VCLogEventType;

enum SerializedOperation : int {
    LoadData = 1,
    SaveData = 2,
    RemoveData = 3,
};

VC_NAMESPACE_END

VC_NAMESPACE_BEGIN

typedef enum : int {
    VCLogTypeStrategy = 1,
    VCLogTypeError = 2,
    VCLogTypePriorityTask = 3,
} VCLogType;

class VCLogItem :
        public std::enable_shared_from_this<VCLogItem>,
        public IVCPrintable {
public:
    typedef std::shared_ptr<VCLogItem> Ptr;

public:
    VCLogItem(VCLogType type, const std::string &module);
    ~VCLogItem() override;

public:
    std::string toString(void) const override;

    template <typename T,
              typename = typename std::enable_if<
                      std::is_constructible<VCJson, T>::value>::type>
    Ptr put(const std::string &key, const T &value) {
        mJsonValue[key] = value;
        return shared_from_this();
    }

public:
    int getLogType();

protected:
    VCLogType mLogType;
    std::string mModule;
    uint64_t mTs{0};
    VCJson mJsonValue;

    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCLogItem);
};

class VCLogStrategyItem : public VCLogItem {
public:
    VCLogStrategyItem(const std::string &module);
    ~VCLogStrategyItem() override;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCLogStrategyItem);
};

class VCLogErrorItem : public VCLogItem {
public:
    VCLogErrorItem(const std::string &module);
    ~VCLogErrorItem() override;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCLogErrorItem);
};

class VCLogPriorityTaskItem : public VCLogItem {
public:
    VCLogPriorityTaskItem();
    ~VCLogPriorityTaskItem() override;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCLogPriorityTaskItem);
};

namespace VCLog {

extern const char *PRELOAD;
extern const char *ABR;
extern const char *GLOBAL;

std::shared_ptr<VCLogItem> ObtainStrategyLog(const std::string &module);
std::shared_ptr<VCLogItem> ObtainErrorLog(const std::string &module);
std::shared_ptr<VCLogItem> ObtainPriorityTaskLog();
void EventLog(const std::shared_ptr<VCLogItem> &logItem);
void Event(const std::string &mediaId,
           int key,
           int value,
           const std::string &info);

void SetEventListenerImp(IVCEventListener *eventListener);
void SetEventLogListenerImp(IVCContext *context);

} // namespace VCLog

VC_NAMESPACE_END
#endif // PRELOAD_VC_LOG_H
