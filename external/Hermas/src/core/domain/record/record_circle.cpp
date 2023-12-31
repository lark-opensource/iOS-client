//
//  record_core.cpp
//  Hermas
//
//  Created by 崔晓兵 on 17/1/2022.
//

#include "record_circle.h"
#include "env.h"
#include "log.h"
#include "record_service.h"
#include <pthread.h>

namespace hermas {

RecordCircle::RecordCircle(const std::string& thread_name) : m_thread_name(thread_name) {
    InitThread();
    m_handler = std::make_unique<TimerHandler>("com.hermas.record." + thread_name);
}

RecordCircle::~RecordCircle() {
    logi("hermas", "~RecordCircle start");
    if (m_task_queue != nullptr) {
        void** params_wrapper = new void* [1];
        params_wrapper[0] = (void*)MSG_STOP;
        m_task_queue->push_back((void*)params_wrapper);
    }

    //收到线程退出信号，等线程任务全部执行完
    if (m_thread.joinable()) {
        m_thread.join();
    }

    m_handler.reset();
    logi("hermas", "~RecordCircle end");
}

void RecordCircle::Record(const RecordService* service, int type, const std::string& content) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [4];
    params_wrapper[0] = (void *) MSG_RECORD;
    params_wrapper[1] = (void*) (service);
    params_wrapper[2] = (void*) (intptr_t) type;
    params_wrapper[3] = new std::string(content);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::RecordRealTime(const RecordService* service, const std::string& content) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [3];
    params_wrapper[0] = (void*) MSG_RECORD_REALTIME;
    params_wrapper[1] = (void*) service;
    params_wrapper[2] = new std::string(content);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::SaveFile(const RecordService* service, int type) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [3];
    params_wrapper[0] = (void*) MSG_SAVE;
    params_wrapper[1] = (void*) service;
    params_wrapper[2] = (void*) (intptr_t) type;
    m_task_queue->push_front((void*)params_wrapper);
}

void RecordCircle::SaveLocalFile(const RecordService *service) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [2];
    params_wrapper[0] = (void*) MSG_SAVE_LOCAl;
    params_wrapper[1] = (void*) service;
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::FlushAllType(const RecordService* service) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [2];
    params_wrapper[0] = (void*) MSG_FLUSH_ALL;
    params_wrapper[1] = (void*) service;
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::StopCache(const RecordService* service) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [2];
    params_wrapper[0] = (void*) MSG_STOP_CACHE;
    params_wrapper[1] = (void*) service;
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::Aggregate(const RecordService* service, const std::string& content) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [3];
    params_wrapper[0] = (void*)MSG_AGGREGATE;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(content);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::StopAggregate(const RecordService* service, bool isLaunchReport) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [3];
    params_wrapper[0] = (void*)MSG_STOP_AGGREGATE;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = (void*) (intptr_t) (isLaunchReport ? 1 : 0);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::StartSemiTraceRecord(const RecordService* service, const std::string &content, const std::string &traceID) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [4];
    params_wrapper[0] = (void*)MSG_START_SEMITRACE;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(content);
    params_wrapper[3] = new std::string(traceID);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::StartSemiSpanRecord(const RecordService *service, const std::string &content, const std::string &traceID, const std::string &spanID) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [5];
    params_wrapper[0] = (void*)MSG_START_SEMISPAN;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(content);
    params_wrapper[3] = new std::string(traceID);
    params_wrapper[4] = new std::string(spanID);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::FinishSemiTraceRecord(const RecordService *service, const std::string &content, const std::string &traceID, const std::string &spanIDList) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [5];
    params_wrapper[0] = (void*)MSG_FINISH_SEMITRACE;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(content);
    params_wrapper[3] = new std::string(traceID);
    params_wrapper[4] = new std::string(spanIDList);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::FinishSemiSpanRecord(const RecordService *service, const std::string &content, const std::string &traceID, const std::string &spanID) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [5];
    params_wrapper[0] = (void*)MSG_FINISH_SEMISPAN;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(content);
    params_wrapper[3] = new std::string(traceID);
    params_wrapper[4] = new std::string(spanID);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::DeleteSemifinishedRecords(const RecordService *service, const std::string &traceID, const std::string &spanIDList) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [4];
    params_wrapper[0] = (void*)MSG_DELETE_SEMIFINISHED;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(traceID);
    params_wrapper[3] = new std::string(spanIDList);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::LaunchReportForSemi(const RecordService *service) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [2];
    params_wrapper[0] = (void*)MSG_LAUNCH_REPORT_FOR_SEMI;
    params_wrapper[1] = (void*)service;
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::UpdateReportHeader(const RecordService* service, const std::string& header) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [3];
    params_wrapper[0] = (void*)MSG_UPDATE_REPORTHEADER;
    params_wrapper[1] = (void*)service;
    params_wrapper[2] = new std::string(header);
    m_task_queue->push_back((void*)params_wrapper);
}

void RecordCircle::DropAllData(const RecordService *service) {
    if (m_task_queue == nullptr) return;
    void** params_wrapper = new void* [2];
    params_wrapper[0] = (void*)MSG_DROP_ALL_DATA;
    params_wrapper[1] = (void*)service;
    m_task_queue->push_front((void*)params_wrapper);
}

void RecordCircle::DoRecord(RecordService* service, int type, const std::string& content) {
    int64_t delay_millis = type;
    service->DoRecord(type, content);
    if (type > 0) {
        m_handler->SendMsg(WHAT_MOVE_RECORD_FILE, type, delay_millis, (void *)service, delay_millis);
    }
}

void RecordCircle::DoRecordRealTime(RecordService* service, const std::string& content) {
    service->DoRecordRealTime(content);
}

void RecordCircle::DoSaveFile(RecordService* service, int type) {
    service->DoSaveFile(type);
}

void RecordCircle::DoSaveLocalFile(RecordService *service) {
    service->DoSaveLocalFile();
}

void RecordCircle::DoFlushAllType(RecordService* service) {
    service->DoFlushAllType();
}

void RecordCircle::DoStopCache(RecordService* service) {
    service->DoStopCache();
}

void RecordCircle::DoAggregate(RecordService* service, const std::string& content) {
    service->DoAggregate(content);
}

void RecordCircle::DoStopAggregate(RecordService* service, bool isLaunchReport) {
    service->DoStopAggregate(isLaunchReport);
    if (isLaunchReport) {
        m_handler->SendMsg(WHAT_STOP_AGGREGATE, 0, 0, (void *)service, 2 * 60 * 1000);
    }
}

void RecordCircle::DoLaunchReportForSemi(RecordService *service) {
    service->DoLaunchReportForSemi();
}

void RecordCircle::DoStartSemiTraceRecord(RecordService *service, const std::string &content, const std::string &traceID) {
    service->DoStartSemiTraceRecord(content, traceID);
}

void RecordCircle::DoStartSemiSpanRecord(RecordService *service, const std::string &content, const std::string &traceID, const std::string &spanID) {
    service->DoStartSemiSpanRecord(content, traceID, spanID);
}

void RecordCircle::DoFinishSemiTraceRecord(RecordService *service, const std::string &content, const std::string &traceID, const std::string &spanIDList) {
    service->DoFinishSemiTraceRecord(content, traceID, spanIDList);
}

void RecordCircle::DoFinishSemiSpanRecord(RecordService *service, const std::string &content, const std::string &traceID, const std::string &spanID) {
    service->DoFinishSemiSpanRecord(content, traceID, spanID);
}

void RecordCircle::DoDeleteSemifinishedRecords(RecordService *service, const std::string &traceID, const std::string &spanIDList) {
    service->DoDeleteSemifinishedRecords(traceID, spanIDList);
}

void RecordCircle::DoUpdateReportHeader(RecordService *service, const std::string& header) {
    service->DoUpdateReportHeader(header);
}

void RecordCircle::DoDropAllData(RecordService *service) {
    service->DoDropAllData();
}


void RecordCircle::InitThread() {
    if (m_task_queue == nullptr) {
        std::lock_guard<std::mutex> lck_guard(m_thread_init_mutex);
        if (m_task_queue == nullptr) {
            m_task_queue = std::make_unique<TaskQueue>();
            m_thread = std::thread([this]() {
                std::string thread_name = "com.hermas.task." + m_thread_name;
                pthread_setname_np(thread_name.c_str());

                bool isContinue = true;
                while (isContinue)
                {
                    // 参数从队列读取
                    std::unique_ptr<void *, void(*)(void**)> params_wrapper((void **) m_task_queue->pop_front()
                                                                            , [](void **data){
                                                                                delete[] data;
                                                                            }); // 有 wait 卡住动作

                    // 解包参数
                    auto msg = (intptr_t) params_wrapper.get()[0];

                    switch (msg)
                    {
                        case MSG_RECORD:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            int type = static_cast<int>((intptr_t)params_wrapper.get()[2]);
                            std::unique_ptr<std::string> p_content((std::string *) params_wrapper.get()[3]);
                            DoRecord(record_service, type, *p_content.get());
                            break;
                        }
                        case MSG_RECORD_REALTIME:
                        {
                            auto *record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string *) params_wrapper.get()[2]);
                            DoRecordRealTime(record_service, *p_content.get());
                            break;
                        }
                        case MSG_FLUSH_ALL:
                        {
                            auto *record_service = (RecordService *) params_wrapper.get()[1];
                            DoFlushAllType(record_service);
                            break;
                        }
                        case MSG_SAVE:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            // 用 intptr_t 解决 int 和 void* 互转问题
                            int type = static_cast<int>((intptr_t)params_wrapper.get()[2]);
                            DoSaveFile(record_service, type);
                            break;
                        }
                        case MSG_SAVE_LOCAl:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            DoSaveLocalFile(record_service);
                            break;
                        }
                        case MSG_STOP_CACHE:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            DoStopCache(record_service);
                            break;
                        }
                        case MSG_AGGREGATE:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string *) params_wrapper.get()[2]);
                            DoAggregate(record_service, *p_content.get());
                            break;
                        }
                        case MSG_STOP_AGGREGATE:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            int isLaunchReport = static_cast<int>((intptr_t)params_wrapper.get()[2]);
                            DoStopAggregate(record_service, isLaunchReport);
                            break;
                        }
                        case MSG_UPDATE_REPORTHEADER:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string *) params_wrapper.get()[2]);
                            DoUpdateReportHeader(record_service, *p_content.get());
                            break;
                        }
                        case MSG_START_SEMITRACE:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string*) params_wrapper.get()[2]);
                            std::unique_ptr<std::string> p_traceID((std::string*) params_wrapper.get()[3]);
                            DoStartSemiTraceRecord(record_service, *p_content.get(), *p_traceID.get());
                            break;
                        }
                        case MSG_START_SEMISPAN:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string*) params_wrapper.get()[2]);
                            std::unique_ptr<std::string> p_traceID((std::string*) params_wrapper.get()[3]);
                            std::unique_ptr<std::string> p_spanID((std::string*) params_wrapper.get()[4]);
                            DoStartSemiSpanRecord(record_service, *p_content.get(), *p_traceID.get(), *p_spanID.get());
                            break;
                        }
                        case MSG_FINISH_SEMITRACE:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string*) params_wrapper.get()[2]);
                            std::unique_ptr<std::string> p_traceID((std::string*) params_wrapper.get()[3]);
                            std::unique_ptr<std::string> p_spanIDList((std::string*) params_wrapper.get()[4]);
                            DoFinishSemiTraceRecord(record_service, *p_content.get(), *p_traceID.get(), *p_spanIDList.get());
                            break;
                        }
                        case MSG_FINISH_SEMISPAN:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_content((std::string*) params_wrapper.get()[2]);
                            std::unique_ptr<std::string> p_traceID((std::string*) params_wrapper.get()[3]);
                            std::unique_ptr<std::string> p_spanID((std::string*) params_wrapper.get()[4]);
                            DoFinishSemiSpanRecord(record_service, *p_content.get(), *p_traceID.get(), *p_spanID.get());
                            break;
                        }
                        case MSG_DELETE_SEMIFINISHED:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            std::unique_ptr<std::string> p_traceID((std::string*) params_wrapper.get()[2]);
                            std::unique_ptr<std::string> p_spanIDList((std::string*) params_wrapper.get()[3]);
                            DoDeleteSemifinishedRecords(record_service, *p_traceID.get(), *p_spanIDList.get());
                        }
                        case MSG_LAUNCH_REPORT_FOR_SEMI:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            DoLaunchReportForSemi(record_service);
                            break;
                        }
                        case MSG_DROP_ALL_DATA:
                        {
                            RecordService * record_service = (RecordService *) params_wrapper.get()[1];
                            DoDropAllData(record_service);
                            break;
                        }
                        case MSG_STOP: {
                            logi("hermas_record", "record quit");
                            isContinue = false;
                            break;
                        }

                        default:
                            break;
                    }
                }
            });
        }
    }
}


void TimerHandler::SendMsg(int what, int64_t arg1, int64_t arg2, void *obj, int64_t delay_millis) {
    RecordService *service = (RecordService *)obj;
    switch (what) {
        case WHAT_MOVE_RECORD_FILE: {
            int type = static_cast<int>(arg1);
            auto& cycle_types = service->GetTypeSet();
            if (cycle_types.find(type) != cycle_types.end()) return;
            cycle_types.insert(type);
            Handler::SendMsg(what, arg1, arg2, obj, delay_millis);
            break;
        }
        case WHAT_STOP_AGGREGATE: {
            Handler::SendMsg(what, obj, delay_millis);
            break;
        }
        default:
            break;
    }
}

void TimerHandler::HandleMessage(int what, int64_t arg1, int64_t arg2, void *obj) {
    switch (what) {
        case WHAT_MOVE_RECORD_FILE: {
            int64_t type = arg1;
            int64_t delay_millis = arg2;

            // 不在定时器的线程里面执行，而是交给 RecordService 线程处理
            auto record_service = (RecordService *)obj;
            if (record_service != nullptr) {
                record_service->SaveFile(static_cast<int>(type));
            }

            // 不断的周期执行定时器
            Handler::SendMsg(WHAT_MOVE_RECORD_FILE, type, delay_millis, obj, delay_millis);
            break;
        }
        case WHAT_STOP_AGGREGATE: {
            int64_t delay_millis = arg2;
            
            auto record_service = (RecordService *)obj;
            if (record_service != nullptr) {
                record_service->StopAggregate(false);
            }
            
            Handler::SendMsg(WHAT_STOP_AGGREGATE, obj, delay_millis);
            break;
        }
        default:
            break;
    }
}

}
