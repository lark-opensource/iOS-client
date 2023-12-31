//
//  aggre_mmap_file.h
//  Hermas
//
//  Created by liuhan on 2022/1/20.
//

#ifndef aggre_mmap_file_h
#define aggre_mmap_file_h

#include "mmap_file.h"
#include "semifinished_helper.h"

namespace hermas {

class ModuleEnv;

class AggreMmapFile {
public:
    AggreMmapFile(const FilePath& file_path);
    ~AggreMmapFile();
    
public:
    bool CreatAggreFile(int aggre_file_max_size);
    bool OpenAggreFile();
    void CloseFile();
    bool WriteAggreFile(const char *record, int32_t record_len, int32_t file_offset);
    std::string ReadAggreFile(int32_t file_offset, int32_t block_len);
    bool WriteRecordAndLength(const char *record, int32_t record_len, int32_t file_offset);
    int32_t ReadRecordLength(int32_t file_offset, int32_t length);

private:
    bool CheckFileSize(int required_len, int32_t file_offset);
    bool CheckAndExpandFileSize(int required_len, int expand_len, int32_t file_offset);

public:
    FilePath const m_file_path;
    FILE_HANDLE m_fd;
    long long m_file_len; //文件总大小
    char *mp_mmap_file; //文件起始地址
    char *mp_mmap_file_content; //文件内容起始地址
    
};
}

#endif /* aggre_mmap_file_h */
