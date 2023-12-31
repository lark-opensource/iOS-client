//
//  migrate_service.cpp
//  AWEAnywhereArena
//
//  Created by 崔晓兵 on 7/6/2022.
//

#include "migrate_service.h"
#include "aggre_mmap_file.h"
#include "protocol_service.h"
#include "json_util.h"
#include "file_util.h"
#include "records.h"
#include "record_aggregation.h"
#include "semfinished_service.h"
#include "file_service_util.h"
#include "forward_protocol.h"
#include "mmap_read_file.h"
#include "network_service.h"
#include "zstd_service.h"
#include "time_util.h"
#include "vector_util.h"
#include "user_default.h"
#include "log.h"
#include "network_util.h"

#include <unistd.h>

#define DELETE_INTERVAL (7 * 24 * 60 * 60 * 1000)


namespace hermas {

MigrateService::MigrateService(const std::shared_ptr<ModuleEnv>& module_env) : m_module_env(module_env) {}

void MigrateService::Migrate() {
    // process semifinished files
    ProcessSemifinishedFiles();
    
    // process aggregate files
    ProcessAggregateFiles();
    
    // move prepare to ready or local
    MovePrepareToReadyAndLocal(m_module_env);
    
    // remove expired files
    ProcessLocalFiles();
    
    // process ready files
    // there is a possibility where too much data needs to be migrated and we set the maximum number of migrations to 10
    int max_count = 10;
    bool should_continue = ProcessReadyFiles();
    while (should_continue && max_count > 0) {
        --max_count;
        should_continue = ProcessReadyFiles();
    }
}


void MigrateService::CleanMigrateMark() {
    std::string key = "process_local_finish_" + m_module_env->GetModuleId();
    UserDefault::Remove(key);
    
    key = "process_aggregate_finish_" + m_module_env->GetModuleId();
    UserDefault::Remove(key);
    
    key = "process_semi_finish_" + m_module_env->GetModuleId();
    UserDefault::Remove(key);
    
    key = "process_ready_finish_" + m_module_env->GetModuleId();
    UserDefault::Remove(key);
}


void MigrateService::ProcessLocalFiles() {
    std::string key = "process_local_finish_" + m_module_env->GetModuleId();
    if (UserDefault::Read(key) == "done") {
        return;
    }
    
    FilePath global_local_dir = GlobalEnv::GetInstance().GetRootPathName().Append(m_module_env->GetModuleId()).Append("local");
    std::vector<FilePath> aid_folders = GetFilesName(global_local_dir, FileSysType::kOnlyFolder);
    
    if (aid_folders.size() == 0) {
        UserDefault::Write(key, "done");
        return;
    }
    
    for(auto& aid_fold : aid_folders) {
        const FilePath local_dir = global_local_dir.Append(aid_fold);
        std::shared_ptr<FilesCollect> files_collect = std::make_shared<FilesCollect>(local_dir);
        while (files_collect->HasNextFile()) {
            auto file_path = files_collect->NextFilePath();
            int64_t timestamp = GetFileCreateTime(file_path);
            if (CurTimeMillis() - timestamp > DELETE_INTERVAL) {
                RemoveFile(file_path);
            }
        }
    }
}

void MigrateService::ProcessAggregateFiles() {
    std::string key = "process_aggregate_finish_" + m_module_env->GetModuleId();
    if (UserDefault::Read(key) == "done") {
        return;
    }
    
    FilePath global_aggregation_dir = GlobalEnv::GetInstance().GetRootPathName().Append(m_module_env->GetModuleId()).Append("aggregation");
    std::vector<FilePath> aid_folders = GetFilesName(global_aggregation_dir, FileSysType::kOnlyFolder);
    
    
    for(auto& aid_fold : aid_folders) {
        const FilePath aggregation_dir = global_aggregation_dir.Append(aid_fold);
        
        std::shared_ptr<hermas::Env> m_env = std::make_shared<hermas::Env>();
        m_env->SetModuleId(m_module_env->GetModuleId().c_str());
        m_env->SetAid(aid_fold.sstrValue().c_str());
        m_env->SetPid(std::to_string(getpid()).c_str());
        m_env->SetReportLowLevelHeader(GlobalEnv::GetInstance().GetReportLowLevelHeader());
        
        auto m_aggregator = std::make_unique<RecordAggregation>(m_env->GetAid(), m_env->GetModuleId(), GlobalEnv::GetInstance().GetRootPathName(), m_env->GetModuleEnv()->GetAggreFileSize(), m_env->GetModuleEnv()->GetAggreFileConfig(), m_env->GetModuleEnv()->GetAggreIntoMax());
        m_aggregator->callback = [this, m_env](const std::string& data) -> void {
            auto file_service = std::make_shared<FileService>(m_env);
            auto records = std::make_unique<Records>(m_env);
            records->SetFileService(file_service);
            records->RecordFile(INTERVAL_15000, data);
        };
        m_aggregator->LaunchReportForAggre();
    }
    
    UserDefault::Write(key, "done");
}

void MigrateService::ProcessSemifinishedFiles() {
    std::string key = "process_semi_finish_" + m_module_env->GetModuleId();
    if (UserDefault::Read(key) == "done") {
        return;
    }
    
    FilePath global_semi_dir = GlobalEnv::GetInstance().GetRootPathName().Append(m_module_env->GetModuleId()).Append("semifinished");
    
    std::vector<FilePath> aid_folders = GetFilesName(global_semi_dir, FileSysType::kOnlyFolder);
    for(auto& aid_fold : aid_folders) {
        std::shared_ptr<hermas::Env> m_env = std::make_shared<hermas::Env>();
        m_env->SetModuleId(m_module_env->GetModuleId().c_str());
        m_env->SetAid(aid_fold.sstrValue().c_str());
        m_env->SetPid(std::to_string(getpid()).c_str());
        m_env->SetReportLowLevelHeader(GlobalEnv::GetInstance().GetReportLowLevelHeader());
        
        auto service = std::make_unique<SemifinishedService>(m_env, false);
        service->LaunchReportForSemi();
    }
    
    UserDefault::Write(key, "done");
}

bool MigrateService::ProcessReadyFiles() {
    std::string key = "process_ready_finish_" + m_module_env->GetModuleId();
    if (UserDefault::Read(key) == "done") {
        return false;
    }
    
    std::vector<FilePath> uploaded_file_paths;
    std::vector<std::string> upload_aid_list;
    std::vector<std::unique_ptr<RecordData>> recordDataList = PackageForUploading(uploaded_file_paths, upload_aid_list);
    if (recordDataList.size() == 0) {
        UserDefault::Write(key, "done");
        return false;
    }
    
    std::string aid_list_str = "aid_list=[";
    aid_list_str.append(VectorToString(upload_aid_list, ",")).append("]");
    return UploadRecordData(recordDataList, uploaded_file_paths, aid_list_str);
}

std::vector<std::unique_ptr<RecordData>> MigrateService::PackageForUploading(std::vector<FilePath>& uploaded_file_paths, std::vector<std::string>& upload_aid_list) {
    std::vector<std::unique_ptr<RecordData>> result;

    unsigned long m_file_current_offset;
    FilePath m_slices_file_path;
    
    FilesCollectQueue file_dirs = GetReadyDirs(m_module_env);
    std::vector<FilePath> ready_file_paths = GetReadyFiles(file_dirs, nullptr);


    // Appending body to buffer
    int64_t body_size = 0;
    int64_t body_head_size = 0;
    
    bool is_need_slices = false;
    std::vector<FilePath> rename_file_list;
    for (auto& file_path : ready_file_paths) {

        logd("hermas_upload", "PackageForUploading has next file to upload");
        
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
        while (file_reader.HasNext()) {
            std::string data_line = file_reader.ReadNext();
            if (!is_first_line) {
                rd->header = data_line;
                body_head_size = data_line.length();
                is_first_line = true;
                //读完record header之后，开始读取起始偏移值并更新
                file_reader.SyncOffsetAfterReadHead();
                
                // 记录本次参与上报的aid
                std::string aid = GetFileAid(file_path);
                auto upload_aid_list_iter = find(upload_aid_list.begin(), upload_aid_list.end(), aid);
                
                if (!aid.empty() && (upload_aid_list_iter == upload_aid_list.end())) {
                    upload_aid_list.push_back(aid);
                }
            } else {
                body_size += (body_head_size + data_line.length());
                if (m_module_env->GetForbidSplitReportFile()) {
                    // 有的情况下，禁止文件切片
                    rd->body.push_back(data_line);
                    if (body_size >= GlobalEnv::GetInstance().GetMaxReportSize()) {
                        break;
                    }
                } else {
                    if (body_size <= GlobalEnv::GetInstance().GetMaxReportSize()) {
                        rd->body.push_back(data_line);
                    } else {
                        // 需要对文件进行切片
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
        result.push_back(std::move(rd));
        file_reader.CloseFile();
        
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

bool MigrateService::UploadRecordData(const std::vector<std::unique_ptr<RecordData>>& body, const std::vector<FilePath>& file_paths, std::string& aid_list) {
    if (body.empty()) {
        return false;
    }
    
    std::string data = ProtocolService::GenUploadData(body, m_module_env);
    if (data.size() == 0) return false;
    
    auto& m_network_service = NetworkService::GetInstance(m_module_env);

    std::string url = urlWithHostAndPath(m_module_env->GetDomain(), m_module_env->GetPath()) + "?" + GlobalEnv::GetInstance().GetQueryParams() + "&" + aid_list;
    std::string method = "POST";
    std::map<std::string, std::string> header_field = {
        { "Content-Type", "application/json; encoding=utf-8" },
        { "Accept", "application/json" },
        { "sdk_aid", "2085" },
        { "Version-Code", "1"},
    };
    
    HttpResponse result;
    if (m_module_env->GetEnableRawUpload()) {
        logd("hermas_upload", "upload data: %s", data.c_str());
        // 原始数据上报，仅在debug模式生效
        result = m_network_service->UploadRecord(url, method, header_field, data);
    } else {
        //compress data
        bool using_dict;
        double compress_time;
        auto& zstd_service = ZstdService::GetInstance(m_module_env);
        std::string compress_data = zstd_service->GetCompressedDataAndSyncHeader(data, header_field, using_dict, compress_time);
        
        if (compress_data.length() == 0) {
            return false;
        }
        
        // encrypt
        if (m_module_env->GetEncryptEnabled() && m_module_env->GetEncryptHandler()) {
            compress_data = m_module_env->GetEncryptHandler()(compress_data);
            logi("hermas_upload", "after encrypt size: %d", compress_data.size());
        }
        
        result = m_network_service->UploadRecord(url, method, header_field, compress_data);
    }
    
    
    if (result.is_success) {
        logd("hermas_upload", "upload successfully, remove file");
        RemoveFile(file_paths);

        if (m_file_current_offset != 0 && !m_slices_file_path.empty()) {
            // 如果有切片文件，并且上报上报成功了，那就更新该文件的offset
            MmapReadFile p_mmap_read_file(m_slices_file_path);
            bool ret = p_mmap_read_file.OpenReadFile();
            if (ret) {
                p_mmap_read_file.SetOffset((int)m_file_current_offset);
                p_mmap_read_file.CloseFile();
            }
        }
    } else {
        logd("hermas_upload", "upload failed");
        //网络上传失败不要删除文件
    }
    
    m_file_current_offset = 0;
    m_slices_file_path = FilePath();
    
    return true;
}


}
