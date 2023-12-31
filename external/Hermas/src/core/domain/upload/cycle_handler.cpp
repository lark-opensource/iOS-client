//
// Created by bytedance on 2020/9/7.
//

#include "cycle_handler.h"

#include <atomic>

#include "env.h"
#include "log.h"
#include "gzip_util.h"
#include "zstd_util.h"
#include "json.h"
#include "disaster_service.h"
#include "forward_service.h"
#include "time_util.h"
#include "json_util.h"
#include "base64_util.hpp"
#include "vector_util.h"
#include "domain_manager.h"
#include "time_util.h"
#include "string_util.h"
#include "macro.h"
#include "network_util.h"

#define HOSTAID_KEY 1
#define INTERVAL_KEY 15000.0
#define STARTTIME_KEY 600000.0
static int64_t TenMinutesAgeTimeStamp = 0;
static int64_t MB = 1024 * 1024;

namespace hermas {

CycleHandler::CycleHandler(const std::shared_ptr<ModuleEnv>& module_env)
    : Handler("com.hermas.upload." + module_env->GetModuleId(), false)
    ,m_module_env(module_env)
    ,m_start_enable(false)
    ,m_forward_service(std::make_unique<ForwardService>(module_env))
    ,m_storage_monitor(StorageMonitor::GetInstance(module_env))
    ,m_network_service(NetworkService::GetInstance(module_env))
    ,m_zstd_dict_service(ZstdService::GetInstance(module_env))
    ,m_ready_mod(1l)
    ,m_last_clean_time(-1)
{
    UpdateFlowControlStrategy(FlowControlStrategyTypeNormal);
}

CycleHandler::~CycleHandler() {
    logd("hermas", "~CycleHandler");
    try {
        Stop();
    } catch(std::bad_alloc) {
        loge("hermas", "~CycleHandler bad alloc!");
    }
}


void CycleHandler::StartCycle() {
    if (m_start_enable.load(std::memory_order_acquire)) {
        return;
    }
    m_start_enable.store(true, std::memory_order_release);
    SendMsg(MSG_UPLOAD_CYCLE_WHAT);
}

void CycleHandler::StopCycle() {
    if (m_start_enable.load(std::memory_order_acquire)) {
        m_start_enable.store(false, std::memory_order_release);
    }
}

void CycleHandler::TriggerUpload() {
    // if the cycle has not been enabled, don't handle the message
    if (!m_start_enable.load(std::memory_order_acquire)) {
        return;
    }
    HandleMessage(0, 0, 0, nullptr);
}

void CycleHandler::UpdateFlowControlStrategy(FlowControlStrategyType type) {
    logi("hermas_upload", "update flowcontrol strategy: %s", (type == FlowControlStrategyTypeNormal ? "normal" : "limited"));
    std::lock_guard<std::mutex> lock(m_strategy_mutex);
    m_strategy_type = type;
}

void CycleHandler::UploadSuccess() {
    logd("hermas_upload", "upload successfully, remove uploaded file. moduleId = %s && appId_list = %s", m_module_env->GetModuleId().c_str(), m_aid_list_str.c_str());
    
    // update measure
    m_measure_info.is_success = true;
    
    // notification
    m_network_service->UploadSuccess(m_module_env->GetModuleId());
    
    // forward data if necessary
    if (m_module_env->GetForwardEnabled()) {
        m_forward_service->forward(m_body);
    }
}

void CycleHandler::UploadFailed() {
    logd("hermas_upload", "upload failed, remove uploaded file. moduleId = %s && appId_list = %s", m_module_env->GetModuleId().c_str(), m_aid_list_str.c_str());
    
    // update measure
    m_measure_info.is_success = false;
    
    // notification
    m_network_service->UploadFailure(m_module_env->GetModuleId());
}

void CycleHandler::HandleMessage(int what, int64_t arg1, int64_t arg2, void *obj) {
    std::lock_guard<std::mutex> lock(m_upload_mutex);
    
    // obtain upload interval
    int64_t interval = GetUploadInterval();
    
    // cycle logic
    ExecuteCycleLogic(interval);
    
    // execute cleanup logic
    ExecuteCleanupLogic();
    
    // start the next cycle when 'start_enable' is 'true'
    ExecuteNextCycleBuryLogic(what, interval);
}

void CycleHandler::ExecuteNextCycleBuryLogic(int what, int64_t interval) {
    switch (what) {
        case MSG_UPLOAD_CYCLE_WHAT:
            if (m_start_enable.load(std::memory_order_acquire)) {
                SendMsg(MSG_UPLOAD_CYCLE_WHAT, interval);
            }
            break;
        case MSG_UPLOAD_REAL_WHAT:
            // do nothing
            break;
    }
}

void CycleHandler::LogMemroyUsage(const std::string& moment) {
    if (GlobalEnv::GetInstance().GetMemoryHandler() == nullptr) return;
    auto& handler = GlobalEnv::GetInstance().GetMemoryHandler();
    int64_t memory_bytes = handler();
    float memory = memory_bytes * 1.0 / MB;
    logi("hermas_upload", "app total memory usage %s data load into memory:%fMB, %s", moment.c_str(), memory, m_module_env->GetModuleId().c_str());
}

void CycleHandler::ExecuteCycleLogic(int64_t interval, bool should_retry) {
    // pre check
    bool ret = ExecutePreCheckLogic();
    if (!ret) return;
    
    // preparing data to be uploaded and corresponding paths
    ExecuteParamResetLogic(interval);
 
    // try to defend oom crash due to big string
    ret = ExecutePackageAndUploadLogic();
    if (!ret) return;

    // execute remote cloud command
    ExecuteRemoteCloudCommand();
    
    // execute downgrade logic
    ExecuteDowngradeInfoUpdateLogic();
    
    // update disaster state
    ret = ExecuteDisasterLogic();
    ret ? UploadSuccess() :  UploadFailed();
    
    // retry if needed
    if (!ret && should_retry) {
        ExecuteCycleLogic(interval, false);
    }
}

bool CycleHandler::ExecutePreCheckLogic() {
    // check if need report degrade
    if (m_module_env->GetNeedReportDegrade()) {
        return false;
    }
    
    // check if the device id is empty
    auto header = GlobalEnv::GetInstance().GetReportLowLevelHeader();
    auto device_id = (*header)["device_id"].asString();
    if (device_id.size() == 0 || device_id == "0") {
        loge("hermas_upload", "the device id is null or 0");
        auto& handler = GlobalEnv::GetInstance().GetDeviceIdRequestHandler();
        if (handler) {
            std::string did = handler();
            if (did.size() >= 0 && did != "0") {
                logi("hermas_upload", "request device id = %s", did.c_str());
                return true;
            }
        }
        return false;
    }
    
    return true;
}

void CycleHandler::ExecuteParamResetLogic(int64_t interval) {
    m_paths.clear();
    m_upload_aid_list.clear();
    m_aid_list_str = "";
    m_measure_info = {};
    m_response = {};
    m_measure_info.upload_inerval = interval;
}

bool CycleHandler::ExecutePackageAndUploadLogic() {
    try {
        m_body = PackageForUploading(m_paths, m_upload_aid_list);
        if (m_body.size() == 0) return false;
        m_aid_list_str = "aid_list=[" + VectorToString(m_upload_aid_list, ",") + "]";
        m_response = UploadRecordData(m_body, m_paths, m_aid_list_str, m_measure_info);
    } catch (...) {
        return false;
    }
    return true;
}

bool CycleHandler::ExecuteDisasterLogic() {
    bool has_success_result = false;
    std::map<std::shared_ptr<Env>, ServerResult> serverResultMap;
    for (auto& aid : m_upload_aid_list) {
        struct ServerResult serverResult;
        serverResult.is_server_saved = false;
        serverResult.server_quato_state = ServerStateUnknown;
        std::shared_ptr<Env> env = Env::GetInstance(m_module_env->GetModuleId(), aid);
        auto& disaster_service = DisasterService::GetInstance(env);
        if (!disaster_service) {
            loge("hermas_upload", "the disaster service is nullptr, module_id = %s, aid = %s", m_module_env->GetModuleId().c_str(), aid.c_str());
            serverResult.is_server_saved = false;
            serverResult.server_quato_state = ServerStateSuccess;
            if (m_response.http_code >= 200 && m_response.http_code <= 299) {
                serverResult.is_server_saved = true;
            }
        } else {
            serverResult = disaster_service->UpdateServerState(m_response.data, m_response.http_code);
            serverResultMap[env] = serverResult;
        }
    }
    
    std::vector<std::string> server_saved_aid_list;
    for (auto& serverRes : serverResultMap) {
        if (serverRes.second.server_quato_state == ServerStateUnknown) {
            continue;
        }
        has_success_result = true;
        if (serverRes.second.server_quato_state == ServerStateDropAllData) {
            // send message to record service to drop all data, include the ready directory
            auto& record_service = infrastruct::BaseDomainManager::GetInstance(serverRes.first)->GetRecordService();
            record_service->DropAllData();
        }
        // only remove the files saved by the server
        if (serverRes.second.server_quato_state != ServerStateUnknown && serverRes.second.is_server_saved) {
            server_saved_aid_list.push_back(serverRes.first->GetAid());
        }
    }
    
    RemoveFile(m_paths, server_saved_aid_list);
    
    std::string slice_aid = GetFileAid(m_slices_file_path);
    bool exist = std::find(server_saved_aid_list.begin(), server_saved_aid_list.end(), slice_aid) != server_saved_aid_list.end();
    if (exist && m_file_current_offset != 0 && !m_slices_file_path.empty()) {
        // if there is slice file uploaded successfully, we update the offset of the file
        MmapReadFile p_mmap_read_file(m_slices_file_path);
        bool ret = p_mmap_read_file.OpenReadFile();
        if (ret) {
            p_mmap_read_file.SetOffset((int)m_file_current_offset);
            p_mmap_read_file.CloseFile();
        }
    }
    
    // reset slice
    m_file_current_offset = 0;
    m_slices_file_path = FilePath();
    
    return has_success_result;
}

void CycleHandler::ExecuteDowngradeInfoUpdateLogic() {
    auto& downgradeRuleUpdator = m_module_env->GetDowngradeRuleUpdator();
    if (!downgradeRuleUpdator) return;
    
    Json::Value json;
    bool ret = hermas::ParseFromJson(m_response.data, json);
    if (!ret) return;
    auto& downgrade_rule = json["downgrade_rule"];
    std::string rule = downgrade_rule ? downgrade_rule.toStyledString() : "";
    downgradeRuleUpdator(rule);
}

void CycleHandler::ExecuteRemoteCloudCommand() {
    Json::Value json;
    bool ret = hermas::ParseFromJson(m_response.data, json);
    if (!ret) return;

    auto& result_dic = json["result"];
    if (!result_dic) return;
    
    auto base64_data = result_dic["data"].asString();
    if (base64_data.length() == 0) return;
    std::string ran = json["ran"].asString();
    if (ran.length() == 0) return;
    
    auto& handler = m_module_env->GetCloudCommandHandler();
    if (handler != nullptr) {
        handler(base64_data, ran);
    }
}

void CycleHandler::ExecuteCleanupLogic() {
    int64_t current_time = CurTimeMillis();
    // default cleanup interval：30 * 1000 ms
    if (current_time - m_last_clean_time > GlobalEnv::GetInstance().GetCleanupInterval()) {
        logd("hermas_upload", "clean up, moduleid = %s \t, time diff %d \n", m_module_env->GetModuleId().c_str(), current_time - m_last_clean_time);
        m_last_clean_time = current_time;
        m_storage_monitor->CleanStorageIfNeeded();
    }
}

std::vector<std::unique_ptr<RecordData>> CycleHandler::PackageForUploading(std::vector<FilePath>& uploaded_file_paths, std::vector<std::string>& upload_aid_list) {
    std::vector<std::unique_ptr<RecordData>> result;
    auto filter = [this](const std::string& aid) -> bool {
        auto env = Env::GetInstance(m_module_env->GetModuleId(), aid);
        auto& disaster_service = DisasterService::GetInstance(env);
        if (!disaster_service) {
            loge("hermas_upload", "the disaster service is nullptr, module_id = %s, aid = %s", m_module_env->GetModuleId().c_str(), aid.c_str());
            return true;
        }
        return disaster_service->IsServerAvailable();
    };
    FilesCollectQueue file_dirs = GetReadyDirs(m_module_env, filter);
    if (file_dirs.size() == 0) return result;
    
    TenMinutesAgeTimeStamp = TenMinutesAgoMillis();
    std::vector<FilePath> ready_file_paths = GetReadyFiles(file_dirs, Compare);


    // Appending body to buffer
    int64_t body_size = 0;
    int64_t body_head_size = 0;
    double current_time = CurTimeSecond();
    
    bool is_need_slices = false;
    std::vector<FilePath> rename_file_list;
    for (auto& file_path : ready_file_paths) {
        logd("hermas_upload", "PackageForUploading has next file to upload");
        std::string aid = GetFileAid(file_path);
        MmapReadFile file_reader(file_path);
        bool file_opened = file_reader.OpenReadFile();
        if (!file_opened) {
            if (file_reader.IsOverMaxOpenRetryTimes()) {
                //over max retry times, delete file auto
                RemoveFile(file_path);
            } else {
                //rename, add retry times
                rename_file_list.push_back(file_path);
            }
            continue;
        }
        auto rd = std::make_unique<RecordData>();
        bool is_first_line = false;
        long max_upload_size = GetUploadMaxSize(m_ready_mod);
        while (file_reader.HasNext()) {
            std::string data_line = file_reader.ReadNext();
            if (!is_first_line) {
                rd->header = data_line;
                body_head_size = data_line.length();
                is_first_line = true;
                // After reading the record header, start reading the starting offset value and update it
                file_reader.SyncOffsetAfterReadHead();
                
                // record the aid reported this time
                auto upload_aid_list_iter = find(upload_aid_list.begin(), upload_aid_list.end(), aid);
                
                if (!aid.empty() && (upload_aid_list_iter == upload_aid_list.end())) {
                    upload_aid_list.push_back(aid);
                }
            } else {
                body_size += (body_head_size + data_line.length());
                if (m_module_env->GetForbidSplitReportFile()) {
                    // in some cases, the file slice is forbidden (for exapmle, the open tracing data should be treated as a whole, slices are not acceptable, nor caps are acceptable)
                    rd->body.push_back(data_line);
                } else {
                    if (body_size <= max_upload_size) {
                        Json::Value json;
                        bool ret = hermas::ParseFromJson(data_line, json);
                        if (!ret) {
                            rd->body.push_back(data_line);
                        } else {
                            if (NeedUploadWithDowngrade(json, aid, current_time) && IsTagValid(json)) {
                                rd->body.push_back(data_line);
                            }
                        }
                    } else {
                        // here we need to slice the file
                        if (rd->body.size() == 0) {
                            m_file_current_offset = file_reader.GetCurrentFileOffset();
                            rd->body.push_back(data_line);
                        } else {
                            m_file_current_offset = file_reader.GetCurrentFileOffset() - data_line.length() - sizeof(int32_t);
                        }
                        m_slices_file_path = file_path;
                        is_need_slices = true;
                        
                        break;
                    }
                }
            }
        }
        
        file_reader.CloseFile();
        if (rd->body.size() == 0) {
            RemoveFile(file_path);
        } else {
            result.push_back(std::move(rd));
        }
        
        if (!is_need_slices) {
            uploaded_file_paths.push_back(file_path);
        } else {
            break;
        }

    }
    // rename retry time
    for (auto iterator = rename_file_list.begin(); iterator != rename_file_list.end(); ++iterator) {
        auto old_file_path = (*iterator).strValue();
        int8_t retry_time = STR_TO_INT(old_file_path.substr(old_file_path.length() - 1, old_file_path.length()).c_str());
        retry_time++;
        
        StringType old_retry_time_file_path = StringType(old_file_path);
        StringType new_retry_time_file_path = old_file_path.replace(old_file_path.length() - 1, 1, TO_STRING(retry_time));
        
        RENAME_FILE(old_retry_time_file_path.c_str(), new_retry_time_file_path.c_str());
    }
    
    return result;
}

HttpResponse CycleHandler::UploadRecordData(const std::vector<std::unique_ptr<RecordData>>& body, const std::vector<FilePath> &file_paths, std::string& aid_list, UploadMeasureInfo& measure_info) {
    if (body.empty()) {
        struct HttpResponse response;
        response.is_success = false;
        return response;
    }
    
    std::string data = ProtocolService::GenUploadData(body, m_module_env);
    if (data.size() == 0) {
        logd("hermas_upload", "body is empty");
        struct HttpResponse response;
        response.is_success = false;
        return response;
    };
    
    std::string url = urlWithHostAndPath(m_module_env->GetDomain(), m_module_env->GetPath()) + "?" + GlobalEnv::GetInstance().GetQueryParams() + "&" + aid_list;

    std::string method = "POST";
    std::map<std::string, std::string> header_field = {
        { "Content-Type", "application/json; encoding=utf-8" },
        { "Accept", "application/json" },
        { "sdk_aid", "2085" },
        { "Version-Code", "1"},
    };
    
    HttpResponse result;
    double zstd_ratio = 0.f, gzip_ratio = 0.f, final_data_size = 0.f;
    bool need_encrypt = false;
    if (m_module_env->GetEnableRawUpload()) {
        logd("hermas_upload", "upload data: %s", data.c_str());
        // In debug env environment, we upload raw data instead of encryption for the convenience of debugging
        result = m_network_service->UploadRecord(url, method, header_field, data);
        measure_info.should_upload = false;
    } else {
        // compress data
        bool using_dict;
        auto& zstd_service = ZstdService::GetInstance(m_module_env);
        
        double zstd_compress_time;
        double gzip_compress_time;
        std::string zstd_compress_data = zstd_service->GetCompressedDataAndSyncHeader(data, header_field, using_dict, zstd_compress_time);
        
        // compress failed, virtual memory exhausted
        if (zstd_compress_data.length() == 0) {
            logd("hermas_upload", "zstd compress failed, maybe because the virtual memory is exhausted");
            struct HttpResponse response;
            response.is_success = false;
            return response;
        };
        
        zstd_ratio = zstd_compress_data.size() * 1.0 / data.size();
        
        // release gzip compress data immediately
        {
            double current_time = CurTimeMillis();
            std::string gzip_compress_data = gzip_data(data.c_str());
            gzip_compress_time = CurTimeMillis() - current_time;
            gzip_ratio = gzip_compress_data.size() * 1.0 / data.size();
        }
        final_data_size = static_cast<double>(zstd_compress_data.size());
        
        // encrypt
        if (m_module_env->GetEncryptEnabled() && m_module_env->GetEncryptHandler()) {
            zstd_compress_data = m_module_env->GetEncryptHandler()(zstd_compress_data);
            need_encrypt = true;
            logi("hermas_upload", "after encrypt size: %d", zstd_compress_data.size());
        }
        result = m_network_service->UploadRecord(url, method, header_field, zstd_compress_data, need_encrypt);
        
        // record compress ratio
        measure_info.zstd_ratio = zstd_ratio;
        measure_info.zstd_compress_time = zstd_compress_time;
        measure_info.gzip_ratio = gzip_ratio;
        measure_info.gzip_compress_time = gzip_compress_time;
        measure_info.upload_size = final_data_size;
        measure_info.need_encrypt = need_encrypt;
        measure_info.using_zstd_dic = using_dict;
        measure_info.should_upload = true;
        measure_info.capacity_ratio = data.size() * 1.0 / (body.size() * GlobalEnv::GetInstance().GetMaxFileSize());
    }
    return result;
}

void CycleHandler::RecordUploadMeasureInfo() {
    if (!m_measure_info.should_upload) return;
    
    m_upload_measure_infos.push_back(m_measure_info);
    auto env = Env::GetInstance("batch", GlobalEnv::GetInstance().GetHeimdallrAid());
    if (!env) return;
    
    auto& record_service = infrastruct::BaseDomainManager::GetInstance(env)->GetRecordService();
    if (!record_service) return;
    
    std::shared_ptr<Json::Value> lowLevelHeader = GlobalEnv::GetInstance().GetReportLowLevelHeader();
    if (lowLevelHeader == nullptr) {
        logi("hermas_upload", "the low level header is nullptr");
        return;
    }
    
    auto low_level_header = *(lowLevelHeader);
    for(auto& info : m_upload_measure_infos) {
        Json::Value json;
        json["service"] = "hermas_upload_info";
        json["module"] = "event";
        json["timestamp"] = CurTimeMillis();
        json["log_type"] = "service_monitor";
        json["aid"] = GlobalEnv::GetInstance().GetHeimdallrAid();
        json["app_version"] = low_level_header["app_version"];
        json["os_version"] = low_level_header["os_version"];
        json["sdk_version"] = low_level_header["sdk_version"];
        json["update_version_code"] = low_level_header["update_version_code"];
        
        Json::Value category;
        category["module_id"] = m_module_env->GetModuleId();
        category["using_zstd_dic"] = info.using_zstd_dic ? "true" : "false";
        category["device_performace"] = GlobalEnv::GetInstance().GetDevicePerformace();
        category["is_success"] = info.is_success ? "true" : "false";
        json["category"] = std::move(category);

        Json::Value metric;
        metric["compress_ratio_zstd"] = info.zstd_ratio;
        metric["compress_ratio_gzip"] = info.gzip_ratio;
        metric["upload_data_size"] = info.upload_size;
        metric["upload_interval"] = info.upload_inerval;
        metric["capacity_ratio"] = info.capacity_ratio;
        
        auto dir_info = StorageMonitor::GetInstance(m_module_env)->GetDirInfo();
        metric["disk_size_local"] = std::get<0>(dir_info);
        metric["disk_size_cache"] = std::get<1>(dir_info);
        metric["disk_size_ready"] = std::get<2>(dir_info);
        metric["disk_size_aggre"] = std::get<3>(dir_info);
        metric["disk_size_semi"] = std::get<4>(dir_info);
        
        auto& memory_handler = GlobalEnv::GetInstance().GetMemoryHandler();
        int64_t memory_bytes = memory_handler();
        metric["app_memory"] = memory_bytes * 1.0 / MB;
        
        auto& memory_limit_handler = GlobalEnv::GetInstance().GetMemoryLimitHandler();
        int64_t memory_limit_bytes = memory_limit_handler();
        metric["app_memory_limit"] = memory_limit_bytes * 1.0 / MB;
        metric["app_memory_ratio"] = memory_bytes * 1.f / memory_limit_bytes;
        
        auto& virtual_memory_handler = GlobalEnv::GetInstance().GetVirtualMemoryHandler();
        int64_t vitual_memory_bytes = virtual_memory_handler();
        metric["vitual_app_memory"] = vitual_memory_bytes * 1.0 / MB;
        
        auto& total_virtual_memory_handler = GlobalEnv::GetInstance().GetTotalVirtualMemoryHandler();
        int64_t total_vitual_memory_bytes = total_virtual_memory_handler();
        metric["total_vitual_app_memory"] = total_vitual_memory_bytes * 1.0 / MB;
        
        double vitual_memory_usage_ratio = GlobalEnv::GetInstance().GetVirtualMemoryUsageRatio();
        metric["app_virtual_memory_ratio"] = vitual_memory_usage_ratio;

        json["metric"] = std::move(metric);

        record_service->Record(INTERVAL_15000, json.toStyledString());
    }
    
    m_upload_measure_infos.clear();
}

void CycleHandler::SetTenMinutesAgeTimeStamp(int64_t time) {
    TenMinutesAgeTimeStamp = time;
}

bool CycleHandler::Compare(const FilePath& item1, const FilePath& item2) {
    if (item1.strValue().length() == 0 || item2.strValue().length() == 0) {
        return false;
    }
    
    std::vector<string> path1_keys = GetReadyPathKeys(item1);
    std::vector<string> path2_keys = GetReadyPathKeys(item2);
    if (path1_keys.size() != 3 || path2_keys.size() != 3) {
        return false;
    }
    
    double type1 = STR_TO_INT(path1_keys[1].c_str()) / INTERVAL_KEY;
    double type2 = STR_TO_INT(path2_keys[1].c_str()) / INTERVAL_KEY;
    if (path1_keys.front() == GlobalEnv::GetInstance().GetHostAid()) {
        type1 += HOSTAID_KEY;
    }
    int64_t startTime = std::atoll(path1_keys[2].c_str());
    type1 += (startTime - TenMinutesAgeTimeStamp) / STARTTIME_KEY;
    
    if (path2_keys.front() == GlobalEnv::GetInstance().GetHostAid()) {
        type2 += HOSTAID_KEY;
    }
    startTime = std::atoll(path2_keys[2].c_str());
    type2 += (startTime - TenMinutesAgeTimeStamp) / STARTTIME_KEY;
    
    return type1 < type2;
}

std::vector<string> CycleHandler::GetReadyPathKeys(const FilePath &item) {
    std::vector<std::string> path_keys;
    
    auto pos = item.strValue().find("ready/");
    if (pos == std::string::npos) {
        return path_keys;
    }
    std::string temp = item.strValue().substr(pos + std::strlen("ready/"));
    std::vector<std::string> ret = SplitStringPiece(temp, "/", WhitespaceHandling::TRIM_WHITESPACE, SplitResult::SPLIT_WANT_NONEMPTY);
    if (ret.size() != 3) {
        return path_keys;
    }
    ret[2] = std::to_string(GetFileCreateTime(item));
    return ret;
}

long CycleHandler::GetUploadInterval() {
    if (m_strategy_type == FlowControlStrategyTypeNormal) {
        long interval = ::hermas::GetUploadInterval(NormalFlowControlStrategy());
        auto ready_size = m_storage_monitor->GetReadyDirSize();
        
        long maxUploadSize = GetUploadMaxSize();
        m_ready_mod = ready_size / maxUploadSize;
        // we assume that
        if (m_ready_mod > 2) {
            interval /= m_ready_mod;
            interval = std::max(interval, 5000l);
        }
        return interval;
    } else {
        return ::hermas::GetUploadInterval(LimitedFlowControlStrategy());
    }
}

long CycleHandler::GetUploadMaxSize(long mod) {
    long ret;
    if (m_strategy_type == FlowControlStrategyTypeNormal) {
        ret = ::hermas::GetUploadMaxSize(NormalFlowControlStrategy());
    } else {
        ret = ::hermas::GetUploadMaxSize(LimitedFlowControlStrategy());
    }
    double memory_ratio = GlobalEnv::GetInstance().GetMemoryUsageRatio();
    double virtual_memory_ratio = GlobalEnv::GetInstance().GetVirtualMemoryUsageRatio();
    ret = GetUploadMaxSizeWeight(memory_ratio, virtual_memory_ratio, mod) * ret;
    return ret;
}

double CycleHandler::GetUploadMaxSizeWeight(double memory_ratio, double virtual_memory_ratio, long mod) {
    std::map<std::string, double> weights = GlobalEnv::GetInstance().GetMaxReportSizeWeights();
    double level_one_weight = weights.count("upload_size_weight_1") ?: 0.5;
    double level_two_weight = weights.count("upload_size_weight_2") ?: 0.25;
    double weight = 1;
    if (memory_ratio < 0.7 && virtual_memory_ratio < 0.5) {
        if (mod > 5) weight = 2;
        else if (mod > 3) weight = 1.5;
    } else if ((memory_ratio < 0.7 && virtual_memory_ratio >= 0.7 && virtual_memory_ratio < 0.85)
               || (memory_ratio >= 0.7 && virtual_memory_ratio < 0.85)) {
        weight = level_one_weight;
    } else if (virtual_memory_ratio >= 0.85) {
        weight = level_two_weight;
    }
    return weight;
}

bool CycleHandler::NeedUploadWithDowngrade(const Json::Value& json, const std::string& aid, double current_time) {
    auto& handler = m_module_env->GetDowngradeHandler();
    if (!handler) return true;

    std::string log_type = json["log_type"].asString();
    std::string service_name = json["service"].asString();
    return handler(log_type, service_name, aid, current_time);
}

bool CycleHandler::IsTagValid(const Json::Value& json) {
    auto& handler = m_module_env->GetTagVerifyHandler();
    if (!handler) return true;
    auto& tag = json["custom_tag"];
    if (!tag) return true;
    return handler(tag.asInt());
}

} // namespace hermas
