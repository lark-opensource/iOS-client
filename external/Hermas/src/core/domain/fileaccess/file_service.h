//
// Created by bytedance on 2020/8/7.
//

#ifndef HERMAS_FILE_SERVICE_H
#define HERMAS_FILE_SERVICE_H

#include <string>
#include <vector>
#include <deque>
#include <mutex>
#include <memory>

#include "base_domain.h"
#include "mmap_write_file.h"
#include "mmap_read_file.h"
#include "files_collect.h"
#include "process_lock.h"
#include "file_service_util.h"
#include "env.h"

namespace hermas {

// FileService是要具体到每个Aid对应一个文件的
    
class FileService final: public infrastruct::BaseDomainService<> {
public:
    explicit FileService(const std::shared_ptr<Env>&env);
    ~FileService();
    
    std::unique_ptr<MmapWriteFile> NewFile(int type);
    bool WriteFile(MmapWriteFile* file_id, const char *data, int data_len, bool is_header = false);
    void CloseFile(MmapWriteFile* file_id);
	const FilePath GetFilePath(MmapWriteFile* file_id);
    
    void MoveFileReady(const FilePath& path, int type);
    void SaveFailData(std::string& process_name, const char* data, int64_t len);

private:
    const FilePath GenPrepareDirPath();
    const FilePath GenReadyDirPath();
    const FilePath GenCacheDirPath();
    const FilePath GenLocalDirPath();
    
private:
    std::shared_ptr<Env> m_env;
    std::mutex m_running_file_lock_mutex;
    int m_file_id = 0;
};

} // namespace hermas


#endif //HERMAS_FILE_SERVICE_H
