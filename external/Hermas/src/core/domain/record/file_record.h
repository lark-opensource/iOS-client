//
// Created by bytedance on 2020/8/6.
//

#ifndef HERMAS_FILE_RECORD_H
#define HERMAS_FILE_RECORD_H

#include <stdint.h>
#include "ifile_record.h"
#include "mmap_write_file.h"
#include "env.h"
#include "mmap_file.h"
#include "file_service.h"
#include "protocol_service.h"

namespace hermas {

class FileRecord final : public IFileRecord {
public:
    FileRecord(const std::shared_ptr<Env>& env, const std::shared_ptr<FileService> file_service, int type);
    ~FileRecord() = default;

public:
    void NewFile() override;
    ERecordRet Record(const std::string& content) override;
    void Close() override;

    bool IsFileValid() override;
    FilePath GetFilePath() override;

private:
    static constexpr int RECORD_BODY_MAX_SIZE = 1024 * 4;

    std::shared_ptr<Env> m_env;
    std::shared_ptr<FileService> m_file_service;
    int m_type;
    bool m_is_head_wrote;
    std::unique_ptr<MmapWriteFile> m_file_id;
    int m_line_count;
};

} //namespace hermas

#endif //HERMAS_FILE_RECORD_H
