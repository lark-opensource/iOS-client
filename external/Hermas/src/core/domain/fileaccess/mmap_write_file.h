//
// Created by bytedance on 2020/8/19.
//

#ifndef HERMAS_MMAP_WRITE_FILE_H
#define HERMAS_MMAP_WRITE_FILE_H

#include "mmap_file.h"

namespace hermas {

class ModuleEnv;

class MmapWriteFile : public MmapFile {
public:
    explicit MmapWriteFile(const FilePath& file_path);
    virtual ~MmapWriteFile();

public:
    bool CreateWriteFile(E_FileType file_type, Env::ERecordEncryptVer encrypt_ver, int assigned_max_file_size = 0);
    bool Write(const char *record, int32_t record_len, bool is_header = false);
    virtual void CloseFile() override;
    bool CheckFileSizeExcludeFirstRecord(int required_len);

private:
    void SyncContentLen(int len);
    void UpdateStopTime();
    bool CheckFileSizeAndExpandIfFirst(int required_len, bool is_first_log);
    
private:
    bool m_first_log_wrote;
};

} //namespace hermas

#endif //HERMAS_MMAP_WRITE_FILE_H
