//
//  vc_play_task.h

#ifndef vc_play_task_hpp
#define vc_play_task_hpp
#pragma once

#include "vc_base.h"
#include "vc_keys.h"
#include "vc_utils.h"

#include <list>
#include <map>
#include <memory>
#include <mutex>
#include <stdio.h>
#include <thread>

#include "vc_message.h"
#include "vc_play_range_interface.h"
#if __has_include(<MDLMediaDataLoader/AVMDLIOManager.h>)
#include <MDLMediaDataLoader/AVMDLIOManager.h>
#else
#include "AVMDLIOManager.h"
#endif

VC_NAMESPACE_BEGIN

using AVMDLIOTask = com::ss::ttm::medialoader::AVMDLIOTask;
using AVMDLIOTaskInfo = com::ss::ttm::medialoader::AVMDLIOTaskInfo;
using AVMDLIOManager = com::ss::ttm::medialoader::AVMDLIOManager;
using AVMDLDownloadContext = com::ss::ttm::medialoader::AVMDLDownloadContext;
using AVMDLStrategyInterface =
        com::ss::ttm::medialoader::AVMDLStrategyInterface;

class VCIOTaskItem : public IVCPrintable {
public:
    typedef enum : int {
        TaskReqStart = 1,
        TaskReqEnd = 2,
        TaskReqPause = 3,
        TaskReqResume = 4,
    } TaskReqState;

public:
    static std::string ReqStateStr(int reqState);

public:
    VCIOTaskItem() = delete;
    explicit VCIOTaskItem(const std::string &mediaId,
                          const std::string &fileHash,
                          int recordState);
    ~VCIOTaskItem() override;

public:
    void updateState(int taskState);
    int getState() const;
    void setIOTask(AVMDLIOTask *ioTask);
    AVMDLIOTask *getIOTask();
    std::string getFileHash();

public:
    std::string toString() const override;

public:
    void pause(bool isForce = false);
    void resume();
    void stop();

private:
    AVMDLIOTask *mIOTask{nullptr};
    volatile int mTaskState{TaskReqState::TaskReqStart};
    std::string mFileHash;
    std::string mMediaId;
    int mRecordState{0};
};

class MessageTaskRunner;
class VCMediaInfo;
class VCManager;

class VCPlayTask : public IVCMessageHandle, public AVMDLStrategyInterface {
public:
    class TaskItem : public IVCPrintable {
    public:
        TaskItem(const std::string &mediaId, const std::string &sceneId) {
            mMediaId = mediaId;
            mSceneId = sceneId;
        }

        ~TaskItem() override {
            mIOTasks.clear();
            LOGD("~TaskItem");
        }

    public:
        void addIOTask(const std::string &mediaId,
                       const std::string &fileHash,
                       AVMDLIOTask *ioTask,
                       int recordState);
        std::shared_ptr<VCIOTaskItem> itemForIOTask(AVMDLIOTask *ioTask);
        std::shared_ptr<VCIOTaskItem>
        itemForFileHash(const std::string &fileHash);
        void updateIOTaskState(AVMDLIOTask *ioTask, int taskState);
        /*just reset the ioTask pointer. */
        void releaseTask(AVMDLIOTask *ioTask);
        void removeAllTasks();
        bool empty();
        bool resumeAllTasks();
        bool pauseAllTasks();
        bool stopAllTasks();
        /// io task state
        int getTaskState();

    public:
        std::string toString() const override;

    public:
        std::string mMediaId;
        std::string mSceneId;
        bool mRelatedPreloadTaskFinished{false};

    private:
        std::list<std::shared_ptr<VCIOTaskItem>> mIOTasks;
        mutable std::mutex mTaskMutex;
    };

public:
    VCPlayTask() = default;
    ~VCPlayTask() override = default;

public: /// Module
    void receiveMessage(std::shared_ptr<VCMessage> &msg) override;

public:
    void addIOTask(const std::string &mediaId,
                   const std::string &sceneId,
                   const std::string &fileHash,
                   AVMDLIOTask *ioTask);

    /* called by the MDL ioTask callback. */
    void releaseIOTask(const std::string &mediaId,
                       const std::string &sceneId,
                       AVMDLIOTask *ioTask);
    void activeMedia(const std::string &mediaId, const std::string &sceneId);
    void stopTaskItem(const std::string &mediaId, const std::string &sceneId);
    /* called when stop player. */
    void releaseTaskItem(const std::string &mediaId,
                         const std::string &sceneId);
    void updateTaskState(const std::string &mediaId,
                         const std::string &sceneId,
                         AVMDLIOTask *ioTask,
                         int state);
    bool isIdle(const std::string &mediaId, const std::string &sceneId);

public:
    void setContext(VCManager *context);
    void setRangeControl(IVCPlayRange::Ptr rangeControl);

public:
    void _playerEvent(std::string &mediaId, int key, int value);

private:
    void _strategyNotify(int moduleType,
                         std::string &fileHash,
                         int resumeTask,
                         int ioDecisionType);

private:
    int obtainAVMDLDownloadContext(AVMDLDownloadContext *ctx,
                                   AVMDLIOTask *task) override;

public:
    std::shared_ptr<TaskItem> getActiveTaskItem();
    std::shared_ptr<TaskItem> getTaskItem(AVMDLIOTask *ioTask);

private:
    std::shared_ptr<TaskItem> mActiveTaskItem{nullptr};
    std::string mActiveMediaId;
    VCManager *mContext{nullptr};
    std::map<std::string, std::shared_ptr<TaskItem>> mAllTasks;
    std::mutex mAllTaskMutex;
    std::mutex mActiveTaskMutex;
    IVCPlayRange::Ptr mRangeControl{nullptr};
};

VC_NAMESPACE_END

#endif /* vc_play_task_hpp */
