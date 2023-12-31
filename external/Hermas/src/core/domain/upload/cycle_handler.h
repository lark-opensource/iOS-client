//
// Created by bytedance on 2020/9/7.
//

#ifndef HERMAS_CYCLE_HANDLER_H
#define HERMAS_CYCLE_HANDLER_H

#include <cstdint>
#include <string>
#include "protocol_service.h"
#include "network_service.h"
#include "handler.h"
#include "file_service.h"
#include "files_collect.h"
#include "mmap_read_file.h"
#include "mmap_write_file.h"
#include "protocol_service.h"
#include "mmap_file.h"
#include "flow_control.h"
#include "storage_monitor.h"
#include "zstd_service.h"
#include "disaster_service.h"

namespace hermas {

class CycleHandlerHelper;
class IFlowControlStrategy;
class IForwardService;

struct UploadMeasureInfo {
    double zstd_ratio;
    double zstd_compress_time;
    double gzip_ratio;
    double gzip_compress_time;
    double upload_size;
    double capacity_ratio;
    int64_t upload_inerval;
    bool using_zstd_dic;
    bool need_encrypt;
    bool should_upload;
    bool is_success;
};

class CycleHandler final : public Handler {

static constexpr int MSG_UPLOAD_CYCLE_WHAT = 1;
static constexpr int MSG_UPLOAD_REAL_WHAT = 2;
static constexpr int MSG_UPDATE_FLOW_CONTROL = 3;

public:
    CycleHandler(const std::shared_ptr<ModuleEnv>& module_env);
    
    ~CycleHandler() ;
    
    CycleHandler(const CycleHandler&) = delete;

public:
    void StartCycle();
    
    void StopCycle();

    void TriggerUpload();
    
    void UpdateFlowControlStrategy(FlowControlStrategyType type);

    void HandleMessage(int what, int64_t arg1, int64_t arg2, void *obj);
    
    std::vector<std::unique_ptr<RecordData>> PackageForUploading(std::vector<FilePath>& uploaded_file_paths, std::vector<std::string>& upload_aid_list);

    HttpResponse UploadRecordData(const std::vector<std::unique_ptr<RecordData>>& body, const std::vector<FilePath> &file_paths, std::string& aid_list, UploadMeasureInfo& measure_info);

private:
    void UploadSuccess();
    void UploadFailed();
    void ExecuteCycleLogic(int64_t interval, bool should_retry = true);
    void ExecuteCleanupLogic();
    void ExecuteRemoteCloudCommand();
    void ExecuteDowngradeInfoUpdateLogic();
    bool ExecuteDisasterLogic();
    bool ExecutePackageAndUploadLogic();
    bool ExecutePreCheckLogic();
    void ExecuteParamResetLogic(int64_t interval);
    void ExecuteNextCycleBuryLogic(int what, int64_t interval);
    
    static bool Compare(const FilePath& item1, const FilePath& item2);
    static std::vector<string> GetReadyPathKeys(const FilePath& item);
    static void SetTenMinutesAgeTimeStamp(int64_t time);
    
    long GetUploadInterval();
    long GetUploadMaxSize(long mod = 1l);
    static double GetUploadMaxSizeWeight(double memory_ratio, double virtual_memory_ratio, long mod);
    
    void LogMemroyUsage(const std::string& moment);
    
    void RecordUploadMeasureInfo();
    
    bool NeedUploadWithDowngrade(const Json::Value& json, const std::string& aid, double current_time);
    
    bool IsTagValid(const Json::Value& json);
    
private:
    std::shared_ptr<ModuleEnv> m_module_env;
    std::atomic<bool> m_start_enable;
    std::unique_ptr<IForwardService> m_forward_service;
    std::unique_ptr<StorageMonitor>& m_storage_monitor;
    std::mutex m_upload_mutex;
    int64_t m_last_clean_time;
    unsigned long m_file_current_offset = 0; //被切片的文件的offset地址，如果上传成功了就把这个offset值设置进去
    FilePath m_slices_file_path; //被切片的文件路径，如果上传失败，需要reset offset，不然会导致数据丢失
    std::unique_ptr<NetworkService>& m_network_service;
    std::unique_ptr<ZstdService>& m_zstd_dict_service;
    std::mutex m_strategy_mutex;
    FlowControlStrategyType m_strategy_type;
    std::vector<UploadMeasureInfo> m_upload_measure_infos;
    std::vector<FilePath> m_paths;
    std::vector<std::string> m_upload_aid_list;
    std::string m_aid_list_str;
    std::vector<std::unique_ptr<RecordData>> m_body;
    UploadMeasureInfo m_measure_info;
    HttpResponse m_response;
    long m_ready_mod;
    
};

} // namespace hermas

#endif //HERMAS_CYCLE_HANDLER_H
