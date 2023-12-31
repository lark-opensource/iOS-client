//
// Created by bytedance on 2020/8/5.
//

#include "env.h"

#include <utility>
#include <assert.h>
#include <future>
#include <unistd.h>
#include "log.h"
#include "json.h"
#include "json_util.h"
#include "file_service_util.h"


namespace hermas {

static bool is_debug_ = false;

//static function
bool IsDebug() {
    return is_debug_;
}

void SetDebug(bool is_debug) {
    is_debug_ = is_debug;
}


//--------------------------------------------------------------------------------------------------

GlobalEnv& GlobalEnv::GetInstance() {
    static GlobalEnv instance;
    return instance;
}

void GlobalEnv::SetRootPathName(const FilePath &root_path_name) {
    m_root_path = root_path_name;
}

void GlobalEnv::SetQuotaPath(const std::string &quota_path) {
    m_quota_path = quota_path;
}

void GlobalEnv::SetQueryParams(const std::string& header) {
    m_query_params = header;
}

bool GlobalEnv::SetReportHeaderLowLevelParams(const std::string& header) {
    if (header.size() == 0) {
        logw("hermas_env", "set frequent report header nil");
    }
    m_lock.lock();
    if (m_report_lowLevel_header_str == header) {
        m_lock.unlock();
        return false;
    }
    m_report_lowLevel_header_str = header;
    m_report_lowlevel_header = JSONObjectWithString(header);
    m_lock.unlock();
    return true;
}

void GlobalEnv::SetReportHeaderConstantParams(const std::string& params) {
    if (params.size() == 0) {
        logw("hermas_env", "set constant report header nil");
    }
    m_report_constant_header = JSONObjectWithString(params);;
}

void GlobalEnv::SetQueryParamsBlock(const std::function<std::string ()> &block) {
    m_query_params_block = block;
}

void GlobalEnv::SetEncryptHandler(const std::function<std::string(const std::string&)>& handler) {
    m_encrypt_handler = handler;
}

void GlobalEnv::SetMemoryHandler(const std::function<int64_t ()>& handler) {
    m_memory_handler = handler;
}

void GlobalEnv::SetMemoryLimitHandler(const std::function<int64_t ()>& handler) {
    m_memory_limit_handler = handler;
}

void GlobalEnv::SetVirtualMemoryHandler(const std::function<int64_t ()> &handler) {
    m_virtual_memory_handler = handler;
}

void GlobalEnv::SetTotalVirtualMemoryHandler(const std::function<int64_t ()> &handler) {
    m_total_virtual_memory_handler = handler;
}

void GlobalEnv::SetSequenceCodeGenerator(const std::function<int64_t (const std::string&)>& generator) {
    m_sequence_code_generator = generator;
}

void GlobalEnv::SetDeviceIdRequestHandler(const std::function<std::string()>& handler) {
    m_device_id_request_handler = handler;
}

void GlobalEnv::SetUseURLSessionUploadBlock(const std::function<bool ()> &block) {
    m_use_url_session_upload_block = block;
}

void GlobalEnv::SetStopWriteToDiskWhenUnhitBlock(const std::function<bool()>& block) {
    m_stop_write_to_disk_when_unhit_block = block;
}

void GlobalEnv::SetZstdDictPath(const std::string& path) {
    m_zstd_dict_path = path;
}

void GlobalEnv::SetHostAid(const std::string& host_aid) {
    m_host_aid = host_aid;
}

void GlobalEnv::SetHeimdallrAid(const std::string& heimdallr_aid) {
    m_hermdallr_aid = heimdallr_aid;
}

void GlobalEnv::SetDevicePerformance(const std::string& level) {
    m_device_performace = level;
}

void GlobalEnv::SetMaxReportSizeWeights(const std::map<std::string, double>& weights) {
    m_max_report_size_weights = weights;
}

void GlobalEnv::SetHeimdallrInitCompleted(bool heimdallr_init_completed) {
    m_heimdallr_init_completed = heimdallr_init_completed;
}

std::string& GlobalEnv::GetHeimdallrAid() {
    return m_hermdallr_aid;
}

std::string& GlobalEnv::GetHostAid() {
    return m_host_aid;
}

std::string& GlobalEnv::GetQuotaPath() {
    return m_quota_path;
}

FilePath& GlobalEnv::GetRootPathName() {
    return m_root_path;
}

std::string GlobalEnv::GetQueryParams() {
    std::string query_params;
    auto& block = GlobalEnv::GetInstance().GetQueryParamsBlock();
    if (block) query_params = static_cast<std::string>(block());
    if (query_params.empty()) {
        m_lock.lock_shared();
        query_params = m_query_params;
        m_lock.unlock_shared();
    }
    
    return query_params;
}

std::unique_ptr<Json::Value>& GlobalEnv::GetReportConstantHeader() {
    return m_report_constant_header;
}

std::shared_ptr<Json::Value> GlobalEnv::GetReportLowLevelHeader() {
    m_lock.lock_shared();
    std::shared_ptr<Json::Value> ret = m_report_lowlevel_header;
    m_lock.unlock_shared();
    return ret;
}

std::function<std::string()>& GlobalEnv::GetQueryParamsBlock() {
    return m_query_params_block;
}

std::function<std::string(const std::string&)>& GlobalEnv::GetEncryptHandler() {
    return m_encrypt_handler;
}

std::function<int64_t()>& GlobalEnv::GetMemoryHandler() {
    return m_memory_handler;
}

std::function<int64_t()>& GlobalEnv::GetMemoryLimitHandler() {
    return m_memory_limit_handler;
}

std::function<int64_t()>& GlobalEnv::GetVirtualMemoryHandler() {
    return m_virtual_memory_handler;
}

std::function<int64_t()>& GlobalEnv::GetTotalVirtualMemoryHandler() {
    return m_total_virtual_memory_handler;
}

std::function<int64_t (const std::string&)>& GlobalEnv::GetSequenceCodeGenerator() {
    return m_sequence_code_generator;
}

std::function<std::string()>& GlobalEnv::GetDeviceIdRequestHandler() {
    return m_device_id_request_handler;
}

std::function<bool()>& GlobalEnv::GetUseURLSessionUploadBlock() {
    return m_use_url_session_upload_block;
}

std::function<bool()>& GlobalEnv::GetStopWriteToDiskWhenUnhitBlock() {
    return m_stop_write_to_disk_when_unhit_block;
}

std::map<std::string, double>& GlobalEnv::GetMaxReportSizeWeights() {
    return m_max_report_size_weights;
}

std::string& GlobalEnv::GetZstdDictPath() {
    return m_zstd_dict_path;
}

int GlobalEnv::GetMaxLogNumber() {
    int ret = m_max_log_number.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetMaxFileSize() {
    return m_max_file_size;
}

int GlobalEnv::GetMaxReportSize(){
    int ret = m_max_report_size.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetReportInterval() {
    int ret = m_report_interval.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetMaxReportSizeLimited() {
    int ret = m_max_report_size_limited.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetReportIntervalLimited() {
    int ret = m_report_interval_limited.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetMaxStoreSize() {
    int ret = m_max_store_size.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetMaxStoreTime() {
    int ret = m_max_store_time.load(std::memory_order_acquire);
    return ret;
}

int GlobalEnv::GetCleanupInterval() {
    int ret = m_cleanup_interval.load(std::memory_order_acquire);
    return ret;
}

std::string& GlobalEnv::GetDevicePerformace() {
    return m_device_performace;
}

double GlobalEnv::GetMemoryUsageRatio() {
    int64_t app_memory = GetMemoryHandler()();
    int64_t app_memory_limit = GetMemoryLimitHandler()();
    return app_memory * 1.f / app_memory_limit;
}

double GlobalEnv::GetVirtualMemoryUsageRatio() {
    if (!GetVirtualMemoryHandler() || !GetTotalVirtualMemoryHandler()) return 0;
    int64_t app_virtual_memory_usage = GetVirtualMemoryHandler()();
    int64_t app_total_virtual_memory = GetTotalVirtualMemoryHandler()();
    if (app_total_virtual_memory <= 0 || app_virtual_memory_usage <= 0) return 0;
    return app_virtual_memory_usage * 1.f / app_total_virtual_memory;
}

bool GlobalEnv::GetHeimdallrInitCompleted() {
    return m_heimdallr_init_completed;
}

bool GlobalEnv::GetUseURLSessionUpload() {
    return GetUseURLSessionUploadBlock()();
}

void GlobalEnv::SetMaxLogNumber(int max_line) {
    m_max_log_number.store(max_line, std::memory_order_release);
}
void GlobalEnv::SetReportInterval(int interval) {
    if (interval < 1000) {
        interval = 1000;
        logd("hermas_env", "User set %d ms, but the minimum report interval is 1s", interval);
    }
    m_report_interval.store(interval, std::memory_order_release);
}

void GlobalEnv::SetReportIntervalLimited(int interval) {
    m_report_interval_limited.store(interval, std::memory_order_release);
}

void GlobalEnv::SetMaxReportSize(int max_size) {
    m_max_report_size.store(max_size, std::memory_order_release);
}

void GlobalEnv::SetMaxReportSizeLimited(int max_size) {
    m_max_report_size_limited.store(max_size, std::memory_order_release);
}

void GlobalEnv::SetMaxFileSize(int max_file_size) {
    m_max_file_size.store(max_file_size, std::memory_order_release);
}

void GlobalEnv::SetMaxStoreSize(int max_store_size) {
    m_max_store_size.store(max_store_size, std::memory_order_release);
}

void GlobalEnv::SetCleanupInterval(int interval) {
    m_cleanup_interval.store(interval, std::memory_order_release);
}

void GlobalEnv::SetMaxStoreTime(int max_store_time) {
    m_max_store_time.store(max_store_time, std::memory_order_release);
}

//--------------------------------------------------------------------------------------------------

ModuleEnv::ModuleEnv() {
    SetNeedReportDegrade(false);
    SetMaxLocalStoreSize(0);
}

void ModuleEnv::RegisterModuleEnv(const std::shared_ptr<ModuleEnv>& module_env) {
    WeakPtr<WeakModuleEnvMap> map_weak_ptr = ModuleEnv::GetModuleEnvMap();
    GetLock().lock();
    auto module_env_map = map_weak_ptr.Lock();
    if (module_env_map) {
        auto& map = module_env_map->GetItem();
        auto& key = module_env->GetModuleId();
        if (map.find(key) == map.end()) {
            map[key] = module_env;
        }
    }
    GetLock().unlock();
}

std::shared_ptr<ModuleEnv>& ModuleEnv::GetModuleEnv(const std::string& module_id) {
    GetLock().lock_shared();
    WeakPtr<WeakModuleEnvMap> map_weak_ptr = ModuleEnv::GetModuleEnvMap();
    auto& module_env_map = map_weak_ptr.Lock()->GetItem();
    std::shared_ptr<ModuleEnv>& module_env = module_env_map.find(module_id)->second;
    GetLock().unlock_shared();
    return module_env;
}


int ModuleEnv::GetMaxStoreSize() {
    int ret = m_max_store_size.load(std::memory_order_acquire);
    return ret;
}

int ModuleEnv::GetMaxLocalStoreSize() {
    int ret = m_max_local_store_size.load(std::memory_order_acquire);
    return ret;
}

std::string ModuleEnv::GetZstdDictType() {
    m_lock.lock_shared();
    std::string ret = m_zstd_dict_type;
    m_lock.unlock_shared();
    return ret;
}


std::string& ModuleEnv::GetModuleId() {
    return m_module_id;
}

std::string& ModuleEnv::GetPid() {
    return m_pid;
}

std::string& ModuleEnv::GetPath() {
    return m_path;
}

std::unique_ptr<IUploader>& ModuleEnv::GetUploader() {
    return m_uploader;
}

std::string ModuleEnv::GetForwardUrl() {
    m_lock.lock_shared();
    std::string ret = m_forward_url;
    m_lock.unlock_shared();
    return ret;
}

bool ModuleEnv::GetForwardEnabled() {
    bool ret = m_forward_enabled.load(std::memory_order_acquire);
    return ret;
}

bool ModuleEnv::GetNeedReportDegrade() {
    bool ret = m_need_report_degrade.load(std::memory_order_acquire);
    return ret;
}

bool ModuleEnv::GetEncryptEnabled() {
    bool ret = m_encrypt_enabled.load(std::memory_order_acquire);
    return ret;
}

bool ModuleEnv::GetUploadTimerEnabled() {
    bool ret = m_upload_timer_enabled.load(std::memory_order_acquire);
    return ret;
}

bool ModuleEnv::GetShareRecordThread() {
    return m_share_record_thread;
}

std::function<std::string(const std::string&)>& ModuleEnv::GetEncryptHandler() {
    return GlobalEnv::GetInstance().GetEncryptHandler();
}

std::function<void(const std::string&, const std::string&)>& ModuleEnv::GetCloudCommandHandler() {
    return m_cloud_command_handler;
}

std::function<void(const std::string&)>& ModuleEnv::GetDowngradeRuleUpdator() {
    return m_downgrade_info_updator;
}

std::function<bool(const std::string&, const std::string&, const std::string&, double)>& ModuleEnv::GetDowngradeHandler() {
    return m_downgrade_handler;
}

std::function<bool(long)>& ModuleEnv::GetTagVerifyHandler() {
    return m_tag_verify_handler;
}

bool ModuleEnv::GetForbidSplitReportFile() {
    bool ret = m_forbid_split_report_file.load(std::memory_order_acquire);
    return ret;
}

int ModuleEnv::GetAggreFileSize() {
    return m_aggre_file_size;
}

std::map<int, int>& ModuleEnv::GetAggreFileConfig() {
    return m_aggre_file_config;
}

std::map<std::string, std::vector<std::string>>& ModuleEnv::GetAggreIntoMax() {
    return m_aggre_into_max;
}

std::string ModuleEnv::GetDomain() {
    m_lock.lock_shared();
    std::string ret = m_domain;
    m_lock.unlock_shared();
    return ret;
}

bool ModuleEnv::GetEnableRawUpload() {
#ifdef DEBUG
    // 原始数据上报，仅在debug模式生效
    return m_enable_raw_upload;
#else
    return false;
#endif
}

void ModuleEnv::SetZstdDictType(const std::string& zstd_dict_type) {
    m_zstd_dict_type = zstd_dict_type;
}

void ModuleEnv::SetMaxStoreSize(int max_store_size) {
    m_max_store_size.store(max_store_size, std::memory_order_release);
}

void ModuleEnv::SetMaxLocalStoreSize(int max_local_store_size) {
    m_max_local_store_size.store(max_local_store_size, std::memory_order_release);
}

void ModuleEnv::SetUploader(std::unique_ptr<IUploader> uploader) {
    m_uploader = std::move(uploader);
}
void ModuleEnv::SetPid(const char *pid) {
    m_pid = pid;
}

void ModuleEnv::SetModuleId(const char *module_id) {
    m_module_id = module_id;
}

void ModuleEnv::SetForwardEnabled(bool enabled) {
    m_forward_enabled.store(enabled, std::memory_order_release);
}

void ModuleEnv::SetForwardUrl(const std::string& url) {
    m_lock.lock();
    m_forward_url = url;
    m_lock.unlock();
}

void ModuleEnv::SetPath(const std::string& path) {
    m_path = path;
}

void ModuleEnv::SetNeedReportDegrade(bool need) {
    m_need_report_degrade.store(need, std::memory_order_release);
}

void ModuleEnv::SetForbidSplitReportFile(bool is_forbid) {
    m_forbid_split_report_file.store(is_forbid, std::memory_order_release);
}

void ModuleEnv::SetCloudCommandHandler(const std::function<void (const std::string &, const std::string &)> &handler) {
    m_cloud_command_handler = handler;
}

void ModuleEnv::SetDowngradeRuleUpdator(const std::function<void (const std::string &)> &handler) {
    m_downgrade_info_updator = handler;
}

void ModuleEnv::SetDowngradeHanlder(const std::function<bool (const std::string &, const std::string &, const std::string &, double)> &handler) {
    m_downgrade_handler = handler;
}

void ModuleEnv::SetTagVerifyHanlder(const std::function<bool (long)>& handler) {
    m_tag_verify_handler = handler;
}

void ModuleEnv::SetAggreFileSize(int max_aggre_file_size) {
    m_aggre_file_size = max_aggre_file_size;
}

void ModuleEnv::SetAggreFileConfig(const std::map<int, int>& aggre_file_config) {
    m_aggre_file_config = aggre_file_config;
}

void ModuleEnv::SetAggreIntoMax(const std::map<std::string, std::vector<std::string>> &aggre_into_max) {
    m_aggre_into_max = aggre_into_max;
}

void ModuleEnv::SetDomain(const std::string& domain) {
    m_lock.lock();
    m_domain = domain;
    m_lock.unlock();
}

void ModuleEnv::SetEnableRawUpload(bool enableRawUplaod) {
    m_enable_raw_upload = enableRawUplaod;
}

void ModuleEnv::SetEncryptEnabled(bool enable_encrypt) {
    m_encrypt_enabled.store(enable_encrypt, std::memory_order_release);
}

void ModuleEnv::SetUploadTimerEnabled(bool enable_timer) {
    m_upload_timer_enabled.store(enable_timer, std::memory_order_release);
}

void ModuleEnv::SetShareRecordThread(bool enable_share) {
    m_share_record_thread = enable_share;
}


//--------------------------------------------------------------------------------------------------

std::shared_ptr<Env> Env::GetInstance(const std::string& module_id, const std::string& aid) {
    GetLock().lock_shared();
    std::string key = module_id + "_" + aid;
    WeakPtr<WeakEnvMap> map_weak_ptr = GetEnvMap();
    auto env_map_ptr = map_weak_ptr.Lock();
    if (env_map_ptr) {
        auto& env_map = env_map_ptr->GetItem();
        auto it = env_map.find(key);
        if (it != env_map.end()) {
            GetLock().unlock_shared();
            return it->second;
        } else {
            GetLock().unlock_shared();
            GetLock().lock();
            std::shared_ptr<Env> env = std::make_shared<Env>();
            env->SetModuleId(module_id.c_str());
            env->SetAid(aid.c_str());
            env->SetPid(std::to_string(getpid()).c_str());
            env->SetReportLowLevelHeader(GlobalEnv::GetInstance().GetReportLowLevelHeader());
            env_map_ptr->GetItem()[key] = env;
            GetLock().unlock();
            return env;
        }
    }
    GetLock().unlock_shared();
    return nullptr;
}

Env::Env() {
}

Env::~Env() {
    logi("hermas", "~Env");
}


std::shared_ptr<ModuleEnv> Env::GetModuleEnv() {
    auto& module_env = ModuleEnv::GetModuleEnv(GetModuleId());
    if (module_env) {
        return module_env;
    } else {
        //如果拿不到class static变量说明发生了进程退出的极端bad case，内存也不用回收了反正进行要退出了
        std::unique_ptr<ModuleEnv> ptr = std::make_unique<ModuleEnv>();
        return ptr;
    }
}

void Env::InitInstance(const std::shared_ptr<Env>& env) {
    GetLock().lock();
    WeakPtr<WeakEnvMap> map_weak_ptr = GetEnvMap();
    auto env_map_ptr = map_weak_ptr.Lock();
    if (env_map_ptr) {
        std::string key = env->GetModuleId() + "_" + env->GetAid();
        if (env_map_ptr->GetItem().find(key) == env_map_ptr->GetItem().end()) {
            env_map_ptr->GetItem()[key] = env;
        } else {
            std::shared_ptr<Env>& ori_env = env_map_ptr->GetItem()[key];
            ori_env->SetEnableAggregator(env->GetEnableAggregator());
            ori_env->SetEnableSemiFinished(env->GetEnableSemiFinished());
        }
    }
    GetLock().unlock();
}

std::string& Env::GetAid() {
    return m_instance_id;
}

std::string& Env::GetPid() {
    return m_pid;
}

std::string& Env::GetModuleId() {
    return m_module_id;
}

std::string Env::GetIdentify() {
    return m_module_id + "_" + m_instance_id;
}

bool Env::GetEnableAggregator() {
    return m_enable_aggregator;
}

bool Env::GetEnableSemiFinished() {
    return m_enable_semifinished;
}

std::shared_ptr<Json::Value> Env::GetReportLowLevelHeader() {
    m_lock.lock_shared();
    std::shared_ptr<Json::Value> ret = m_report_lowlevel_header;
    m_lock.unlock_shared();
    return ret;
}

void Env::SetPid(const char* pid) {
    m_pid = pid;
}

void Env::SetModuleId(const char *module_id) {
    m_module_id = module_id;
}

void Env::SetAid(const char *instance_id) {
    m_instance_id = instance_id;
}

void Env::SetEnableAggregator(bool enableAggregator) {
    m_enable_aggregator = enableAggregator;
}

void Env::SetEnableSemiFinished(bool enableSemiFinished) {
    m_enable_semifinished = enableSemiFinished;
}

void Env::SetReportLowLevelHeader(const std::shared_ptr<Json::Value>& low_level_header) {
    m_lock.lock();
    m_report_lowlevel_header = low_level_header;
    m_lock.unlock();
}

//--------------------------------------------------------------------------------------------------

}
