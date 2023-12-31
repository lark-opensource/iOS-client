//
//  cache_service.cpp
//  Hermas
//
//  Created by 崔晓兵 on 28/1/2022.
//

#include "cache_service.h"
#include "file_service.h"
#include "file_util.h"
#include "mmap_read_file.h"
#include "protocol_service.h"
#include "log.h"
#include "env.h"
#include "json.h"
#include "json_util.h"
#include "constants.h"

namespace hermas {

void CacheService::WriteBack() {
    FSQueue file_dirs = CollectFileDirs();
    if (file_dirs.size() == 0) return;
    
    logd("hermas_cache", "write cache back to local or ready directory");
    
    std::unique_ptr<MmapWriteFile> ready_file_writer = nullptr;
    std::unique_ptr<MmapWriteFile> local_file_writer = nullptr;
    
    while (!file_dirs.empty()) {
        m_rename_file_list.clear();
        auto file_collect = std::move(file_dirs.front());
        file_dirs.pop_front();
        while (file_collect->HasNextFile()) {
            auto file_path = file_collect->NextFilePath();
            auto file_reader = GenerateFileReader(file_path);
            if (!file_reader) continue;;
            while (file_reader->HasNext()) {
                std::string data_line = file_reader->ReadNext();
                std::string after_data_line;
                bool is_ready = NeedUpload(data_line, after_data_line);
                if (is_ready) {
                    if (!ready_file_writer) {
                        FilePath ready_file_path = GenCache2ReadyFile(file_path);
                        ready_file_writer = GenerateFileWriter(ready_file_path);
                    }
                    if (ready_file_writer) {
                        bool ret = Record(ready_file_writer, after_data_line);
                        if (!ret) {
                            logi("hermas_cache", "write cache back to ready directory, filename = %s", ready_file_writer->GetFilePath().strValue().c_str());
                            ready_file_writer->CloseFile();
                            MoveCache2ReadyFile(ready_file_writer->GetFilePath());
                            ready_file_writer = nullptr;
                        }
                    }
                } else {
                    auto& block = GlobalEnv::GetInstance().GetStopWriteToDiskWhenUnhitBlock();
                    if (block && block()) {
                        continue;
                    }
                    
                    if (!local_file_writer) {
                        FilePath local_file_path = GenCache2LocalFile(file_path);
                        local_file_writer = GenerateFileWriter(local_file_path);
                    }
                    if (local_file_writer) {
                        bool ret = Record(local_file_writer, after_data_line);
                        if (!ret) {
                            logi("hermas_cache", "write cache back to local directory, filename = %s", local_file_writer->GetFilePath().strValue().c_str());
                            local_file_writer->CloseFile();
                            MoveCache2LocalFile(local_file_writer->GetFilePath());
                            local_file_writer = nullptr;
                        }
                    }
                }
            }
            file_reader->CloseFile();
            RemoveFile(file_path);
            logi("hermas_cache", "remove cache file, filename = %s", file_path.strValue().c_str());
        }
        RenameRetryFiles(m_rename_file_list);
    }
    if (ready_file_writer) {
        logi("hermas_cache", "write cache back to ready directory, filename = %s", ready_file_writer->GetFilePath().strValue().c_str());
        ready_file_writer->CloseFile();
        MoveCache2ReadyFile(ready_file_writer->GetFilePath());
    }
    if (local_file_writer) {
        logi("hermas_cache", "write cache back to local directory, filename = %s", local_file_writer->GetFilePath().strValue().c_str());
        local_file_writer->CloseFile();
        MoveCache2LocalFile(local_file_writer->GetFilePath());
    }
}

FSQueue CacheService::CollectFileDirs() {
    FSQueue file_dirs;
    auto global_cache_path = GenCacheDirPath(m_env->GetModuleEnv());
    auto aid_path = global_cache_path.Append(m_env->GetAid());
    std::unique_ptr<FilesCollect> files_collect = std::make_unique<FilesCollect>(aid_path);
    file_dirs.push_back(std::move(files_collect));
    return file_dirs;
}

bool CacheService::NeedUpload(const std::string& content, std::string& after_content) {
    Json::Value object;
    bool ret = hermas::ParseFromJson(content, object);
    if (!ret) return false;
    
    if (object.isObject() && object["enable_upload"].asBool() && m_env->sequence_number_generator != nullptr) {
        object["sequence_number"] = m_env->sequence_number_generator();
        object["sequence_code"] = object["sequence_number"];
        after_content = object.toStyledString();
        return true;
    }
    after_content = content;
    return false;
}

std::unique_ptr<MmapReadFile> CacheService::GenerateFileReader(FilePath& file_path) {
    std::unique_ptr<MmapReadFile> file_reader = std::make_unique<MmapReadFile>(file_path);
    bool file_opened = file_reader->OpenReadFile();
    if (!file_opened) {
        if (file_reader->IsOverMaxOpenRetryTimes()) {
            //over max retry times, delete file auto
            RemoveFile(file_path);
            logi("hermas_cache", "failed to open file and over max open retry times, delete it, filename = %s", file_path.strValue().c_str());
        } else {
            //rename, add retry times
            m_rename_file_list.push_back(file_path);
            logi("hermas_cache", "failed to open file and add it to rename file list, filename = %s", file_path.strValue().c_str());
        }
        return nullptr;
    }
    if (file_reader->HasNext()) {
        std::string data_line = file_reader->ReadNext();
        file_reader->SyncOffsetAfterReadHead();
    }
    return file_reader;
}

std::unique_ptr<MmapWriteFile> CacheService::GenerateFileWriter(const FilePath& file_path) {
    auto file_writer = std::make_unique<MmapWriteFile>(file_path);
    std::string record_head = ProtocolService::GenRecordHead(m_env);
    bool ret = file_writer->CreateWriteFile(MmapFile::FILE_TYPE_NORMAL, Env::ERecordEncryptVer::NONE);
    if (!ret) return nullptr;
    ret = file_writer->Write(record_head.c_str(), (int32_t)record_head.length());
    if (!ret) return nullptr;
    return file_writer;
}

bool CacheService::Record(std::unique_ptr<MmapWriteFile>& file_writer, const std::string& content) {
    if (!file_writer) return false;
    bool ret = file_writer->Write(content.c_str(), (int32_t)content.length());
    return ret;
}

void CacheService::RenameRetryFiles(std::vector<FilePath>& rename_file_list) {
    for (auto iterator = rename_file_list.begin(); iterator != rename_file_list.end(); ++iterator) {
        auto old_file_path = (*iterator).strValue();
        int8_t retry_time = STR_TO_INT(old_file_path.substr(old_file_path.length() - 1, old_file_path.length()).c_str());
        retry_time++;
        StringType old_retry_time_file_path = StringType(old_file_path);
        StringType new_retry_time_file_path = old_file_path.replace(old_file_path.length() - 1, 1, TO_STRING(retry_time));
        RENAME_FILE(old_retry_time_file_path.c_str(), new_retry_time_file_path.c_str());
    }
}

FilePath CacheService::GenCache2ReadyFile(const FilePath& file_path) {
    auto base_name = std::to_string(INTERVAL_15000) + file_path.FullBaseName().strValue().substr(2);
    return file_path.DirName().Append(base_name);
}

FilePath CacheService::GenCache2LocalFile(const FilePath& file_path) {
    auto base_name = std::to_string(LOCAL_RECORDER_TYPE) + file_path.FullBaseName().strValue().substr(2);
    return file_path.DirName().Append(base_name);
}

void CacheService::MoveCache2ReadyFile(const FilePath& file_path) {
    auto ready_dir = GenReadyDirPath(m_env->GetModuleEnv());
    FilePath target_path = ready_dir.Append(file_path.DirName().BaseName()).Append(std::to_string(INTERVAL_15000)).Append(file_path.FullBaseName());
    RenameFile(file_path, target_path);
}

void CacheService::MoveCache2LocalFile(const FilePath& file_path) {
    auto local_dir = GenLocalDirPath(m_env->GetModuleEnv());
    FilePath target_path = local_dir.Append(file_path.DirName().BaseName()).Append(file_path.FullBaseName());
    RenameFile(file_path, target_path);
}

}
