//
//  vc_smart_task_manager.h
//  VCPreloadStrategy
//
//  Created by ByteDance on 2022/7/21.
//

#ifndef vc_smart_task_manager_h
#define vc_smart_task_manager_h
#pragma once

#include "vc_base.h"
#include "vc_object.h"
#ifdef VCMODULE_PITAYA
#include "pitaya_interface.h"
#endif

VC_NAMESPACE_BEGIN

// pitaya::TaskConfig
class SmartTaskConfig : public IVCPrintable {
public:
    SmartTaskConfig() = default;
    SmartTaskConfig(const std::string& entrance, float timeout = -1.0);

    std::string toString() const override;

public:
    std::string entrance;
    float pending_timeout = -1.0;
};

#ifdef VCMODULE_PITAYA
class VCBusinessPackageInfo : public IVCPrintable {
public:
    typedef enum : int {
        StatusUnknown = 0,
        StatusChecking = 1,
        StatusExisted = 2,
    } BusinessPackageStatus;

    typedef enum : int {
        PackageNotDownloading = 0,
        PackageDownloading = 1,
        PackageDownloaded = 2,
    } PackageDownloadStatus;

    VCBusinessPackageInfo(const std::string& businessName);
    ~VCBusinessPackageInfo() override;

public:
    std::string toString() const override;

    const static int PACKAGE_MAX_RETRY_COUNT = 5;

public:
    std::string mBusinessName;
    BusinessPackageStatus packageStatus{StatusUnknown};
    PackageDownloadStatus downloadStatus{PackageNotDownloading};
    int retryCount{0};
};

class VCSmartTaskInfo : public IVCPrintable {
public:
    VCSmartTaskInfo();
    VCSmartTaskInfo(const std::string& businessName,
                    std::shared_ptr<pitaya::TaskData> taskData,
                    std::shared_ptr<pitaya::TaskConfig> taskConfig,
                    int64_t timeStamp);
    ~VCSmartTaskInfo() override;

public:
    std::string toString() const override;

public:
    std::string mBusinessName;
    std::shared_ptr<pitaya::TaskData> mInputData;
    std::shared_ptr<pitaya::TaskConfig> mTaskConfig;
    std::shared_ptr<pitaya::TaskData> mResult;
    int64_t mStartTime;

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCSmartTaskInfo);
};
#endif

class IVCMessageSender;

class VCSmartTaskManager {
public:
    VCSmartTaskManager();
    ~VCSmartTaskManager();

public:
    void setContext(IVCMessageSender* context);
    // bool setPitayaCore(std::shared_ptr<pitaya::PitayaCore> pitayaCore);
    bool isPitayaReady(void);

    int postSmartTask(const std::string& business,
                      const std::shared_ptr<Dict> input,
                      const std::shared_ptr<SmartTaskConfig> config);
    std::shared_ptr<Dict> tryGetTaskResult(const std::string& business,
                                           bool& isRunning);

private:
    bool isPackageAvailable(const std::string& business);

public:
    const static int PITAYA_TASK_MAX_COUNT = 10;
    const static int PITAYA_TASK_MAX_PER_BUSINESS = 5;

private:
#ifdef VCMODULE_PITAYA
    IVCMessageSender* mContext{nullptr};
    std::shared_ptr<pitaya::IPitaya> mPitayaCore{nullptr};
    bool isReady{false};
    std::mutex mTaskMutex;

    std::map<std::string, std::map<int64_t, std::shared_ptr<VCSmartTaskInfo>>>
            mSmartTaskMap; // businessName-timeStamp-taskInfo
    std::map<std::string, std::shared_ptr<VCBusinessPackageInfo>>
            mPackageInfoMap;
    std::map<std::string, std::shared_ptr<VCSmartTaskInfo>> mSmartTaskResultMap;
    bool isDownloading{false};
    int mCurrentTaskCount{0};
#endif

private:
    VC_DISALLOW_COPY_ASSIGN_AND_MOVE(VCSmartTaskManager);
};

VC_NAMESPACE_END

#endif /* vc_smart_task_manager_h */
