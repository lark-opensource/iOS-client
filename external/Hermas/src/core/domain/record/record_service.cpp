//
// Created by bytedance on 2020/8/6.
//

#include "record_service.h"

#include <mutex>
#include <map>

#include <thread>
#include "log.h"
#include "record_circle.h"

namespace hermas {

RecordService::RecordService(const std::shared_ptr<Env>& env) :
m_env(env),
m_records(env),
m_upload_service(UploadService::GetInstance(env->GetModuleEnv())),
m_record_core(RecordCircle::GetInstance(env->GetModuleEnv()->GetShareRecordThread() ? "shared" : env->GetModuleId())) ,
m_disaster_service(DisasterService::GetInstance(env))
{
}

RecordService::~RecordService() {
}

void RecordService::InjectDepend(std::shared_ptr<FileService> file_service, std::shared_ptr<CacheService> cache_service, std::shared_ptr<AggregateService> aggretate_service, std::shared_ptr<SemifinishedService> semifinished_service) {
    m_cache_service = cache_service;
    m_records.SetFileService(file_service);
    m_aggregate_service = aggretate_service;
    m_semifinished_service = semifinished_service;
}

void RecordService::OnAggregateFinish(const std::string& content) {
    m_record_core->Record(this, INTERVAL_15000, content);
}

void RecordService::Record(int type, const std::string& content) {
    m_record_core->Record(this, type, content);
}

void RecordService::RecordCache(const std::string& content) {
    m_record_core->Record(this, CACHE_RECORDER_TYPE, content);
}

void RecordService::RecordLocal(const std::string& content) {
    m_record_core->Record(this, LOCAL_RECORDER_TYPE, content);
}

void RecordService::RecordRealTime(const std::string& content) {
    m_record_core->RecordRealTime(this, content);
}

void RecordService::StopCache() {
    m_record_core->StopCache(this);
}

void RecordService::Aggregate(const std::string& content) {
    m_record_core->Aggregate(this, content);
}

void RecordService::StopAggregate(bool isLaunchReport) {
    m_record_core->StopAggregate(this, isLaunchReport);
}

void RecordService::StartSemiTraceRecord(const std::string &content, const std::string &traceID) {
    m_record_core->StartSemiTraceRecord(this, content, traceID);
}

void RecordService::StartSemiSpanRecord(const std::string &content, const std::string &traceID, const std::string &spanID) {
    m_record_core->StartSemiSpanRecord(this, content, traceID, spanID);
}

void RecordService::FinishSemiTraceRecord(const std::string &content, const std::string &traceID, const std::string &spanIDList) {
    m_record_core->FinishSemiTraceRecord(this, content, traceID, spanIDList);
}

void RecordService::FinishSemiSpanRecord(const std::string &content, const std::string &traceID, const std::string &spanID) {
    m_record_core->FinishSemiSpanRecord(this, content, traceID, spanID);
}

void RecordService::DeleteSemifinishedRecords(const std::string &traceID, const std::string &spanIDList) {
    m_record_core->DeleteSemifinishedRecords(this, traceID, spanIDList);
}

void RecordService::LaunchReportForSemi() {
    m_record_core->LaunchReportForSemi(this);
}

void RecordService::UpdateReportHeader(const std::string& header) {
    m_record_core->UpdateReportHeader(this, header);
}


void RecordService::SaveFile(int type) {
    if (!m_record_core) return;
    m_record_core->SaveFile(this, type);
}

void RecordService::SaveLocalFile() {
    if (!m_record_core) return;
    m_record_core->SaveLocalFile(this);
}

void RecordService::FlushAllType() {
    m_record_core->FlushAllType(this);
}

void RecordService::DropAllData() {
    m_record_core->DropAllData(this);
}

void RecordService::DoFlushAllType() {
    if (SafeDisasterServiceNeedDrop()) return;
    
    for (int type: GetTypeSet()) {
        m_records.SaveFile(type);
    }
    m_upload_service->TriggerUpload();
}

void RecordService::DoRecord(int type, const std::string& content) {
    if (SafeDisasterServiceNeedDrop()) return;
    m_records.RecordFile(type, content);
}

void RecordService::DoRecordRealTime(const std::string& content) {
    if (SafeDisasterServiceNeedDrop()) return;
    m_records.RecordFile(REAL_RECORDER_TYPE, content);
    m_records.SaveFile(REAL_RECORDER_TYPE);
    m_upload_service->TriggerUpload();
}

void RecordService::DoSaveFile(int type) {
    if (SafeDisasterServiceNeedDrop()) return;
    logi("hermas_record", "message react to save file, type: %d", type);
    m_records.SaveFile(type);
}

void RecordService::DoSaveLocalFile() {
    if (SafeDisasterServiceNeedDrop()) return;
    m_records.SaveFile(LOCAL_RECORDER_TYPE);
    hermas::MoveLocalToReady(m_env);
}

void RecordService::DoStopCache() {
    if (SafeDisasterServiceNeedDrop()) return;
    m_records.SaveFile(CACHE_RECORDER_TYPE);
    m_cache_service->WriteBack();
}

void RecordService::DoAggregate(const std::string& content) {
    if (SafeDisasterServiceNeedDrop() || !m_aggregate_service) return;
    m_aggregate_service->Aggregate(content);
}

void RecordService::DoStopAggregate(bool isLaunchReport) {
    if (SafeDisasterServiceNeedDrop() || !m_aggregate_service) return;
    m_aggregate_service->StopAggregate(isLaunchReport);
}

void RecordService::DoStartSemiTraceRecord(const std::string &content, const std::string &traceID) {
    if (SafeDisasterServiceNeedDrop() || !m_semifinished_service) return;
    m_semifinished_service->StartTraceRecord(content, traceID);
}

void RecordService::DoStartSemiSpanRecord(const std::string &content, const std::string &traceID, const std::string &spanID) {
    if (SafeDisasterServiceNeedDrop() || !m_semifinished_service) return;
    m_semifinished_service->StartSpanRecord(content, traceID, spanID);
}

void RecordService::DoFinishSemiTraceRecord(const std::string &content, const std::string &traceID, const std::string &spanIDList) {
    if (SafeDisasterServiceNeedDrop() || !m_semifinished_service) return;
    m_semifinished_service->FinishTraceRecord(content, traceID, spanIDList);
}

void RecordService::DoFinishSemiSpanRecord(const std::string &content, const std::string &traceID, const std::string &spanID) {
    if (SafeDisasterServiceNeedDrop() || !m_semifinished_service) return;
    m_semifinished_service->FinishSpanRecord(content, traceID, spanID);
}

void RecordService::DoDeleteSemifinishedRecords(const std::string &traceID, const std::string &spanIDList) {
    if (SafeDisasterServiceNeedDrop() || !m_semifinished_service) return;
    m_semifinished_service->DeleteRecords(traceID, spanIDList);
    
}

void RecordService::DoLaunchReportForSemi() {
    if (SafeDisasterServiceNeedDrop() || !m_semifinished_service) return;
    m_semifinished_service->LaunchReportForSemi();
}

void RecordService::DoUpdateReportHeader(const std::string& header) {
    // no content production here, so there is no need to care about "drop all data"
    for (int type: GetTypeSet()) {
        m_records.SaveFile(type);
    }
    m_env->SetReportLowLevelHeader(GlobalEnv::GetInstance().GetReportLowLevelHeader());
}

void RecordService::DoDropAllData() {
    // stop record file (cache + prepare + local) and remove
    for (int type: GetTypeSet()) {
        m_records.SaveFile(type);
    }
    RemoveCacheDirPath(m_env);
    RemovePrepareDirPath(m_env);
    RemoveLocalDirPath(m_env);
    
    // aggregate
    if (m_aggregate_service != nullptr) {
        m_aggregate_service->FreeFiles();
    }
    RemoveAggregateDirPath(m_env);
    
    // semifinish
    if (m_semifinished_service != nullptr) {
        m_semifinished_service->RemoveSemiFiles();
    }
    RemoveSemifinishedDirPath(m_env);
    
    // ready
    RemoveReadyDirPath(m_env);
}

bool RecordService::SafeDisasterServiceNeedDrop() {
    if (m_disaster_service) {
        return m_disaster_service->NeedDropData();
    }

    loge("record_service", "the disaster service is nullptr, module_id = %s, aid = %s", m_env->GetModuleId().c_str(), m_env->GetAid().c_str());
    return false;
}

} //namespace hermas
