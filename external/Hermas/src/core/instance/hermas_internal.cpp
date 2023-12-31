//
// Created by xuzhi on 2020/8/5.
//

#include "hermas_internal.h"

#include <mutex>
#if defined(HERMAS_PERFORMANCE) && defined(PLATFORM_WIN)
#include <process.h>
#endif

#include "env.h"
#include "log.h"
#include "time_util.h"
#include "domain_manager.h"
#include "fun_wrapper.h"
#include "record_service.h"
#include "upload_service.h"
#include "file_service.h"
#include "protocol_service.h"
#include "network_service.h"

namespace hermas {

HermasInternal::HermasInternal(const std::shared_ptr<Env>&env): m_env(env), m_service_manager(infrastruct::BaseDomainManager::GetInstance(env))
{
}

HermasInternal::~HermasInternal() {
    logi("hermas", "~HermasInternal start");
    std::lock_guard<std::mutex> upload_lck(m_is_uploading);
    infrastruct::BaseDomainManager::DestroyInstance(m_env);
    logi("hermas", "~HermasInternal end");
}

std::shared_ptr<HermasInternal> HermasInternal::GetInstance(const std::string& moduld_id, const std::string& aid) {
    // TODO 优化，读不加锁，写copy一份去操作后再覆盖原来的
    std::map<std::string, std::shared_ptr<HermasInternal>>::iterator it;
    auto map_weak_ptr = GetHermasMap();
    auto map_ptr = map_weak_ptr.Lock();
    if (!map_ptr) {
        return nullptr;
    }
    auto& map = map_ptr->GetItem();
    
    const std::shared_ptr<Env>& env = Env::GetInstance(moduld_id, aid);
    if (env == nullptr) {
        return nullptr;
    }
    string key = moduld_id + "_" + aid;
    std::lock_guard<std::mutex> lc_guard(GetMutex());
    it = map.find(key);
    if (it != map.end()) {
        return it->second;
    } else {
        map[key] = std::make_shared<HermasInternal>(env);
    }

    return map.find(key)->second;
}

bool HermasInternal::IsDropData() {
    if (m_service_manager->GetDisasterService()) {
        return m_service_manager->GetDisasterService()->NeedDropData();
    }
    loge("hermas_intermal", "the disaster service is nullptr, module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    return false;
}

bool HermasInternal::IsServerAvailable() {
    if (m_service_manager->GetDisasterService()) {
        return m_service_manager->GetDisasterService()->IsServerAvailable();
    }
    loge("hermas_intermal", "the disaster service is nullptr, module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    return false;
}

void HermasInternal::Record(int interval, const std::string& data) {
    if (interval == 0) {
        m_service_manager->GetRecordService()->RecordRealTime(data);
    } else {
        m_service_manager->GetRecordService()->Record(interval, data);
    }
}

void HermasInternal::RecordCache(const std::string& data) {
    m_service_manager->GetRecordService()->RecordCache(data);
}

void HermasInternal::RecordLocal(const std::string& data) {
    m_service_manager->GetRecordService()->RecordLocal(data);
}

void HermasInternal::StopCache() {
    m_service_manager->GetRecordService()->StopCache();
}

void HermasInternal::Aggregate(const std::string& data) {
    m_service_manager->GetRecordService()->Aggregate(data);
}

void HermasInternal::StopAggregate(bool isLaunchReport) {
    m_service_manager->GetRecordService()->StopAggregate(isLaunchReport);
}

void HermasInternal::StartSemiTraceRecord(const std::string &content, const std::string &traceID) {
    m_service_manager->GetRecordService()->StartSemiTraceRecord(content, traceID);
}

void HermasInternal::StartSemiSpanRecord(const std::string &content, const std::string &traceID, const std::string &spanID) {
    m_service_manager->GetRecordService()->StartSemiSpanRecord(content, traceID, spanID);
}

void HermasInternal::FinishSemiTraceRecord(const std::string &data, const std::string &traceID, const std::string &spanIDList) {
    m_service_manager->GetRecordService()->FinishSemiTraceRecord(data, traceID, spanIDList);
}

void HermasInternal::FinishSemiSpanRecord(const std::string &data, const std::string &traceID, const std::string &spanID) {
    m_service_manager->GetRecordService()->FinishSemiSpanRecord(data, traceID, spanID);
}

void HermasInternal::DeleteSemifinishedRecords(const std::string &traceID, const std::string &spanIDList) {
    m_service_manager->GetRecordService()->DeleteSemifinishedRecords(traceID, spanIDList);
}

void HermasInternal::LaunchReportForSemi() {
    m_service_manager->GetRecordService()->LaunchReportForSemi();
}

void HermasInternal::UpdateReportHeader(const std::string& header) {
    m_service_manager->GetRecordService()->UpdateReportHeader(header);
}

std::vector<std::unique_ptr<SearchData>> HermasInternal::Search(const std::shared_ptr<ConditionNode>& condition) {
    return m_service_manager->GetSerachService()->Search(condition);
}

void HermasInternal::Upload() {
    m_service_manager->GetUploadService()->StartCycle();
}

void HermasInternal::UploadWithFlushImmediately() {
    m_service_manager->GetRecordService()->FlushAllType();
}

void HermasInternal::FlushAll() {
    m_service_manager->GetRecordService()->FlushAllType();
}

void HermasInternal::CleanAllCache() {
    m_service_manager->GetRecordService()->DropAllData();
}

void HermasInternal::UploadLocalData() {
    m_service_manager->GetRecordService()->SaveLocalFile();
}

} //namespace hermas
