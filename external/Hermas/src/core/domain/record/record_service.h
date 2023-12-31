//
// Created by bytedance on 2020/8/6.
//

#ifndef HERMAS_RECORD_SERVICE_H
#define HERMAS_RECORD_SERVICE_H

#include <string>
#include <functional>
#include <thread>
#include <set>

#include "record_service.h"

#include "records.h"
#include "upload_service.h"
#include "file_service.h"
#include "cache_service.h"
#include "protocol_service.h"
#include "handler.h"
#include "base_domain.h"
#include "ifile_record.h"
#include "fun_wrapper.h"
#include "env.h"
#include "log.h"
#include "aggregate_service.h"
#include "semfinished_service.h"
#include "disaster_service.h"
#include "service_factory.hpp"

namespace hermas {

class TimerHandler;
class RecordCircle;
class AggregateService;

class RecordService: public ServiceFactory<RecordService>, public infrastruct::BaseDomainService<std::shared_ptr<FileService>, std::shared_ptr<CacheService>, std::shared_ptr<AggregateService>, std::shared_ptr<SemifinishedService>>, public std::enable_shared_from_this<RecordService>, public AggregateServiceClient {
 
public:
    explicit RecordService(const std::shared_ptr<Env>&env);
    virtual ~RecordService();
    
    virtual void InjectDepend(std::shared_ptr<FileService> file_service, std::shared_ptr<CacheService> cache_service, std::shared_ptr<AggregateService> aggretate_service, std::shared_ptr<SemifinishedService> semifinished_service) override;
    virtual void OnAggregateFinish(const std::string& data) override;

    void Record(int type, const std::string& content);
    void RecordCache(const std::string& content);
    void RecordLocal(const std::string& content);
    void RecordRealTime(const std::string& content);
    void SaveFile(int type);
    void SaveLocalFile();
    void FlushAllType();
    void StopCache();
    void Aggregate(const std::string& content);
    void StopAggregate(bool isLaunchReport);
    
    void StartSemiTraceRecord(const std::string& content, const std::string& traceID);
    
    void StartSemiSpanRecord(const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void FinishSemiTraceRecord(const std::string& content, const std::string& traceID, const std::string& spanIDList);
    
    void FinishSemiSpanRecord(const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void DeleteSemifinishedRecords(const std::string& traceID, const std::string& spanIDList);
    
    void LaunchReportForSemi();
    
    void DropAllData();
    
    void UpdateReportHeader(const std::string& header);
    
    std::set<int>& GetTypeSet() {
        return m_cycle_types;
    }
    
private:
    void DoRecord(int type, const std::string& content);
    void DoRecordRealTime(const std::string& content);
    void DoSaveFile(int type);
    void DoSaveLocalFile();
    void DoFlushAllType();
    void DoStopCache();
    void DoAggregate(const std::string& content);
    void DoStopAggregate(bool isLaunchReport);
    void DoUpdateReportHeader(const std::string& header);
    void DoStartSemiTraceRecord(const std::string& content, const std::string& traceID);
    void DoStartSemiSpanRecord(const std::string& content, const std::string& traceID, const std::string& spanID);
    void DoFinishSemiTraceRecord(const std::string& content, const std::string& traceID, const std::string& spanIDList);
    void DoFinishSemiSpanRecord(const std::string& content, const std::string& traceID, const std::string& spanID);
    void DoDeleteSemifinishedRecords(const std::string& traceID, const std::string& spanIDList);
    void DoLaunchReportForSemi();
    void DoDropAllData();
    bool SafeDisasterServiceNeedDrop();
   
private:
    std::shared_ptr<Env> m_env;
    Records m_records;
    std::unique_ptr<UploadService>& m_upload_service;
    std::shared_ptr<CacheService> m_cache_service;
    std::unique_ptr<RecordCircle>& m_record_core;
    std::shared_ptr<AggregateService> m_aggregate_service;
    std::shared_ptr<SemifinishedService> m_semifinished_service;
    std::unique_ptr<DisasterService>& m_disaster_service;
    std::set<int> m_cycle_types;
    friend class RecordCircle;
};

}  //namespace hermas

#endif //HERMAS_RECORD_SERVICE_H
