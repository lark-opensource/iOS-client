//
// Created by bytedance on 2020/8/5.
//
#pragma once

#include <cstdint>
#include <functional>
#include <map>
#include <string>

#include "protocol_service.h"
#include "constants.h"
#include "env.h"
#include "base_domain.h"
#include "domain_manager.h"
#include "no_destructor.hpp"

namespace hermas {

class HermasInternal;
typedef WeakWrapper<std::map<std::string, std::shared_ptr<HermasInternal>>> WeakHermasMap;

class HermasInternal final {
public:
    explicit HermasInternal(const std::shared_ptr<Env>& env);
    ~HermasInternal();
    
    static std::mutex& GetMutex() {
        static NoDestructor<std::mutex> s_mutex;
        return *s_mutex;
    }

    static WeakPtr<WeakHermasMap> GetHermasMap() {
        static NoDestructor<StaticWrapper<WeakHermasMap>> s_instance_map;
        return (*s_instance_map).SafeGet();
    }
    
    static std::shared_ptr<HermasInternal> GetInstance(const std::string& moduld_id, const std::string& aid);

    bool IsDropData();
    
    bool IsServerAvailable();
    
    void Record(int interval, const std::string& data);
    
    void RecordLocal(const std::string& data);
    
    void RecordCache(const std::string& data);
    
    void StopCache();
    
    void Aggregate(const std::string& service_name);
    
    void StopAggregate(bool isLaunchReport);
    
    void StartSemiTraceRecord(const std::string& content, const std::string& traceID);
    
    void StartSemiSpanRecord(const std::string& content, const std::string& traceID, const std::string& spanID);
    
    void FinishSemiTraceRecord(const std::string& data, const std::string& traceID, const std::string& spanIDList);
    
    void FinishSemiSpanRecord(const std::string& data, const std::string& traceID, const std::string& spanID);
    
    void DeleteSemifinishedRecords(const std::string& traceID, const std::string& spanIDList);
    
    void LaunchReportForSemi();
    
    void UpdateReportHeader(const std::string& header);
    
    std::vector<std::unique_ptr<SearchData>> Search(const std::shared_ptr<ConditionNode>& condition);
    
    void Upload();
    
    void UploadWithFlushImmediately();
    
    void FlushAll();
    
    void CleanAllCache();
    
    void UploadLocalData();

private:
    std::shared_ptr<Env> m_env;
    std::mutex m_is_uploading;  // temporary solution, need to optimize
    std::unique_ptr<infrastruct::BaseDomainManager>& m_service_manager;
};
}
