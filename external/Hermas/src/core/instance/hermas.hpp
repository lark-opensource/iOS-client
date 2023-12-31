#pragma once

#include <map>
#include <string>

#include "recorder.h"
#include "env.h"
#include "rwlock.h"
#include "search_service.h"

#define AID_LINK_SYMBOL "_"

namespace hermas { class HermasInternal; }
namespace hermas { class ConditionNode; }

namespace hermas {

class Hermas final {
public:
    ~Hermas();
    
    Hermas(const std::string& module_id, const std::string& aid) : m_module_id(module_id), m_aid(aid) {}

    void InitInstanceEnv(const std::shared_ptr<Env>& env);

    void Upload();

    void UploadWithFlushImmediately();
    
    void StopCache();
    
    void Aggregate(const std::string& data);
    
    void StopAggregate(bool isLaunchReport);
    
    void StartSemiTraceRecord(const std::string& content, const std::string& traceID);
    
    void StartSemiSpanRecord(const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void FinishSemiTraceRecord(const std::string& data, const std::string& traceID, const std::string& spanIDList);
    
    void FinishSemiSpanRecord(const std::string& data, const std::string& traceID, const std::string& spanID);
    
    void DeleteSemifinishedRecords(const std::string& traceID, const std::string& spanIDList);
    
    void LaunchReportForSemi();
    
    void UpdateReportHeader(const std::string& header);
    
    std::vector<std::unique_ptr<SearchData>> Search(const std::shared_ptr<ConditionNode>& condition);
    
    std::shared_ptr<Recorder> CreateRecorder(enum RECORD_INTERVAL interval);
    
    void DestroyRecorder(Recorder* recorder);
    
    bool IsDropData();
    
    bool IsServerAvailable();
    
    void CleanAllCache();

    void UploadLocalData();
private:
    std::shared_ptr<HermasInternal> GetCurrentInstance();
    rwlock m_delete_lock_mutex;
    StringType m_aid = "";
    StringType m_module_id;
};

} //namespace hermas
