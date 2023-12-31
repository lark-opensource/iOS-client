//
//  storage_monitor.cpp
//  Hermas
//
//  Created by 崔晓兵 on 25/2/2022.
//

#include "storage_monitor.h"
#include "file_path.h"
#include "files_collect.h"
#include "file_util.h"
#include "file_service.h"
#include "time_util.h"
#include "log.h"
#include "file_service_util.h"
#include <vector>
#include <memory>

namespace hermas {

void StorageMonitor::MovePrepareToReadyAndLocal() {
    m_move_finished.store(false, std::memory_order_release);
    hermas::MovePrepareToReadyAndLocal(m_module_env);
    m_move_finished.store(true, std::memory_order_release);
    if (OnMoveFinished != nullptr) OnMoveFinished();
}

bool StorageMonitor::IsMoveFinished() {
    return m_move_finished;
}

std::tuple<int64_t, int64_t, int64_t, int64_t, int64_t> StorageMonitor::GetDirInfo() {
    auto local_path = GenLocalDirPath(m_module_env);
    auto cache_path = GenCacheDirPath(m_module_env);
    auto ready_path = GenReadyDirPath(m_module_env);
    auto aggre_path = GenAggregateDirPath(m_module_env);
    auto semi_path = GenSemifinishedDirPath(m_module_env);
    
    // collect file path
    std::vector<FilePath> local_files = GetFilesNameRecursively(local_path);
    std::vector<FilePath> cache_files = GetFilesNameRecursively(cache_path);
    std::vector<FilePath> ready_files = GetFilesNameRecursively(ready_path);
    std::vector<FilePath> aggre_files = GetFilesNameRecursively(aggre_path);
    std::vector<FilePath> semi_files = GetFilesNameRecursively(semi_path);
    
    int total_aggre_size = 0, total_semi_size = 0;
    for (auto& fp : aggre_files) total_aggre_size += GetFileSize(fp);
    for (auto& fp : semi_files) total_semi_size += GetFileSize(fp);
    
    int file_size =  GlobalEnv::GetInstance().GetMaxFileSize();
    return std::make_tuple<int64_t, int64_t, int64_t, int64_t, int64_t>((int)local_files.size() * file_size,
                                                                        (int)cache_files.size() * file_size,
                                                                        (int)ready_files.size() * file_size,
                                                                        total_aggre_size,
                                                                        total_semi_size);
}

long StorageMonitor::GetReadyDirSize() {
    auto ready_path = GenReadyDirPath(m_module_env);
    std::vector<FilePath> ready_files = GetFilesNameRecursively(ready_path);
    int file_size = GlobalEnv::GetInstance().GetMaxFileSize();
    return ready_files.size() * file_size;
}

void StorageMonitor::CleanStorageIfNeeded() {

    auto local_path = GenLocalDirPath(m_module_env);
    auto cache_path = GenCacheDirPath(m_module_env);
    auto ready_path = GenReadyDirPath(m_module_env);
    
    // collect file path
    std::vector<FilePath> local_files = GetFilesNameRecursively(local_path);
    std::vector<FilePath> cache_files = GetFilesNameRecursively(cache_path);
    std::vector<FilePath> ready_files = GetFilesNameRecursively(ready_path);
    
    // remove expired data in local|cache|ready directory
    RemoveExpiredFiles(local_files);
    RemoveExpiredFiles(cache_files);
    RemoveExpiredFiles(ready_files);
    logi("After removing expired data", "detail: local %d, cache %d, ready %d", local_files.size(), cache_files.size(), ready_files.size());
   
    
    // remove old local files
    RemoveFilesOneByOne(local_files, [this, &local_files]() -> bool {
        return CheckIfNeedRemoveLocal(local_files);
    });
    
    // remove old cache files
    RemoveFilesOneByOne(cache_files, [this, &cache_files, &ready_files]() -> bool {
        return CheckIfNeedRemoveReadyAndCache(cache_files, ready_files);
    });
    
    // remove old ready files
    RemoveFilesOneByOne(ready_files, [this, &cache_files, &ready_files]() -> bool {
        return CheckIfNeedRemoveReadyAndCache(cache_files, ready_files);
    });
    logi("After removing exceeded files", "detail: local %d, cache %d, ready %d", local_files.size(), cache_files.size(), ready_files.size());
}

void StorageMonitor::RemoveFilesWithMaxRemainSeconds(int max_remain_seconds) {
    auto local_path = GenLocalDirPath(m_module_env);
    auto cache_path = GenCacheDirPath(m_module_env);
    auto ready_path = GenReadyDirPath(m_module_env);
    
    // collect file path
    std::vector<FilePath> local_files = GetFilesNameRecursively(local_path);
    std::vector<FilePath> cache_files = GetFilesNameRecursively(cache_path);
    std::vector<FilePath> ready_files = GetFilesNameRecursively(ready_path);
    
    // remove expired data in local|cache|ready directory
    RemoveExpiredFiles(local_files, max_remain_seconds);
    RemoveExpiredFiles(cache_files, max_remain_seconds);
    RemoveExpiredFiles(ready_files, max_remain_seconds);
    logi("After removing expired data", "detail: max_remain_seconds %d, local %d, cache %d, ready %d", max_remain_seconds, local_files.size(), cache_files.size(), ready_files.size());
}

void StorageMonitor::RemoveExpiredFiles(std::vector<FilePath>& files, int out_date) {
    auto current_time = CurTimeMillis();
    auto it = files.begin();
    while (it != files.end()) {
        int64_t create_time = GetFileCreateTime(*it);
        if (current_time - create_time >= out_date * 1000) {
            RemoveFile(*it);
            it = files.erase(it);
        } else {
            it++;
        }
    }
}

void StorageMonitor::RemoveExpiredFiles(std::vector<FilePath>& files) {
    RemoveExpiredFiles(files, GlobalEnv::GetInstance().GetMaxStoreTime());
}

bool StorageMonitor::RemoveFilesOneByOne(std::vector<FilePath>& files, const std::function<bool()>& callback) {
    bool need_remove = callback();
    if (!need_remove) return false;
    std::sort(files.begin(), files.end(), [](FilePath& a, FilePath& b) -> bool {
        return GetFileCreateTime(a) < GetFileCreateTime(b);
    });
    
    auto it = files.begin();
    while (it != files.end() && callback()) {
        RemoveFile(*it);
        it = files.erase(it);
    }
    return callback();
}


bool StorageMonitor::CheckIfNeedRemoveLocal(const std::vector<FilePath>& local_files) {
    auto total_file_count = local_files.size();
    auto total_file_size = total_file_count * GlobalEnv::GetInstance().GetMaxFileSize();
    // 添加动线local size
    
    int max_local_store_size = m_module_env->GetMaxLocalStoreSize();
    if (max_local_store_size <= 0) {
        max_local_store_size = m_module_env->GetMaxStoreSize() * 0.2;
    }
    bool need_remove = total_file_size > max_local_store_size;
    return need_remove;
}

bool StorageMonitor::CheckIfNeedRemoveReadyAndCache(const std::vector<FilePath>& cache_files, const std::vector<FilePath>& ready_files) {
    auto total_file_count = ready_files.size() + cache_files.size();
    auto total_file_size = total_file_count * GlobalEnv::GetInstance().GetMaxFileSize();
    bool need_remove = total_file_size > m_module_env->GetMaxStoreSize() * 0.8;
    return need_remove;
}

}  //namespace hermas
