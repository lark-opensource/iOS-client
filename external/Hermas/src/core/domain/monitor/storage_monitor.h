//
//  storage_monitor.h
//  Hermas
//
//  Created by 崔晓兵 on 25/2/2022.
//

#ifndef storage_monitor_h
#define storage_monitor_h

#include <string>
#include <vector>
#include "env.h"
#include "service_factory.hpp"

namespace hermas {

class StorageMonitor : public ServiceFactory<StorageMonitor>  {
 
public:
    std::tuple<int64_t, int64_t, int64_t, int64_t, int64_t> GetDirInfo();
    
    long GetReadyDirSize();
    
    void MovePrepareToReadyAndLocal();

    void CleanStorageIfNeeded();
    
    bool IsMoveFinished();
    
    void RemoveFilesWithMaxRemainSeconds(int max_remain_seconds);
    std::function<void()> OnMoveFinished;
    
private:
    explicit StorageMonitor(const std::shared_ptr<ModuleEnv>& module_env) : m_module_env(module_env) {}
    friend class ServiceFactory<StorageMonitor>;
    
private:
    bool CheckIfNeedRemoveLocal(const std::vector<FilePath>& local_files);
    bool CheckIfNeedRemoveReadyAndCache(const std::vector<FilePath>& cache_files, const std::vector<FilePath>& ready_files);
    void RemoveExpiredFiles(std::vector<FilePath>& files);
    void RemoveExpiredFiles(std::vector<FilePath>& files, int out_date);
    bool RemoveFilesOneByOne(std::vector<FilePath>& files, const std::function<bool()>& callback);
    
private:
    std::shared_ptr<ModuleEnv> m_module_env;
    std::atomic<bool> m_move_finished;
};

}  //namespace hermas
#endif /* storage_monitor_h */
