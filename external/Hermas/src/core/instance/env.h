//
// Created by bytedance on 2020/8/5.
//

#pragma once

#include <string>
#include <map>
#include <vector>

#include "weak_handler.h"
#include "file_path.h"
#include "constants.h"
#include "rwlock.h"
#include "iuploader.h"



namespace hermas {

void SetDebug(bool is_debug);
bool IsDebug();

namespace Json { class Value; }

// global
class Env;
class ModuleEnv;

using WeakModuleEnvMap = WeakWrapper<std::map<std::string, std::shared_ptr<ModuleEnv>>>;
using WeakEnvMap = WeakWrapper<std::map<std::string, std::shared_ptr<Env>>>;
using WeakEnvVector = WeakWrapper<std::vector<std::shared_ptr<Env>>>;

class GlobalEnv {
public:
    static GlobalEnv& GetInstance();
private:
    GlobalEnv() = default;
    
public:
    void SetHeimdallrAid(const std::string& heimdallr_aid);
    void SetHostAid(const std::string& host_aid);
    void SetRootPathName(const FilePath& root_path_name);
    void SetQuotaPath(const std::string& quota_path);
    bool SetReportHeaderLowLevelParams(const std::string& header);
    void SetReportHeaderConstantParams(const std::string& params);
    void SetQueryParams(const std::string& header);
    void SetQueryParamsBlock(const std::function<std::string()>& block);
    void SetEncryptHandler(const std::function<std::string(const std::string&)>& handler);
    void SetMemoryHandler(const std::function<int64_t()>& handler);
    void SetMemoryLimitHandler(const std::function<int64_t()>& handler);
    void SetVirtualMemoryHandler(const std::function<int64_t()>& handler);
    void SetTotalVirtualMemoryHandler(const std::function<int64_t()>& handler);
    void SetFreeDiskSpaceSizeGenerator(const std::function<size_t()>& generator);
    void SetSequenceCodeGenerator(const std::function<int64_t (const std::string&)>& generator);
    void SetDeviceIdRequestHandler(const std::function<std::string()>& generator);
    void SetUseURLSessionUploadBlock(const std::function<bool()>& block);
    void SetStopWriteToDiskWhenUnhitBlock(const std::function<bool()>& is_stop);
    
    void SetZstdDictPath(const std::string& path);
    void SetMaxLogNumber(int max_line);
    void SetReportInterval(int interval);
    void SetReportIntervalLimited(int interval);
    void SetMaxReportSize(int max_size);
    void SetMaxReportSizeLimited(int max_size);
    void SetMaxFileSize(int max_file_size);
    void SetMaxStoreSize(int max_store_size);
    void SetCleanupInterval(int interval); // time unit is ms
    void SetMaxStoreTime(int max_store_time);
    void SetDevicePerformance(const std::string& level);
    void SetMaxReportSizeWeights(const std::map<std::string, double>& weights);
    void SetHeimdallrInitCompleted(bool heimdallr_init_completed);
    
    std::string& GetHeimdallrAid();
    std::string& GetHostAid();
    std::string& GetQuotaPath();
    FilePath& GetRootPathName();
    std::string GetQueryParams();
    std::string& GetZstdDictPath();
    std::string& GetDevicePerformace();
    
    std::unique_ptr<Json::Value>& GetReportConstantHeader();
    std::shared_ptr<Json::Value> GetReportLowLevelHeader();
    
    std::function<std::string()>& GetQueryParamsBlock();
    std::function<std::string(const std::string&)>& GetEncryptHandler();
    std::function<int64_t()>& GetMemoryHandler();
    std::function<int64_t()>& GetMemoryLimitHandler();
    std::function<int64_t()>& GetVirtualMemoryHandler();
    std::function<int64_t()>& GetTotalVirtualMemoryHandler();
    std::function<size_t()>& GetFreeDiskSpaceSizeGenerator();
    std::function<int64_t(const std::string&)>& GetSequenceCodeGenerator();
    std::function<std::string()>& GetDeviceIdRequestHandler();
    std::function<bool()>& GetUseURLSessionUploadBlock();
    std::map<std::string, double>& GetMaxReportSizeWeights();
    std::function<bool()>& GetStopWriteToDiskWhenUnhitBlock();
    
    int GetMaxLogNumber();
    int GetMaxFileSize();
    int GetMaxReportSize();
    int GetReportInterval();
    int GetMaxReportSizeLimited();
    int GetReportIntervalLimited();
    int GetMaxStoreSize();
    int GetMaxStoreTime();
    int GetCleanupInterval();
    double GetMemoryUsageRatio();
    double GetVirtualMemoryUsageRatio();
    
    bool GetHeimdallrInitCompleted();
    bool GetUseURLSessionUpload();
    
private:
    FilePath m_root_path;
    std::string m_hermdallr_aid;
    std::string m_host_aid = "";
    std::string m_quota_path;
    std::string m_query_params;
    std::string m_report_lowLevel_header_str;
    std::shared_ptr<Json::Value> m_report_lowlevel_header;
    std::unique_ptr<Json::Value> m_report_constant_header;
    std::function<std::string()> m_query_params_block;
    std::function<std::string(const std::string&)> m_encrypt_handler;
    std::function<std::string()> m_device_id_request_handler;
    std::function<int64_t()> m_memory_handler;
    std::function<int64_t()> m_memory_limit_handler;
    std::function<int64_t()> m_virtual_memory_handler;
    std::function<int64_t()> m_total_virtual_memory_handler;
    std::function<int64_t (const std::string&)> m_sequence_code_generator;
    std::function<bool()> m_use_url_session_upload_block;
    std::function<bool()> m_stop_write_to_disk_when_unhit_block;  //未命中采样不落盘
    std::string m_zstd_dict_path;
    std::string m_device_performace;
    std::map<std::string, double> m_max_report_size_weights;
    
    bool m_heimdallr_init_completed = false;
    
    // need atomic
    std::atomic<int> m_max_log_number;          // 本地单个文件的最多日志条数
    std::atomic<int> m_max_file_size;           // 本地单个文件的最大大小
    std::atomic<int> m_max_report_size;         // 最大上报大小
    std::atomic<int> m_max_report_size_limited; // 最大上报大小（限流模式下）
    std::atomic<int> m_report_interval;         // 上报间隔
    std::atomic<int> m_report_interval_limited; // 上报间隔（限流模式下）
    std::atomic<int> m_cleanup_interval;        // 本地存储清理间隔
    std::atomic<int> m_max_store_size;          // 本地最大存储大小
    std::atomic<int> m_max_store_time;          // 本地最大存储时长
    rwlock m_lock;
};


class ModuleEnv {
public:
    ModuleEnv();
    ~ModuleEnv() = default;

public:
    static void RegisterModuleEnv(const std::shared_ptr<ModuleEnv>& module_env);
    static std::shared_ptr<ModuleEnv>& GetModuleEnv(const std::string& module_id);
    
    static WeakPtr<WeakModuleEnvMap> GetModuleEnvMap() {
        static StaticWrapper<WeakModuleEnvMap> s_module_env_map;
        return s_module_env_map.SafeGet();
    }
    
    static rwlock& GetLock() {
        static rwlock lock;
        return lock;
    }

    int GetMaxStoreSize();
    int GetMaxLocalStoreSize();
    
    std::string& GetModuleId();
    std::string& GetPid();
    std::string& GetPath();
    std::string GetDomain();
    std::string GetForwardUrl();
    std::string GetZstdDictType();
    std::function<std::string(const std::string&)>& GetEncryptHandler();
    std::function<void(const std::string&, const std::string&)>& GetCloudCommandHandler();
    std::function<void(const std::string&)>& GetDowngradeRuleUpdator();
    std::function<bool(const std::string&, const std::string&, const std::string&, double)>& GetDowngradeHandler();
    std::function<bool(long)>& GetTagVerifyHandler();
    
    bool GetForwardEnabled();
    bool GetNeedReportDegrade();
    bool GetForbidSplitReportFile();
    bool GetEncryptEnabled();
    bool GetUploadTimerEnabled();
    bool GetShareRecordThread();
    
    int GetAggreFileSize();
    std::map<int, int>& GetAggreFileConfig();
    std::map<std::string, std::vector<std::string>>& GetAggreIntoMax();
    
    bool GetEnableRawUpload();
    
    std::unique_ptr<IUploader>& GetUploader();
    
    void SetDomain(const std::string& domain);
    void SetZstdDictType(const std::string& zstd_dict_type);
    void SetMaxStoreSize(int max_store_size);
    void SetMaxLocalStoreSize(int max_local_store_size);
    void SetUploader(std::unique_ptr<IUploader> uploader);
    void SetPid(const char *pid);
    void SetPath(const std::string& path);
    void SetModuleId(const char *module_id);
    void SetForwardEnabled(bool enabled);
    void SetForwardUrl(const std::string& url);
    void SetNeedReportDegrade(bool need);
    void SetForbidSplitReportFile(bool is_forbid);
    void SetCloudCommandHandler(const std::function<void(const std::string&, const std::string&)>& handler);
    void SetDowngradeRuleUpdator(const std::function<void(const std::string&)>& handler);
    void SetDowngradeHanlder(const std::function<bool(const std::string&, const std::string&, const std::string&, double)>& handler);
    void SetTagVerifyHanlder(const std::function<bool(long)>& handler);
    void SetAggreFileSize(int max_aggre_file_size);
    void SetAggreFileConfig(const std::map<int, int>& aggre_file_config);
    void SetAggreIntoMax(const std::map<std::string, std::vector<std::string>>& aggre_into_max);
    void SetEnableRawUpload(bool enableRawUpload);
    void SetEncryptEnabled(bool enable_encrypt);
    void SetUploadTimerEnabled(bool enable_timer);
    void SetShareRecordThread(bool enable_share);
   
private:
    std::string m_module_id = "";
    std::string m_pid;
    std::string m_process_name;
    std::string m_path;
    std::string m_domain;
    
    int m_aggre_file_size;                      // 聚合文件大小
    std::map<int, int> m_aggre_file_config;     // 聚合文件结构配置
    std::map<std::string, std::vector<std::string>> m_aggre_into_max; // 特殊聚合字段
    
    bool m_enable_raw_upload = false;           // 不压缩上报，仅在debug生效
    bool m_share_record_thread = false;         // 是否共享写入线程
    
    std::unique_ptr<IUploader> m_uploader;
    
    std::function<void(const std::string&, const std::string&)> m_cloud_command_handler;
    std::function<void(const std::string&)> m_downgrade_info_updator;
    std::function<bool(const std::string&, const std::string&, const std::string&, double)> m_downgrade_handler;
    std::function<bool(long)> m_tag_verify_handler;
    
    // need lock
    std::string m_forward_url;                  // 双发域名+Path
    std::string m_zstd_dict_type;               // zstd字典类型
    std::atomic<int> m_max_store_size;          // 本地最大存储大小
    std::atomic<int> m_max_local_store_size;    // 未命中采样最大存储大小
    std::atomic<bool> m_forward_enabled;        // 双发逻辑
    std::atomic<bool> m_need_report_degrade;    // 上报降级
    std::atomic<bool> m_encrypt_enabled;        // 是否加密
    std::atomic<bool> m_upload_timer_enabled;   // 是否启动定时上报
    std::atomic<bool> m_forbid_split_report_file; // 禁止文件分片上传（全链路）
    rwlock m_lock;
};


class Env {

public:
    enum class ERecordEncryptVer : char {
        NONE = (char) 0, DEFAULT = (char) 1
    };
    struct RecordEncrypt {
        ERecordEncryptVer encrypt_ver = ERecordEncryptVer::NONE;
        char *encrypt_key;
    };
    
    Env();
    ~Env();

public:
    static rwlock& GetLock() {
        static rwlock lock;
        return lock;
    }

    static WeakPtr<WeakEnvMap> GetEnvMap() {
        static StaticWrapper<WeakEnvMap> s_env_instance_map;
        return s_env_instance_map.SafeGet();
    }

    static void InitInstance(const std::shared_ptr<Env>& env);
    static std::shared_ptr<Env> GetInstance(const std::string& module_id, const std::string& aid);
    
    std::function<int64_t()> sequence_number_generator;
//    std::function<std::string()> common_params_block;

    std::shared_ptr<ModuleEnv> GetModuleEnv();
    
    std::string& GetPid();
    std::string& GetModuleId();
    std::string& GetAid();
    std::string GetIdentify();
    bool GetEnableSemiFinished();
    bool GetEnableAggregator();
    std::shared_ptr<Json::Value> GetReportLowLevelHeader();
    
    void SetPid(const char* pid);
    void SetModuleId(const char *module_id);
    void SetAid(const char *instance_id);
    void SetEnableSemiFinished(bool enableSemiFinished);
    void SetEnableAggregator(bool enableAggregator);
    void SetReportLowLevelHeader(const std::shared_ptr<Json::Value>& low_level_header);
    
private:
    std::string m_pid;
	std::string m_instance_id;
    std::string m_module_id;
    std::string m_process_name;
    bool m_enable_semifinished = false;
    bool m_enable_aggregator = false;
    std::unique_ptr<Json::Value> m_custom_param;
    std::shared_ptr<Json::Value> m_report_lowlevel_header;
    rwlock m_lock;
};

}
