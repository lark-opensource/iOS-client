//
// Created by bytedance on 2020/8/19.
//

#ifndef HERMAS_MMAP_READ_FILE_H
#define HERMAS_MMAP_READ_FILE_H

#include "mmap_file.h"

namespace hermas {

class ModuleEnv;

const static int8_t MAX_OPEN_RETRY_TIME = 3;

class MmapReadFile : public MmapFile {
public:
    MmapReadFile(const FilePath& file_path);
    virtual ~MmapReadFile();

public:
    bool OpenReadFile();
    bool HasNext();
    std::string ReadNext();
    int GetCurrentFileOffset();
    bool IsOverMaxOpenRetryTimes();
    bool SetOffset(int32_t offset);
    void SyncOffsetAfterReadHead();
    virtual void CloseFile() override;

private:
    bool SafeRead();

    int32_t GetContentLen();
    int32_t GetOffset();
};

} //namespace hermas


#endif //HERMAS_MMAP_READ_FILE_H
