//
//  record_core.hpp
//  Hermas
//
//  Created by 崔晓兵 on 17/1/2022.
//

#ifndef record_core_hpp
#define record_core_hpp

#include <string>
#include <functional>
#include <thread>
#include <set>
#include <mutex>
#include "task_queue.h"
#include "handler.h"
#include "log.h"
#include "ifile_record.h"
#include "service_factory.hpp"

namespace hermas {

class ModuleEnv;
class TimerHandler;
class TaskQueue;
class Env;
class RecordService;

static constexpr intptr_t MSG_RECORD = 1;
static constexpr intptr_t MSG_SAVE = 2;
static constexpr intptr_t MSG_STOP = 3;
static constexpr intptr_t MSG_RECORD_REALTIME = 4;
static constexpr intptr_t MSG_FLUSH_ALL = 5;
static constexpr intptr_t MSG_STOP_CACHE = 6;

static constexpr intptr_t MSG_AGGREGATE = 7;
static constexpr intptr_t MSG_STOP_AGGREGATE = 8;
static constexpr intptr_t MSG_UPDATE_REPORTHEADER = 9;

static constexpr intptr_t MSG_START_SEMITRACE = 10;
static constexpr intptr_t MSG_START_SEMISPAN = 11;
static constexpr intptr_t MSG_FINISH_SEMITRACE = 12;
static constexpr intptr_t MSG_FINISH_SEMISPAN = 13;
static constexpr intptr_t MSG_DELETE_SEMIFINISHED = 14;
static constexpr intptr_t MSG_LAUNCH_REPORT_FOR_SEMI = 15;
static constexpr intptr_t MSG_DROP_ALL_DATA = 16;

static constexpr intptr_t MSG_SAVE_LOCAl = 17;

static constexpr int WHAT_MOVE_RECORD_FILE = 1;
static constexpr int WHAT_STOP_AGGREGATE = 2;

class RecordCircle : public ServiceFactory<RecordCircle> {
public:
    virtual ~RecordCircle();
    
private:
    explicit RecordCircle(const std::string& thread_name);
    friend class ServiceFactory<RecordCircle>;
 
public:
    void Record(const RecordService* service, int type, const std::string& content);
    
    void RecordRealTime(const RecordService* service, const std::string& content);
    
    void SaveFile(const RecordService* service, int type);
    
    void SaveLocalFile(const RecordService* service);
    
    void FlushAllType(const RecordService* service);
    
    void StopCache(const RecordService* service);
    
    void Aggregate(const RecordService* service, const std::string& content);
    
    void StopAggregate(const RecordService* service, bool isLaunchReport);
    
    void StartSemiTraceRecord(const RecordService* service, const std::string& content, const std::string& traceID);
    
    void StartSemiSpanRecord(const RecordService* service, const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void FinishSemiTraceRecord(const RecordService* service, const std::string& content, const std::string& traceID, const std::string& spanIDList);
    
    void FinishSemiSpanRecord(const RecordService* service, const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void DeleteSemifinishedRecords(const RecordService* service, const std::string& traceID, const std::string& spanIDList);
    
    void LaunchReportForSemi(const RecordService* service);
    
    void UpdateReportHeader(const RecordService* service, const std::string& header);
    void DropAllData(const RecordService* service);
    
private:
    void DoRecord(RecordService* service, int type, const std::string& content);
    
    void DoRecordRealTime(RecordService* service, const std::string& content);
    
    void DoSaveFile(RecordService* service, int type);
    
    void DoSaveLocalFile(RecordService* service);
    
    void DoFlushAllType(RecordService* service);
    
    void DoStopCache(RecordService* service);
    
    void DoAggregate(RecordService* service, const std::string& content);
    
    void DoStopAggregate(RecordService* service, bool isLaunchReport);
    
    void DoStartSemiTraceRecord(RecordService* service, const std::string& content, const std::string& traceID);
    
    void DoStartSemiSpanRecord(RecordService* service, const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void DoFinishSemiTraceRecord(RecordService* service, const std::string& content, const std::string& traceID, const std::string& spanIDList);
    
    void DoFinishSemiSpanRecord(RecordService* service, const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void DoDeleteSemifinishedRecords(RecordService* service, const std::string& traceID, const std::string& spanIDList);
    
    void DoLaunchReportForSemi(RecordService* service);
    
    void DoUpdateReportHeader(RecordService* service, const std::string& header);
    
    void DoDropAllData(RecordService* service);
    
    void InitThread();
    
    std::string m_thread_name;
    std::unique_ptr<TimerHandler> m_handler;
    std::mutex m_thread_init_mutex;
    std::unique_ptr<TaskQueue> m_task_queue = nullptr;
    std::thread m_thread;
};


/**
 * 目前周期执行起来就不会停下
 */
class TimerHandler : public Handler, public ServiceFactory<TimerHandler> {
public:
    explicit TimerHandler(const std::string& thread_name) : Handler(thread_name, false){}
    
    virtual ~TimerHandler() {
        Stop();
        logi("hermas", "~TimerHandler");
    }

public:
    void SendMsg(int what, int64_t arg1, int64_t arg2, void * obj, int64_t delay_millis) override;
    void HandleMessage(int what, int64_t arg1, int64_t arg2, void * obj) override;
    
private:
    std::string m_thread_name;
};
}

#endif /* record_core_hpp */
